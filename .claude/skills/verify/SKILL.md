---
name: verify
description: Build, run and drive the Earthi Naturals Flutter app on the iOS simulator to observe a change working end to end.
---

# Verifying Earthi Naturals

Flutter app (iOS + Android) with an Express/MongoDB backend in `server/`.

## Simulator

`flutter devices` usually shows only a wirelessly-paired physical iPhone, which
can't be driven automatically. Boot the simulator explicitly:

```bash
xcrun simctl list devices available | grep iPhone   # get the UDID
xcrun simctl boot <UDID> && open -a Simulator
```

It sometimes shuts down between long runs — re-boot it if `flutter test -d`
reports "No supported devices found".

Screenshots: `xcrun simctl io <UDID> screenshot out.png`.

## Backend

The app reads products/categories from the API; without it, Home silently falls
back to `MockData` but the category/all-products screens show an error state.

```bash
cd server && node src/server.js    # http://localhost:4000/api
```

⚠️ `server/.env` points at a **live MongoDB Atlas cluster**, not a local DB.
Treat it as production: never run `npm run seed`, and don't create orders or
accounts to test with — that writes real rows to a shared database. Endpoints
under `/wishlist` and `/orders` need a bearer token, so signed-out runs get 401
(the UI degrades to a "Please sign in" snackbar).

## Running a screen in isolation

`app_router.dart` honours a compile-time start route, so any screen can be
opened directly without tapping through:

```bash
flutter run -d <UDID> --dart-define=START=/addresses
flutter run -d <UDID> --dart-define=SEED=true --dart-define=START=/cart  # seeded cart
```

## Driving the UI

There is no `idb`/`cliclick` here, so taps go through `integration_test`
(`integration_test/app_test.dart`), which runs the real widgets on the
simulator:

```bash
flutter test integration_test/app_test.dart -d <UDID> --timeout 120s
flutter test integration_test/app_test.dart -d <UDID> --plain-name "size chips"
```

Gotchas learned the hard way:

- **Use a real `GoRouter`.** Hosting a screen in a plain `MaterialApp` with
  `routes:` throws "No GoRouter found in context" the moment anything calls
  `context.push`.
- **Let the font land before measuring.** `google_fonts` swaps the font in
  asynchronously; text reflows ~21px *after* the first `pumpAndSettle`, which
  looks exactly like a layout bug. `pumpAndSettle` → `pump(2s)` →
  `pumpAndSettle` before recording any rect.
- **The product page is a lazy `ListView`.** On a 375pt-wide surface the size
  chips aren't built until you `scrollUntilVisible` them.
- **Don't call `binding.convertFlutterSurfaceToImage()`** — it's Android-only
  and hangs the run on iOS until the 10-minute `pumpAndSettle` timeout. Capture
  frames with `simctl io ... screenshot` instead of `flutter drive`.
- Layout-stability claims are best asserted on geometry (`tester.getRect`
  before/after), not eyeballed from a screenshot.
