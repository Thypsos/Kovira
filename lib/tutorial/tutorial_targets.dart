import 'package:flutter/widgets.dart';

class TutorialTargets {
  static final Map<String, GlobalKey> _keys = {};

  static void register(String id, GlobalKey key) {
    _keys[id] = key;
  }

  static void unregister(String id) {
    _keys.remove(id);
  }

  static GlobalKey? get(String id) => _keys[id];

  static Rect? rectOf(String id) {
    final key = _keys[id];
    final ctx = key?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
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
      TutorialTargets.unregister(old.id);
      TutorialTargets.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    TutorialTargets.unregister(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
