import { Router } from 'express';
import mongoose from 'mongoose';
import { Product, shapeProduct } from '../models/Product.js';
import { Category } from '../models/Category.js';

const router = Router();

const isObjectId = (v) => mongoose.isValidObjectId(v) && String(v).length === 24;

/**
 * Resolves a category param (an ObjectId string OR a category name like
 * "Skin") to its ObjectId. Returns null if it can't be resolved.
 */
async function resolveCategoryId(value) {
  if (!value) return null;
  if (isObjectId(value)) return new mongoose.Types.ObjectId(value);
  const cat = await Category.findOne({ name: new RegExp(`^${escapeRegex(value)}$`, 'i') });
  return cat ? cat._id : null;
}

/**
 * Resolves a subcategory param (an ObjectId string OR a subcategory name) to
 * its ObjectId, optionally scoped to a known category id.
 */
async function resolveSubcategoryId(value, categoryId) {
  if (!value) return null;
  if (isObjectId(value)) return new mongoose.Types.ObjectId(value);
  const query = categoryId ? { _id: categoryId } : {};
  const cats = await Category.find(query);
  for (const cat of cats) {
    const sub = (cat.subcategories || []).find(
      (s) => (s.name || '').toLowerCase() === String(value).toLowerCase()
    );
    if (sub) return sub._id;
  }
  return null;
}

/**
 * GET /api/products?category=<id|name>&subcategory=<id|name>&q=&all=true
 * Lists available products, optionally filtered by category & subcategory.
 */
router.get('/', async (req, res, next) => {
  try {
    const { category, subcategory, q, all } = req.query;
    const filter = {};

    // Only show published/available products unless ?all=true is passed.
    if (all !== 'true') filter.available = { $ne: false };

    if (category) {
      const categoryId = await resolveCategoryId(category);
      // Unresolvable category -> no products rather than everything.
      if (!categoryId) return res.json([]);
      filter.category = categoryId;

      if (subcategory) {
        const subId = await resolveSubcategoryId(subcategory, categoryId);
        if (!subId) return res.json([]);
        filter.subcategory = subId;
      }
    } else if (subcategory) {
      const subId = await resolveSubcategoryId(subcategory, null);
      if (!subId) return res.json([]);
      filter.subcategory = subId;
    }

    if (q) filter.productName = { $regex: escapeRegex(q), $options: 'i' };

    const products = await Product.find(filter).sort({ updatedDate: -1 });
    res.json(products.map(shapeProduct));
  } catch (err) {
    next(err);
  }
});

/** GET /api/products/:id — single product by `pid` (or Mongo _id). */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const product = await Product.findOne(
      isObjectId(id) ? { $or: [{ pid: id }, { _id: id }] } : { pid: id }
    );
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.json(shapeProduct(product));
  } catch (err) {
    next(err);
  }
});

/** Escapes user input before using it inside a RegExp. */
function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export default router;
