# Branding Assets

## Source File
- Place the master logo at `assets/branding/logo_source.png`.
- Recommended source dimensions: at least 1024x1024 PNG.

## Generate Logo Variants
Run from `apps/mobile_flutter`:

```bash
flutter pub get
dart run tool/generate_brand_variants.dart
```

Outputs are written to `assets/branding/generated/`:
- `logo_primary.png`
- `logo_bg_light.png`
- `logo_bg_dark.png`
- `logo_bg_navy.png`

## Generate App Icons
After `logo_source.png` exists, run:

```bash
dart run flutter_launcher_icons
```

This updates launcher icons for:
- Android (`android/app/src/main/res/mipmap-*`)
- Web (`web/icons`, `web/favicon.png`)
- Windows (`windows/runner/resources/app_icon.ico`)
