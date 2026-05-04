import 'package:flutter/material.dart';

class PulsingGlowIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color? glowColor;
  final Duration duration;
  final double maxBlur;
  final double minOpacity;
  final double maxOpacity;

  const PulsingGlowIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = Colors.white,
    this.glowColor,
    this.duration = const Duration(milliseconds: 1800),
    this.maxBlur = 14,
    this.minOpacity = 0.25,
    this.maxOpacity = 0.65,
  });

  @override
  State<PulsingGlowIcon> createState() => _PulsingGlowIconState();
}

class _PulsingGlowIconState extends State<PulsingGlowIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glow = widget.glowColor ?? widget.color;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        if (!isDark) {
          final discAlpha =
              widget.minOpacity + (widget.maxOpacity - widget.minOpacity) * t;
          final scale = 1.0 + 0.06 * t;
          final discDiameter = widget.size * 2.05;
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: discDiameter,
                  height: discDiameter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          glow.withValues(alpha: discAlpha),
                          glow.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: scale,
                  child: Icon(
                    widget.icon,
                    size: widget.size,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          );
        }
        final alpha =
            widget.minOpacity + (widget.maxOpacity - widget.minOpacity) * t;
        final blur = 2 + widget.maxBlur * t;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: alpha),
                blurRadius: blur,
                spreadRadius: 1.5,
              ),
            ],
          ),
          child: Icon(widget.icon, size: widget.size, color: widget.color),
        );
      },
    );
  }
}

class SpinningIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Duration period;
  final bool clockwise;

  const SpinningIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.period = const Duration(seconds: 14),
    this.clockwise = true,
  });

  @override
  State<SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: widget.clockwise
          ? _ctrl
          : Tween(begin: 0.0, end: -1.0).animate(_ctrl),
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}

class AppearOnMount extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double fromScale;
  const AppearOnMount({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.fromScale = 0.92,
  });

  @override
  State<AppearOnMount> createState() => _AppearOnMountState();
}

class _AppearOnMountState extends State<AppearOnMount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: widget.fromScale, end: 1.0).animate(curved),
        child: widget.child,
      ),
    );
  }
}
