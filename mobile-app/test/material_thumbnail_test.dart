import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/screens/video/provider/text_preview_provider.dart';
import 'package:qspot/screens/video/widgets/material_thumbnail.dart';
import 'package:qspot/screens/video/widgets/pdf_first_page_thumbnail.dart';
import 'package:qspot/screens/video/widgets/text_snippet_thumbnail.dart';

Widget _host(VideoDownload material) => MaterialApp(
  home: Scaffold(
    body: Center(child: MaterialThumbnail(material: material)),
  ),
);

void main() {
  test('text previews read only the opening lines', () async {
    final body = 'Line one\n${'x' * 10000}';
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response(body, 200);
    });
    final preview = TextPreviewProvider(
      'https://example.com/long-notes.txt',
      client: client,
    );
    await preview.load();
    expect(preview.failed, isFalse);
    expect(preview.snippet, startsWith('Line one\n'));
    expect(utf8.encode(preview.snippet!).length, lessThanOrEqualTo(2048));

    // A second card for the same file reuses the snippet.
    final again = TextPreviewProvider(
      'https://example.com/long-notes.txt',
      client: client,
    );
    await again.load();
    expect(again.snippet, preview.snippet);
    expect(requests, 1);
  });

  test('unreadable or empty text files have no preview', () async {
    for (final response in [
      http.Response('missing', 404),
      http.Response('   \n', 200),
    ]) {
      final preview = TextPreviewProvider(
        'https://example.com/bad-${response.statusCode}.txt',
        client: MockClient((_) async => response),
      );
      await preview.load();
      expect(preview.failed, isTrue);
      expect(preview.snippet, isNull);
    }
  });

  testWidgets('each file type picks its own preview', (tester) async {
    await tester.pumpWidget(
      _host(
        const VideoDownload(
          title: 'Checklist',
          url: 'https://example.com/checklist.pdf',
        ),
      ),
    );
    expect(find.byType(PdfFirstPageThumbnail), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const VideoDownload(
          title: 'Notes',
          url: 'https://example.com/notes.txt',
        ),
      ),
    );
    expect(find.byType(TextSnippetThumbnail), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const VideoDownload(
          title: 'Chart',
          url: 'https://example.com/chart.png',
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('files with no preview keep the file icon', (tester) async {
    await tester.pumpWidget(
      _host(
        const VideoDownload(
          title: 'Slides',
          url: 'https://example.com/slides.pptx',
        ),
      ),
    );
    expect(find.byIcon(LucideIcons.file), findsOneWidget);

    await tester.pumpWidget(
      _host(const VideoDownload(title: 'Broken', url: 'javascript:alert(1)')),
    );
    expect(find.byIcon(LucideIcons.file), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text previews draw the file’s opening lines', (tester) async {
    const url = 'https://example.com/routine.txt';
    await TextPreviewProvider(
      url,
      client: MockClient((_) async => http.Response('Warm up first', 200)),
    ).load();
    await tester.pumpWidget(
      _host(const VideoDownload(title: 'Routine', url: url)),
    );
    expect(find.text('Warm up first'), findsOneWidget);
    expect(find.byIcon(LucideIcons.fileText), findsNothing);
  });

  testWidgets('text previews show the icon until the file is read', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const VideoDownload(
          title: 'Notes',
          url: 'https://example.com/unreachable.txt',
        ),
      ),
    );
    expect(find.byIcon(LucideIcons.fileText), findsOneWidget);
    await tester.pumpAndSettle();
    // Test HTTP always fails, so the icon stays.
    expect(find.byIcon(LucideIcons.fileText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
