import mongoose from 'mongoose';
import { Product } from '../models/Product.js';

/** Flat delivery fee, in rupees. Mirrors CartController.deliveryFee. */
export const DELIVERY_FEE = 69;

/** Thrown when the cart can't be priced. Carries an HTTP status. */
export class PricingError extends Error {
  constructor(message, status = 400) {
    super(message);
    this.status = status;
  }
}

/** "50 ml" / "50ml" / "50 ML" all normalise to "50ml" so sizes compare safely. */
const normaliseSize = (s) => String(s ?? '').toLowerCase().replace(/\s+/g, '');

/** The size label a pricing row represents, e.g. { quantity: 50, unit: 'ml' } -> "50ml". */
const pricingLabel = (p) => normaliseSize(`${p.quantity ?? ''}${p.unit ?? ''}`);

/**
 * Re-prices a client-submitted cart against the database.
 *
 * The client sends only *what* it wants (product + size + qty); every rupee is
 * looked up here. Prices in the request body are ignored outright — trusting
 * them would let a patched app pay ₹1 for a ₹2000 order, and the payment
 * signature would still verify because it only proves the charged amount
 * matches the amount we asked Razorpay for.
 *
 * @param {Array<{productSlug: string, size: string, qty: number}>} rawItems
 * @returns {Promise<{items: Array, subtotal: number, deliveryFee: number, total: number}>}
 *   `items` are full order lines (name and unit price resolved server-side).
 */
export async function priceCart(rawItems) {
  if (!Array.isArray(rawItems) || rawItems.length === 0) {
    throw new PricingError('items array is required');
  }
  if (rawItems.length > 50) {
    throw new PricingError('too many items in one order');
  }

  const slugs = [...new Set(rawItems.map((i) => String(i.productSlug ?? '')))];
  if (slugs.some((s) => !s)) throw new PricingError('every item needs a productSlug');

  // Products are addressed by `pid`, but shapeProduct falls back to _id when a
  // document has no pid — so accept either form of identifier.
  const objectIds = slugs.filter((s) => mongoose.isValidObjectId(s));
  const products = await Product.find({
    $or: [{ pid: { $in: slugs } }, { _id: { $in: objectIds } }],
  });

  const byKey = new Map();
  for (const p of products) {
    if (p.pid) byKey.set(String(p.pid), p);
    byKey.set(String(p._id), p);
  }

  const items = [];
  let subtotal = 0;

  for (const raw of rawItems) {
    const slug = String(raw.productSlug);
    const qty = Number(raw.qty);
    if (!Number.isInteger(qty) || qty < 1 || qty > 99) {
      throw new PricingError(`invalid quantity for "${slug}"`);
    }

    const product = byKey.get(slug);
    if (!product) throw new PricingError(`unknown product "${slug}"`, 404);
    if (product.available === false) {
      throw new PricingError(`"${product.productName}" is no longer available`, 409);
    }

    const pricings = Array.isArray(product.pricings) ? product.pricings : [];
    if (pricings.length === 0) {
      throw new PricingError(`"${product.productName}" has no price set`, 409);
    }

    // Match the requested size; fall back to the primary pricing only when the
    // product is single-size, so a bad size can never silently pick a cheaper row.
    const wanted = normaliseSize(raw.size);
    const pricing =
      pricings.find((p) => pricingLabel(p) === wanted) ??
      (pricings.length === 1 && !wanted ? pricings[0] : null);

    if (!pricing) {
      throw new PricingError(
        `size "${raw.size}" is not available for "${product.productName}"`,
        409
      );
    }
    if (pricing.inStock === false) {
      throw new PricingError(
        `"${product.productName}" (${raw.size}) is out of stock`,
        409
      );
    }

    const unitPrice = Math.round(pricing.finalPrice ?? pricing.price ?? 0);
    if (!Number.isFinite(unitPrice) || unitPrice <= 0) {
      throw new PricingError(`"${product.productName}" has an invalid price`, 409);
    }

    subtotal += unitPrice * qty;
    items.push({
      productSlug: product.pid || String(product._id),
      name: product.productName || '',
      size: String(raw.size ?? ''),
      qty,
      price: unitPrice,
    });
  }

  return { items, subtotal, deliveryFee: DELIVERY_FEE, total: subtotal + DELIVERY_FEE };
}
