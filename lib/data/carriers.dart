import '../models/models.dart';

// Dial codes confirmed: NetOne *133*PIN#, Econet *121*PIN#. Card prefixes are still unverified (PLAN.md, Phase 4).
const List<CarrierFormat> kCarrierFormats = [
  CarrierFormat(id: 'netone', name: 'NetOne', prefix: '*133*', suffix: '#', cardPrefixes: ['4022']),
  CarrierFormat(id: 'econet', name: 'Econet', prefix: '*121*', suffix: '#', cardPrefixes: ['3630']),
];

CarrierFormat get defaultFormat => kCarrierFormats.first;

/// The carrier whose card prefix matches [pin], or null when none does.
CarrierFormat? detectCarrierByPin(String pin) {
  final clean = pin.replaceAll(RegExp(r'\D'), '');
  for (final fmt in kCarrierFormats) {
    if (fmt.cardPrefixes.any(clean.startsWith)) return fmt;
  }
  return null;
}

CarrierFormat? findFormatById(String id) {
  for (final fmt in kCarrierFormats) {
    if (fmt.id == id) return fmt;
  }
  return null;
}

String wrapPin(String pin, CarrierFormat format) =>
    '${format.prefix}${pin.replaceAll(RegExp(r'\D'), '')}${format.suffix}';
