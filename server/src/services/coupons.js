/**
 * Coupon rules and validation.
 *
 * The server is the only place a discount is decided: the app shows what it is
 * told, and /api/payments/order re-applies the code from scratch, so a patched
 * app cannot invent a discount.
 *
 * These are SAMPLE codes for testing the flow. Replace them with the real
 * offers before launch (or move them into a MongoDB collection — applyCoupon
 * only needs `findCoupon` to return the same shape).
 *
 * Shape:
 *   code         – what the customer types (matched case-insensitively)
 *   title        – short description shown in the app
 *   type         – 'percent' | 'flat' | 'freeship'
 *   value        – percent (0-100) or rupees; unused for 'freeship'
 *   maxDiscount  – rupee cap for 'percent' coupons (optional)
 *   minCart      – minimum cart subtotal in rupees (after product discounts)
 *   expiresAt    – ISO date string, or null for no expiry
 */
export const COUPONS = [
  {
    code: 'WELCOME10',
    title: '10% off, up to ₹100',
    type: 'percent',
    value: 10,
    maxDiscount: 100,
    minCart: 499,
    expiresAt: null,
  },
  {
    code: 'EARTHI50',
    title: 'Flat ₹50 off',
    type: 'flat',
    value: 50,
    minCart: 399,
    expiresAt: null,
  },
  {
    code: 'NATURAL15',
    title: '15% off, up to ₹200',
    type: 'percent',
    value: 15,
    maxDiscount: 200,
    minCart: 999,
    expiresAt: null,
  },
  {
    code: 'FREESHIP',
    title: 'Free delivery',
    type: 'freeship',
    value: 0,
    minCart: 299,
    expiresAt: null,
  },
  {
    code: 'FESTIVE100',
    title: 'Flat ₹100 off',
    type: 'flat',
    value: 100,
    minCart: 1299,
    expiresAt: null,
  },
];

/** Thrown when a code can't be applied. `message` is safe to show to the customer. */
export class CouponError extends Error {
  constructor(message, status = 400) {
    super(message);
    this.status = status;
  }
}

/** Codes are typed by hand, so ignore case and stray spaces. */
export const normaliseCode = (code) => String(code ?? '').trim().toUpperCase();

export function findCoupon(code) {
  const wanted = normaliseCode(code);
  return COUPONS.find((c) => c.code === wanted) ?? null;
}

/** The fields the app needs to display a coupon and recompute it as the cart changes. */
export function publicCoupon(c) {
  return {
    code: c.code,
    title: c.title,
    type: c.type,
    value: c.value,
    maxDiscount: c.maxDiscount ?? null,
    minCart: c.minCart,
    expiresAt: c.expiresAt ?? null,
  };
}

/** Coupons that are currently usable, for the "pick an offer" list. */
export function listActiveCoupons(now = new Date()) {
  return COUPONS.filter((c) => !c.expiresAt || new Date(c.expiresAt) > now).map(publicCoupon);
}

/**
 * Applies [code] to a cart.
 *
 * @param {string} code
 * @param {number} subtotal    rupees, after product discounts, before delivery
 * @param {number} deliveryFee rupees
 * @returns {{coupon: object, discount: number}} `discount` is the total saving
 *   in rupees (for 'freeship' it equals the delivery fee), never more than
 *   what it is taken from, so the order total can't go negative.
 * @throws {CouponError} with a customer-facing message
 */
export function applyCoupon(code, subtotal, deliveryFee, now = new Date()) {
  if (!normaliseCode(code)) throw new CouponError('Enter a coupon code');

  const coupon = findCoupon(code);
  if (!coupon) throw new CouponError('Invalid coupon code');

  if (coupon.expiresAt && new Date(coupon.expiresAt) <= now) {
    throw new CouponError(`${coupon.code} has expired`);
  }

  if (subtotal < coupon.minCart) {
    const short = coupon.minCart - subtotal;
    throw new CouponError(
      `Add ₹${short} more to use ${coupon.code} (minimum cart ₹${coupon.minCart})`
    );
  }

  let discount = 0;
  switch (coupon.type) {
    case 'percent':
      discount = Math.floor((subtotal * coupon.value) / 100);
      if (coupon.maxDiscount != null) discount = Math.min(discount, coupon.maxDiscount);
      break;
    case 'flat':
      discount = coupon.value;
      break;
    case 'freeship':
      discount = deliveryFee;
      break;
    default:
      throw new CouponError('Invalid coupon code');
  }

  // Never discount below zero (or below ₹1 of goods) — Razorpay rejects ₹0 orders.
  const ceiling = coupon.type === 'freeship' ? deliveryFee : Math.max(subtotal - 1, 0);
  discount = Math.max(0, Math.min(discount, ceiling));

  return { coupon, discount };
}
