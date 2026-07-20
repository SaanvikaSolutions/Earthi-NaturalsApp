import { Router } from 'express';
import { Order } from '../models/Order.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

/**
 * GET /api/orders — the signed-in user's orders, newest first.
 *
 * Abandoned checkouts ('Pending payment') are hidden: the user closed the
 * Razorpay sheet without paying, and surfacing those as orders is confusing.
 * Failed payments stay visible so they can retry.
 */
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const orders = await Order.find({
      user: req.userId,
      status: { $ne: 'Pending payment' },
    }).sort({ createdAt: -1 });
    res.json(orders);
  } catch (err) {
    next(err);
  }
});

// Orders are no longer created here. Creating one is step 1 of paying for it,
// so it lives in POST /api/payments/order — which prices the cart from the
// database and leaves the order 'Pending payment' until a Razorpay signature
// has been verified. A plain create endpoint would hand out free orders.

export default router;
