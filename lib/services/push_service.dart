// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js' as js;

/// Gerencia Web Push Notifications para a PWA.
class PushService {
  static const _vapidPublicKey =
      String.fromEnvironment('VAPID_PUBLIC_KEY', defaultValue: '');

  /// Retorna o estado atual da permissão: 'granted', 'denied', 'default'.
  static String get permissionState {
    try {
      final n = js.context['Notification'];
      if (n == null) return 'default';
      return (n as js.JsObject)['permission'] as String? ?? 'default';
    } catch (_) {
      return 'default';
    }
  }

  /// Solicita permissão e inscreve o dispositivo no push.
  /// Retorna o mapa da subscription (endpoint, p256dh, auth) ou null se falhar.
  static Future<Map<String, String>?> subscribe() async {
    if (_vapidPublicKey.isEmpty) return null;

    final completer = Completer<Map<String, String>?>();

    try {
      js.context.callMethod('subscribeToPush', [
        _vapidPublicKey,
        js.allowInterop((result) {
          if (result == null) { completer.complete(null); return; }
          try {
            final r = result as js.JsObject;
            completer.complete({
              'endpoint': r['endpoint'] as String,
              'p256dh':   r['p256dh']   as String,
              'auth':     r['auth']     as String,
            });
          } catch (_) { completer.complete(null); }
        }),
        js.allowInterop((Object? _) { completer.complete(null); }),
      ]);
    } catch (_) {
      return null;
    }

    return completer.future.timeout(const Duration(seconds: 20),
        onTimeout: () => null);
  }

  /// Cancela a inscrição do dispositivo. Retorna o endpoint removido ou null.
  static Future<String?> unsubscribe() async {
    final completer = Completer<String?>();
    try {
      js.context.callMethod('unsubscribeFromPush', [
        js.allowInterop((Object? ep) => completer.complete(ep as String?)),
      ]);
    } catch (_) { return null; }
    return completer.future.timeout(const Duration(seconds: 10),
        onTimeout: () => null);
  }
}
