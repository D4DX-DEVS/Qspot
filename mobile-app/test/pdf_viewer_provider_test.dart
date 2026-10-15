import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/pdf_viewer/provider/pdf_viewer_provider.dart';

void main() {
  const url = 'https://example.com/notes.pdf';

  test('page label appears once the document is ready and follows pages', () {
    final viewer = PdfViewerProvider(url: url);
    expect(viewer.pageLabel, isNull);
    viewer.onViewerReady(12, null);
    expect(viewer.pageLabel, '1 / 12');
    viewer.onPageChanged(3);
    expect(viewer.pageLabel, '3 / 12');
    viewer.onPageChanged(null);
    expect(viewer.pageLabel, '3 / 12');
  });

  test('retry starts a new attempt and clears the old page state', () {
    final viewer = PdfViewerProvider(url: url);
    var notified = 0;
    viewer.addListener(() => notified++);
    viewer.onViewerReady(4, 2);
    viewer.retry();
    expect(viewer.attempt, 1);
    expect(viewer.pageLabel, isNull);
    expect(notified, 2);
  });

  test('download progress is a 0-1 fraction, null when size is unknown', () {
    expect(PdfViewerProvider.downloadProgress(50, 200), 0.25);
    expect(PdfViewerProvider.downloadProgress(300, 200), 1.0);
    expect(PdfViewerProvider.downloadProgress(50, null), isNull);
    expect(PdfViewerProvider.downloadProgress(50, 0), isNull);
  });

  test('opening externally hands the URL to the launcher', () async {
    Uri? launched;
    final viewer = PdfViewerProvider(
      url: url,
      launcher: (uri) async {
        launched = uri;
        return true;
      },
    );
    expect(await viewer.openExternally(), isTrue);
    expect(launched, Uri.parse(url));
  });

  test(
    'opening externally fails safely for bad URLs and launcher errors',
    () async {
      var calls = 0;
      Future<bool> launcher(Uri uri) async {
        calls++;
        throw Exception('no handler');
      }

      expect(
        await PdfViewerProvider(
          url: 'javascript:alert(1)',
          launcher: launcher,
        ).openExternally(),
        isFalse,
      );
      expect(calls, 0);
      expect(
        await PdfViewerProvider(url: url, launcher: launcher).openExternally(),
        isFalse,
      );
      expect(calls, 1);
    },
  );

  test('updates after dispose are ignored', () {
    final viewer = PdfViewerProvider(url: url)..dispose();
    expect(() => viewer.onViewerReady(3, 1), returnsNormally);
    expect(() => viewer.onPageChanged(2), returnsNormally);
    expect(viewer.retry, returnsNormally);
  });
}
