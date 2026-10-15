import 'dart:io';

import 'package:http/http.dart' as http;

/// Thrown when a download is stopped by the learner.
class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// Streams a file from the internet to disk, reporting progress. The file
/// only appears at [download]'s target once it is complete.
class FileDownloader {
  FileDownloader({http.Client Function()? client})
    : _client = client ?? http.Client.new;

  final http.Client Function() _client;

  /// Returns the number of bytes saved.
  Future<int> download(
    String url,
    File target, {
    void Function(int received, int? total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final client = _client();
    final partial = File('${target.path}.part');
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})');
      }
      final sink = partial.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          if (isCancelled?.call() ?? false) throw const DownloadCancelled();
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, response.contentLength);
        }
      } finally {
        await sink.close();
      }
      await partial.rename(target.path);
      return received;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      client.close();
    }
  }
}
