import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AutoScroll extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  final Duration period;
  final Duration resumeDelay;
  final Curve curve;

  const AutoScroll({
    super.key,
    required this.controller,
    required this.child,
    this.period = const Duration(seconds: 14),
    this.resumeDelay = const Duration(seconds: 3),
    this.curve = Curves.easeInOutSine,
  });

  @override
  State<AutoScroll> createState() => _AutoScrollState();
}

class _AutoScrollState extends State<AutoScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  Timer? _resumeTimer;
  bool _userActive = false;
  int _activePointers = 0;

  @override
  void initState() {
    super.initState();
    _anim.addListener(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(covariant AutoScroll oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.period != widget.period) {
      _anim.duration = widget.period;
    }
  }

  void _start() {
    if (!mounted || !widget.controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
      return;
    }
    if (widget.controller.position.maxScrollExtent <= 0) return;
    _anim.repeat(reverse: true);
  }

  void _tick() {
    if (_userActive || !widget.controller.hasClients) return;
    if (widget.controller.positions.isEmpty) return;
    final max = widget.controller.position.maxScrollExtent;
    if (max <= 0) return;
    final t = widget.curve.transform(_anim.value);
    widget.controller.jumpTo(max * t);
  }

  void _pauseForUser() {
    _userActive = true;
    _anim.stop();
    _resumeTimer?.cancel();
  }

  void _resumeIfIdle() {
    if (_activePointers > 0) return;
    _resumeTimer?.cancel();
    if (!mounted) return;
    _userActive = false;
    if (widget.controller.hasClients &&
        widget.controller.positions.isNotEmpty) {
      final max = widget.controller.position.maxScrollExtent;
      if (max > 0) {
        _anim.value = (widget.controller.offset / max).clamp(0.0, 1.0);
      }
    }
    _anim.repeat(reverse: true);
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _anim.removeListener(_tick);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _activePointers++;
        _pauseForUser();
      },
      onPointerCancel: (_) {
        if (_activePointers > 0) _activePointers--;
        _resumeIfIdle();
      },
      onPointerUp: (_) {
        if (_activePointers > 0) _activePointers--;
        _resumeIfIdle();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is UserScrollNotification &&
              n.direction != ScrollDirection.idle) {
            _pauseForUser();
          }
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
