/// A carrier's USSD recharge format, e.g. NetOne `*133*PIN#`.
class CarrierFormat {
  const CarrierFormat({
    required this.id,
    required this.name,
    required this.prefix,
    required this.suffix,
    required this.cardPrefixes,
  });

  final String id;
  final String name;
  final String prefix;
  final String suffix;

  /// Leading PIN digits that identify this carrier's cards.
  final List<String> cardPrefixes;

  String get pattern => '${prefix}PIN$suffix';
}

enum CardStatus { success, warning, error }

class DigitConfidence {
  const DigitConfidence({required this.index, required this.char, required this.confidence});

  final int index;
  final String char;

  /// 0–100. Positions that were never read are 0.
  final int confidence;

  bool get isLowConfidence => confidence < 80;
}

class ScannedCard {
  const ScannedCard({
    required this.id,
    required this.rawPin,
    required this.wrappedPin,
    required this.carrierId,
    required this.carrierName,
    required this.confidence,
    required this.digits,
    required this.status,
    required this.timestamp,
    this.errorMessage,
    this.photoPath,
    this.manualEditsCount = 0,
  });

  final String id;

  /// Always 16 characters; unread positions are placeholder zeros flagged in [digits].
  final String rawPin;
  final String wrappedPin;
  final String carrierId;
  final String carrierName;
  final int confidence;
  final List<DigitConfidence> digits;
  final CardStatus status;
  final String? errorMessage;
  final DateTime timestamp;

  /// The photo the PIN was read from.
  final String? photoPath;
  final int manualEditsCount;

  bool get canDial => status == CardStatus.success;

  /// `4022 6224 0582 1561`
  String get formattedPin => rawPin.replaceAllMapped(RegExp(r'(\d{4})(?=\d)'), (m) => '${m[1]} ');

  ScannedCard copyWith({
    String? rawPin,
    String? wrappedPin,
    String? carrierId,
    String? carrierName,
    int? confidence,
    List<DigitConfidence>? digits,
    CardStatus? status,
    String? Function()? errorMessage,
    int? manualEditsCount,
  }) {
    return ScannedCard(
      id: id,
      rawPin: rawPin ?? this.rawPin,
      wrappedPin: wrappedPin ?? this.wrappedPin,
      carrierId: carrierId ?? this.carrierId,
      carrierName: carrierName ?? this.carrierName,
      confidence: confidence ?? this.confidence,
      digits: digits ?? this.digits,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      timestamp: timestamp,
      photoPath: photoPath,
      manualEditsCount: manualEditsCount ?? this.manualEditsCount,
    );
  }
}
