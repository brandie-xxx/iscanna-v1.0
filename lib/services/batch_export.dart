import 'dart:convert';

import '../models/models.dart';

enum ExportFormat {
  csv('csv', 'text/csv'),
  json('json', 'application/json'),
  txt('txt', 'text/plain');

  const ExportFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}

/// Quote a CSV field and neutralise spreadsheet formula prefixes.
String csvField(String value) {
  final safe = RegExp(r'^[=+\-@\t\r]').hasMatch(value) ? "'$value" : value;
  return '"${safe.replaceAll('"', '""')}"';
}

String buildExport(List<ScannedCard> cards, ExportFormat format) {
  switch (format) {
    case ExportFormat.csv:
      final rows = [
        for (var i = 0; i < cards.length; i++)
          [('${i + 1}'), cards[i].rawPin, cards[i].wrappedPin, cards[i].carrierName].map(csvField).join(','),
      ];
      return ['Index,RAW_PIN,WRAPPED_PIN,CARRIER', ...rows].join('\n');
    case ExportFormat.json:
      return const JsonEncoder.withIndent('  ').convert([
        for (final c in cards) {'pin': c.rawPin, 'wrapped': c.wrappedPin, 'carrier': c.carrierName},
      ]);
    case ExportFormat.txt:
      return cards.map((c) => c.wrappedPin).join('\n');
  }
}

String exportFileName(ExportFormat format, DateTime now) {
  final date = now.toIso8601String().substring(0, 10);
  return 'iscanna1.0-batch-$date.${format.extension}';
}
