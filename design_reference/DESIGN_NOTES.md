# Earthi Naturals — Design System Notes

Extracted from Figma exports (EN APP). Source of truth for the Flutter theme.

## Brand
- App name: **Earthi Naturals** — tagline "Tradition · Touch · Transformation"
- Category: Ayurvedic / natural skincare & haircare e-commerce (India, ₹ INR)

## Colors
| Token | Hex (approx) | Usage |
|---|---|---|
| `primary` (olive green) | `#4E5D38` | Primary buttons (Login, Sign Up, Proceed to Pay), top app-bar on dark screens |
| `primaryDark` | `#3D4A2C` | Pressed states |
| `onPrimary` | `#FFFFFF` | Text on green buttons |
| `accentBlack` | `#101010` | Secondary CTAs (Apply, Buy Now) |
| `discountGreen` bg | `#CDEAC0` | "15% off" / "23% off" badges |
| `discountGreen` text | `#2E7D32` | Discount % text, "Delivered" status |
| `priceStrike` | `#9E9E9E` | Struck-through MRP |
| `error/remove` | `#E53935` | Remove (X), "Canceled" status |
| `inputBorder` | `#D9D9D9` | Rounded input + card borders |
| `textPrimary` | `#1A1A1A` | Headings / body |
| `textMuted` | `#8A8A8A` | Placeholders, secondary text |
| `surface` | `#FFFFFF` | Cards, page background |
| `scaffoldBg` | `#FFFFFF` | Page background |
| `logoYellow` | `#F4C430` | Logo underline banner |

## Typography
- Clean geometric/rounded sans-serif (Poppins is the closest free match → use `google_fonts` Poppins).
- Headings: ~22–28px semibold/bold.
- Body: ~14–16px regular.
- Prices: bold; struck MRP lighter weight + line-through.

## Shape & spacing
- **Buttons:** fully rounded pill (radius ≈ 28–30px), full-width, ~56px tall.
- **Inputs:** rounded rect, radius ≈ 12px, 1px border `inputBorder`, ~56px tall, generous horizontal padding.
- **Cards / badges:** radius ≈ 10–12px.
- Page horizontal padding: ~20px.
- Vertical rhythm between fields: ~16–20px.

## Vertical-slice screens (first milestone)
1. **Login** — logo, Mobile Number field, Password field (eye toggle), "agree to Terms" checkbox, green Login pill, "Don't have an account? Sign Up".
2. **Signup** — Full Name, Mobile Number, Email, Password, Confirm Password, green Sign Up pill, "Already have an account? Login".
3. **Home** — search/cart icons header, hero banner carousel, "Our best sellers" horizontal list, "Shop by concerns", "Just Dropped" grid, product cards (image, name, star rating + reviews, price + MRP + % off, "ADD TO CART"), bottom nav (Home / Collection / Cart / Profile).
4. **Product Detail** — image carousel w/ thumbnails, title, rating, price block, size selector chips (25/50/100/250 ml), qty stepper, trust badges row, expandable sections (Product Details / Ingredients / How to Use), Buy Now + Add To Cart, Recommended Products, ratings breakdown, reviews.
5. **Cart** — address summary w/ Change, line items (image, name, size dropdown, qty stepper, price+MRP+badge, delivery date, remove X), remove confirmation dialog (Remove / Move to wishlist), "Add More Items", Apply Coupons, grand total + Proceed to Pay.
6. **Checkout (Select Address & Pay)** — delivery address card w/ Change/Edit, Price Details breakdown (cart total, discount, delivery fee, You Pay), Order Items w/ delivery estimates, Proceed to Pay (payment STUBBED for now).

## Bottom navigation (4 tabs)
Home · Collection · Cart · Profile
