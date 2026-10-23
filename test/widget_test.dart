import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iscanna/data/carriers.dart';
import 'package:iscanna/main.dart';
import 'package:iscanna/services/ocr_service.dart';
import 'package:iscanna/state/app_controller.dart';

class _NoOcr implements OcrService {
  _NoOcr([this.text = '']);
  final String text;

  @override
  Future<OcrResult> readImage(String path) async => OcrResult(text, null);

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('sample scan, edit cancel, batch flow', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final app = AppController(_NoOcr('4022 6224 05'), sampleDelay: Duration.zero);
    await tester.pumpWidget(IscannaApp(controller: app));
    expect(find.text('Awaiting Voucher Card'), findsOneWidget);

    // One tap on a preset = one scan.
    await tester.tap(find.text('Econet card'));
    await tester.pumpAndSettle();
    expect(find.text('*121*3630146682113274#'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);

    // A partial camera read needs review and can't be dialed.
    unawaited(app.scanPhoto('/partial.jpg'));
    await tester.pumpAndSettle();
    expect(find.text('Review Needed'), findsOneWidget);
    expect(find.text('Fix PIN to Dial'), findsOneWidget);

    // Editor opens on the first unread digit; Cancel discards edits.
    await tester.ensureVisible(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Digit 11 of 16'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(GridView), matching: find.text('9')));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.card?.rawPin, '4022622405000000');

    // Fill in the six missing digits: 821561.
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    for (final d in '821561'.split('')) {
      await tester.tap(find.descendant(of: find.byType(GridView), matching: find.text(d)));
    }
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Dial NetOne Code'), findsOneWidget);

    // Queue it and view the batch tab.
    await tester.ensureVisible(find.text('Add to Batch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Batch'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Batch'), -300);
    await tester.tap(find.text('Batch'));
    await tester.pumpAndSettle();
    expect(find.text('*133*4022622405821561#'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('no overflow on a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(720, 1480);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final app = AppController(_NoOcr('4022 6224 05'), sampleDelay: Duration.zero);
    await tester.pumpWidget(IscannaApp(controller: app));
    app.incrementTarget();
    unawaited(app.scanPhoto('/partial.jpg'));
    await tester.pumpAndSettle();
    expect(find.text('Review Needed'), findsOneWidget);

    unawaited(app.scanSample(kSampleScenarios[1]));
    await tester.pumpAndSettle();
    app.selectTab(AppTab.batch);
    await tester.pumpAndSettle();
    expect(find.text('*121*3630146682113274#'), findsOneWidget);
    // Layout overflows would have been reported as test failures above.
  });
}
