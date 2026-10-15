import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/services/downloads/file_downloader.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('downloader_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  FileDownloader downloader({int status = 200}) => FileDownloader(
    client: () => MockClient.streaming((request, _) async {
      final chunks = Stream.fromIterable([
        List<int>.filled(100, 1),
        List<int>.filled(50, 2),
      ]);
      return http.StreamedResponse(chunks, status, contentLength: 150);
    }),
  );

  test('streams the file to disk and reports progress', () async {
    final target = File('${dir.path}/lesson.mp4');
    final seen = <int>[];
    final bytes = await downloader().download(
      'https://cdn.example.com/lesson.mp4',
      target,
      onProgress: (received, total) => seen.add(received),
    );
    expect(bytes, 150);
    expect(target.lengthSync(), 150);
    expect(seen, [100, 150]);
    expect(File('${target.path}.part').existsSync(), isFalse);
  });

  test('a cancelled download leaves no file behind', () async {
    final target = File('${dir.path}/lesson.mp4');
    await expectLater(
      downloader().download(
        'https://cdn.example.com/lesson.mp4',
        target,
        isCancelled: () => true,
      ),
      throwsA(isA<DownloadCancelled>()),
    );
    expect(dir.listSync(), isEmpty);
  });

  test('a server error is a failure with no file', () async {
    final target = File('${dir.path}/lesson.mp4');
    await expectLater(
      downloader(status: 404).download('https://x/y.mp4', target),
      throwsA(isA<HttpException>()),
    );
    expect(dir.listSync(), isEmpty);
  });
}
