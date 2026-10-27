/// Trader temperaments for Market Haggle (P8-922): price floors and politeness weight.
library;

class TraderPersonality {
  const TraderPersonality({
    required this.id,
    required this.displayNameEn,
    required this.markupOnFloor,
    required this.politenessWeight,
    required this.openingLineEn,
  });

  final String id;
  final String displayNameEn;

  /// Starting ask = floor * markupOnFloor.
  final double markupOnFloor;

  /// How much a rude move increases the ask (0–1 scale applied to price).
  final double politenessWeight;

  final String openingLineEn;

  int openingPrice(int floorPrice) =>
      (floorPrice * markupOnFloor).round();

  int minimumAccept(int floorPrice) => floorPrice;
}

const List<TraderPersonality> kTraderPersonalities = [
  TraderPersonality(
    id: 'patient_aunt',
    displayNameEn: 'Patient Auntie',
    markupOnFloor: 1.35,
    politenessWeight: 0.08,
    openingLineEn: 'Welcome — take your time and greet me properly first.',
  ),
  TraderPersonality(
    id: 'firm_uncle',
    displayNameEn: 'Firm Uncle',
    markupOnFloor: 1.55,
    politenessWeight: 0.12,
    openingLineEn: 'This is my best cloth. I expect respect at my stall.',
  ),
  TraderPersonality(
    id: 'cheerful_vendor',
    displayNameEn: 'Cheerful Vendor',
    markupOnFloor: 1.25,
    politenessWeight: 0.06,
    openingLineEn: 'Good to see you! Let us find a fair price together.',
  ),
];

TraderPersonality traderById(String id) {
  return kTraderPersonalities.firstWhere(
    (t) => t.id == id,
    orElse: () => kTraderPersonalities.first,
  );
}
