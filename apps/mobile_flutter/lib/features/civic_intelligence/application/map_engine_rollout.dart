enum MapEngine {
  mapLibre,
  leaflet,
}

/// Resolves which map engine to render for a user/session.
///
/// Compile-time controls:
/// - MAP_ENGINE=maplibre|leaflet|auto (default: auto)
/// - LEAFLET_ROLLOUT_PERCENT=0..100 (default: 0)
class MapEngineRollout {
  const MapEngineRollout._();

  static const String _engineOverride =
      String.fromEnvironment('MAP_ENGINE', defaultValue: 'auto');

  static const int _leafletRolloutPercent =
      int.fromEnvironment('LEAFLET_ROLLOUT_PERCENT', defaultValue: 0);

  static bool get isAutoMode => _engineOverride.trim().toLowerCase() == 'auto';

  static MapEngine resolveForUser(String userSeed) {
    final normalized = _engineOverride.trim().toLowerCase();

    if (normalized == 'leaflet') {
      return MapEngine.leaflet;
    }

    if (normalized == 'maplibre' || normalized == 'map_libre') {
      return MapEngine.mapLibre;
    }

    final rolloutPercent = _clampPercent(_leafletRolloutPercent);
    if (rolloutPercent == 0) {
      return MapEngine.mapLibre;
    }

    if (rolloutPercent == 100) {
      return MapEngine.leaflet;
    }

    final bucket = _stableBucket(userSeed);
    return bucket < rolloutPercent ? MapEngine.leaflet : MapEngine.mapLibre;
  }

  static int _clampPercent(int value) {
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  /// Stable hash bucket [0, 99] so users stay pinned to one engine.
  static int _stableBucket(String input) {
    var hash = 2166136261;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % 100;
  }
}
