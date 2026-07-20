import { Router } from 'express';
import { Category } from '../models/Category.js';

const router = Router();

/**
 * GET /api/categories
 * Enabled categories with their enabled subcategories, shaped as
 * { id, name, subcategories: [{ id, name }] }.
 */
router.get('/', async (_req, res, next) => {
  try {
    const cats = await Category.find({ enabled: { $ne: false } }).sort({ createdAt: 1 });
    const shaped = cats.map((c) => ({
      id: String(c._id),
      name: c.name || '',
      subcategories: (c.subcategories || [])
        .filter((s) => s.enabled !== false)
        .map((s) => ({ id: String(s._id), name: s.name || '' })),
    }));
    res.json(shaped);
  } catch (err) {
    next(err);
  }
});

export default router;
