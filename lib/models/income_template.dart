class IncomeTemplate {
  final int? id;
  final String name;
  final String icon;
  final int sourceId;
  final int amount;
  final bool isFixed;
  final int? reminderDay;

  IncomeTemplate({
    this.id,
    required this.name,
    required this.icon,
    required this.sourceId,
    required this.amount,
    required this.isFixed,
    this.reminderDay,
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
    };
  }
}
