import 'dart:collection';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// QSpot patch. Scripts that hide YouTube's own overlay inside the player.
///
/// The player lives in a cross-origin iframe, so the page around it cannot
/// reach into it. A user script injected into *all* frames at document start
/// can: it adds a style sheet that hides every direct child of the player
/// except the video itself, the captions and the error screen. That covers
/// the title bar, share button, "More videos", the YouTube logo, YouTube's own
/// play / pause button and its spinner, and whatever YouTube adds later.
///
/// If YouTube renames those three classes the overlay simply comes back; the
/// video is never hidden by this.
final UnmodifiableListView<UserScript> youtubeOverlayHiderScripts =
    UnmodifiableListView<UserScript>([
  UserScript(
    source: _source,
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    forMainFrameOnly: false,
  ),
]);

const String _source = r'''
(function () {
  var css =
    '[class*="ytPlayerControlsContainer"],' +
    '.html5-video-player > :not(.html5-video-container)' +
    ':not(.ytp-caption-window-container):not(.ytp-error)' +
    '{display:none !important;}';
  function add() {
    try {
      var sheet = new CSSStyleSheet();
      sheet.replaceSync(css);
      document.adoptedStyleSheets = document.adoptedStyleSheets.concat([sheet]);
      return true;
    } catch (e) {
      // Falls back to a <style> tag below.
    }
    var root = document.head || document.documentElement;
    if (!root) return false;
    var style = document.createElement('style');
    style.textContent = css;
    root.appendChild(style);
    return true;
  }
  if (!add()) {
    document.addEventListener('readystatechange', function once() {
      if (add()) document.removeEventListener('readystatechange', once);
    });
  }
})();
''';
