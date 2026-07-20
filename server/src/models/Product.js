import mongoose from 'mongoose';

/**
 * Read-only model over the existing `products` collection in the `test` DB.
 *
 * Real shape: { pid, productName, category(ObjectId -> categories._id),
 * subcategory(ObjectId -> categories.subcategories._id), description,
 * ingredients, howToUse, imgurls[], pricings[], available, reviews[] }.
 *
 * `strict: false` keeps every stored field intact; the API never writes here.
 */
const pricingSchema = new mongoose.Schema(
  {
    uid: String,
    unit: String,
    quantity: Number,
    price: Number,
    discount: Number,
    finalPrice: Number,
    inStock: Boolean,
    stockCount: Number,
  },
  { _id: false, strict: false }
);

const productSchema = new mongoose.Schema(
  {
    pid: { type: String, index: true },
    productName: String,
    category: { type: mongoose.Schema.Types.ObjectId, index: true },
    subcategory: { type: mongoose.Schema.Types.ObjectId, index: true },
    description: String,
    ingredients: String,
    howToUse: String,
    imgurls: { type: [String], default: [] },
    pricings: { type: [pricingSchema], default: [] },
    available: { type: Boolean, default: true },
    reviews: { type: [mongoose.Schema.Types.Mixed], default: [] },
    updatedDate: Date,
  },
  { collection: 'products', strict: false }
);

/**
 * Shapes a raw product document into the JSON the Flutter app expects:
 * { id, name, category, subcategory, image, images, price, mrp, rating,
 *   reviews, description, ingredients, howToUse, sizes }.
 * `category`/`subcategory` are the ObjectId references (as strings).
 */
export function shapeProduct(p) {
  const doc = typeof p.toObject === 'function' ? p.toObject() : p;
  const pricings = Array.isArray(doc.pricings) ? doc.pricings : [];
  const primary = pricings[0] || {};
  const sizes = pricings
    .map((pr) => `${pr.quantity ?? ''}${pr.unit || ''}`.trim())
    .filter(Boolean);

  const reviews = Array.isArray(doc.reviews) ? doc.reviews : [];
  const ratings = reviews
    .map((r) => (r && typeof r.rating === 'number' ? r.rating : null))
    .filter((n) => n !== null);
  const rating = ratings.length
    ? ratings.reduce((a, b) => a + b, 0) / ratings.length
    : 0;

  const finalPrice = primary.finalPrice ?? primary.price ?? 0;
  const price = primary.price ?? finalPrice;

  return {
    id: doc.pid || String(doc._id),
    name: doc.productName || '',
    category: doc.category ? String(doc.category) : '',
    subcategory: doc.subcategory ? String(doc.subcategory) : '',
    image: (doc.imgurls && doc.imgurls[0]) || '',
    images: doc.imgurls || [],
    price: Math.round(finalPrice),
    mrp: Math.round(price),
    rating: Math.round(rating * 10) / 10,
    reviews: reviews.length,
    description: doc.description || '',
    ingredients: doc.ingredients || '',
    howToUse: doc.howToUse || '',
    sizes,
    available: doc.available !== false,
  };
}

export const Product = mongoose.model('Product', productSchema);
