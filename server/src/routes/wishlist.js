import { Router } from 'express';
import { User } from '../models/User.js';
import { Product, shapeProduct } from '../models/Product.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

/** GET /api/wishlist  — full product objects for the user's saved product ids. */
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    const products = await Product.find({ pid: { $in: user.wishlist } });
    res.json(products.map(shapeProduct));
  } catch (err) {
    next(err);
  }
});

/** POST /api/wishlist/:slug  — add a product (by pid) to the wishlist. */
router.post('/:slug', requireAuth, async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.userId,
      { $addToSet: { wishlist: req.params.slug } },
      { new: true }
    );
    res.json({ wishlist: user.wishlist });
  } catch (err) {
    next(err);
  }
});

/** DELETE /api/wishlist/:slug  — remove a product from the wishlist. */
router.delete('/:slug', requireAuth, async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.userId,
      { $pull: { wishlist: req.params.slug } },
      { new: true }
    );
    res.json({ wishlist: user.wishlist });
  } catch (err) {
    next(err);
  }
});

export default router;
