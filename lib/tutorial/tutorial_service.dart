import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learn_service.dart';
import 'tutorial_messages.dart';
import 'tutorial_nav_observer.dart';
import 'tutorial_overlay.dart';
import 'tutorial_targets.dart';

class TutorialService {
  TutorialService._();
  static final TutorialService instance = TutorialService._();

  static const _seenPrefix = 'tut_seen_';
  static const _skipAllKey = 'tut_skip_all';

  SharedPreferences? _prefs;
  bool _skipAll = false;
  final Set<String> _seen = {};

  int _activeCount = 0;
  final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);

  void _enterActive() {
    _activeCount++;
    if (!isActive.value) isActive.value = true;
  }

  void _exitActive() {
    _activeCount--;
    if (_activeCount <= 0) {
      _activeCount = 0;
      if (isActive.value) isActive.value = false;
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _skipAll = _prefs!.getBool(_skipAllKey) ?? false;
    for (final k in _prefs!.getKeys()) {
      if (k.startsWith(_seenPrefix) && (_prefs!.getBool(k) ?? false)) {
        _seen.add(k.substring(_seenPrefix.length));
      }
    }
  }

  bool get skipAll => _skipAll;

  Future<void> setSkipAll(bool v) async {
    _skipAll = v;
    await _prefs?.setBool(_skipAllKey, v);
  }

  bool hasSeen(String id) => _seen.contains(id);

  Future<bool> waitForDepth(int target, {int maxSpins = 6000}) async {
    var spins = 0;
    while (TutorialNavObserver.instance.depth > target && spins < maxSpins) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      spins++;
    }
    return TutorialNavObserver.instance.depth <= target;
  }

  EdgeInsets dialogInsetsFor(String messageId) {
    return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
  }

  Future<void> markSeen(String id) async {
    if (_seen.add(id)) {
      await _prefs?.setBool('$_seenPrefix$id', true);
    }
  }

  Future<void> resetAll() async {
    final p = _prefs;
    if (p == null) return;
    final toRemove = p
        .getKeys()
        .where((k) => k.startsWith(_seenPrefix) || k == _skipAllKey)
        .toList();
    for (final k in toRemove) {
      await p.remove(k);
    }
    _seen.clear();
    _skipAll = false;
  }

  Future<void> show(
    BuildContext context,
    String id, {
    bool force = false,
    bool forced = true,
  }) async {
    if (!force) return;
    if (_skipAll || _seen.contains(id)) return;
    final msg = TutorialMessages.get(id);
    if (msg == null) return;
    if (!context.mounted) return;

    _enterActive();
    try {
      await WidgetsBinding.instance.endOfFrame;
      FocusManager.instance.primaryFocus?.unfocus();

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return;

      await TutorialOverlay.show(context, message: msg, forced: forced);
      await markSeen(id);
    } finally {
      _exitActive();
    }
  }

  Future<void> showChain(
    BuildContext context,
    List<String> ids, {
    bool force = false,
    bool forced = true,
    bool waitDepthBetween = true,
  }) async {
    if (!force) return;
    final pending = ids.toList();
    if (pending.isEmpty) return;
    final baseDepth = TutorialNavObserver.instance.depth;
    for (var i = 0; i < pending.length; i++) {
      final id = pending[i];
      if (!context.mounted) return;
      final msg = TutorialMessages.get(id);
      if (msg == null) continue;

      if (i > 0 && waitDepthBetween) {
        var spins = 0;
        while (TutorialNavObserver.instance.depth > baseDepth && spins < 600) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          spins++;
          if (!context.mounted) return;
        }
        if (TutorialNavObserver.instance.depth > baseDepth) return;
      }

      _enterActive();
      try {
        await WidgetsBinding.instance.endOfFrame;
        if (i == 0) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        await Future<void>.delayed(Duration(milliseconds: i == 0 ? 500 : 280));
        if (!context.mounted) return;

        await TutorialOverlay.show(
          context,
          message: msg,
          stepIndex: i + 1,
          stepCount: pending.length,
          forced: forced,
        );
        await markSeen(id);
      } finally {
        _exitActive();
      }
    }
  }
}

class TutorialAutoFire extends StatefulWidget {
  final String messageId;
  final String targetId;
  final Widget child;

  const TutorialAutoFire({
    super.key,
    required this.messageId,
    required this.targetId,
    required this.child,
  });

  @override
  State<TutorialAutoFire> createState() => _TutorialAutoFireState();
}

class _TutorialAutoFireState extends State<TutorialAutoFire> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TutorialTargets.register(widget.targetId, _key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TutorialService.instance.show(context, widget.messageId);
    });
  }

  @override
  void dispose() {
    TutorialTargets.unregister(widget.targetId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

class TutorialFireOnMount extends StatefulWidget {
  final String messageId;
  final String? pendingDialogKey;
  final Widget child;

  const TutorialFireOnMount({
    super.key,
    required this.messageId,
    required this.child,
    this.pendingDialogKey,
  });

  @override
  State<TutorialFireOnMount> createState() => _TutorialFireOnMountState();
}

class _TutorialFireOnMountState extends State<TutorialFireOnMount> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = widget.pendingDialogKey;
      if (key != null) {
        if (!LearnService.instance.consumePendingDialog(key)) return;
        TutorialService.instance.show(
          context,
          widget.messageId,
          force: true,
          forced: false,
        );
      } else {
        TutorialService.instance.show(context, widget.messageId);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
