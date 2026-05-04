class Category {
  final int? id;
  final String name;
  final String icon;
  final int useCount;
  final int? color;

  Category({
    this.id,
    required this.name,
    required this.icon,
    this.useCount = 0,
    this.color,
  });

  static const _palette = [
    0xFF4CAF50,
    0xFF2196F3,
    0xFFFF9800,
    0xFF9C27B0,
    0xFFE91E63,
    0xFF00BCD4,
    0xFFFF5722,
    0xFF795548,
    0xFF607D8B,
    0xFF009688,
    0xFFCDDC39,
    0xFF3F51B5,
  ];

  bool get isLetterIcon => icon.length == 1 && RegExp(r'[A-Z]').hasMatch(icon);

  int get effectiveColor {
    if (color != null) return color!;
    final seed = id ?? name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[seed % _palette.length];
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      useCount: (map['useCount'] as int?) ?? 0,
      color: map['color'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'useCount': useCount,
      if (color != null) 'color': color,
    };
  }
}
