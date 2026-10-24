import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iscanna/main.dart';
import 'package:iscanna/services/ocr_service.dart';
import 'package:iscanna/state/app_controller.dart';

/// Returns canned OCR text per photo path.
class _FakeOcr implements OcrService {
  static const texts = {
    '/econet.jpg': '3630 1466 8211 3274',
    '/netone.jpg': '4022 6224 0582 1561',
    '/partial.jpg': '4022 6224 05',
  };

  @override
  Future<OcrResult> readImage(String path) async => OcrResult(texts[path] ?? '', null);

  @override
  Future<void> dispose() async {}
}

Future<AppController> _pumpApp(WidgetTester tester, {Size size = const Size(390, 844), double text = 1}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final app = AppController(_FakeOcr());
  await tester.pumpWidget(IscannaApp(controller: app));
  await tester.pumpAndSettle();
  return app;
}

Future<void> _scan(WidgetTester tester, AppController app, String path) async {
  unawaited(app.scanPhoto(path));
  await tester.pumpAndSettle();
}

/// Scrolls the current tab until [finder] is built and on screen (lists build lazily).
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final page = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(finder, 200, scrollable: page);
  await tester.pumpAndSettle();
}

/// A keypad key in the PIN editor (round keys are labelled with their digit).
Finder _key(String digit) => find.bySemanticsLabel(RegExp('^$digit\$'));

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scan, review, edit and queue a card', (tester) async {
    final app = await _pumpApp(tester);

    // Header brand only; no sample presets, no footer wordmark; author link present.
    expect(find.text('iscanna1.0'), findsOneWidget);
    expect(find.textContaining('sample', findRichText: true), findsNothing);
    await _scrollTo(tester, find.text('No Card Yet'));
    await _scrollTo(tester, find.text('*exxstatix'));
    expect(find.text('*exxstatix'), findsOneWidget);

    await _scan(tester, app, '/econet.jpg');
    await _scrollTo(tester, find.text('Verified'));
    expect(find.text('*121*3630146682113274#'), findsOneWidget);

    // A partial read needs review and can't be dialed.
    await _scan(tester, app, '/partial.jpg');
    await _scrollTo(tester, find.text('Fix PIN to Dial'));
    expect(find.text('Review'), findsOneWidget);

    // Editor opens on the first unread digit; Cancel discards edits.
    await _tapVisible(tester, find.text('Edit'));
    expect(find.text('Digit 11/16'), findsOneWidget);
    await tester.tap(_key('9'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.card?.rawPin, '4022622405000000');

    // Fill in the six missing digits and save.
    await _tapVisible(tester, find.text('Edit'));
    for (final d in '821561'.split('')) {
      await tester.tap(_key(d));
    }
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Dial NetOne'), findsOneWidget);

    // Batch is off at a target of 1: no Add to Batch, and the tab stays put.
    expect(find.text('Add to Batch'), findsNothing);
    await tester.tap(find.text('Batch'));
    await tester.pumpAndSettle();
    expect(app.tab, AppTab.scanner);
    expect(find.textContaining('2 or more'), findsWidgets);

    // Turn Batch on, queue the card, then open the Batch tab from the tab bar.
    // The batch target sits above the scanner, so scroll back up to it.
    final page = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.bySemanticsLabel(RegExp('^Increase')), -200, scrollable: page);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Increase')));
    await tester.pumpAndSettle();
    expect(app.batchEnabled, isTrue);
    await _tapVisible(tester, find.text('Add to Batch'));
    await tester.tap(find.text('Batch'));
    await tester.pumpAndSettle();
    expect(find.text('*133*4022622405821561#'), findsOneWidget);
    expect(find.text('Export'), findsNWidgets(2)); // section header and button

    // Cards are dialed one at a time from each row: there is no dial-all control.
    expect(find.textContaining(RegExp('dial all', caseSensitive: false)), findsNothing);

    // Row tap opens the action sheet (with Dial for just this card); remove the card.
    await tester.tap(find.text('*133*4022622405821561#'));
    await tester.pumpAndSettle();
    expect(find.text('Edit PIN'), findsOneWidget);
    await tester.tap(find.text('Remove from Batch'));
    await tester.pumpAndSettle();
    expect(find.text('No Cards Yet'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('clearing the batch asks for confirmation', (tester) async {
    final app = await _pumpApp(tester);
    app.incrementTarget();
    for (final path in ['/econet.jpg', '/netone.jpg']) {
      await _scan(tester, app, path);
      app.addToBatch(app.card!);
    }
    app.selectTab(AppTab.batch);
    await tester.pumpAndSettle();
    expect(find.text('2 cards'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Clear Batch?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(CupertinoAlertDialog), matching: find.text('Clear')));
    await tester.pumpAndSettle();
    expect(app.batch, isEmpty);
    expect(find.text('No Cards Yet'), findsOneWidget);
  });

  testWidgets('no overflow on a small phone with large text', (tester) async {
    final app = await _pumpApp(tester, size: const Size(340, 720), text: 1.3);
    app.incrementTarget();
    await _scan(tester, app, '/partial.jpg');
    await _scrollTo(tester, find.text('Review'));
    expect(find.text('Fix PIN to Dial'), findsOneWidget);

    await _scan(tester, app, '/econet.jpg');
    app.selectTab(AppTab.batch);
    await tester.pumpAndSettle();
    expect(find.text('*121*3630146682113274#'), findsOneWidget);
    // Layout overflows would have been reported as test failures above.
  });

  testWidgets('About sheet opens from the Scan header', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('About iscanna'));
    await tester.pumpAndSettle();
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Scan a recharge card and dial it in one tap.'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('How it works'), findsNothing);
  });

  testWidgets('empty Batch keeps the credit at the bottom of the page', (tester) async {
    final app = await _pumpApp(tester);
    app.incrementTarget();
    app.selectTab(AppTab.batch);
    await tester.pumpAndSettle();
    expect(find.text('No Cards Yet'), findsOneWidget);
    final credit = tester.getRect(find.text('*exxstatix'));
    expect(credit.bottom, greaterThan(844 * 0.75));
  });

  testWidgets('no forced uppercase text on any screen', (tester) async {
    final app = await _pumpApp(tester);
    app.incrementTarget();
    await _scan(tester, app, '/partial.jpg');

    void expectNoShouting() {
      for (final widget in tester.widgetList<Text>(find.byType(Text))) {
        final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
        final letters = text.replaceAll(RegExp('[^A-Za-z]'), '');
        // Acronyms (PIN, CSV, USSD…) are fine; whole words or phrases in capitals are not.
        expect(letters.length >= 5 && letters == letters.toUpperCase(), isFalse, reason: 'Uppercase text: "$text"');
      }
    }

    expectNoShouting();
    app.selectTab(AppTab.batch);
    await tester.pumpAndSettle();
    expectNoShouting();
    app.selectTab(AppTab.scanner);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('About iscanna'));
    await tester.pumpAndSettle();
    expectNoShouting();
  });
}
