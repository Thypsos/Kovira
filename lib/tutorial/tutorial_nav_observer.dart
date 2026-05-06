import 'package:flutter/widgets.dart';

class TutorialNavObserver extends NavigatorObserver {
  TutorialNavObserver._();
  static final TutorialNavObserver instance = TutorialNavObserver._();

  final List<VoidCallback> _dismissers = <VoidCallback>[];
  int _depth = 0;

  int get depth => _depth;

  void register(VoidCallback dismiss) => _dismissers.add(dismiss);
  void unregister(VoidCallback dismiss) => _dismissers.remove(dismiss);

  void notifyDismiss() {
    if (_dismissers.isEmpty) return;
    final snapshot = List<VoidCallback>.from(_dismissers);
    for (final d in snapshot) {
      d();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _depth++;
    notifyDismiss();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_depth > 0) _depth--;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (_depth > 0) _depth--;
  }
}
