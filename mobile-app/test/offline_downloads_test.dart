import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/downloads/model/lesson_download_plan.dart';
import 'package:qspot/screens/downloads/provider/downloads_provider.dart';
import 'package:qspot/screens/downloads/screens/downloads_screen.dart';
import 'package:qspot/screens/downloads/widgets/lesson_offline_button.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/services/downloads/file_downloader.dart';
import 'package:qspot/services/downloads/offline_store.dart';
import 'package:qspot/utils/byte_size.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writes a small file instead of going to the internet.
class _FakeDownloader extends FileDownloader {
  final requested = <String>[];

  @override
  Future<int> download(
    String url,
    File target, {
    void Function(int received, int? total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    requested.add(url);
    if (url.contains('broken')) throw const HttpException('nope');
    if (isCancelled?.call() ?? false) throw const DownloadCancelled();
    final bytes = List<int>.filled(2048, 1);
    await target.writeAsBytes(bytes);
    onProgress?.call(bytes.length, bytes.length);
    return bytes.length;
  }
}

VideoModel _lesson({
  String id = 'v1',
  String video = 'https://cdn.example.com/lessons/madd.mp4',
  List<VideoDownload> downloads = const [
    VideoDownload(title: 'Madd chart', url: 'https://cdn.example.com/madd.pdf'),
  ],
}) => VideoModel(
  id: id,
  caption: '',
  video: video,
  title: 'Rules of Madd',
  downloads: downloads,
);

void main() {
  late Directory dir;
  late _FakeDownloader downloader;
  late DownloadsProvider downloads;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('offline_test');
    downloader = _FakeDownloader();
    downloads = DownloadsProvider(
      store: OfflineStore(baseDir: () async => dir),
      downloader: downloader,
    );
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('what can be saved', () {
    test('an uploaded lesson saves its video and handouts', () {
      final files = LessonDownloadPlan.filesFor(_lesson());
      expect(files.map((f) => f.kind), ['video', 'handout']);
    });

    test('a YouTube lesson saves only its handouts', () {
      final files = LessonDownloadPlan.filesFor(
        _lesson(video: 'https://www.youtube.com/watch?v=abc'),
      );
      expect(files.map((f) => f.kind), ['handout']);
      expect(
        LessonDownloadPlan.hasVideo(_lesson(video: 'https://youtu.be/x')),
        isFalse,
      );
    });

    test('sizes read like people say them', () {
      expect(byteSize(512), '512 B');
      expect(byteSize(650 * 1024), '650 KB');
      expect(byteSize(48 * 1024 * 1024), '48 MB');
      expect(byteSize(1288490189), '1.2 GB');
    });
  });

  group('saving', () {
    test('a saved lesson plays and opens from the phone', () async {
      await downloads.save(_lesson());
      expect(downloads.isSaved('v1'), isTrue);
      expect(downloads.lessonFor('v1')!.bytes, 4096);
      expect(downloads.lessonFor('v1')!.contentsLabel, 'Video + 1 handout');
      final path = downloads.localPathFor(
        'https://cdn.example.com/lessons/madd.mp4',
      );
      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);
    });

    test('the list survives an app restart', () async {
      await downloads.save(_lesson());
      final again = DownloadsProvider(
        store: OfflineStore(baseDir: () async => dir),
        downloader: downloader,
      );
      await again.ensureLoaded();
      expect(again.isSaved('v1'), isTrue);
    });

    test('a failed download leaves nothing behind and says why', () async {
      await downloads.save(
        _lesson(
          downloads: const [
            VideoDownload(title: 'x', url: 'https://cdn.example.com/broken'),
          ],
        ),
      );
      expect(downloads.isSaved('v1'), isFalse);
      expect(downloads.errorFor('v1'), DownloadsProvider.failedMessage);
      expect(
        dir.listSync(recursive: true).whereType<File>(),
        isEmpty,
        reason: 'the video saved before the failure is removed',
      );
    });

    test('removing deletes the files; logout removes everything', () async {
      await downloads.save(_lesson());
      await downloads.save(_lesson(id: 'v2'));
      final path = downloads.localPathFor(
        'https://cdn.example.com/lessons/madd.mp4',
      )!;
      await downloads.remove('v1');
      expect(downloads.isSaved('v1'), isFalse);
      expect(File(path).existsSync(), isFalse);
      await downloads.removeAll();
      expect(downloads.lessons, isEmpty);
      expect(downloads.totalBytes, 0);
    });
  });

  group('screens', () {
    Widget host(Widget child) => ChangeNotifierProvider.value(
      value: downloads,
      child: MaterialApp(home: Scaffold(body: child)),
    );

    testWidgets('the lesson button saves, then shows the saved size', (
      tester,
    ) async {
      await tester.pumpWidget(host(LessonOfflineButton(video: _lesson())));
      expect(find.text('Save for offline'), findsOneWidget);
      await tester.runAsync(() => downloads.save(_lesson()));
      await tester.pump();
      expect(find.textContaining('Saved on this phone · 4 KB'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('a lesson with nothing to save shows no button', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          LessonOfflineButton(
            video: _lesson(
              video: 'https://www.youtube.com/watch?v=abc',
              downloads: const [],
            ),
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('Downloads lists saved lessons and their size', (tester) async {
      await tester.pumpWidget(host(const DownloadsScreen()));
      expect(find.text('Nothing Saved Yet'), findsOneWidget);
      await tester.runAsync(() => downloads.save(_lesson()));
      await tester.pump();
      expect(find.text('Rules of Madd'), findsOneWidget);
      expect(find.text('1 lesson · 4 KB on this phone'), findsOneWidget);
      expect(find.text('Remove all downloads'), findsOneWidget);
    });
  });
}
