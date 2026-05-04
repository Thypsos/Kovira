import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../utils/currency_symbol.dart';
import '../utils/money_input.dart';
import '../widgets/big_action_button.dart';
import '../widgets/category_icon.dart';
import '../widgets/live_icon.dart';
import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';
import 'settings_screen.dart';
import '../tutorial/tutorial_targets.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    implements ShellRefreshable {
  @override
  void refreshFromShell() => _load();

  List<Category> _categories = [];
  Map<int, int> _budgets = {};
  Map<int, int> _spent = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final cats = await db.getCategories();
    final budgets = await db.getAllBudgets();
    final entries = await db.getEntriesForMonth(DateTime.now());
    final spent = <int, int>{};
    for (final e in entries) {
      if (e.type != 'expense') continue;
      spent[e.categoryId] = (spent[e.categoryId] ?? 0) + e.amount;
    }
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _budgets = budgets;
      _spent = spent;
    });
  }

  Future<void> _editBudget(Category c) async {
    final ctrl = TextEditingController(
      text: (_budgets[c.id] ?? 0) > 0
          ? formatMoneyCompact(_budgets[c.id]!)
          : '',
    );
    final amountFocus = FocusNode();
    String? amountError;
    final cents = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          insetPadding: TutorialService.instance.dialogInsetsFor(
            TutorialIds.budgetDialogFields,
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Row(
            children: [
              RawCategoryIcon(icon: c.icon, color: c.color, size: 22),
              const SizedBox(width: 8),
              Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
            ],
          ),

          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: SizedBox(
              width: 260,
              child: TutorialFireOnMount(
                messageId: TutorialIds.budgetDialogFields,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TutorialTarget(
                      id: TutorialTargetIds.budgetDialogField,
                      child: TextField(
                        controller: ctrl,
                        focusNode: amountFocus,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        style: const TextStyle(fontSize: 16),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Monthly limit',
                          prefixIcon: amountPrefixIcon(ctx),
                          hintText: 'Tap Clear to remove',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          errorText: amountError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0),
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = parseCents(ctrl.text) ?? 0;
                if (v <= 0) {
                  setS(() => amountError = 'Enter a monthly limit');
                  amountFocus.requestFocus();
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (cents == null) return;
    final wasFirstBudget = (_budgets.values.where((v) => v > 0).isEmpty);
    await DatabaseHelper.instance.setBudgetForCategory(c.id!, cents);
    await _load();
    if (!mounted) return;
    if (wasFirstBudget && cents > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        TutorialService.instance.show(context, TutorialIds.budgetCardTapHint);
      });
    }
  }

  Future<void> _pickCategoryToBudget() async {
    final unbudgeted = _categories
        .where((c) => (_budgets[c.id] ?? 0) == 0)
        .toList();
    final list = unbudgeted.isEmpty ? _categories : unbudgeted;

    final picked = await showDialog<Category>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        title: const Text(
          'Set budget for…',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 320,

          height: MediaQuery.of(ctx).size.height * 0.55,
          child: list.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No categories yet — add one from the Categories '
                      'page first.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      leading: RawCategoryIcon(
                        icon: c.icon,
                        color: c.color,
                        size: 24,
                      ),
                      title: Text(c.name),
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (picked != null) await _editBudget(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final budgeted =
        _categories.where((c) => (_budgets[c.id] ?? 0) > 0).toList()
          ..sort((a, b) {
            final pb = (_spent[b.id] ?? 0) / (_budgets[b.id] ?? 1);
            final pa = (_spent[a.id] ?? 0) / (_budgets[a.id] ?? 1);
            return pb.compareTo(pa);
          });
    final totalBudget = _budgets.values.fold<int>(0, (s, v) => s + v);
    final totalSpent = budgeted.fold<int>(0, (s, c) => s + (_spent[c.id] ?? 0));
    final overall = totalBudget == 0
        ? 0.0
        : (totalSpent / totalBudget).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        leading: buildShellBackButton(context),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulsingGlowIcon(
              icon: Icons.pie_chart_outline,
              size: 22,
              color: Colors.deepOrange,
              glowColor: Colors.deepOrange,
              maxBlur: 10,
              minOpacity: 0.10,
              maxOpacity: 0.40,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Budget',
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const SpinningIcon(
              icon: Icons.settings_outlined,
              size: 24,
              period: Duration(seconds: 18),
            ),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: budgeted.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🥧', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text(
                      'No budgets set yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cap your spending per category to keep an eye on the month.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _overallCard(cs, totalBudget, totalSpent, overall),
                const SizedBox(height: 14),
                ...budgeted.asMap().entries.map((entry) {
                  final tile = _budgetTile(entry.value, cs);
                  return entry.key == 0
                      ? TutorialTarget(
                          id: TutorialTargetIds.budgetFirstCard,
                          child: tile,
                        )
                      : tile;
                }),
              ],
            ),
      bottomNavigationBar: TutorialTarget(
        id: TutorialTargetIds.budgetAddBtn,
        child: BigActionButton(
          icon: Icons.pie_chart_outline,
          tint: Colors.deepOrange,
          tooltip: 'Set a category budget · swipe up for menu',
          onTap: _pickCategoryToBudget,
          onSwipeUp: () =>
              showMainMenuSheet(context, current: MainScreen.budget),
          onLongPress: () => MainShell.maybeOf(
            context,
          )?.gotoPage(MainScreen.dashboard, animate: false, fade: true),
        ),
      ),
    );
  }

  Color _budgetHealthColor(double ratio, {required bool overBudget}) =>
      ProgressColors.budgetProgress(ratio, overBudget: overBudget);

  Widget _overallCard(ColorScheme cs, int total, int spent, double ratio) {
    final over = spent > total && total > 0;
    final remaining = total - spent;
    final fill = _budgetHealthColor(ratio, overBudget: over);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Color.alphaBlend(
                Colors.black.withValues(alpha: 0.08),
                fill.withValues(alpha: 0.20),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  color: Color.alphaBlend(
                    Colors.black.withValues(alpha: 0.08),
                    fill.withValues(alpha: over ? 0.68 : 0.62),
                  ),
                ),
              ),
            ),
          ),
          _BudgetOverallContent(
            total: total,
            spent: spent,
            remaining: remaining,
            over: over,
            fill: fill,
            textColor: isDark ? cs.onSurface : Colors.black,
          ),
          Positioned.fill(
            child: ClipRect(
              clipper: _LeftRatioClipper(ratio),
              child: _BudgetOverallContent(
                total: total,
                spent: spent,
                remaining: remaining,
                over: over,
                fill: fill,
                textColor: Colors.white,
                overFill: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetTile(Category c, ColorScheme cs) {
    final budget = _budgets[c.id] ?? 0;
    final spent = _spent[c.id] ?? 0;
    final ratio = budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = spent > budget;
    final fill = _budgetHealthColor(ratio, overBudget: over);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _editBudget(c),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.08),
                  fill.withValues(alpha: 0.20),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    color: Color.alphaBlend(
                      Colors.black.withValues(alpha: 0.08),
                      fill.withValues(alpha: over ? 0.58 : 0.50),
                    ),
                  ),
                ),
              ),
            ),
            _BudgetTileContent(
              c: c,
              spent: spent,
              budget: budget,
              ratio: ratio,
              over: over,
              fill: fill,
              textColor: isDark ? cs.onSurface : Colors.black,
            ),
            Positioned.fill(
              child: ClipRect(
                clipper: _LeftRatioClipper(ratio),
                child: _BudgetTileContent(
                  c: c,
                  spent: spent,
                  budget: budget,
                  ratio: ratio,
                  over: over,
                  fill: fill,
                  textColor: Colors.white,
                  overFill: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetOverallContent extends StatelessWidget {
  final int total;
  final int spent;
  final int remaining;
  final bool over;
  final Color fill;
  final Color textColor;
  final bool overFill;

  const _BudgetOverallContent({
    required this.total,
    required this.spent,
    required this.remaining,
    required this.over,
    required this.fill,
    required this.textColor,
    this.overFill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Total this month',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                formatMoney(total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Spent ${formatMoney(spent)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                over
                    ? 'Over by ${formatMoney(-remaining)}'
                    : '${formatMoney(remaining)} left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  // Both layers carry the full-strength textColor —
                  // base = pure black on the unfilled portion, overlay
                  // = pure white clipped to the filled portion. The
                  // tint-coloured callout is dropped because it was
                  // the exact source of the yellow-on-yellow problem
                  // — it could not survive every fill colour.
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetTileContent extends StatelessWidget {
  final Category c;
  final int spent;
  final int budget;
  final double ratio;
  final bool over;
  final Color fill;
  final Color textColor;
  final bool overFill;

  const _BudgetTileContent({
    required this.c,
    required this.spent,
    required this.budget,
    required this.ratio,
    required this.over,
    required this.fill,
    required this.textColor,
    this.overFill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RawCategoryIcon(icon: c.icon, color: c.color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                '${formatMoney(spent)} / ${formatMoney(budget)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            over ? 'Budget crossed' : '${((ratio * 100).round())}% used',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
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
