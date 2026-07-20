import Razorpay from 'razorpay';

const keyId = process.env.RAZORPAY_KEY_ID;
const keySecret = process.env.RAZORPAY_KEY_SECRET;

if (!keyId || !keySecret) {
  // Fail loudly at boot rather than at the first checkout — a missing secret
  // here means every payment attempt 500s in production.
  throw new Error(
    'RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET must be set (see .env.example)'
  );
}

export const razorpay = new Razorpay({ key_id: keyId, key_secret: keySecret });

/** Public key, safe to hand to the app. The secret never leaves this process. */
export const RAZORPAY_KEY_ID = keyId;
export const RAZORPAY_KEY_SECRET = keySecret;
export const RAZORPAY_WEBHOOK_SECRET = process.env.RAZORPAY_WEBHOOK_SECRET || '';
