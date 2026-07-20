import mongoose from 'mongoose';

const orderItemSchema = new mongoose.Schema(
  {
    productSlug: { type: String, required: true },
    name: { type: String, required: true },
    size: { type: String, required: true },
    qty: { type: Number, required: true, min: 1 },
    price: { type: Number, required: true }, // unit price at purchase time
  },
  { _id: false }
);

/**
 * Razorpay state for an order. `razorpayOrderId` is set when we ask Razorpay to
 * create an order; the rest lands only after a signature we've verified
 * ourselves. The key secret is never stored here.
 */
const paymentSchema = new mongoose.Schema(
  {
    provider: { type: String, default: 'razorpay' },
    razorpayOrderId: { type: String, index: true },
    razorpayPaymentId: { type: String },
    status: {
      type: String,
      enum: ['created', 'paid', 'failed'],
      default: 'created',
    },
    amount: { type: Number }, // rupees, as charged
    paidAt: { type: Date },
    failureReason: { type: String },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    reference: { type: String, required: true, unique: true }, // e.g. "EN1042"
    // Orders start unpaid and only reach 'Placed' once a Razorpay signature has
    // been verified server-side — never on the app's say-so.
    status: {
      type: String,
      enum: ['Pending payment', 'Payment failed', 'Placed', 'In transit', 'Delivered', 'Cancelled'],
      default: 'Pending payment',
    },
    items: { type: [orderItemSchema], required: true },
    subtotal: { type: Number, required: true },
    deliveryFee: { type: Number, required: true, default: 0 },
    total: { type: Number, required: true },
    payment: { type: paymentSchema, default: () => ({}) },
  },
  // Dedicated collection so app-placed orders don't mix with the existing
  // `orders` collection (which has a different schema).
  { timestamps: true, collection: 'app_orders' }
);

orderSchema.set('toJSON', {
  versionKey: false,
  transform: (_doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    return ret;
  },
});

export const Order = mongoose.model('Order', orderSchema);
