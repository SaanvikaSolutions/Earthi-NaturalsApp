# Earthi Naturals — Mobile App

Cross-platform (iOS + Android) e-commerce app for natural / ayurvedic skincare
& haircare, built in **Flutter** from the Figma designs (`EN APP`).

## Stack
- **Flutter** (Dart) — single codebase, identical UI on iOS & Android
- **Riverpod** — state management (cart)
- **go_router** — navigation + bottom-nav shell
- **google_fonts** (Poppins) — typography
- _Planned:_ Supabase (auth/DB/storage), Razorpay (payments — currently stubbed)

## Status — Milestone 1: vertical slice ✅
A tap-through shopping flow with mock data, verified on the iOS simulator:

`Login → Signup → Home → Product Detail → Cart → Checkout (payment stub)`

All screens match the Figma design language (olive-green palette, pill buttons,
rounded inputs, discount badges).

## Project layout
```
lib/
  core/
    theme/      # app_colors, app_theme (spacing, radii, typography)
    widgets/    # buttons, text field, logo, price row, rating, qty stepper
    router/     # go_router config + bottom-nav shell
  data/
    models/     # Product, CartItem
    mock/       # MockData catalogue
  features/
    auth/       # login, signup
    home/       # home + product card
    product/    # product detail
    cart/       # cart screen + cart_controller (Riverpod)
    checkout/   # select address & pay (payment stubbed)
    shell/      # bottom-nav scaffold
```

## Run
```bash
flutter pub get
flutter run                 # pick a device, or:
flutter run -d <ios-sim-id>
```

### Debug screenshot hooks (no effect in production defaults)
- `--dart-define=START=/home` — launch straight into a given route
- `--dart-define=SEED=true` — pre-fill the cart with sample items

## Next steps
- [ ] Remaining screens: OTP, filters, sort, profile, orders, addresses,
      exchange/return, notifications, policy pages (~35 more from Figma)
- [ ] Wire Supabase (products, auth, orders, addresses, reviews)
- [ ] Integrate Razorpay payments
- [ ] Real product imagery + brand logo asset from Figma
- [ ] Android AVD verification
- [ ] App icons, splash, store metadata
