// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool get isFullscreen => html.document.fullscreenElement != null;

void toggleFullscreen() {
  if (isFullscreen) {
    html.document.exitFullscreen();
  } else {
    html.document.documentElement?.requestFullscreen();
  }
}

Stream<bool> get onFullscreenChange =>
    html.document.onFullscreenChange.map((_) => isFullscreen);
