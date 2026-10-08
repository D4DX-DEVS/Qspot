import 'package:intl/intl.dart';

import '../../../utils/json_parsing.dart';

/// One certificate issued to the signed-in student, from
/// `GET /api/certificates/mine`.
///
/// Wording comes from the certificate's own snapshot, taken when it was
/// issued, so later edits to the exam never change a certificate already
/// given out. Blank fields fall back to the same text the admin panel prints.
class CertificateModel {
  const CertificateModel({
    required this.id,
    required this.quizId,
    required this.certificateNumber,
    required this.studentName,
    required this.title,
    required this.issuerName,
    required this.signatoryName,
    required this.description,
    required this.examTitle,
    required this.isPractical,
    required this.percentage,
    required this.score,
    required this.totalQuestions,
    required this.issuedAt,
  });

  final String id;

  /// The exam this certificate was issued for.
  final String quizId;
  final String certificateNumber;
  final String studentName;
  final String title;
  final String issuerName;
  final String signatoryName;
  final String description;
  final String examTitle;
  final bool isPractical;
  final num percentage;
  final int score;
  final int totalQuestions;

  /// Local time.
  final DateTime? issuedAt;

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    final snapshot = _map(json['snapshot']);
    // `exam` is the populated quiz; older payloads only had `quizId`, which
    // may itself be the populated object or a bare id string.
    final exam = _map(json['exam']).isNotEmpty
        ? _map(json['exam'])
        : _map(json['quizId']);
    final student = _map(json['student']);
    return CertificateModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      quizId: _text(
        exam['_id'],
        json['quizId'] is String ? json['quizId'] : '',
      ),
      certificateNumber: _text(json['certificateNumber']),
      studentName: _text(student['name'], 'Student'),
      title: _text(snapshot['title'], 'Certificate of Achievement'),
      issuerName: _text(snapshot['issuerName'], 'QSPOT Learning'),
      signatoryName: _text(snapshot['signatoryName'], 'Authorized Signatory'),
      description: _text(
        snapshot['description'],
        'For successfully completing the examination.',
      ),
      examTitle: _text(snapshot['examTitle'], _text(exam['title'], 'Exam')),
      isPractical: exam['assessmentType'] == 'practical',
      percentage: jsonDouble(json['percentage'])?.clamp(0, 100) ?? 0,
      score: jsonInt(json['score']) ?? 0,
      totalQuestions: jsonInt(json['totalQuestions']) ?? 0,
      issuedAt: DateTime.tryParse(_text(json['issuedAt']))?.toLocal(),
    );
  }

  /// "100%" or "87.5%".
  String get percentageLabel => percentage % 1 == 0
      ? '${percentage.toInt()}%'
      : '${percentage.toStringAsFixed(1)}%';

  /// "7 October 2026", or empty when the date is missing.
  String get issuedLabel =>
      issuedAt == null ? '' : DateFormat('d MMMM yyyy').format(issuedAt!);

  /// Safe file name for the shared PDF.
  String get fileName {
    final base = certificateNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    return '${base.isEmpty ? 'certificate' : base}.pdf';
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
