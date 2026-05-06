import 'dart:async';

// ignore: unnecessary_import
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';
import 'gesture_indicator.dart';
import 'tutorial_messages.dart';
import 'tutorial_nav_observer.dart';
import 'tutorial_targets.dart';

class TutorialOverlay {
  static VoidCallback? _activeDismiss;

  static Future<void> show(
    BuildContext context, {
    required TutorialMessage message,
    int? stepIndex,
    int? stepCount,
    bool forced = true,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final priorDismiss = _activeDismiss;
    if (priorDismiss != null) {
      priorDismiss();
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    final completer = Completer<void>();
    late final OverlayEntry entry;
    void dismiss() {
      if (!completer.isCompleted) completer.complete();
    }

    _activeDismiss = dismiss;

    entry = OverlayEntry(
      builder: (_) => _TutorialOverlay(
        message: message,
        stepIndex: stepIndex,
        stepCount: stepCount,
        forced: forced,
        onDismiss: dismiss,
      ),
    );
    overlay.insert(entry);
    try {
      await completer.future;
    } finally {
      if (_activeDismiss == dismiss) _activeDismiss = null;
      try {
        entry.remove();
      } catch (_) {}
    }
  }
}

class _TutorialOverlay extends StatefulWidget {
  final TutorialMessage message;
  final int? stepIndex;
  final int? stepCount;
  final bool forced;
  final VoidCallback onDismiss;

  const _TutorialOverlay({
    required this.message,
    required this.onDismiss,
    this.stepIndex,
    this.stepCount,
    this.forced = true,
  });

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _entry;
  Rect? _targetRect;
  bool _dismissed = false;
  late final VoidCallback _navDismisser;
  Timer? _resolveTimer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();

    _navDismisser = _dismiss;
    TutorialNavObserver.instance.register(_navDismisser);

    if (!widget.forced) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointer);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRect());
    _resolveTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _resolveRect(),
    );
  }

  void _onGlobalPointer(PointerEvent event) {
    if (_dismissed || !mounted) return;
    if (event is! PointerDownEvent) return;
    final spot = _targetRect;
    if (spot == null) return;
    if (!spot.inflate(12).contains(event.position)) return;
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _dismiss();
    });
  }

  void _resolveRect() {
    if (!mounted) return;
    final r = TutorialTargets.rectOf(widget.message.targetId);
    if (r != _targetRect) setState(() => _targetRect = r);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  void dispose() {
    TutorialNavObserver.instance.unregister(_navDismisser);
    if (!widget.forced) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointer);
    }
    _resolveTimer?.cancel();
    _pulse.dispose();
    _entry.dispose();
    super.dispose();
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

    final entryAnim = CurvedAnimation(
      parent: _entry,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: entryAnim,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    rect: spot,
                    radius: 14,
                    dimColor: Colors.black.withValues(alpha: 0.52),
                  ),
                ),
              ),
            ),

            ..._buildBlockingRegions(raw == null ? null : spot, size),

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

            if (widget.message.gesture != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: GestureIndicator(
                    gesture: widget.message.gesture!,
                    targetRect: raw,
                    screenSize: size,
                    tint: tint,
                  ),
                ),
              ),

            Positioned.fill(
              child: SafeArea(
                child: widget.forced
                    ? IgnorePointer(
                        child: _CaptionPositioner(
                          spot: raw,
                          child: _captionCard(chrome, tint),
                        ),
                      )
                    : _CaptionPositioner(
                        spot: raw,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _dismiss,
                          child: _captionCard(chrome, tint),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _captionCard(MainScreenChrome chrome, Color tint) {
    return _CaptionCard(
      title: widget.message.title,
      body: widget.message.body,
      tint: tint,
      icon: chrome.icon,
      pageLabel: chrome.label,
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      forced: widget.forced,
    );
  }

  bool get _gestureIsSwipe {
    final g = widget.message.gesture;
    return g == TutorialGesture.swipeLeft ||
        g == TutorialGesture.swipeRight ||
        g == TutorialGesture.swipeUp ||
        g == TutorialGesture.swipeDown;
  }

  List<Widget> _buildBlockingRegions(Rect? spot, Size size) {
    if (spot == null) {
      if (_gestureIsSwipe) return const [];
      return [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.forced ? () {} : _dismiss,
            onLongPress: widget.forced ? () {} : null,
            onPanStart: widget.forced ? (_) {} : (_) => _dismiss(),
          ),
        ),
      ];
    }
    return [
      _block(0, 0, size.width, spot.top.clamp(0.0, size.height)),
      _block(
        0,
        spot.bottom.clamp(0.0, size.height),
        size.width,
        size.height - spot.bottom.clamp(0.0, size.height),
      ),
      _block(
        0,
        spot.top.clamp(0.0, size.height),
        spot.left.clamp(0.0, size.width),
        spot.height.clamp(0.0, size.height),
      ),
      _block(
        spot.right.clamp(0.0, size.width),
        spot.top.clamp(0.0, size.height),
        size.width - spot.right.clamp(0.0, size.width),
        spot.height.clamp(0.0, size.height),
      ),
    ];
  }

  Widget _block(double left, double top, double width, double height) {
    if (width <= 0 || height <= 0) return const SizedBox.shrink();
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.forced ? () {} : _dismiss,
        onLongPress: widget.forced ? () {} : null,
        onPanStart: widget.forced ? (_) {} : (_) => _dismiss(),
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
  final bool forced;

  const _CaptionCard({
    required this.title,
    required this.body,
    required this.tint,
    required this.icon,
    required this.pageLabel,
    this.stepIndex,
    this.stepCount,
    this.forced = true,
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
                            Icon(
                              forced
                                  ? Icons.touch_app_outlined
                                  : Icons.arrow_forward_rounded,
                              size: 13,
                              color: tint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              forced
                                  ? 'Try the gesture'
                                  : (showDots && stepIndex! < stepCount!
                                        ? 'Tap to continue'
                                        : 'Tap to dismiss'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: tint,
                              ),
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
