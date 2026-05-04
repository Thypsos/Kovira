import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tutorial_messages.dart';
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

  int _fireToken = 0;

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

  EdgeInsets dialogInsetsFor(String messageId) {
    final seen = hasSeen(messageId) || _skipAll;
    return seen
        ? const EdgeInsets.symmetric(horizontal: 40, vertical: 24)
        : const EdgeInsets.fromLTRB(24, 24, 24, 210);
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

  Future<void> show(BuildContext context, String id) async {
    if (_skipAll || _seen.contains(id)) return;
    final msg = TutorialMessages.get(id);
    if (msg == null) return;
    if (!context.mounted) return;

    final myToken = ++_fireToken;
    _enterActive();
    try {
      await WidgetsBinding.instance.endOfFrame;
      FocusManager.instance.primaryFocus?.unfocus();

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (myToken != _fireToken) return;
      if (_skipAll || _seen.contains(id)) return;
      if (!context.mounted) return;

      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(TutorialOverlay.route(message: msg));

      if (myToken == _fireToken) await markSeen(id);
    } finally {
      _exitActive();
    }
  }

  Future<void> showChain(BuildContext context, List<String> ids) async {
    final pending = ids.where((id) => !_seen.contains(id)).toList();
    if (_skipAll || pending.isEmpty) return;
    for (var i = 0; i < pending.length; i++) {
      final id = pending[i];
      if (!context.mounted) return;
      if (_skipAll || _seen.contains(id)) continue;
      final msg = TutorialMessages.get(id);
      if (msg == null) continue;

      final myToken = ++_fireToken;
      _enterActive();
      try {
        await WidgetsBinding.instance.endOfFrame;
        if (i == 0) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        await Future<void>.delayed(Duration(milliseconds: i == 0 ? 900 : 160));
        if (myToken != _fireToken) return;
        if (_skipAll || _seen.contains(id)) continue;
        if (!context.mounted) return;

        await Navigator.of(context, rootNavigator: true).push(
          TutorialOverlay.route(
            message: msg,
            stepIndex: i + 1,
            stepCount: pending.length,
          ),
        );
        if (myToken != _fireToken) return;
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
  final Widget child;

  const TutorialFireOnMount({
    super.key,
    required this.messageId,
    required this.child,
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
      TutorialService.instance.show(context, widget.messageId);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
