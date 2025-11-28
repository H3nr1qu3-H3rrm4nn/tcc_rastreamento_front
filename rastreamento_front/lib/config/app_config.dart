import 'package:flutter/foundation.dart';

/// Google Maps API key passed via --dart-define=GOOGLE_MAPS_API_KEY=...
const String googleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'AIzaSyCPbPjsjVjPi4dG6ylSp5B-Pjwn7Svmlqc',
);

/// Returns true when Google Maps can be rendered in the current platform.
bool get isGoogleMapsEnabled => !kIsWeb || googleMapsApiKey.isNotEmpty;
