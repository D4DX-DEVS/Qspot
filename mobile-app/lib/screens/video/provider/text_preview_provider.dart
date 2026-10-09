import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Loads the opening lines of a text handout for its thumbnail. Only the
/// first few KB are read, so a large file never downloads in full.
class TextPreviewProvider extends ChangeNotifier {
  TextPreviewProvider(this.url, {http.Client? client})
    : _client = client ?? http.Client();

  static const _maxBytes = 2048;

  /// Snippets already read this session, so scrolling back doesn't refetch.
  static final Map<String, String> _cache = {};

  final String url;
  final http.Client _client;

  late String? _snippet = _cache[url];
  bool _failed = false;
  bool _disposed = false;

  String? get snippet => _snippet;
  bool get failed => _failed;

  Future<void> load() async {
    if (snippet != null || url.isEmpty) {
      _failed = url.isEmpty;
      return;
    }
    try {
      final response = await _client
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw http.ClientException('status');
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        if (bytes.length >= _maxBytes) break;
      }
      final text = utf8
          .decode(bytes.take(_maxBytes).toList(), allowMalformed: true)
          .trim();
      if (text.isEmpty) throw const FormatException('empty');
      _snippet = _cache[url] = text;
    } catch (_) {
      _failed = true;
    } finally {
      _client.close();
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }
}
