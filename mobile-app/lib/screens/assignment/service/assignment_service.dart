import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/services/api_client.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AssignmentUpload {
  const AssignmentUpload({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;
}

class AssignmentService {
  static List<AssignmentModel> parseList(dynamic body) {
    dynamic values = body;
    if (body is Map) {
      values = body['assignments'] ?? body['items'] ?? body['data'] ?? [];
      if (values is Map) {
        values = values['assignments'] ?? values['items'] ?? [];
      }
    }
    if (values is! List) return const [];
    return values
        .whereType<Map>()
        .map(
          (item) => AssignmentModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static Future<List<AssignmentModel>> fetchAll() async =>
      parseList(await ApiClient.get('/api/user/assignments'));

  static Future<AssignmentModel> fetchOne(String id) async {
    final body = await ApiClient.get('/api/user/assignments/$id');
    if (body is! Map) {
      throw const FormatException('Assignment details unavailable');
    }
    final data = body['assignment'] ?? body['data'] ?? body;
    if (data is! Map) {
      throw const FormatException('Assignment details unavailable');
    }
    return AssignmentModel.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<AssignmentModel?> submitText(String id, String text) async {
    final body = await ApiClient.post(
      '/api/user/assignments/$id/submissions',
      body: {'text': text.trim()},
    );
    if (body is! Map) return null;
    final data = body['assignment'] ?? body['submission'] ?? body['data'];
    if (data is! Map) return null;
    return AssignmentModel.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<void> submit(
    String id, {
    required String text,
    List<AssignmentUpload> attachments = const [],
  }) async {
    final files = attachments
        .map(
          (attachment) => http.MultipartFile.fromBytes(
            'files',
            attachment.bytes,
            filename: attachment.name,
            contentType: _contentType(attachment.mimeType),
          ),
        )
        .toList();
    await ApiClient.multipart(
      '/api/user/assignments/$id/submissions',
      method: 'POST',
      fields: {'text': text.trim()},
      files: files,
    );
  }

  static MediaType? _contentType(String value) {
    final parts = value.split('/');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) return null;
    return MediaType(parts[0], parts[1]);
  }
}
