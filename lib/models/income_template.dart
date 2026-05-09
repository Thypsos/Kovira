enum IncomeCadence { hourly, daily, weekly, monthly }

IncomeCadence cadenceFromString(String? s) {
  switch (s) {
    case 'hourly':
      return IncomeCadence.hourly;
    case 'daily':
      return IncomeCadence.daily;
    case 'weekly':
      return IncomeCadence.weekly;
    case 'monthly':
    default:
      return IncomeCadence.monthly;
  }
}

String cadenceLabel(IncomeCadence c) {
  switch (c) {
    case IncomeCadence.hourly:
      return 'Hourly';
    case IncomeCadence.daily:
      return 'Daily';
    case IncomeCadence.weekly:
      return 'Weekly';
    case IncomeCadence.monthly:
      return 'Monthly';
  }
}

class IncomeTemplate {
  final int? id;
  final String name;
  final String icon;
  final int sourceId;
  final int amount;
  final bool isFixed;
  final int? reminderDay;
  final IncomeCadence cadence;

  IncomeTemplate({
    this.id,
    required this.name,
    required this.icon,
    required this.sourceId,
    required this.amount,
    required this.isFixed,
    this.reminderDay,
    this.cadence = IncomeCadence.monthly,
  });

  factory IncomeTemplate.fromMap(Map<String, dynamic> map) {
    return IncomeTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      sourceId: map['sourceId'] as int,
      amount: map['amount'] as int,
      isFixed: (map['isFixed'] as int) == 1,
      reminderDay: map['reminderDay'] as int?,
      cadence: cadenceFromString(map['cadence'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'sourceId': sourceId,
      'amount': amount,
      'isFixed': isFixed ? 1 : 0,
      'reminderDay': reminderDay,
      'cadence': cadence.name,
    };
  }
}
