class BillTemplate {
  final int? id;
  final String name;
  final String icon;
  final int categoryId;
  final int sourceId;
  final int amount;
  final bool isFixed;

  BillTemplate({
    this.id,
    required this.name,
    required this.icon,
    required this.categoryId,
    required this.sourceId,
    required this.amount,
    required this.isFixed,
  });

  factory BillTemplate.fromMap(Map<String, dynamic> map) {
    return BillTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      categoryId: map['categoryId'] as int,
      sourceId: map['sourceId'] as int,
      amount: map['amount'] as int,
      isFixed: (map['isFixed'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'categoryId': categoryId,
      'sourceId': sourceId,
      'amount': amount,
      'isFixed': isFixed ? 1 : 0,
    };
  }
}
