import 'package:flutter/material.dart';

import 'tutorial_messages.dart';

class GestureIndicator extends StatefulWidget {
  final TutorialGesture gesture;
  final Rect? targetRect;
  final Size screenSize;
  final Color tint;

  const GestureIndicator({
    super.key,
    required this.gesture,
    required this.targetRect,
    required this.screenSize,
    required this.tint,
  });

  @override
  State<GestureIndicator> createState() => _GestureIndicatorState();
}

class _GestureIndicatorState extends State<GestureIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final dur = widget.gesture == TutorialGesture.longPress
        ? const Duration(milliseconds: 2200)
        : const Duration(milliseconds: 1700);
    _ctrl = AnimationController(vsync: this, duration: dur)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        switch (widget.gesture) {
          case TutorialGesture.tap:
            return _buildTap(_ctrl.value);
          case TutorialGesture.longPress:
            return _buildLongPress(_ctrl.value);
          case TutorialGesture.swipeLeft:
            return _buildSwipe(_ctrl.value, Axis.horizontal, true);
          case TutorialGesture.swipeRight:
            return _buildSwipe(_ctrl.value, Axis.horizontal, false);
          case TutorialGesture.swipeUp:
            return _buildSwipe(_ctrl.value, Axis.vertical, true);
          case TutorialGesture.swipeDown:
            return _buildSwipe(_ctrl.value, Axis.vertical, false);
        }
      },
    );
  }

  Offset _center() {
    final r = widget.targetRect;
    if (r != null) return r.center;
    return Offset(widget.screenSize.width / 2, widget.screenSize.height / 2);
  }

  Widget _buildTap(double t) {
    final center = _center();
    final phase = (t * 2) % 1.0;
    final ringR = 14 + 42 * phase;
    final ringOpacity = (1 - phase).clamp(0.0, 1.0);
    final dotScale = phase < 0.18
        ? 1.0 - (phase / 0.18) * 0.35
        : 0.65 + (phase - 0.18) * 0.4;
    final tint = widget.tint;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: center.dx - ringR,
            top: center.dy - ringR,
            child: Container(
              width: ringR * 2,
              height: ringR * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tint.withValues(alpha: 0.90 * ringOpacity),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            left: center.dx - 22 * dotScale,
            top: center.dy - 22 * dotScale,
            child: Container(
              width: 44 * dotScale,
              height: 44 * dotScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint,
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.60),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.touch_app,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLongPress(double t) {
    final center = _center();
    final phase = t;
    final ringR = 18 + 64 * phase;
    final ringOpacity = (1 - phase).clamp(0.0, 1.0);
    final pressed = phase > 0.10;
    final tint = widget.tint;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: center.dx - ringR,
            top: center.dy - ringR,
            child: Container(
              width: ringR * 2,
              height: ringR * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.18 * ringOpacity),
                border: Border.all(
                  color: tint.withValues(alpha: 0.90 * ringOpacity),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            left: center.dx - 24,
            top: center.dy - 24,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: pressed ? 0.85 : 1.0,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint,
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.65),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.touch_app,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipe(double t, Axis axis, bool reverse) {
    final r = widget.targetRect;
    final cx = r?.center.dx ?? widget.screenSize.width / 2;
    final cy = r?.center.dy ?? widget.screenSize.height / 2;
    final span = axis == Axis.horizontal
        ? (r?.width ?? widget.screenSize.width * 0.6).clamp(140.0, 320.0)
        : (r?.height ?? widget.screenSize.height * 0.4).clamp(120.0, 280.0);

    final easeT = Curves.easeInOutCubic.transform((t * 1.4).clamp(0.0, 1.0));
    final dim = 1.0 - ((t - 0.78) * 4.5).clamp(0.0, 1.0);
    final fadeIn = (t * 4).clamp(0.0, 1.0);
    final opacity = (fadeIn * dim).clamp(0.0, 1.0);

    final progress = reverse ? 1.0 - easeT : easeT;
    final offsetFromCenter = (progress - 0.5) * span;

    final x = axis == Axis.horizontal ? cx + offsetFromCenter : cx;
    final y = axis == Axis.vertical ? cy + offsetFromCenter : cy;

    final iconAngle = switch (widget.gesture) {
      TutorialGesture.swipeLeft => 3.14159,
      TutorialGesture.swipeRight => 0.0,
      TutorialGesture.swipeUp => -1.5708,
      TutorialGesture.swipeDown => 1.5708,
      _ => 0.0,
    };
    final tint = widget.tint;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: x - 26,
            top: y - 26,
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: iconAngle,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint,
                    boxShadow: [
                      BoxShadow(
                        color: tint.withValues(alpha: 0.65),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
