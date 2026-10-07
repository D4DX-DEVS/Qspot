import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/pdf_viewer/screens/pdf_viewer_screen.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/screens/video/widgets/learning_material_card.dart';
import 'package:qspot/screens/video/widgets/episode_downloads_tab.dart';
import 'package:qspot/utils/api_urls.dart';

void main() {
  test('malformed legacy file URLs are unavailable instead of throwing', () {
    for (final url in [
      'http://[bad/notes.png',
      'https://%zz/notes.pdf',
      'javascript:alert(1)',
      '',
    ]) {
      expect(VideoDownload(title: 'Old file', url: url).resolvedUrl, '');
    }
  });

  testWidgets('large Downloads lists build only nearby previews', (
    tester,
  ) async {
    final video = VideoModel(
      id: 'many',
      caption: '',
      video: '',
      downloads: [
        for (var i = 0; i < 20; i++)
          VideoDownload(title: 'Image $i', url: 'https://example.com/$i.png'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EpisodeDownloadsTab(video: video)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LearningMaterialCard).evaluate().length, lessThan(20));
    final image = tester.widget<Image>(find.byType(Image).first);
    final resized = image.image as ResizeImage;
    expect(resized.width, 640);
    expect(resized.height, 640);
    expect(resized.policy, ResizeImagePolicy.fit);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF cards open the resolved file in the in-app viewer', (
    tester,
  ) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    MethodCall? launched;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      launched = call;
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningMaterialCard(
            material: VideoDownload(
              title: 'Checklist',
              url: '/uploads/handouts/checklist.pdf',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Checklist'));
    // The viewer's loading spinner never settles, so pump the route in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final screen = tester.widget<PdfViewerScreen>(find.byType(PdfViewerScreen));
    expect(screen.url, '${ApiUrls.baseUrl}/uploads/handouts/checklist.pdf');
    expect(screen.title, 'Checklist');
    expect(launched, isNull);
  });

  test(
    'material types and API-relative URLs survive cached model round trips',
    () {
      final video = VideoModel.fromJson({
        'id': 'demo',
        'video': 'https://example.com/video',
        'downloads': [
          {'title': 'Chart', 'url': '/uploads/handouts/chart.PNG'},
          {
            'title': 'Checklist',
            'url': 'https://example.com/checklist.pdf?version=2',
          },
          {'title': 'Notes', 'url': 'https://example.com/notes.txt'},
        ],
      });
      final cached = VideoModel.fromJson(video.toJson());
      // Files alone show in Downloads, not as Learn content.
      expect(cached.hasLearnContent, isFalse);
      expect(cached.downloads[0].isImage, isTrue);
      expect(
        cached.downloads[0].resolvedUrl,
        '${ApiUrls.baseUrl}/uploads/handouts/chart.PNG',
      );
      expect(cached.downloads[1].isPdf, isTrue);
      expect(cached.downloads[2].isText, isTrue);
    },
  );

  testWidgets('failed image previews explain how to open the original', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningMaterialCard(
            material: VideoDownload(
              title: 'Practice chart',
              url: 'https://example.com/chart.png',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Preview unavailable. Tap to open the image.'),
      findsOneWidget,
    );
    expect(find.text('Practice chart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsupported link schemes show a helpful error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningMaterialCard(
            material: VideoDownload(
              title: 'Invalid file',
              url: 'javascript:alert(1)',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Invalid file'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'We couldn’t open this file. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
