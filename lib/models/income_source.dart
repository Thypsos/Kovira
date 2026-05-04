class IncomeSource {
  final int? id;
  final String name;
  final String icon;
  final int color;
  final int balance;
  final int monthlyStart;
  final int archived;

  IncomeSource({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.balance,
    this.monthlyStart = 0,
    this.archived = 0,
  });

  bool get isArchived => archived == 1;

  factory IncomeSource.fromMap(Map<String, dynamic> map) {
    return IncomeSource(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as int,
      balance: map['balance'] as int,
      monthlyStart: (map['monthlyStart'] as int?) ?? 0,
      archived: (map['archived'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'balance': balance,
      'monthlyStart': monthlyStart,
      'archived': archived,
    };
  }
}
