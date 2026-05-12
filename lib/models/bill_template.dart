enum BillCadence { weekly, monthly, onDemand }

BillCadence billCadenceFromString(String? s) {
  switch (s) {
    case 'weekly':
      return BillCadence.weekly;
    case 'onDemand':
      return BillCadence.onDemand;
    case 'monthly':
    default:
      return BillCadence.monthly;
  }
}

String billCadenceToString(BillCadence c) {
  switch (c) {
    case BillCadence.weekly:
      return 'weekly';
    case BillCadence.onDemand:
      return 'onDemand';
    case BillCadence.monthly:
      return 'monthly';
  }
}

String billCadenceLabel(BillCadence c) {
  switch (c) {
    case BillCadence.weekly:
      return 'Weekly';
    case BillCadence.monthly:
      return 'Monthly';
    case BillCadence.onDemand:
      return 'As needed';
  }
}

class BillTemplate {
  final int? id;
  final String name;
  final String icon;
  final int categoryId;
  final int sourceId;
  final int amount;
  final bool isFixed;
  final BillCadence cadence;

  BillTemplate({
    this.id,
    required this.name,
    required this.icon,
    required this.categoryId,
    required this.sourceId,
    required this.amount,
    required this.isFixed,
    this.cadence = BillCadence.monthly,
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
      cadence: billCadenceFromString(map['cadence'] as String?),
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
      'cadence': billCadenceToString(cadence),
    };
  }
}
