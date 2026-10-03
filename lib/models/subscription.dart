import 'dart:typed_data';

enum Cadence { weekly, monthly, quarterly, yearly }

extension CadenceLabel on Cadence {
  String get label => switch (this) {
        Cadence.weekly => 'Weekly',
        Cadence.monthly => 'Monthly',
        Cadence.quarterly => 'Quarterly',
        Cadence.yearly => 'Yearly',
      };
}

const remindOptions = {
  -1: 'Off',
  0: 'Same day',
  1: '1 day before',
  2: '2 days before',
  3: '3 days before',
  7: '1 week before',
};

class Subscription {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final Cadence cadence;
  final int every; // every N weeks/months/etc
  final DateTime startDate;
  final String? brandKey;
  final Uint8List? customImage;
  final int? color;
  final int remindDaysBefore; // -1 = off
  final String notes;
  final String? category; // Category.name, null = guess from brand
  final bool trial; // startDate is when the trial ends / first real charge
  final bool paused;
  final int people; // split between this many, 1 = just me
  final DateTime? endsOn; // cancelled, last renewal is on or before this

  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.cadence,
    required this.startDate,
    this.every = 1,
    this.brandKey,
    this.customImage,
    this.color,
    this.remindDaysBefore = 1,
    this.notes = '',
    this.trial = false,
    this.paused = false,
    this.category,
    this.people = 1,
    this.endsOn,
  });

  /// what you actually pay per charge
  double get share => amount / people;

  bool endedBy(DateTime now) =>
      endsOn != null && DateTime(endsOn!.year, endsOn!.month, endsOn!.day).isBefore(DateTime(now.year, now.month, now.day));

  bool inTrial(DateTime now) =>
      trial && !DateTime(startDate.year, startDate.month, startDate.day).isBefore(DateTime(now.year, now.month, now.day));

  Subscription copyWith({
    String? name,
    double? amount,
    String? currency,
    Cadence? cadence,
    int? every,
    DateTime? startDate,
    String? brandKey,
    Uint8List? customImage,
    int? color,
    int? remindDaysBefore,
    String? notes,
    bool? trial,
    bool? paused,
    String? category,
    int? people,
    DateTime? endsOn,
    bool clearEnd = false,
    bool clearImage = false,
    bool clearBrand = false,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      cadence: cadence ?? this.cadence,
      every: every ?? this.every,
      startDate: startDate ?? this.startDate,
      brandKey: clearBrand ? null : (brandKey ?? this.brandKey),
      customImage: clearImage ? null : (customImage ?? this.customImage),
      color: color ?? this.color,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      notes: notes ?? this.notes,
      trial: trial ?? this.trial,
      paused: paused ?? this.paused,
      category: category ?? this.category,
      people: people ?? this.people,
      endsOn: clearEnd ? null : (endsOn ?? this.endsOn),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'currency': currency,
        'cadence': cadence.name,
        'every': every,
        'start': startDate.millisecondsSinceEpoch,
        'brand': brandKey,
        'img': customImage,
        'color': color,
        'remind': remindDaysBefore,
        'notes': notes,
        'trial': trial,
        'paused': paused,
        'category': category,
        'people': people,
        'ends': endsOn?.millisecondsSinceEpoch,
      };

  factory Subscription.fromMap(Map m) => Subscription(
        id: m['id'] as String,
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String,
        cadence: Cadence.values.byName(m['cadence'] as String),
        every: (m['every'] as int?) ?? 1,
        startDate: DateTime.fromMillisecondsSinceEpoch(m['start'] as int),
        brandKey: m['brand'] as String?,
        customImage: m['img'] as Uint8List?,
        color: m['color'] as int?,
        remindDaysBefore: (m['remind'] as int?) ?? 1,
        notes: (m['notes'] as String?) ?? '',
        trial: (m['trial'] as bool?) ?? false,
        paused: (m['paused'] as bool?) ?? false,
        category: m['category'] as String?,
        people: (m['people'] as int?) ?? 1,
        endsOn: m['ends'] == null ? null : DateTime.fromMillisecondsSinceEpoch(m['ends'] as int),
      );
}
