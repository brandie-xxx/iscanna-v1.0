import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iscanna/data/carriers.dart';
import 'package:iscanna/models/models.dart';
import 'package:iscanna/services/batch_export.dart';
import 'package:iscanna/services/dialer.dart';
import 'package:iscanna/services/ocr_service.dart';
import 'package:iscanna/services/pin_parser.dart';
import 'package:iscanna/state/app_controller.dart';

final netOne = kCarrierFormats[0];
final econet = kCarrierFormats[1];

class FakeOcr implements OcrService {
  final Map<String, Completer<OcrResult>> pending = {};
  final Map<String, OcrResult> results = {};

  @override
  Future<OcrResult> readImage(String path) {
    final r = results[path];
    if (r != null) return Future.value(r);
    return (pending[path] = Completer<OcrResult>()).future;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('carriers', () {
    test('detects by 4-digit card prefix only', () {
      expect(detectCarrierByPin('4022622405821561')?.id, 'netone');
      expect(detectCarrierByPin('3630 1466 8211 3274')?.id, 'econet');
      expect(detectCarrierByPin('4099000000000000'), isNull);
      expect(detectCarrierByPin('3600000000000000'), isNull);
    });

    test('wraps digits only', () {
      expect(wrapPin('4022 6224-0582 1561', netOne), '*133*4022622405821561#');
    });
  });

  group('parsePinText', () {
    test('reads a clean 16-digit run and auto-detects carrier', () {
      final card = parsePinText('PIN 3630146682113274', fallbackFormat: netOne, confidence: 97);
      expect(card.rawPin, '3630146682113274');
      expect(card.carrierName, 'Econet');
      expect(card.wrappedPin, '*121*3630146682113274#');
      expect(card.status, CardStatus.success);
      expect(card.formattedPin, '3630 1466 8211 3274');
    });

    test('reads grouped digits and ignores neighbouring numbers', () {
      final card = parsePinText('Serial 998877\n4022 6224 0582 1561\nExp 2027', fallbackFormat: econet);
      expect(card.rawPin, '4022622405821561');
      expect(card.carrierName, 'NetOne');
    });

    test('uses the selected carrier when the prefix is unknown', () {
      final card = parsePinText('1234567812345678', fallbackFormat: econet);
      expect(card.carrierId, 'econet');
      expect(card.wrappedPin, '*121*1234567812345678#');
    });

    test('never presents a partial read as verified', () {
      final card = parsePinText('4022 6224 05', fallbackFormat: netOne, confidence: 99);
      expect(card.status, CardStatus.warning);
      expect(card.canDial, isFalse);
      expect(card.rawPin, '4022622405000000');
      expect(card.digits.where((d) => d.confidence == 0).length, 6);
      expect(card.errorMessage, contains('10 of 16'));
    });

    test('no digits is an error', () {
      final card = parsePinText('no numbers here', fallbackFormat: netOne);
      expect(card.status, CardStatus.error);
      expect(card.confidence, 0);
    });

    test('low confidence needs review; unknown confidence accepts a clean match', () {
      expect(parsePinText('4022622405821561', fallbackFormat: netOne, confidence: 60).status, CardStatus.warning);
      expect(parsePinText('4022622405821561', fallbackFormat: netOne).status, CardStatus.success);
    });

    test('correction verifies and keeps the card carrier', () {
      final card = parsePinText('3630 1466 82', fallbackFormat: netOne);
      final fixed = applyCorrection(card, '3630146682113274', netOne);
      expect(fixed.status, CardStatus.success);
      expect(fixed.errorMessage, isNull);
      expect(fixed.carrierId, 'econet');
      expect(fixed.wrappedPin, '*121*3630146682113274#');
      expect(fixed.manualEditsCount, 1);
      expect(fixed.digits.map((d) => d.index), List.generate(16, (i) => i));
    });

    test('switching carrier keeps label and code in agreement', () {
      final card = switchCarrier(parsePinText('4022622405821561', fallbackFormat: netOne), econet);
      expect(card.carrierName, 'Econet');
      expect(card.wrappedPin, '*121*4022622405821561#');
    });
  });

  group('export', () {
    final cards = [
      parsePinText('4022622405821561', fallbackFormat: netOne),
      parsePinText('3630146682113274', fallbackFormat: netOne),
    ];

    test('csv quotes fields and neutralises formulas', () {
      expect(csvField('=HYPERLINK("x")'), '"\'=HYPERLINK(""x"")"');
      final csv = buildExport(cards, ExportFormat.csv).split('\n');
      expect(csv.first, 'Index,RAW_PIN,WRAPPED_PIN,CARRIER');
      expect(csv[1], '"1","4022622405821561","*133*4022622405821561#","NetOne"');
    });

    test('json and txt', () {
      final json = jsonDecode(buildExport(cards, ExportFormat.json)) as List;
      expect(json.last, {'pin': '3630146682113274', 'wrapped': '*121*3630146682113274#', 'carrier': 'Econet'});
      expect(buildExport(cards, ExportFormat.txt), '*133*4022622405821561#\n*121*3630146682113274#');
    });

    test('file name', () {
      expect(exportFileName(ExportFormat.csv, DateTime(2026, 10, 23)), 'iscanna1.0-batch-2026-10-23.csv');
    });
  });

  test('ussd uri encodes # so it is not a fragment', () {
    final uri = ussdUri('*133*4022622405821561#');
    expect(uri.toString(), 'tel:*133*4022622405821561%23');
    expect(uri.fragment, isEmpty);
  });

  group('AppController', () {
    late FakeOcr ocr;
    late AppController app;

    setUp(() {
      ocr = FakeOcr();
      app = AppController(ocr, sampleDelay: Duration.zero);
    });

    test('photo scan builds a card from OCR text', () async {
      ocr.results['a.jpg'] = const OcrResult('4022 6224 0582 1561', 95);
      await app.scanPhoto('a.jpg');
      expect(app.card?.rawPin, '4022622405821561');
      expect(app.isScanning, isFalse);
      expect(app.scanError, isNull);
    });

    test('OCR failure shows an error and no card', () async {
      ocr.pending.clear();
      final future = app.scanPhoto('b.jpg');
      ocr.pending['b.jpg']!.completeError(Exception('boom'));
      await future;
      expect(app.card, isNull);
      expect(app.scanError, isNotNull);
    });

    test('stale scan results are ignored', () async {
      final first = app.scanPhoto('slow.jpg');
      ocr.results['fast.jpg'] = const OcrResult('3630146682113274', 99);
      await app.scanPhoto('fast.jpg');
      ocr.pending['slow.jpg']!.complete(const OcrResult('4022622405821561', 99));
      await first;
      expect(app.card?.rawPin, '3630146682113274');
    });

    test('auto-queues only verified cards, deduped by PIN', () async {
      app.incrementTarget();
      await app.scanSample(kSampleScenarios[1]);
      await app.scanSample(kSampleScenarios[1]);
      await app.scanSample(kSampleScenarios[2]); // damaged: needs review
      expect(app.batch.map((c) => c.rawPin), ['3630146682113274']);
      expect(app.card?.status, CardStatus.warning);
      expect(app.card?.digits[10].confidence, 55);
    });

    test('corrections and carrier switches update the batch copy', () async {
      await app.scanSample(kSampleScenarios[0]);
      app.addToBatch(app.card!);
      app.saveCorrection(app.card!, '4022622405821560');
      expect(app.batch.single.rawPin, '4022622405821560');
      app.selectFormat(econet);
      expect(app.batch.single.wrappedPin, '*121*4022622405821560#');
      expect(app.card?.carrierName, 'Econet');
    });

    test('rescan replays the current source', () async {
      await app.scanSample(kSampleScenarios[1]);
      await app.rescan();
      expect(app.card?.carrierName, 'Econet');
      expect(app.activeSampleId, 'sample-econet');
    });
  });
}
