import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User } from '../models/User.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

function signToken(user) {
  return jwt.sign({ sub: user._id.toString() }, process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
}

/** Parse a phone string into the numeric `phoneNumber` the collection expects. */
function toPhoneNumber(phone) {
  if (phone == null) return null;
  const digits = String(phone).replace(/\D/g, '');
  return digits ? Number(digits) : null;
}

/** POST /api/auth/signup  { name, email, phone, password } */
router.post('/signup', async (req, res, next) => {
  try {
    const { name, email, phone, password } = req.body || {};
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'name, email and password are required' });
    }
    const phoneNumber = toPhoneNumber(phone);
    if (phoneNumber == null) {
      // phoneNumber carries a unique, non-sparse index, so it's mandatory.
      return res.status(400).json({ error: 'A valid phone number is required' });
    }

    const normEmail = String(email).trim().toLowerCase();
    if (await User.findOne({ email: normEmail })) {
      return res.status(409).json({ error: 'Email already registered' });
    }
    if (await User.findOne({ phoneNumber })) {
      return res.status(409).json({ error: 'Phone number already registered' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email: normEmail,
      phoneNumber,
      password: passwordHash,
      role: 'user',
    });
    res.status(201).json({ token: signToken(user), user });
  } catch (err) {
    next(err);
  }
});

/** POST /api/auth/login  { email, password } */
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }
    const normEmail = String(email).trim().toLowerCase();
    const user = await User.findOne({ email: normEmail });
    if (!user || !user.password) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

    res.json({ token: signToken(user), user });
  } catch (err) {
    next(err);
  }
});

/** GET /api/auth/me  — the signed-in user (used to restore a session from a saved token). */
router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    next(err);
  }
});

/** PATCH /api/auth/me  { name?, phone? }  — update the signed-in user's profile. */
router.patch('/me', requireAuth, async (req, res, next) => {
  try {
    const { name, phone } = req.body || {};
    const update = {};
    if (typeof name === 'string' && name.trim()) update.name = name.trim();
    if (phone != null) {
      const phoneNumber = toPhoneNumber(phone);
      if (phoneNumber == null) {
        return res.status(400).json({ error: 'A valid phone number is required' });
      }
      // Respect the unique index: reject a number already taken by someone else.
      const owner = await User.findOne({ phoneNumber });
      if (owner && owner._id.toString() !== req.userId) {
        return res.status(409).json({ error: 'Phone number already registered' });
      }
      update.phoneNumber = phoneNumber;
    }

    const user = await User.findByIdAndUpdate(req.userId, update, {
      new: true,
      runValidators: true,
    });
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    next(err);
  }
});

export default router;
