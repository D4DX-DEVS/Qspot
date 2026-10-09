import '../../../services/api_client.dart';
import '../model/certificate_model.dart';

/// Reads the signed-in student's certificates from the API.
class CertificateService {
  CertificateService._();

  /// Certificates in a `{items: [...]}` body (or a bare list). Revoked ones
  /// are already left out by the server.
  static List<CertificateModel> parseList(dynamic body) {
    final values = body is Map ? body['items'] : body;
    if (values is! List) return const [];
    return values
        .whereType<Map>()
        .map(
          (item) => CertificateModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.certificateNumber.isNotEmpty)
        .toList();
  }

  static Future<List<CertificateModel>> fetchMine() async =>
      parseList(await ApiClient.get('/api/certificates/mine'));
}
