import crypto from 'node:crypto';
import { Router } from 'express';
import { Order } from '../models/Order.js';
import { requireAuth } from '../middleware/auth.js';
import { priceCart, PricingError } from '../services/pricing.js';
import {
  razorpay,
  RAZORPAY_KEY_ID,
  RAZORPAY_KEY_SECRET,
  RAZORPAY_WEBHOOK_SECRET,
} from '../config/razorpay.js';

const router = Router();

/** Constant-time compare so a wrong signature can't be brute-forced byte by byte. */
function safeEqual(a, b) {
  const bufA = Buffer.from(String(a), 'utf8');
  const bufB = Buffer.from(String(b), 'utf8');
  if (bufA.length !== bufB.length) return false;
  return crypto.timingSafeEqual(bufA, bufB);
}

function hmac(payload, secret) {
  return crypto.createHmac('sha256', secret).update(payload).digest('hex');
}

/** "EN" + 6 digits, retried on the (unlikely) unique-index collision. */
function makeReference() {
  return 'EN' + String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
}

/**
 * POST /api/payments/order — start a checkout.
 *
 * body: { items: [{ productSlug, size, qty }] }   // note: no prices
 *
 * Prices the cart from the database, records a 'Pending payment' order, and
 * opens a matching Razorpay order. Returns everything the app needs to launch
 * checkout — including the *public* key id, never the secret.
 */
router.post('/order', requireAuth, async (req, res, next) => {
  try {
    const { items: rawItems } = req.body || {};
    const priced = await priceCart(rawItems);

    let order;
    for (let attempt = 0; attempt < 5 && !order; attempt++) {
      try {
        order = await Order.create({
          user: req.userId,
          reference: makeReference(),
          status: 'Pending payment',
          items: priced.items,
          subtotal: priced.subtotal,
          deliveryFee: priced.deliveryFee,
          total: priced.total,
        });
      } catch (err) {
        if (err?.code !== 11000) throw err; // 11000 = duplicate reference
      }
    }
    if (!order) throw new Error('could not allocate an order reference');

    // Razorpay works in the smallest currency unit — paise, not rupees.
    const rzOrder = await razorpay.orders.create({
      amount: priced.total * 100,
      currency: 'INR',
      receipt: order.reference,
      notes: { orderId: String(order._id), userId: String(req.userId) },
    });

    order.payment = {
      provider: 'razorpay',
      razorpayOrderId: rzOrder.id,
      status: 'created',
      amount: priced.total,
    };
    await order.save();

    res.status(201).json({
      orderId: String(order._id),
      reference: order.reference,
      razorpayOrderId: rzOrder.id,
      amount: rzOrder.amount, // paise
      currency: rzOrder.currency,
      keyId: RAZORPAY_KEY_ID,
      subtotal: priced.subtotal,
      deliveryFee: priced.deliveryFee,
      total: priced.total,
    });
  } catch (err) {
    if (err instanceof PricingError) {
      return res.status(err.status).json({ error: err.message });
    }
    next(err);
  }
});

/**
 * POST /api/payments/verify — confirm a completed checkout.
 *
 * body: { razorpay_order_id, razorpay_payment_id, razorpay_signature }
 *
 * The signature is HMAC-SHA256("<order_id>|<payment_id>") keyed with our secret,
 * so only Razorpay could have produced it. This check is what makes the order
 * real: without it a patched app could report a success it never paid for.
 */
router.post('/verify', requireAuth, async (req, res, next) => {
  try {
    const {
      razorpay_order_id: rzOrderId,
      razorpay_payment_id: rzPaymentId,
      razorpay_signature: signature,
    } = req.body || {};

    if (!rzOrderId || !rzPaymentId || !signature) {
      return res.status(400).json({
        error: 'razorpay_order_id, razorpay_payment_id and razorpay_signature are required',
      });
    }

    // Scope to the caller so one user can't settle another user's order.
    const order = await Order.findOne({
      'payment.razorpayOrderId': rzOrderId,
      user: req.userId,
    });
    if (!order) return res.status(404).json({ error: 'Order not found' });

    const expected = hmac(`${rzOrderId}|${rzPaymentId}`, RAZORPAY_KEY_SECRET);
    if (!safeEqual(expected, signature)) {
      order.status = 'Payment failed';
      order.payment.status = 'failed';
      order.payment.failureReason = 'signature mismatch';
      await order.save();
      return res.status(400).json({ error: 'Payment verification failed' });
    }

    // Replaying a verified payment must not double-place the order.
    if (order.payment.status !== 'paid') {
      order.status = 'Placed';
      order.payment.status = 'paid';
      order.payment.razorpayPaymentId = rzPaymentId;
      order.payment.paidAt = new Date();
      order.payment.failureReason = undefined;
      await order.save();
    }

    res.json(order);
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/payments/webhook — Razorpay's server-to-server confirmation.
 *
 * The app can die between paying and calling /verify (backgrounded, network
 * drop, force-quit). This fires regardless, so the money and the order stay in
 * sync. Unauthenticated by design — the signature over the raw body is the auth.
 * Needs `req.rawBody`, captured by the express.json verify hook in server.js.
 */
router.post('/webhook', async (req, res) => {
  if (!RAZORPAY_WEBHOOK_SECRET) return res.status(503).json({ error: 'Webhook not configured' });

  const signature = req.get('X-Razorpay-Signature');
  const raw = req.rawBody;
  if (!signature || !raw) return res.status(400).json({ error: 'Missing signature' });
  if (!safeEqual(hmac(raw, RAZORPAY_WEBHOOK_SECRET), signature)) {
    return res.status(400).json({ error: 'Invalid signature' });
  }

  // Acknowledge immediately — Razorpay retries on any non-2xx, and a slow or
  // throwing handler turns one payment into a retry storm.
  res.json({ ok: true });

  try {
    const event = req.body?.event;
    const entity = req.body?.payload?.payment?.entity;
    if (!entity?.order_id) return;

    const order = await Order.findOne({ 'payment.razorpayOrderId': entity.order_id });
    if (!order) return;

    if (event === 'payment.captured' && order.payment.status !== 'paid') {
      order.status = 'Placed';
      order.payment.status = 'paid';
      order.payment.razorpayPaymentId = entity.id;
      order.payment.paidAt = new Date();
      await order.save();
    } else if (event === 'payment.failed' && order.payment.status === 'created') {
      order.status = 'Payment failed';
      order.payment.status = 'failed';
      order.payment.failureReason = entity.error_description || 'payment failed';
      await order.save();
    }
  } catch (err) {
    console.error('webhook handling failed:', err);
  }
});

export default router;
