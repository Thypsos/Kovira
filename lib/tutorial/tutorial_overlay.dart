import 'package:flutter/material.dart';

import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';
import 'tutorial_messages.dart';
import 'tutorial_targets.dart';

class TutorialOverlay extends StatefulWidget {
  final TutorialMessage message;
  final int? stepIndex;
  final int? stepCount;

  const TutorialOverlay({
    super.key,
    required this.message,
    this.stepIndex,
    this.stepCount,
  });

  static PageRouteBuilder<void> route({
    required TutorialMessage message,
    int? stepIndex,
    int? stepCount,
  }) {
    return PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (_, _, _) => TutorialOverlay(
        message: message,
        stepIndex: stepIndex,
        stepCount: stepCount,
      ),
      transitionsBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRect());
  }

  void _resolveRect() {
    if (!mounted) return;
    final r = TutorialTargets.rectOf(widget.message.targetId);
    if (r != _targetRect) setState(() => _targetRect = r);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final chrome = MainScreenChrome.of(MainShell.currentScreen);
    final tint = chrome.color;

    final raw = _targetRect;
    final spot = raw == null
        ? Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2),
            radius: 0,
          )
        : raw.inflate(10);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  rect: spot,
                  radius: 14,
                  dimColor: Colors.black.withValues(alpha: 0.52),
                ),
              ),
            ),

            if (raw != null)
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) {
                  final t = Curves.easeInOut.transform(_pulse.value);
                  final grow = 3 + 6 * t;
                  final ringRect = spot.inflate(grow);
                  return Positioned.fromRect(
                    rect: ringRect,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14 + grow),
                          border: Border.all(
                            color: tint.withValues(alpha: 0.80 - 0.45 * t),
                            width: 2,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: tint.withValues(alpha: 0.22 + 0.10 * t),
                              blurRadius: 12 + 6 * t,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            Positioned.fill(
              child: SafeArea(
                child: _CaptionPositioner(
                  spot: raw,
                  child: _CaptionCard(
                    title: widget.message.title,
                    body: widget.message.body,
                    tint: tint,
                    icon: chrome.icon,
                    pageLabel: chrome.label,
                    stepIndex: widget.stepIndex,
                    stepCount: widget.stepCount,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect rect;
  final double radius;
  final Color dimColor;

  _SpotlightPainter({
    required this.rect,
    required this.radius,
    required this.dimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final hole = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(hole),
    );
    canvas.drawPath(path, Paint()..color = dimColor);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.rect != rect || old.dimColor != dimColor || old.radius != radius;
}

class _CaptionPositioner extends StatelessWidget {
  final Rect? spot;
  final Widget child;

  const _CaptionPositioner({required this.spot, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        const horizontalPad = 18.0;

        if (spot == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
            child: Center(child: child),
          );
        }

        final mq = MediaQuery.of(context);
        final localTop = spot!.top - mq.padding.top;
        final localBottom = spot!.bottom - mq.padding.top;
        final spotMid = (localTop + localBottom) / 2;
        final dockBottom = spotMid < h / 2;

        final maxCaptionH = h * 0.5;

        return Stack(
          children: [
            Positioned(
              left: horizontalPad,
              right: horizontalPad,
              top: dockBottom ? null : 16,
              bottom: dockBottom ? 20 : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxCaptionH,
                  maxWidth: w - 2 * horizontalPad,
                ),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CaptionCard extends StatelessWidget {
  final String title;
  final String body;
  final Color tint;
  final IconData icon;
  final String pageLabel;
  final int? stepIndex;
  final int? stepCount;

  const _CaptionCard({
    required this.title,
    required this.body,
    required this.tint,
    required this.icon,
    required this.pageLabel,
    this.stepIndex,
    this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final showDots = stepIndex != null && stepCount != null && stepCount! > 1;

    final surface = isDark ? Color.lerp(cs.surface, tint, 0.05)! : cs.surface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: 0.30),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: tint.withValues(alpha: 0.55), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tint.withValues(alpha: 0.65),
                    tint,
                    tint.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: tint.withValues(alpha: 0.45),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, size: 16, color: tint),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pageLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: tint,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showDots)
                        Text(
                          '${stepIndex!} / ${stepCount!}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: cs.onSurface.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (showDots)
                        _Dots(
                          count: stepCount!,
                          active: stepIndex! - 1,
                          tint: tint,
                          dimColor: cs.onSurface.withValues(alpha: 0.20),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tint.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              showDots && stepIndex! < stepCount!
                                  ? 'Tap to continue'
                                  : 'Tap to dismiss',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: tint,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: tint,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;
  final Color tint;
  final Color dimColor;

  const _Dots({
    required this.count,
    required this.active,
    required this.tint,
    required this.dimColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: isActive ? 18 : 6,
          height: 6,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            color: isActive ? tint : dimColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
