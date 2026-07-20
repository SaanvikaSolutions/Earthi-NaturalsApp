import mongoose from 'mongoose';

/**
 * Read-only model over the existing `categories` collection in the `test` DB.
 * Each category embeds its subcategories (each with its own ObjectId _id, which
 * products reference via their `subcategory` field).
 */
const subcategorySchema = new mongoose.Schema(
  {
    name: { type: String },
    enabled: { type: Boolean, default: true },
  },
  { _id: true }
);

const categorySchema = new mongoose.Schema(
  {
    name: { type: String },
    enabled: { type: Boolean, default: true },
    subcategories: { type: [subcategorySchema], default: [] },
  },
  { collection: 'categories', strict: false, timestamps: true }
);

export const Category = mongoose.model('Category', categorySchema);
