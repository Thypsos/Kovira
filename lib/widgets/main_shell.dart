import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/home_screen.dart';
import '../screens/income_sources_screen.dart';
import '../screens/records_screen.dart';
import '../screens/bills_screen.dart';
import '../screens/category_editor_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/goals_screen.dart';
import '../app.dart';
import '../data/settings_service.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_service.dart';
import 'live_icon.dart';
import 'main_menu_sheet.dart';
import 'main_tab_bar.dart';

abstract class ShellRefreshable {
  void refreshFromShell();
}

abstract class ShellPrimaryAction {
  void firePrimaryAction();
}

Widget shellBottomBar(Widget dedicated, {required MainScreen current}) {
  return ValueListenableBuilder<BottomBarMode>(
    valueListenable: bottomBarModeNotifier,
    builder: (_, mode, _) {
      if (mode != BottomBarMode.dedicated) return const SizedBox.shrink();
      return dedicated;
    },
  );
}

class _ShellPageBubbles extends StatelessWidget {
  final MainScreen current;
  const _ShellPageBubbles({required this.current});

  static const _order = [
    MainScreen.records,
    MainScreen.budget,
    MainScreen.accounts,
    MainScreen.dashboard,
    MainScreen.bills,
    MainScreen.categories,
    MainScreen.goals,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: _order.map((s) {
        final color = MainScreenChrome.of(s).color;
        final active = s == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: active ? 14 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
        );
      }).toList(),
    );
  }
}

Widget? buildShellBackButton(BuildContext context) {
  final shell = MainShell.maybeOf(context);
  final target = shell?.backTarget;
  if (shell == null || target == null) return null;
  final chrome = MainScreenChrome.of(target);
  return InkWell(
    onTap: shell.back,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 20, color: chrome.color),
          const SizedBox(width: 4),
          PulsingGlowIcon(
            icon: chrome.icon,
            size: 20,
            color: chrome.color,
            glowColor: chrome.color,
            maxBlur: 14,
            minOpacity: 0.30,
            maxOpacity: 0.75,
            duration: const Duration(milliseconds: 1400),
          ),
        ],
      ),
    ),
  );
}

Widget buildModalBackButton(BuildContext context) {
  final chrome = MainScreenChrome.of(MainShell.currentScreen);
  return InkWell(
    onTap: () => Navigator.of(context).pop(),
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 20, color: chrome.color),
          const SizedBox(width: 4),
          PulsingGlowIcon(
            icon: chrome.icon,
            size: 20,
            color: chrome.color,
            glowColor: chrome.color,
            maxBlur: 14,
            minOpacity: 0.30,
            maxOpacity: 0.75,
            duration: const Duration(milliseconds: 1400),
          ),
        ],
      ),
    ),
  );
}

Widget buildModalBackButtonTo(
  BuildContext context,
  IconData icon,
  Color color,
) {
  return InkWell(
    onTap: () => Navigator.of(context).pop(),
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 20, color: color),
          const SizedBox(width: 4),
          PulsingGlowIcon(
            icon: icon,
            size: 20,
            color: color,
            glowColor: color,
            maxBlur: 14,
            minOpacity: 0.30,
            maxOpacity: 0.75,
            duration: const Duration(milliseconds: 1400),
          ),
        ],
      ),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();

  static MainShellState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  static MainScreen currentScreen = MainScreen.dashboard;

  static MainShellState? _activeState;
  static void refreshAllPages() => _activeState?._refreshAll();
}

class MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  static const int _initialPage = 3;
  late final PageController _pageCtrl = PageController(
    initialPage: _initialPage,
  );
  bool _dashboardSwipeLocked = false;
  bool _pageSwipeGuardLocked = false;
  Timer? _pageSwipeGuardTimer;

  late final AnimationController _jumpFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  DateTime? _lastBackPress;

  final List<MainScreen> _history = <MainScreen>[];
  MainScreen _current = MainScreen.dashboard;

  bool _suppressHistory = false;

  MainScreen? get backTarget => _history.isNotEmpty ? _history.last : null;

  final _recordsKey = GlobalKey<State<RecordsScreen>>();
  final _budgetKey = GlobalKey<State<BudgetScreen>>();
  final _accountsKey = GlobalKey<State<IncomeSourcesScreen>>();
  final _dashboardKey = GlobalKey<State<HomeScreen>>();
  final _billsKey = GlobalKey<State<BillsScreen>>();
  final _categoriesKey = GlobalKey<State<CategoryEditorScreen>>();
  final _goalsKey = GlobalKey<State<GoalsScreen>>();

  static int indexOf(MainScreen s) {
    switch (s) {
      case MainScreen.records:
        return 0;
      case MainScreen.budget:
        return 1;
      case MainScreen.accounts:
        return 2;
      case MainScreen.dashboard:
        return 3;
      case MainScreen.bills:
        return 4;
      case MainScreen.categories:
        return 5;
      case MainScreen.goals:
        return 6;
    }
  }

  Future<void> gotoPage(
    MainScreen s, {
    bool animate = true,
    bool fade = false,
  }) async {
    if (s == _current) return;
    final i = indexOf(s);
    if (animate) {
      await _pageCtrl.animateToPage(
        i,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (fade) {
      await _jumpFade.forward(from: 0);
      _pageCtrl.jumpToPage(i);
      await _jumpFade.reverse();
      return;
    }
    _pageCtrl.jumpToPage(i);
  }

  void back() {
    if (_history.isEmpty) return;
    final target = _history.removeLast();
    _suppressHistory = true;
    gotoPage(target);
  }

  void _onPageChanged(int i) {
    final next = _screenAt(i);
    if (_suppressHistory) {
      _suppressHistory = false;
    } else if (next != _current) {
      _history.add(_current);
    }
    setState(() => _current = next);
    _armPageSwipeGuard();
    MainShell.currentScreen = next;

    _maybeFireTutorialFor(next);

    State? s;
    switch (i) {
      case 0:
        s = _recordsKey.currentState;
        break;
      case 1:
        s = _budgetKey.currentState;
        break;
      case 2:
        s = _accountsKey.currentState;
        break;
      case 3:
        s = _dashboardKey.currentState;
        break;
      case 4:
        s = _billsKey.currentState;
        break;
      case 5:
        s = _categoriesKey.currentState;
        break;
      case 6:
        s = _goalsKey.currentState;
        break;
    }
    if (s is ShellRefreshable) (s as ShellRefreshable).refreshFromShell();
  }

  static MainScreen _screenAt(int i) {
    switch (i) {
      case 0:
        return MainScreen.records;
      case 1:
        return MainScreen.budget;
      case 2:
        return MainScreen.accounts;
      case 3:
        return MainScreen.dashboard;
      case 4:
        return MainScreen.bills;
      case 5:
        return MainScreen.categories;
      case 6:
        return MainScreen.goals;
    }
    return MainScreen.dashboard;
  }

  void setDashboardSwipeLocked(bool locked) {
    if (_dashboardSwipeLocked == locked) return;
    setState(() => _dashboardSwipeLocked = locked);
  }

  void _armPageSwipeGuard() {
    _pageSwipeGuardTimer?.cancel();
    if (!_pageSwipeGuardLocked) {
      setState(() => _pageSwipeGuardLocked = true);
    }
    _pageSwipeGuardTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_pageSwipeGuardLocked) {
        setState(() => _pageSwipeGuardLocked = false);
      }
    });
  }

  bool _tutorialActive = false;

  bool get _shellSwipeLocked =>
      _dashboardSwipeLocked || _pageSwipeGuardLocked || _tutorialActive;

  @override
  void initState() {
    super.initState();
    MainShell._activeState = this;
    TutorialService.instance.isActive.addListener(_onTutorialActiveChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeFireTutorialFor(_current);
    });
  }

  void _refreshAll() {
    final keys = [
      _recordsKey,
      _budgetKey,
      _accountsKey,
      _dashboardKey,
      _billsKey,
      _categoriesKey,
      _goalsKey,
    ];
    for (final k in keys) {
      final s = k.currentState;
      if (s is ShellRefreshable) (s as ShellRefreshable).refreshFromShell();
    }
  }

  MainScreen get currentPage => _current;

  void fireCurrentPagePrimaryAction() {
    final State? s;
    switch (_current) {
      case MainScreen.records:
        s = _recordsKey.currentState;
        break;
      case MainScreen.budget:
        s = _budgetKey.currentState;
        break;
      case MainScreen.accounts:
        s = _accountsKey.currentState;
        break;
      case MainScreen.dashboard:
        s = _dashboardKey.currentState;
        break;
      case MainScreen.bills:
        s = _billsKey.currentState;
        break;
      case MainScreen.categories:
        s = _categoriesKey.currentState;
        break;
      case MainScreen.goals:
        s = _goalsKey.currentState;
        break;
    }
    if (s is ShellPrimaryAction) {
      (s as ShellPrimaryAction).firePrimaryAction();
    }
  }

  void _onTutorialActiveChanged() {
    if (!mounted) return;
    final v = TutorialService.instance.isActive.value;
    if (v != _tutorialActive) setState(() => _tutorialActive = v);
  }

  @override
  void dispose() {
    if (MainShell._activeState == this) MainShell._activeState = null;
    TutorialService.instance.isActive.removeListener(_onTutorialActiveChanged);
    _pageSwipeGuardTimer?.cancel();
    _jumpFade.dispose();
    super.dispose();
  }

  void _maybeFireTutorialFor(MainScreen s) {
    switch (s) {
      case MainScreen.dashboard:
        TutorialService.instance.showChain(context, const [
          TutorialIds.dashWelcomeTopcard,
          TutorialIds.dashExpenseBtn,
          TutorialIds.dashSettingsGear,
          TutorialIds.dashNavigation,
        ]);
        break;
      case MainScreen.accounts:
        TutorialService.instance.show(context, TutorialIds.accountsAddBtn);
        break;
      case MainScreen.bills:
        TutorialService.instance.show(context, TutorialIds.billsAddBtn);
        break;
      case MainScreen.categories:
        TutorialService.instance.show(context, TutorialIds.categoriesAddBtn);
        break;
      case MainScreen.goals:
        TutorialService.instance.show(context, TutorialIds.goalsAddBtn);
        break;
      case MainScreen.budget:
        TutorialService.instance.show(context, TutorialIds.budgetAddBtn);
        break;
      case MainScreen.records:
        TutorialService.instance.showChain(context, const [
          TutorialIds.recordsIntro,
          TutorialIds.recordsGraphMode,
        ]);
        break;
    }
  }

  void _handleSystemPop() {
    if (_tutorialActive) return;
    if (_current != MainScreen.dashboard) {
      if (_history.isNotEmpty) {
        back();
      } else {
        gotoPage(MainScreen.dashboard, animate: false, fade: true);
      }
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        const orange = Colors.orange;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: orange, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.exit_to_app, size: 16, color: orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Press back again to exit',
                      style: TextStyle(
                        color: orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        PageView(
          controller: _pageCtrl,
          onPageChanged: _onPageChanged,
          physics: _shellSwipeLocked
              ? const NeverScrollableScrollPhysics()
              : const _ShellPageScrollPhysics(),
          children: [
            RecordsScreen(key: _recordsKey),
            BudgetScreen(key: _budgetKey),
            IncomeSourcesScreen(key: _accountsKey),
            HomeScreen(key: _dashboardKey),
            BillsScreen(key: _billsKey),
            CategoryEditorScreen(key: _categoriesKey),
            GoalsScreen(key: _goalsKey),
          ],
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _jumpFade,
            builder: (_, _) => Opacity(
              opacity: _jumpFade.value,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleSystemPop();
      },
      child: ValueListenableBuilder<BottomBarMode>(
        valueListenable: bottomBarModeNotifier,
        builder: (_, mode, _) {
          final scaffold = Scaffold(
            backgroundColor: Colors.transparent,
            body: body,
            bottomNavigationBar: mode == BottomBarMode.tabs
                ? MainTabBar(current: _current)
                : null,
          );
          if (mode != BottomBarMode.dedicated) return scaffold;
          final safeBottom = MediaQuery.paddingOf(context).bottom;
          return Stack(
            children: [
              scaffold,
              Positioned(
                left: 0,
                right: 0,
                bottom: safeBottom + 88,
                child: IgnorePointer(
                  child: _ShellPageBubbles(current: _current),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShellPageScrollPhysics extends PageScrollPhysics {
  const _ShellPageScrollPhysics({super.parent});

  @override
  _ShellPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ShellPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold => 18.0;

  @override
  double get minFlingDistance => 24.0;

  @override
  double get minFlingVelocity => 550.0;
}
