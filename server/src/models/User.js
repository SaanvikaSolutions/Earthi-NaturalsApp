import mongoose from 'mongoose';
import { randomUUID } from 'crypto';

/**
 * Bound to the EXISTING `users` collection — the real accounts live here, so the
 * app authenticates against them directly (rather than a separate `app_users`).
 *
 * The legacy schema stores the bcrypt hash under `password` (not `passwordHash`),
 * the phone as a numeric `phoneNumber` (with a unique index), and a unique `uid`.
 * We model only the fields we touch; `strict` defaults to true so existing extras
 * (refreshTokens, createdOn, gender, …) are left untouched on update.
 */
const userSchema = new mongoose.Schema(
  {
    uid: { type: String, unique: true, default: () => randomUUID() },
    name: { type: String, required: true },
    email: { type: String, required: true, lowercase: true, index: true },
    phoneNumber: { type: Number, unique: true },
    password: { type: String, required: true },
    role: { type: String, default: 'user' },
    // Saved product ids (pid values). Additive — absent on legacy docs, defaults to [].
    wishlist: { type: [String], default: [] },
  },
  // No timestamps: legacy docs use `createdOn`; we must not add createdAt/updatedAt.
  { collection: 'users' }
);

userSchema.set('toJSON', {
  versionKey: false,
  transform: (_doc, ret) => {
    ret.id = ret._id.toString();
    // The app's AppUser expects a string `phone`.
    ret.phone = ret.phoneNumber != null ? String(ret.phoneNumber) : '';
    delete ret._id;
    delete ret.phoneNumber;
    delete ret.password;
    delete ret.refreshTokens;
    return ret;
  },
});

export const User = mongoose.model('User', userSchema);
