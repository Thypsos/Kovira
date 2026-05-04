import 'package:flutter/material.dart';

class RawCategoryIcon extends StatelessWidget {
  final String icon;
  final int? color;
  final double size;

  const RawCategoryIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 28,
  });

  bool get _isLetter => icon.length == 1 && RegExp(r'[A-Z]').hasMatch(icon);

  @override
  Widget build(BuildContext context) {
    if (_isLetter) {
      final bg = color ?? 0xFF607D8B;
      return Container(
        width: size * 1.4,
        height: size * 1.4,
        decoration: BoxDecoration(color: Color(bg), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          icon,
          style: TextStyle(
            fontSize: size * 0.65,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    return Text(icon, style: TextStyle(fontSize: size));
  }
}
