import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/settings_service.dart';
import '../widgets/main_menu_sheet.dart';

class LearnService {
  LearnService._();
  static final LearnService instance = LearnService._();

  static const _usedPrefix = 'learn_used_';
  static const _kTopCard = 'learn_global_topcard';
  static const _kLongPress = 'learn_global_longpress';
  static const _kSwipePage = 'learn_global_swipepage';
  static const _kBackArrow = 'learn_global_backarrow';

  SharedPreferences? _prefs;
  final Set<String> _used = {};

  bool _topCardSeen = false;
  bool _longPressSeen = false;
  bool _swipePageSeen = false;
  bool _backArrowSeen = false;

  String? _pendingDialogKey;

  final ValueNotifier<int> changeCounter = ValueNotifier<int>(0);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    for (final k in _prefs!.getKeys()) {
      if (k.startsWith(_usedPrefix)) {
        _used.add(k.substring(_usedPrefix.length));
      }
    }
    _topCardSeen = _prefs!.getBool(_kTopCard) ?? false;
    _longPressSeen = _prefs!.getBool(_kLongPress) ?? false;
    _swipePageSeen = _prefs!.getBool(_kSwipePage) ?? false;
    _backArrowSeen = _prefs!.getBool(_kBackArrow) ?? false;
  }

  String _shellKey(MainScreen page, BottomBarMode mode) =>
      '${page.name}_${mode.name}';

  bool isPageUsed(MainScreen page, BottomBarMode mode) =>
      _used.contains(_shellKey(page, mode));

  Future<void> markPageUsed(MainScreen page, BottomBarMode mode) async {
    final k = _shellKey(page, mode);
    if (_used.add(k)) {
      await _prefs?.setBool('$_usedPrefix$k', true);
      changeCounter.value++;
    }
  }

  bool isModalUsed(String key) => _used.contains(key);

  Future<void> markModalUsed(String key) async {
    if (_used.add(key)) {
      await _prefs?.setBool('$_usedPrefix$key', true);
      changeCounter.value++;
    }
  }

  bool get topCardSeen => _topCardSeen;
  bool get longPressSeen => _longPressSeen;
  bool get swipePageSeen => _swipePageSeen;
  bool get backArrowSeen => _backArrowSeen;

  Future<void> markTopCardSeen() async {
    if (_topCardSeen) return;
    _topCardSeen = true;
    await _prefs?.setBool(_kTopCard, true);
  }

  Future<void> markLongPressSeen() async {
    if (_longPressSeen) return;
    _longPressSeen = true;
    await _prefs?.setBool(_kLongPress, true);
  }

  Future<void> markSwipePageSeen() async {
    if (_swipePageSeen) return;
    _swipePageSeen = true;
    await _prefs?.setBool(_kSwipePage, true);
  }

  Future<void> markBackArrowSeen() async {
    if (_backArrowSeen) return;
    _backArrowSeen = true;
    await _prefs?.setBool(_kBackArrow, true);
  }

  void setPendingDialog(String? key) {
    _pendingDialogKey = key;
  }

  bool consumePendingDialog(String key) {
    if (_pendingDialogKey == key) {
      _pendingDialogKey = null;
      return true;
    }
    return false;
  }

  Future<void> resetAll() async {
    final p = _prefs;
    if (p == null) return;
    final toRemove = p
        .getKeys()
        .where(
          (k) =>
              k.startsWith(_usedPrefix) ||
              k == _kTopCard ||
              k == _kLongPress ||
              k == _kSwipePage ||
              k == _kBackArrow,
        )
        .toList();
    for (final k in toRemove) {
      await p.remove(k);
    }
    _used.clear();
    _topCardSeen = false;
    _longPressSeen = false;
    _swipePageSeen = false;
    _backArrowSeen = false;
    _pendingDialogKey = null;
    changeCounter.value++;
  }
}
