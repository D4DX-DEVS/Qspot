import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// State for the in-app PDF viewer: the page counter, reload attempts and
/// the "open in another app" fallback.
class PdfViewerProvider extends ChangeNotifier {
  PdfViewerProvider({
    required this.url,
    Future<bool> Function(Uri uri)? launcher,
  }) : _launch = launcher ?? _launchExternally;

  final String url;
  final Future<bool> Function(Uri uri) _launch;

  int _attempt = 0;
  int _pageCount = 0;
  int? _pageNumber;
  bool _disposed = false;

  /// Bumped on retry so the viewer loads the file again instead of reusing
  /// the failed download.
  int get attempt => _attempt;

  /// "3 / 12" once the document is open, otherwise null.
  String? get pageLabel => _pageCount > 0 && _pageNumber != null
      ? '$_pageNumber / $_pageCount'
      : null;

  /// 0–1 download progress, or null while the size is unknown.
  static double? downloadProgress(int bytesDownloaded, int? totalBytes) {
    if (totalBytes == null || totalBytes <= 0) return null;
    return (bytesDownloaded / totalBytes).clamp(0.0, 1.0);
  }

  void onViewerReady(int pageCount, int? pageNumber) {
    _pageCount = pageCount;
    _pageNumber = pageNumber ?? 1;
    _notify();
  }

  void onPageChanged(int? pageNumber) {
    if (pageNumber == null || pageNumber == _pageNumber) return;
    _pageNumber = pageNumber;
    _notify();
  }

  void retry() {
    _attempt++;
    _pageCount = 0;
    _pageNumber = null;
    _notify();
  }

  /// Hands the file to the device (browser or PDF app). False when that fails.
  Future<bool> openExternally() async {
    final uri = Uri.tryParse(url);
    if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) {
      return false;
    }
    try {
      return await _launch(uri);
    } catch (e) {
      debugPrint('PDF open externally failed: $e');
      return false;
    }
  }

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
