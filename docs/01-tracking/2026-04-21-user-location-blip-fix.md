# Current Location Pin Fix

Date: 2026-04-21

## What changed

- The community map now draws a Flutter overlay for the user location marker instead of depending on MapLibre’s built-in `myLocationEnabled` layer.
- The marker is projected from the current GPS position into screen coordinates and refreshed when the map style loads or the camera moves.
- The marker uses a pulsing visual treatment so the user can clearly spot the "you are here" location.

## Why it changed

- The previous native location layer was not rendering reliably in this workspace setup, so the current location pin could disappear even when location access was granted.
- Rendering the marker in Flutter makes the behavior deterministic and keeps the marker visible across the current OpenFreeMap/MapLibre configuration.
- The change also makes the location marker easier to control and style without depending on plugin-specific rendering behavior.

## Files touched

- [apps/mobile_flutter/lib/features/civic_intelligence/presentation/issue_map_page.dart](../../apps/mobile_flutter/lib/features/civic_intelligence/presentation/issue_map_page.dart)
