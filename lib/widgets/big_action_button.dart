import 'package:flutter/material.dart';
import 'live_icon.dart';

class BigActionButton extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onLongPress;
  final String? tooltip;

  const BigActionButton({
    super.key,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.onSwipeUp,
    this.onLongPress,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? Color.lerp(tint, Colors.black, 0.72)!
        : Color.lerp(tint, Colors.white, 0.25)!;
    final fg = isDark ? Color.lerp(tint, Colors.white, 0.45)! : Colors.white;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          onVerticalDragEnd: onSwipeUp == null
              ? null
              : (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v < -250) onSwipeUp!();
                },

          child: _maybeWrapTooltip(
            tooltip: tooltip,
            enabled: onLongPress == null,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (onSwipeUp != null)
                    Positioned(
                      top: 6,
                      child: Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  PulsingGlowIcon(
                    icon: icon,
                    size: 36,
                    color: fg,

                    glowColor: isDark ? tint : Colors.white,
                    maxBlur: 14,
                    minOpacity: isDark ? 0.20 : 0.30,
                    maxOpacity: isDark ? 0.50 : 0.75,
                    duration: const Duration(milliseconds: 1800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _maybeWrapTooltip({
  required String? tooltip,
  required bool enabled,
  required Widget child,
}) {
  if (!enabled || tooltip == null || tooltip.isEmpty) return child;
  return Tooltip(message: tooltip, child: child);
}
