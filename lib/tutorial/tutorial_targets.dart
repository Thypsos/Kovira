import 'package:flutter/widgets.dart';

class TutorialTargets {
  static final Map<String, List<GlobalKey>> _keys = {};

  static void register(String id, GlobalKey key) {
    final list = _keys.putIfAbsent(id, () => <GlobalKey>[]);
    if (!list.contains(key)) list.add(key);
  }

  static void unregister(String id, [GlobalKey? key]) {
    final list = _keys[id];
    if (list == null) return;
    if (key == null) {
      list.clear();
    } else {
      list.remove(key);
    }
    if (list.isEmpty) _keys.remove(id);
  }

  static GlobalKey? get(String id) {
    final list = _keys[id];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  static Rect? rectOf(String id) {
    final list = _keys[id];
    if (list == null || list.isEmpty) return null;
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screen = view.physicalSize / view.devicePixelRatio;
    Rect? best;
    for (final key in list) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      if (!box.attached) continue;
      final origin = box.localToGlobal(Offset.zero);
      final rect = origin & box.size;
      if (rect.right < 0 || rect.left > screen.width) continue;
      if (rect.bottom < 0 || rect.top > screen.height) continue;
      best = rect;
      break;
    }
    return best;
  }
}

class TutorialTarget extends StatefulWidget {
  final String id;
  final Widget child;

  const TutorialTarget({super.key, required this.id, required this.child});

  @override
  State<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends State<TutorialTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TutorialTargets.register(widget.id, _key);
  }

  @override
  void didUpdateWidget(covariant TutorialTarget old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      TutorialTargets.unregister(old.id, _key);
      TutorialTargets.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    TutorialTargets.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
