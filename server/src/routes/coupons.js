import { Router } from 'express';
import { listActiveCoupons } from '../services/coupons.js';
import { CouponError } from '../services/coupons.js';
import { priceCart, PricingError } from '../services/pricing.js';

const router = Router();

/** GET /api/coupons — offers the customer can pick from in the cart. */
router.get('/', (_req, res) => {
  res.json(listActiveCoupons());
});

/**
 * POST /api/coupons/validate — check a code against a cart.
 *
 * body: { code, items: [{ productSlug, size, qty }] }
 *
 * Prices the cart from the database and applies the code to it, so the minimum
 * cart check uses real prices. Returns the coupon's rules (so the app can keep
 * the discount in step as the cart changes) and the resulting totals. Nothing
 * is saved — /api/payments/order applies the code again when the order is made.
 */
router.post('/validate', async (req, res, next) => {
  try {
    const { code, items } = req.body || {};
    if (!String(code ?? '').trim()) {
      return res.status(400).json({ error: 'Enter a coupon code' });
    }
    const priced = await priceCart(items, code);
    res.json({
      coupon: priced.coupon,
      subtotal: priced.subtotal,
      deliveryFee: priced.deliveryFee,
      discount: priced.discount,
      total: priced.total,
    });
  } catch (err) {
    if (err instanceof CouponError || err instanceof PricingError) {
      return res.status(err.status).json({ error: err.message });
    }
    next(err);
  }
});

export default router;
