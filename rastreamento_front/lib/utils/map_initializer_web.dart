import 'dart:async';
import 'dart:html' as html;

Future<void> ensureGoogleMapsScript(String apiKey) async {
  if (apiKey.isEmpty) return;

  final existing = html.document.getElementById('google-maps-script');
  if (existing != null) return;

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..id = 'google-maps-script'
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'
    ..defer = true
    ..type = 'text/javascript';

  script.onError.first.then(
    (_) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Falha ao carregar Google Maps JS')); // logged upstream
      }
    },
  );

  script.onLoad.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  html.document.head?.append(script);
  await completer.future.catchError((_) {
    // swallow errors to avoid crashing app; UI will handle map unavailable state
  });
}
