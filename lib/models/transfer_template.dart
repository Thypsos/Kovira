class TransferTemplate {
  final int? id;
  final int fromSourceId;
  final int toSourceId;
  final int amount;
  final bool isFixed;
  final int? reminderDay;

  TransferTemplate({
    this.id,
    required this.fromSourceId,
    required this.toSourceId,
    required this.amount,
    required this.isFixed,
    this.reminderDay,
  });

  factory TransferTemplate.fromMap(Map<String, dynamic> map) {
    return TransferTemplate(
      id: map['id'] as int?,
      fromSourceId: map['fromSourceId'] as int,
      toSourceId: map['toSourceId'] as int,
      amount: map['amount'] as int,
      isFixed: (map['isFixed'] as int) == 1,
      reminderDay: map['reminderDay'] as int?,
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
    };
  }
}
