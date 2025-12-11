import 'package:flutter/foundation.dart';

/// Google Maps API key injected at build time (e.g. via --dart-define or .env file).
const String googleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: '',
);

/// Returns true when Google Maps can be rendered in the current platform.
bool get isGoogleMapsEnabled => !kIsWeb || googleMapsApiKey.isNotEmpty;
