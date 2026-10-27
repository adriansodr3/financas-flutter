// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
// dart:html está disponível no Flutter web
// ignore: depend_on_referenced_packages
import 'dart:js' as js;

/// Gerencia Web Push Notifications para a PWA.
class PushService {
  // VAPID public key injetada no build via --dart-define
  static const _vapidPublicKey =
      String.fromEnvironment('VAPID_PUBLIC_KEY', defaultValue: '');

  /// Verifica se o browser suporta Web Push.
  static bool get isSupported {
    try {
      return js.context.hasProperty('Notification') &&
          js.context.hasProperty('navigator') &&
          (js.context['navigator'] as js.JsObject)
              .hasProperty('serviceWorker');
    } catch (_) {
      return false;
    }
  }

  /// Retorna o estado atual da permissão: 'granted', 'denied', 'default'.
  static String get permissionState {
    try {
      return js.context['Notification']['permission'] as String? ?? 'default';
    } catch (_) {
      return 'default';
    }
  }

  /// Solicita permissão e inscreve o dispositivo no push.
  /// Retorna o mapa da subscription (endpoint, p256dh, auth) ou null se falhar.
  static Future<Map<String, String>?> subscribe() async {
    if (_vapidPublicKey.isEmpty || !isSupported) return null;

    final completer = Completer<Map<String, String>?>();

    try {
      // Chama a função JS definida no index.html
      js.context.callMethod('subscribeToPush', [
        _vapidPublicKey,
        js.allowInterop((js.JsObject? result) {
          if (result == null) {
            completer.complete(null);
            return;
          }
          try {
            completer.complete({
              'endpoint': result['endpoint'] as String,
              'p256dh': result['p256dh'] as String,
              'auth': result['auth'] as String,
            });
          } catch (e) {
            completer.complete(null);
          }
        }),
        js.allowInterop((String error) {
          completer.complete(null);
        }),
      ]);
    } catch (e) {
      return null;
    }

    return completer.future.timeout(const Duration(seconds: 15),
        onTimeout: () => null);
  }

  /// Cancela a inscrição do dispositivo.
  static Future<String?> unsubscribe() async {
    if (!isSupported) return null;
    final completer = Completer<String?>();
    try {
      js.context.callMethod('unsubscribeFromPush', [
        js.allowInterop((String? endpoint) => completer.complete(endpoint)),
      ]);
    } catch (_) {
      return null;
    }
    return completer.future.timeout(const Duration(seconds: 10),
        onTimeout: () => null);
  }
}
