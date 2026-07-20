# Earthi Naturals — Backend API

Express + MongoDB (Mongoose) backend for the Earthi Naturals Flutter app.
The Flutter app talks to this API over HTTPS; **only this server** knows the
MongoDB connection string.

## Setup

```bash
cd server
npm install
cp .env.example .env      # then edit .env with your real values
```

Fill in `.env`:

- `MONGO_URI` — your Atlas connection string. **Percent-encode special
  characters in the password** (`@` → `%40`, `#` → `%23`, `!` → `%21`, …).
  Get the exact string from Atlas → Database → **Connect** → **Drivers**.
- `JWT_SECRET` — any long random string.
- `PORT` — defaults to `4000`.

## Run

```bash
npm run seed     # load the 6 starter products into MongoDB (one-time)
npm run dev      # start with auto-reload (Node --watch)
# or: npm start
```

Health check: `curl http://localhost:4000/api/health` → `{"ok":true}`

## Endpoints

| Method | Path                  | Auth | Purpose                         |
|--------|-----------------------|------|---------------------------------|
| GET    | `/api/health`         | —    | Liveness check                  |
| GET    | `/api/products`       | —    | List/filter products (`?category=`, `?q=`) |
| GET    | `/api/products/:id`   | —    | Single product by slug (`p1`)   |
| POST   | `/api/auth/signup`    | —    | Register, returns JWT + user    |
| POST   | `/api/auth/login`     | —    | Login, returns JWT + user       |
| GET    | `/api/wishlist`       | JWT  | User's saved products           |
| POST   | `/api/wishlist/:slug` | JWT  | Add to wishlist                 |
| DELETE | `/api/wishlist/:slug` | JWT  | Remove from wishlist            |
| GET    | `/api/orders`         | JWT  | User's orders                   |
| POST   | `/api/payments/order` | JWT  | Start checkout — prices the cart, opens a Razorpay order |
| POST   | `/api/payments/verify`| JWT  | Verify the signature and place the order |
| POST   | `/api/payments/webhook`| sig | Razorpay server-to-server confirmation |

Authenticated requests send `Authorization: Bearer <token>`.

## Payments (Razorpay)

Checkout is three steps. Orders are created `Pending payment` and only become
`Placed` once a signature has been verified here — never on the app's word.

1. `POST /api/payments/order` with `{ items: [{ productSlug, size, qty }] }`.
   Note there are **no prices in the request**: the server looks up every unit
   price in the `products` collection and computes the total itself. A patched
   app therefore cannot pay ₹1 for a ₹2000 order.
   Returns `{ razorpayOrderId, amount, currency, keyId, reference, ... }`.
2. The app opens the Razorpay sheet with that `razorpayOrderId` and the
   **public** `keyId`.
3. `POST /api/payments/verify` with the three fields Razorpay returns. The
   server recomputes `HMAC_SHA256("<order_id>|<payment_id>")` with the key
   secret and compares in constant time. Mismatch → the order is marked
   `Payment failed`.

`POST /api/payments/webhook` covers the case where the app dies between paying
and calling `/verify` (backgrounded, force-quit, network drop). It is
unauthenticated by design — the signature over the raw request body is the auth,
which is why `express.json` keeps `req.rawBody` around. Configure it in
Dashboard → Settings → Webhooks for `payment.captured` and `payment.failed`, and
put the signing secret in `RAZORPAY_WEBHOOK_SECRET`. Both paths are idempotent,
so an order can't be placed twice.

## Security notes

- `.env` is gitignored — never commit credentials.
- **`RAZORPAY_KEY_SECRET` must never reach the app.** Only the key id ships to
  the client (and it is served from `/api/payments/order`, not hardcoded). The
  secret can create, capture and refund payments — anyone who unpacks an APK
  can read a key bundled into it.
- If a key secret was ever shared in plaintext, **regenerate it** in the
  Razorpay dashboard (Settings → API Keys) and update `.env`. No code changes
  needed.
- If a connection string was ever shared in plaintext, **rotate the DB
  password** in Atlas (Database Access → Edit user).
- Lock Atlas **Network Access** to known IPs where possible.
