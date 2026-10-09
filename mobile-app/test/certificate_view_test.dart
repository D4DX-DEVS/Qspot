import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qspot/screens/certificate/model/certificate_model.dart';
import 'package:qspot/screens/certificate/provider/certificate_share_provider.dart';
import 'package:qspot/screens/certificate/screens/certificate_screen.dart';
import 'package:qspot/screens/certificate/widgets/certificate_preview.dart';
import 'package:qspot/screens/quiz/screens/quiz_results_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/utils/widget_capture.dart';

/// One item as `GET /api/certificates/mine` returns it (copied from the
/// local API), with the quiz populated under both `quizId` and `exam`.
Map<String, dynamic> _item({
  String quizId = 'quiz-1',
  String name = 'Test Student',
  Map<String, dynamic>? snapshot,
}) {
  final exam = {
    '_id': quizId,
    'title': 'test',
    'assessmentType': 'quiz',
    'endDate': '2026-10-08T14:20:00.000Z',
  };
  return {
    'id': 'c1',
    'certificateNumber': 'QSPOT-2026-F55BC174',
    'quizId': exam,
    'userId': 'u1',
    'student': {'id': 'u1', 'name': name, 'class': '8'},
    'percentage': 50,
    'score': 1,
    'totalQuestions': 2,
    'issuedAt': '2026-10-08T14:20:12.121Z',
    'status': 'issued',
    'snapshot':
        snapshot ??
        {
          'title': 'Certificate of Achievement',
          'issuerName': 'qspot',
          'signatoryName': 'director',
          'description': 'For successfully completing the examination.',
          'examTitle': 'test',
        },
    'exam': exam,
  };
}

/// Every text field at the longest the admin API accepts.
final _longest = CertificateModel.fromJson(
  _item(
    name: 'മുഹമ്മദ് അബ്ദുൽ റഹ്മാൻ ഫാത്തിമ സുഹൈബ് ' * 3,
    snapshot: {
      'title': 'Certificate of Excellence in Quran Studies ' * 4,
      'issuerName': 'QSPOT Learning Foundation Kerala ' * 5,
      'signatoryName': 'Director of Academic Affairs and Studies ' * 4,
      'description': 'For successfully completing the examination. ' * 11,
      'examTitle': 'Weekly Quran Quiz Week 1 ' * 6,
    },
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => ApiClient.clientOverride = null);

  group('CertificateModel.quizId', () {
    test('comes from the populated exam', () {
      expect(CertificateModel.fromJson(_item()).quizId, 'quiz-1');
    });

    test('falls back to a bare quizId string', () {
      final model = CertificateModel.fromJson({
        'certificateNumber': 'X',
        'quizId': 'quiz-9',
      });
      expect(model.quizId, 'quiz-9');
    });
  });

  group('View Certificate on the results screen', () {
    Future<void> pumpResults(
      WidgetTester tester, {
      required String quizId,
      required http.Response reply,
    }) async {
      ApiClient.clientOverride = MockClient((_) async => reply);
      await tester.pumpWidget(
        MaterialApp(
          home: QuizResultsScreen(
            title: 'test',
            score: 1,
            totalQuestions: 2,
            percentage: 50,
            completedAt: null,
            results: const [],
            quizId: quizId,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final issued = http.Response(
      jsonEncode({
        'items': [_item()],
      }),
      200,
    );

    testWidgets('shows when this quiz has a certificate', (tester) async {
      await pumpResults(tester, quizId: 'quiz-1', reply: issued);
      expect(find.text('View Certificate'), findsOneWidget);
    });

    testWidgets('stays hidden for a quiz without one', (tester) async {
      await pumpResults(tester, quizId: 'quiz-2', reply: issued);
      expect(find.text('View Certificate'), findsNothing);
    });

    testWidgets('stays hidden when the lookup fails', (tester) async {
      await pumpResults(
        tester,
        quizId: 'quiz-1',
        reply: http.Response('{"message":"Internal server error"}', 500),
      );
      expect(find.text('View Certificate'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the certificate', (tester) async {
      await pumpResults(tester, quizId: 'quiz-1', reply: issued);
      await tester.tap(find.text('View Certificate'));
      await tester.pumpAndSettle();
      expect(find.byType(CertificateScreen), findsOneWidget);
      expect(find.text('Test Student'), findsOneWidget);
      expect(find.text('Certificate No. QSPOT-2026-F55BC174'), findsOneWidget);
      expect(find.text('Share PDF'), findsOneWidget);
    });
  });

  group('Certificate screen layout', () {
    const sizes = {
      'phone portrait': Size(360, 740),
      'phone landscape': Size(740, 360),
      'tablet': Size(1024, 1366),
    };
    for (final entry in sizes.entries) {
      for (final dark in [false, true]) {
        testWidgets(
          'fits on ${entry.key} (${dark ? 'dark' : 'light'}) with longest text',
          (tester) async {
            tester.view.physicalSize = entry.value;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                home: CertificateScreen(certificate: _longest),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Share PDF'), findsOneWidget);
          },
        );
      }
    }
  });

  testWidgets('shared PDF is drawn from the full A4 sheet', (tester) async {
    final certificate = CertificateModel.fromJson(_item());
    Uint8List? shared;
    String? sharedName;
    final provider = CertificateShareProvider(
      certificate,
      sharer: (bytes, filename, _) async {
        shared = bytes;
        sharedName = filename;
        return true;
      },
    );
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 300,
            child: ChangeNotifierProvider.value(
              value: provider,
              child: CertificatePreview(certificate: certificate),
            ),
          ),
        ),
      ),
    );

    String? failure;
    late Uint8List png;
    await tester.runAsync(() async {
      png = await WidgetCapture.png(provider.sheetKey, pixelRatio: 1);
      failure = await provider.share();
    });

    // PNG header: width and height are big-endian at bytes 16 and 20.
    final header = ByteData.sublistView(png);
    expect(header.getUint32(16), 842);
    expect(header.getUint32(20), 595);
    expect(failure, isNull);
    expect(utf8.decode(shared!.sublist(0, 5)), '%PDF-');
    expect(sharedName, 'QSPOT-2026-F55BC174.pdf');
  });
}
