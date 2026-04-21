# Mobile App (Flutter) - M1 Shell

## Included in M1
- App shell with role-aware home routing (`community`, `student`, `admin`)
- Basic sign-in entry page
- Firebase dependencies and initialization hook

## Next (M2)
- Community issue submission form
- Map pin rendering for validated issues

## Setup Notes
1. Install Flutter SDK.
2. Run `flutter pub get` in this folder.
3. Configure Firebase for Android/iOS and generate platform configs.
4. Run the app with `flutter run`.

## Branding and App Icons
1. Put the source logo in `assets/branding/logo_source.png`.
2. Generate safe variants: `dart run tool/generate_brand_variants.dart`
3. Generate launcher icons: `dart run flutter_launcher_icons`
