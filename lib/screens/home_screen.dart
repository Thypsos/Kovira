import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/income_source.dart';
import '../models/ledger_entry.dart';
import '../models/goal.dart';
import '../utils/currency_symbol.dart';
import '../utils/money_input.dart';
import '../widgets/category_icon.dart';
import '../theme/app_colors.dart';
import 'add_entry_screen.dart';
import 'category_detail_screen.dart';
import 'settings_screen.dart';
import '../widgets/live_icon.dart';
import '../widgets/auto_scroll.dart';
import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';
import '../tutorial/learn_button.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_nav_observer.dart';
import '../tutorial/tutorial_service.dart';
import '../tutorial/tutorial_targets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    implements ShellRefreshable, ShellPrimaryAction {
  @override
  void refreshFromShell() => _load();

  @override
  void firePrimaryAction() => _addExpense();

  @override
  bool get hasData => entries.isNotEmpty;

  Future<void> _addExpense() async {
    if (!await _requireSource('add an expense')) return;
    if (!mounted) return;
    final c = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEntryScreen()),
    );
    if (c == true && mounted) _load();
  }

  List<IncomeSource> sources = [];
  List<Category> categories = [];
  List<LedgerEntry> entries = [];
  int totalMoney = 0, spentThisMonth = 0, incomeThisMonth = 0;
  List<LedgerEntry> dueEntries = [];
  int totalDue = 0;

  List<Goal> goals = [];
  int budgetTotal = 0;
  int budgetSpent = 0;
  Map<int, int> _budgetLimits = {};
  Map<int, int> _budgetSpentByCategory = {};
  bool _accountsExpanded = false;
  bool _goalsExpanded = false;
  bool _budgetExpanded = false;

  bool _accountsCardDragging = false;
  double _accountsCardDragDy = 0;
  bool _goalsCardDragging = false;
  double _goalsCardDragDy = 0;
  bool _budgetCardDragging = false;
  double _budgetCardDragDy = 0;
  final ScrollController _activityScrollCtrl = ScrollController();

  int _topPageIndex = 1;

  double _topCardDx = 0;

  int _lastCardDir = 1;

  int? _tutPrevSpent;
  int? _tutPrevDue;
  int? _tutPrevActivity;

  int _nextTopPage(int from, int dir) {
    const count = 3;
    return (from + dir + count) % count;
  }

  Color _topCardTintForIndex(ColorScheme cs, int index) {
    switch (index) {
      case 0:
        return Colors.teal;
      case 1:
        return cs.primary;
      default:
        return Colors.deepOrange;
    }
  }

  Widget _swipeArrowOverlay(double dx, double threshold, Color color) {
    final intensity = (dx.abs() / threshold).clamp(0.0, 1.0);
    if (intensity <= 0) return const SizedBox.shrink();
    final goingLeft = dx > 0;
    return Positioned(
      left: goingLeft ? 12 : null,
      right: goingLeft ? null : 12,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: intensity,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55 * intensity),
                    blurRadius: 18 * intensity,
                    spreadRadius: 1 + 2 * intensity,
                  ),
                ],
              ),
              child: Icon(
                goingLeft ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: color,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DatabaseHelper.instance.snapshotMonthlyStart();
    final db = DatabaseHelper.instance;
    sources = await db.getActiveSources();
    categories = await db.getCategories();
    entries = await db.getEntriesForMonth(DateTime.now());
    totalMoney = await db.totalBalance();
    spentThisMonth = await db.spentThisMonth();
    incomeThisMonth = await db.incomeThisMonth();
    dueEntries = await db.getDueEntries();
    totalDue = await db.totalDueAmount();
    goals = await db.getGoals();
    _budgetLimits = await db.getAllBudgets();
    final spentByCategory = <int, int>{};
    for (final e in entries) {
      if (e.type != 'expense') continue;
      spentByCategory[e.categoryId] =
          (spentByCategory[e.categoryId] ?? 0) + e.amount;
    }
    _budgetSpentByCategory = spentByCategory;
    budgetTotal = _budgetLimits.values.fold<int>(0, (s, v) => s + v);
    budgetSpent = _budgetLimits.entries.fold<int>(0, (s, e) {
      return s + (spentByCategory[e.key] ?? 0);
    });
    if (!mounted) return;
    setState(() {});
    _checkTutorialTransitions();
  }

  void _checkTutorialTransitions() {
    final activityCount = entries
        .where((e) => e.type == 'income' || e.type == 'transfer')
        .length;
    final prevSpent = _tutPrevSpent;
    final prevDue = _tutPrevDue;
    final prevAct = _tutPrevActivity;
    _tutPrevSpent = spentThisMonth;
    _tutPrevDue = totalDue;
    _tutPrevActivity = activityCount;
    if (prevSpent == null || prevDue == null || prevAct == null) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (prevAct == 0 && activityCount > 0) {
        TutorialService.instance.show(context, TutorialIds.dashActivityStrip);
      }
      if (prevSpent == 0 && spentThisMonth > 0) {
        TutorialService.instance.show(context, TutorialIds.dashExpenseSection);
      }
      if (prevDue == 0 && totalDue > 0) {
        TutorialService.instance.show(context, TutorialIds.dashDueSection);
      }
    });
  }

  @override
  void dispose() {
    _activityScrollCtrl.dispose();
    super.dispose();
  }

  Future<bool> _requireSource(String action) async {
    if (sources.isNotEmpty) return true;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'No income sources yet',
          style: TextStyle(fontSize: 20),
        ),
        content: Text(
          'You need to add at least one income source before you can $action.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              MainShell.maybeOf(context)?.gotoPage(MainScreen.accounts);
            },
            child: const Text('Add Income Source'),
          ),
        ],
      ),
    );
    return false;
  }

  void _openMenu() {
    showMainMenuSheet(
      context,
      current: MainScreen.dashboard,
      requireSource: _requireSource,
    );
  }

  Color _goalProgressColor(double ratio) => ProgressColors.goalProgress(ratio);

  Color _budgetProgressColor(double ratio, {required bool overBudget}) =>
      ProgressColors.budgetProgress(ratio, overBudget: overBudget);

  bool get _goalsChevronVisible =>
      goals.length > 2 && !_goalsExpanded && !_goalsCardDragging;

  bool get _budgetChevronVisible =>
      _budgetedCategories().length > 2 &&
      !_budgetExpanded &&
      !_budgetCardDragging;

  @override
  Widget build(BuildContext context) {
    final expenseEntries = entries.where((e) => e.type == 'expense').toList();
    final Map<int, int> categoryTotals = {};
    for (final e in expenseEntries) {
      categoryTotals[e.categoryId] =
          (categoryTotals[e.categoryId] ?? 0) + e.amount;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leadingWidth: 80,
        leading: buildShellBackButton(context),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            PulsingGlowIcon(
              icon: Icons.shopping_bag_outlined,
              size: 22,
              color: PageColors.dashboard,
              glowColor: PageColors.dashboard,
              maxBlur: 16,
              minOpacity: 0.35,
              maxOpacity: 0.85,
              duration: Duration(milliseconds: 1400),
            ),
            SizedBox(width: 8),
            Text(
              'Expenses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          const LearnButton(page: MainScreen.dashboard),
          TutorialTarget(
            id: TutorialTargetIds.dashSettingsGear,
            child: IconButton(
              icon: const SpinningIcon(
                icon: Icons.settings_outlined,
                size: 24,
                period: Duration(seconds: 18),
              ),
              tooltip: 'Settings',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                if (!mounted) return;
                _load();
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          TutorialTarget(
            id: TutorialTargetIds.dashTopCard,
            child: _topSection(),
          ),
          const SizedBox(height: 16),
          if (dueEntries.isNotEmpty) ...[
            TutorialTarget(
              id: TutorialTargetIds.dashDueSection,
              child: _dueSection(),
            ),
            const SizedBox(height: 16),
          ],
          TutorialTarget(
            id: TutorialTargetIds.dashExpenseSection,
            child: _expenseSection(categoryTotals),
          ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: shellBottomBar(
        TutorialTarget(
          id: TutorialTargetIds.dashExpenseBtn,
          child: _bottomBar(),
        ),
        current: MainScreen.dashboard,
      ),
    );
  }

  Widget _topSection() {
    final cs = Theme.of(context).colorScheme;
    final acctActivity = entries
        .where((e) => e.type == 'income' || e.type == 'transfer')
        .toList();

    final pageTints = <Color>[Colors.teal, cs.primary, Colors.deepOrange];
    final tint = pageTints[_topPageIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = isDark
        ? Color.lerp(cs.surface, tint, 0.18)!
        : Color.lerp(tint, Colors.white, 0.30)!;
    final accent = isDark
        ? Color.lerp(cs.surface, tint, 0.32)!
        : Color.lerp(tint, Colors.white, 0.20)!;
    final onCard = isDark ? cs.onSurface : Colors.white;
    final showAccountsActivity = _topPageIndex == 1 && acctActivity.isNotEmpty;

    final indicatorTopPad = _topPageIndex == 1 ? 1.0 : 6.0;

    final indicatorBottomPad = _topPageIndex == 1
        ? (_accountsExpanded && showAccountsActivity ? 6.0 : 1.0)
        : 10.0;

    final bodyHeight = _topCardBodyHeight();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          MainShell.maybeOf(context)?.setDashboardSwipeLocked(true);
          setState(() => _topCardDx = 0);
        },
        onHorizontalDragUpdate: (d) {
          setState(() => _topCardDx += d.delta.dx);
        },
        onHorizontalDragEnd: (d) {
          final dx = _topCardDx;
          final v = d.primaryVelocity ?? 0;
          setState(() => _topCardDx = 0);
          MainShell.maybeOf(context)?.setDashboardSwipeLocked(false);
          if (dx.abs() < 40 && v.abs() < 250) return;
          final dir = (v != 0 ? v > 0 : dx > 0) ? -1 : 1;
          final next = _nextTopPage(_topPageIndex, dir);
          setState(() {
            _lastCardDir = dir;
            _topPageIndex = next;
          });
          TutorialNavObserver.instance.notifyDismiss();
        },
        onHorizontalDragCancel: () {
          if (_topCardDx != 0) {
            setState(() => _topCardDx = 0);
          }
          MainShell.maybeOf(context)?.setDashboardSwipeLocked(false);
        },
        onVerticalDragStart: (_) {
          setState(() {
            if (_topPageIndex == 0) {
              _goalsCardDragging = true;
              _goalsCardDragDy = 0;
            } else if (_topPageIndex == 1) {
              _accountsCardDragging = true;
              _accountsCardDragDy = 0;
            } else {
              _budgetCardDragging = true;
              _budgetCardDragDy = 0;
            }
          });
        },
        onVerticalDragUpdate: (d) {
          setState(() {
            if (_topPageIndex == 0) {
              _goalsCardDragDy += d.delta.dy;
            } else if (_topPageIndex == 1) {
              _accountsCardDragDy += d.delta.dy;
            } else {
              _budgetCardDragDy += d.delta.dy;
            }
          });
        },
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          setState(() {
            final downward =
                v > 250 ||
                (v == 0 &&
                    ((_topPageIndex == 0 && _goalsCardDragDy > 30) ||
                        (_topPageIndex == 1 && _accountsCardDragDy > 30) ||
                        (_topPageIndex == 2 && _budgetCardDragDy > 30)));
            final upward =
                v < -250 ||
                (v == 0 &&
                    ((_topPageIndex == 0 && _goalsCardDragDy < -30) ||
                        (_topPageIndex == 1 && _accountsCardDragDy < -30) ||
                        (_topPageIndex == 2 && _budgetCardDragDy < -30)));

            if (_topPageIndex == 0) {
              if (downward && _hasMoreGoals()) _goalsExpanded = true;
              if (upward) _goalsExpanded = false;
              _goalsCardDragging = false;
              _goalsCardDragDy = 0;
            } else if (_topPageIndex == 1) {
              if (downward && _hasMoreAccounts()) _accountsExpanded = true;
              if (upward) _accountsExpanded = false;
              _accountsCardDragging = false;
              _accountsCardDragDy = 0;
            } else {
              if (downward && _hasMoreBudgetRows()) _budgetExpanded = true;
              if (upward) _budgetExpanded = false;
              _budgetCardDragging = false;
              _budgetCardDragDy = 0;
            }
          });
        },
        onVerticalDragCancel: () {
          setState(() {
            _goalsCardDragging = false;
            _goalsCardDragDy = 0;
            _accountsCardDragging = false;
            _accountsCardDragDy = 0;
            _budgetCardDragging = false;
            _budgetCardDragDy = 0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, base],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: bodyHeight,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) {
                    MainShell.maybeOf(context)?.setDashboardSwipeLocked(true);
                  },
                  onPointerUp: (_) {
                    MainShell.maybeOf(context)?.setDashboardSwipeLocked(false);
                  },
                  onPointerCancel: (_) {
                    MainShell.maybeOf(context)?.setDashboardSwipeLocked(false);
                  },
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.translucent,
                    gestures: {
                      HorizontalDragGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            HorizontalDragGestureRecognizer
                          >(() => HorizontalDragGestureRecognizer(), (
                            instance,
                          ) {
                            instance.dragStartBehavior = DragStartBehavior.down;
                            instance.onStart = (_) {
                              setState(() => _topCardDx = 0);
                            };
                            instance.onUpdate = (d) {
                              setState(() => _topCardDx += d.delta.dx);
                            };
                            instance.onEnd = (d) {
                              final dx = _topCardDx;
                              final v = d.primaryVelocity ?? 0;
                              setState(() => _topCardDx = 0);
                              MainShell.maybeOf(
                                context,
                              )?.setDashboardSwipeLocked(false);
                              if (dx.abs() < 40 && v.abs() < 250) return;
                              final dir = (v != 0 ? v > 0 : dx > 0) ? -1 : 1;
                              final next = _nextTopPage(_topPageIndex, dir);
                              setState(() {
                                _lastCardDir = dir;
                                _topPageIndex = next;
                              });
                              TutorialNavObserver.instance.notifyDismiss();
                            };
                            instance.onCancel = () {
                              if (_topCardDx != 0) {
                                setState(() => _topCardDx = 0);
                              }
                              MainShell.maybeOf(
                                context,
                              )?.setDashboardSwipeLocked(false);
                            };
                          }),
                    },
                    child: Stack(
                      children: [
                        ClipRect(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) {
                              final incoming =
                                  (child.key == ValueKey(_topPageIndex));
                              final from = incoming
                                  ? (_lastCardDir > 0 ? 1.0 : -1.0)
                                  : (_lastCardDir > 0 ? -1.0 : 1.0);
                              return SlideTransition(
                                position: anim.drive(
                                  Tween<Offset>(
                                    begin: Offset(from, 0),
                                    end: Offset.zero,
                                  ),
                                ),
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey(_topPageIndex),
                              child: _topPageIndex == 0
                                  ? _goalsCarouselPage(onCard, tint)
                                  : _topPageIndex == 1
                                  ? _accountsCarouselPage(cs, onCard)
                                  : _budgetCarouselPage(onCard, tint),
                            ),
                          ),
                        ),
                        _swipeArrowOverlay(
                          _topCardDx,
                          80,
                          _topCardTintForIndex(
                            cs,
                            _nextTopPage(
                              _topPageIndex,
                              _topCardDx > 0 ? -1 : 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(
                  top: indicatorTopPad,
                  bottom: indicatorBottomPad,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(3, (i) {
                      final on = i == _topPageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: on ? 12 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: on ? tint : onCard.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                    if (_topPageIndex == 0 && _goalsChevronVisible) ...[
                      const SizedBox(width: 4),
                      _footerChevron(
                        color: tint,
                        background: tint.withValues(alpha: 0.16),
                        onTap: () => setState(() => _goalsExpanded = true),
                      ),
                    ] else if (_topPageIndex == 1 && _chevronVisible) ...[
                      const SizedBox(width: 4),
                      _footerChevron(
                        color: tint,
                        background: tint.withValues(alpha: 0.16),
                        onTap: () => setState(() => _accountsExpanded = true),
                      ),
                    ] else if (_topPageIndex == 2 && _budgetChevronVisible) ...[
                      const SizedBox(width: 4),
                      _footerChevron(
                        color: tint,
                        background: tint.withValues(alpha: 0.16),
                        onTap: () => setState(() => _budgetExpanded = true),
                      ),
                    ],
                  ],
                ),
              ),
              if (_topPageIndex == 1) ...[
                if (showAccountsActivity)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: onCard.withValues(alpha: 0.18),
                  ),
                SizedBox(
                  height: 34,
                  child: showAccountsActivity
                      ? _accountActivityLine(cs, acctActivity)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountsCarouselPage(ColorScheme cs, Color onCard) {
    void goToAccounts() {
      MainShell.maybeOf(context)?.gotoPage(MainScreen.accounts);
    }

    return GestureDetector(
      onTap: goToAccounts,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _accountsColumn(cs, onCard),
      ),
    );
  }

  bool _hasMoreAccounts() => sources.length > 3;

  bool _hasMoreGoals() => goals.length > 2;

  bool _hasMoreBudgetRows() => _budgetedCategories().length > 2;

  double _topCardBodyHeight() {
    const goalsBudgetBase = 136.0;
    const accountsBase = 136.0;
    const rowHeight = 28.0;
    final textScale = (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(
      1.0,
      1.6,
    );
    final scaleExtra = (textScale - 1.0) * 20.0;
    int extraRows = 0;
    if (_topPageIndex == 0 && _goalsExpanded) {
      extraRows = goals.length > 2 ? goals.length - 2 : 0;
    } else if (_topPageIndex == 1 && _accountsExpanded) {
      extraRows = sources.length > 3 ? sources.length - 3 : 0;
    } else if (_topPageIndex == 2 && _budgetExpanded) {
      final budgetRows = _budgetedCategories().length;
      extraRows = budgetRows > 2 ? budgetRows - 2 : 0;
    }
    final pageBase = _topPageIndex == 1 ? accountsBase : goalsBudgetBase;
    return pageBase + scaleExtra + (rowHeight * extraRows);
  }

  bool get _chevronVisible =>
      _hasMoreAccounts() && !_accountsExpanded && !_accountsCardDragging;

  Widget _goalsCarouselPage(Color onCard, Color tint) {
    final totalSaved = goals.fold<int>(0, (s, g) => s + g.savedAmount);
    final totalTarget = goals.fold<int>(0, (s, g) => s + g.targetAmount);
    final totalLeft = totalTarget - totalSaved;
    final hasGoals = goals.isNotEmpty;
    final shownGoals = _goalsExpanded ? goals : goals.take(2).toList();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => MainShell.maybeOf(context)?.gotoPage(MainScreen.goals),

      child: ClipRect(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: hasGoals ? 20 : 18,
                    color: tint,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasGoals
                          ? 'Goals · ${formatMoney(totalSaved)} saved'
                          : 'Goals',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: hasGoals ? 15 : 13,
                        fontWeight: FontWeight.w700,
                        color: onCard.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  if (hasGoals) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (totalLeft < 0 ? Colors.red.shade400 : tint)
                            .withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        totalLeft < 0
                            ? 'over ${formatMoney(-totalLeft)}'
                            : '${formatMoney(totalLeft)} left',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: onCard,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              if (!hasGoals) ...[
                const Spacer(),
                Text(
                  'No goals yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: onCard,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap to set a savings target',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tint,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: tint),
                  ],
                ),
                const Spacer(),
              ] else
                Expanded(
                  child: Align(
                    alignment: shownGoals.length <= 1
                        ? Alignment.center
                        : Alignment.topCenter,
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 4),
                      physics: _goalsExpanded
                          ? const ClampingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      itemCount: shownGoals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 5),
                      itemBuilder: (_, i) =>
                          _goalSummaryRow(shownGoals[i], onCard),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _budgetCarouselPage(Color onCard, Color tint) {
    final hasBudget = budgetTotal > 0;
    final remaining = budgetTotal - budgetSpent;
    final over = budgetSpent > budgetTotal;
    final budgeted = _budgetedCategories();
    final shownBudgeted = _budgetExpanded
        ? budgeted
        : budgeted.take(2).toList();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => MainShell.maybeOf(context)?.gotoPage(MainScreen.budget),

      child: ClipRect(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: hasBudget ? 20 : 18,
                    color: tint,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasBudget
                          ? 'Budget · ${formatMoney(budgetSpent)} spent'
                          : 'Budget',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: hasBudget ? 15 : 13,
                        fontWeight: FontWeight.w700,
                        color: onCard.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  if (hasBudget) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (over ? Colors.red.shade400 : tint).withValues(
                          alpha: 0.22,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        over
                            ? 'over ${formatMoney(-remaining)}'
                            : '${formatMoney(remaining)} left',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: onCard,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              if (!hasBudget) ...[
                const Spacer(),
                Text(
                  'No monthly budget set',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: onCard,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap to cap spending per tag',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tint,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: tint),
                  ],
                ),
                const Spacer(),
              ] else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 4),
                    physics: _budgetExpanded
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: shownBudgeted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 5),
                    itemBuilder: (_, i) {
                      final c = shownBudgeted[i];
                      final limit = _budgetLimits[c.id] ?? 0;
                      final spent = _budgetSpentByCategory[c.id] ?? 0;
                      return _budgetSummaryRow(c, spent, limit, onCard);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Category> _budgetedCategories() {
    final list = categories
        .where((c) => (_budgetLimits[c.id] ?? 0) > 0)
        .toList();
    list.sort((a, b) {
      final bLimit = _budgetLimits[b.id] ?? 0;
      final aLimit = _budgetLimits[a.id] ?? 0;
      final bSpent = _budgetSpentByCategory[b.id] ?? 0;
      final aSpent = _budgetSpentByCategory[a.id] ?? 0;
      final bRatio = bLimit == 0 ? 0.0 : bSpent / bLimit;
      final aRatio = aLimit == 0 ? 0.0 : aSpent / aLimit;
      return bRatio.compareTo(aRatio);
    });
    return list;
  }

  Widget _footerChevron({
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Icon(Icons.keyboard_arrow_down, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _goalSummaryRow(Goal goal, Color onCard) {
    final ratio = goal.progress;
    final fill = _goalProgressColor(ratio);
    final left = goal.targetAmount - goal.savedAmount;
    final info =
        'saved ${formatMoney(goal.savedAmount)} | Left ${formatMoney(left > 0 ? left : 0)}';

    return Row(
      children: [
        Text(goal.icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text(
            goal.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: onCard.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 8,
          child: _rowProgressBar(
            text: info,
            ratio: ratio,
            fill: fill,
            onCard: onCard,
          ),
        ),
      ],
    );
  }

  Widget _budgetSummaryRow(Category c, int spent, int limit, Color onCard) {
    final ratio = limit == 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final over = spent > limit;
    final fill = _budgetProgressColor(ratio, overBudget: over);
    final left = limit - spent;
    final info =
        'spent ${formatMoney(spent)} | Left ${formatMoney(left > 0 ? left : 0)}';
    return Row(
      children: [
        RawCategoryIcon(icon: c.icon, color: c.color, size: 22),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text(
            c.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: onCard.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 8,
          child: _rowProgressBar(
            text: info,
            ratio: ratio,
            fill: fill,
            onCard: onCard,
          ),
        ),
      ],
    );
  }

  Widget _rowProgressBar({
    required String text,
    required double ratio,
    required Color fill,
    required Color onCard,
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    const textStyle = TextStyle(
      fontSize: 10.75,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.1,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 19,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? onCard.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped,
                child: Container(color: fill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textStyle.copyWith(color: Colors.black87),
              ),
            ),
            Positioned.fill(
              child: ClipRect(
                clipper: _LeftRatioClipper(clamped),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Center(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountsColumn(ColorScheme cs, Color onCard) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fg = isDark ? cs.onPrimaryContainer : onCard;
    final tint = cs.primary;
    if (sources.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: tint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Income Sources',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: onCard.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Spacer(),
          Text(
            'No income sources yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: onCard,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tap to add an income source',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tint,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: tint),
            ],
          ),
          const Spacer(),
        ],
      );
    }

    final useCount = <int, int>{};
    for (final e in entries) {
      useCount[e.sourceId] = (useCount[e.sourceId] ?? 0) + 1;
      if (e.toSourceId != null) {
        useCount[e.toSourceId!] = (useCount[e.toSourceId!] ?? 0) + 1;
      }
    }
    final ranked = [...sources]
      ..sort((a, b) => (useCount[b.id] ?? 0).compareTo(useCount[a.id] ?? 0));
    const visibleN = 3;
    final visible = _accountsExpanded ? ranked : ranked.take(visibleN).toList();

    Widget row(IncomeSource s) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Text(s.icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                s.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatMoney(s.balance),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sources (${ranked.length}) | Total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.75),
              ),
            ),
            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: fg.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${deviceCurrencySymbol(context)}${formatMoney(totalMoney)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: _accountsExpanded
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            itemBuilder: (_, i) => row(visible[i]),
          ),
        ),
      ],
    );
  }

  Widget _accountActivityLine(ColorScheme cs, List<LedgerEntry> acts) {
    final recent = acts.take(30).toList();
    return TutorialTarget(
      id: TutorialTargetIds.dashActivityStrip,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        color: cs.tertiaryContainer.withValues(alpha: 0.85),
        child: SizedBox(
          height: 18,
          child: Row(
            children: [
              Icon(
                Icons.swap_vert,
                size: 12,
                color: cs.onTertiaryContainer.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AutoScroll(
                  controller: _activityScrollCtrl,
                  period: const Duration(seconds: 88),
                  curve: Curves.linear,
                  child: ListView.builder(
                    controller: _activityScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: recent.length,
                    itemBuilder: (_, i) {
                      final e = recent[i];
                      final isIncome = e.type == 'income';
                      final src = sources
                          .where((s) => s.id == e.sourceId)
                          .firstOrNull;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (src != null) ...[
                              Text(
                                src.icon,
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              '${isIncome ? "+" : "→"}${formatMoney(e.amount)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cs.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dueSection() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Dues',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            const Spacer(),
            Text(
              'Total: ${formatMoney(totalDue)}',
              style: const TextStyle(fontSize: 14, color: Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...dueEntries.map((e) {
          final cat = categories.where((c) => c.id == e.categoryId).firstOrNull;
          return Card(
            color: isDark ? const Color(0xFF2A1A00) : Colors.orange.shade50,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: Text(
                cat?.icon ?? '📦',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(e.name, style: const TextStyle(fontSize: 15)),
              subtitle: Text(
                'Owed: ${formatMoney(e.remainingDue)}${e.paidAmount > 0 ? ' (paid ${formatMoney(e.paidAmount)})' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              onLongPress: () => _showDueActions(e),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showPayDialog(e, partial: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Full',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showPayDialog(e, partial: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Partial',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showDueActions(LedgerEntry due) async {
    if (!mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, size: 24),
              title: const Text('Edit', style: TextStyle(fontSize: 17)),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, size: 24, color: Colors.red),
              title: const Text(
                'Remove',
                style: TextStyle(fontSize: 17, color: Colors.red),
              ),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      final c = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEntryScreen(existing: due)),
      );
      if (c == true && mounted) _load();
    } else if (action == 'remove') {
      await DatabaseHelper.instance.deleteEntry(due.id!);
      if (!mounted) return;
      _load();
    }
  }

  Future<void> _showPayDialog(LedgerEntry due, {bool partial = false}) async {
    if (sources.isEmpty) return;
    if (!partial) {
      IncomeSource? payFrom = sources.first;
      final picked = await showDialog<IncomeSource?>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            title: Text(
              'Clear "${due.name}"',
              style: const TextStyle(fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay ${formatMoney(due.remainingDue)} from:',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  ...sources.map((s) {
                    final sel = s.id == payFrom?.id;
                    return GestureDetector(
                      onTap: () => setDlg(() => payFrom = s),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: sel
                              ? Color(s.color).withValues(alpha: 0.2)
                              : Theme.of(
                                  ctx,
                                ).colorScheme.surfaceContainerHighest,
                          border: sel
                              ? Border.all(color: Color(s.color), width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(s.icon, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(s.name, style: const TextStyle(fontSize: 16)),
                            const Spacer(),
                            Text(
                              formatMoney(s.balance),
                              style: TextStyle(
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, payFrom),
                child: const Text('Clear', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      await DatabaseHelper.instance.payDue(
        due.id!,
        due.remainingDue,
        picked.id!,
      );
      if (!mounted) return;
      _load();
      return;
    }
    IncomeSource? payFrom = sources.first;
    final amountCtrl = TextEditingController(
      text: formatMoneyCompact(due.remainingDue),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(
            'Clear "${due.name}"',
            style: const TextStyle(fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining: ${formatMoney(due.remainingDue)}',
                  style: const TextStyle(color: Colors.orange, fontSize: 16),
                ),
                const SizedBox(height: 14),
                const Text('Pay from', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                ...sources.map((s) {
                  final sel = s.id == payFrom?.id;
                  return GestureDetector(
                    onTap: () => setDlg(() => payFrom = s),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: sel
                            ? Color(s.color).withValues(alpha: 0.2)
                            : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                        border: sel
                            ? Border.all(color: Color(s.color), width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(s.icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text(s.name, style: const TextStyle(fontSize: 16)),
                          const Spacer(),
                          Text(
                            formatMoney(s.balance),
                            style: TextStyle(
                              color: Theme.of(
                                ctx,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [MoneyInputFormatter()],
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Amount to pay',
                    labelStyle: const TextStyle(fontSize: 16),
                    prefixIcon: amountPrefixIcon(ctx),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                final entered = parseCents(amountCtrl.text) ?? 0;
                if (entered <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Enter an amount greater than zero.'),
                    ),
                  );
                  return;
                }
                if (entered > due.remainingDue) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cannot exceed remaining due (${formatMoney(due.remainingDue)}).',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Pay', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (payFrom == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an income source to pay from.')),
      );
      return;
    }
    final payAmount = parseCents(amountCtrl.text) ?? 0;
    if (payAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a payment amount greater than zero.'),
        ),
      );
      return;
    }
    await DatabaseHelper.instance.payDue(
      due.id!,
      payAmount > due.remainingDue ? due.remainingDue : payAmount,
      payFrom!.id!,
    );
    if (!mounted) return;
    _load();
  }

  Widget _inOutHotbar() {
    Widget tile({
      required IconData icon,
      required String label,
      required int cents,
      required Color color,
    }) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      // Light mode: saturated pastel solid bg with white iconography
      // and amount, matching the bottom-bar pastel + white pattern so
      // the dashboard reads as a single cohesive design system.
      // Dark mode keeps the dim tinted bg with on-color text since
      // saturated pastels would be too loud on the near-black scaffold.
      final bg = isDark
          ? color.withValues(alpha: 0.15)
          : Color.lerp(color, Colors.white, 0.18)!;
      final borderCol = isDark
          ? color.withValues(alpha: 0.45)
          : Color.lerp(color, Colors.white, 0.05)!;
      final fg = isDark ? color : Colors.white;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: fg.withValues(alpha: 0.92),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  formatMoney(cents),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(
          icon: Icons.arrow_downward_rounded,
          label: 'EARNED',
          cents: incomeThisMonth,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: 10),
        tile(
          icon: Icons.arrow_upward_rounded,
          label: 'SPENT',
          cents: spentThisMonth,
          color: Colors.red.shade600,
        ),
      ],
    );
  }

  Widget _expenseSection(Map<int, int> categoryTotals) {
    final monthName = DateFormat('MMMM').format(DateTime.now());
    final cs = Theme.of(context).colorScheme;
    final lastUsed = <int, DateTime>{};
    for (final e in entries) {
      if (e.type != 'expense') continue;
      final prev = lastUsed[e.categoryId];
      if (prev == null || e.date.isAfter(prev)) {
        lastUsed[e.categoryId] = e.date;
      }
    }
    final sortedCategories = [...categories]..sort((a, b) {
      final ad = lastUsed[a.id];
      final bd = lastUsed[b.id];
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expenses — $monthName',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _inOutHotbar(),
        const SizedBox(height: 12),
        ...sortedCategories.map((c) {
          final total = categoryTotals[c.id] ?? 0;
          if (total == 0) return const SizedBox.shrink();
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: Text(c.icon, style: const TextStyle(fontSize: 26)),
              title: Text(c.name, style: const TextStyle(fontSize: 16)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatMoney(total),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(category: c),
                  ),
                );
                if (!mounted) return;
                _load();
              },
            ),
          );
        }),
        if (categoryTotals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No spending this month',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseBg = isDark
        ? AppColorsDark.expenseBg
        : AppColorsLight.expenseBg;
    final expenseFg = isDark
        ? AppColorsDark.expenseFg
        : AppColorsLight.expenseFg;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _addExpense,
          // Upward swipe (anywhere on the bar) opens the menu sheet.
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < -150) _openMenu();
          },
          child: SizedBox(
            height: 72,
            child: Container(
              decoration: BoxDecoration(
                color: expenseBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grip indicator at the very top — visual cue for swipe up.
                  Positioned(
                    top: 6,
                    child: Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: expenseFg.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  PulsingGlowIcon(
                    icon: Icons.shopping_bag_outlined,
                    size: 34,
                    color: expenseFg,
                    // Light mode fg is white on pastel red; a white
                    // glow on a saturated bg reads as a brighter halo
                    // than re-glowing in the same shade as the icon.
                    // Dark mode keeps the dim red expenseFg as glow.
                    glowColor: isDark ? expenseFg : Colors.white,
                    maxBlur: 16,
                    minOpacity: 0.30,
                    maxOpacity: 0.75,
                    duration: const Duration(milliseconds: 1600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftRatioClipper extends CustomClipper<Rect> {
  final double ratio;
  const _LeftRatioClipper(this.ratio);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * ratio.clamp(0.0, 1.0), size.height);
  @override
  bool shouldReclip(covariant _LeftRatioClipper old) => old.ratio != ratio;
}
