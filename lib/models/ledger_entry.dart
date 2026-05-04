class LedgerEntry {
  final int? id;
  final String type;
  final int categoryId;
  final int sourceId;
  final int? toSourceId;
  final int amount;
  final int paidAmount;
  final String name;
  final DateTime date;
  final String status;

  LedgerEntry({
    this.id,
    required this.type,
    required this.categoryId,
    required this.sourceId,
    this.toSourceId,
    required this.amount,
    this.paidAmount = 0,
    required this.name,
    required this.date,
    this.status = 'paid',
  });

  int get remainingDue => amount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'categoryId': categoryId,
      'sourceId': sourceId,
      'toSourceId': toSourceId,
      'amount': amount,
      'paidAmount': paidAmount,
      'name': name,
      'date': date.toIso8601String(),
      'status': status,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as int?,
      type: map['type'] as String,
      categoryId: map['categoryId'] as int,
      sourceId: map['sourceId'] as int,
      toSourceId: map['toSourceId'] as int?,
      amount: map['amount'] as int,
      paidAmount: (map['paidAmount'] as int?) ?? 0,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      status: (map['status'] as String?) ?? 'paid',
    );
  }
}
