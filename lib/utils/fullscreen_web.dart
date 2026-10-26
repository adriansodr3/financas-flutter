// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool get isFullscreen => html.document.fullscreenElement != null;

/// false em iOS Safari/Brave — o Fullscreen API não é suportado no iOS
bool get isFullscreenSupported {
  final ua = html.window.navigator.userAgent.toLowerCase();
  final isIos = ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('ipod') ||
      (ua.contains('mac') && (html.window.navigator.maxTouchPoints ?? 0) > 0);
  if (isIos) return false;
  // Verifica se a API existe no document
  return html.document.documentElement?.requestFullscreen != null;
}

void toggleFullscreen() {
  if (!isFullscreenSupported) return;
  if (isFullscreen) {
    html.document.exitFullscreen();
  } else {
    html.document.documentElement?.requestFullscreen();
  }
}

Stream<bool> get onFullscreenChange =>
    html.document.onFullscreenChange.map((_) => isFullscreen);
