class TransferTemplate {
  final int? id;
  final int fromSourceId;
  final int toSourceId;
  final int amount;
  final bool isFixed;
  final int? reminderDay;
  final int feeCents;
  final int feePercentBps;
  final String name;

  TransferTemplate({
    this.id,
    required this.fromSourceId,
    required this.toSourceId,
    required this.amount,
    required this.isFixed,
    this.reminderDay,
    this.feeCents = 0,
    this.feePercentBps = 0,
    this.name = '',
  });

  bool get hasFee => feeCents > 0 || feePercentBps > 0;

  int feeForAmount(int amountCents) {
    final pct = (amountCents * feePercentBps) ~/ 10000;
    return feeCents + pct;
  }

  factory TransferTemplate.fromMap(Map<String, dynamic> map) {
    return TransferTemplate(
      id: map['id'] as int?,
      fromSourceId: map['fromSourceId'] as int,
      toSourceId: map['toSourceId'] as int,
      amount: map['amount'] as int,
      isFixed: (map['isFixed'] as int) == 1,
      reminderDay: map['reminderDay'] as int?,
      feeCents: (map['feeCents'] as int?) ?? 0,
      feePercentBps: (map['feePercentBps'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fromSourceId': fromSourceId,
      'toSourceId': toSourceId,
      'amount': amount,
      'isFixed': isFixed ? 1 : 0,
      'reminderDay': reminderDay,
      'feeCents': feeCents,
      'feePercentBps': feePercentBps,
      'name': name,
    };
  }
}
