class Goal {
  final int? id;
  final String name;
  final String icon;
  final int color;
  final int targetAmount;
  final int savedAmount;
  final DateTime? targetDate;
  final DateTime createdAt;
  final bool archived;
  final bool inactive;

  Goal({
    this.id,
    required this.name,
    this.icon = '🎯',
    this.color = 0xFF4CAF50,
    this.targetAmount = 0,
    this.savedAmount = 0,
    this.targetDate,
    DateTime? createdAt,
    this.archived = false,
    this.inactive = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Goal copyWith({
    int? id,
    String? name,
    String? icon,
    int? color,
    int? targetAmount,
    int? savedAmount,
    DateTime? targetDate,
    bool clearTargetDate = false,
    bool? archived,
    bool? inactive,
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    targetAmount: targetAmount ?? this.targetAmount,
    savedAmount: savedAmount ?? this.savedAmount,
    targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
    createdAt: createdAt,
    archived: archived ?? this.archived,
    inactive: inactive ?? this.inactive,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'targetDate': targetDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'archived': archived ? 1 : 0,
    'inactive': inactive ? 1 : 0,
  };

  static Goal fromMap(Map<String, dynamic> m) => Goal(
    id: m['id'] as int?,
    name: m['name'] as String,
    icon: (m['icon'] as String?) ?? '🎯',
    color: (m['color'] as int?) ?? 0xFF4CAF50,
    targetAmount: (m['targetAmount'] as int?) ?? 0,
    savedAmount: (m['savedAmount'] as int?) ?? 0,
    targetDate: (m['targetDate'] as String?) != null
        ? DateTime.parse(m['targetDate'] as String)
        : null,
    createdAt: DateTime.parse(m['createdAt'] as String),
    archived: ((m['archived'] as int?) ?? 0) != 0,
    inactive: ((m['inactive'] as int?) ?? 0) != 0,
  );

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);
}
