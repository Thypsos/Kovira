import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../tutorial/learn_button.dart';
import '../tutorial/tutorial_nav_observer.dart';
import '../models/category.dart';
import '../models/income_source.dart';
import '../models/ledger_entry.dart';
import '../widgets/category_icon.dart';
import '../utils/currency_symbol.dart';
import '../utils/money_input.dart';
import 'add_entry_screen.dart';
import 'settings_screen.dart';
import '../widgets/live_icon.dart';
import '../widgets/big_action_button.dart';
import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';

enum RecordSort { dateDesc, dateAsc, amountDesc, amountAsc }

enum RecordTypeFilter { all, expense, income, transfer }

enum GraphMode { categoryBar, categoryDonut, dailyLine, dailyBar }

String _graphModeLabel(GraphMode m) {
  switch (m) {
    case GraphMode.categoryBar:
      return 'Bars · by tag';
    case GraphMode.categoryDonut:
      return 'Donut · by tag';
    case GraphMode.dailyLine:
      return 'Trend · daily';
    case GraphMode.dailyBar:
      return 'Bars · daily';
  }
}

const _graphPalette = [
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
  Color(0xFFFF5722),
  Color(0xFF795548),
];

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  static final ValueNotifier<bool> showingGraph = ValueNotifier<bool>(false);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with SingleTickerProviderStateMixin
    implements ShellRefreshable, ShellPrimaryAction {
  @override
  void refreshFromShell() => _load();

  @override
  void firePrimaryAction() => _toggleGraph();

  @override
  bool get hasData => entries.isNotEmpty;

  static const _sortPrefsKey = 'records_sort_mode';
  static const _filterPrefsKey = 'records_type_filter';
  static const _graphPrefsKey = 'records_graph_mode';

  final DateTime _now = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime currentMonth;

  double _bodySwipeDx = 0;
  double _headerSwipeDx = 0;

  int _lastMonthDir = 1;
  int _lastGraphDir = 1;
  List<Category> categories = [];
  List<IncomeSource> sources = [];
  List<LedgerEntry> entries = [];
  RecordSort _sort = RecordSort.dateDesc;
  Set<String> _activeTypes = {'expense', 'income', 'transfer'};
  final MenuController _typeMenuCtrl = MenuController();
  GraphMode _graphMode = GraphMode.categoryBar;
  DateTimeRange? _dateRange;
  int? _minCents;
  int? _maxCents;
  Set<int> _selectedAccounts = <int>{};
  Set<int> _selectedTagIds = <int>{};
  bool _showGraph = false;
  late AnimationController _graphAnim;
  late Animation<double> _graphFade;

  @override
  void initState() {
    super.initState();
    currentMonth = _now;
    _graphAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _graphFade = CurvedAnimation(parent: _graphAnim, curve: Curves.easeOut);
    _loadSortPref();
    _loadFilterPref();
    _loadGraphPref();
    _load();
  }

  Future<void> _loadGraphPref() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_graphPrefsKey);
    if (idx != null && idx >= 0 && idx < GraphMode.values.length) {
      if (!mounted) return;
      setState(() => _graphMode = GraphMode.values[idx]);
    }
  }

  Future<void> _saveGraphPref(GraphMode m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_graphPrefsKey, m.index);
  }

  void _cycleGraph(int delta) {
    final values = GraphMode.values;
    final next =
        values[(_graphMode.index + delta + values.length) % values.length];
    setState(() => _graphMode = next);
    _saveGraphPref(next);
  }

  Future<void> _loadSortPref() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_sortPrefsKey);
    if (idx != null && idx >= 0 && idx < RecordSort.values.length) {
      if (!mounted) return;
      setState(() => _sort = RecordSort.values[idx]);
    }
  }

  Future<void> _saveSortPref(RecordSort s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortPrefsKey, s.index);
  }

  Future<void> _loadFilterPref() async {
    final prefs = await SharedPreferences.getInstance();
    final csv = prefs.getString(_filterPrefsKey);
    if (csv != null && csv.isNotEmpty) {
      final parts = csv
          .split(',')
          .where((s) => ['expense', 'income', 'transfer'].contains(s))
          .toSet();
      if (parts.isNotEmpty && mounted) {
        setState(() => _activeTypes = parts);
      }
    }
  }

  Future<void> _saveFilterPref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_filterPrefsKey, _activeTypes.join(','));
  }

  void _setSort(RecordSort s) {
    setState(() => _sort = s);
    _saveSortPref(s);
  }

  void _toggleType(String t) {
    setState(() {
      if (_activeTypes.contains(t)) {
        if (_activeTypes.length > 1) _activeTypes.remove(t);
      } else {
        _activeTypes.add(t);
      }
    });
    _saveFilterPref();
  }

  String _typeName(String t) {
    switch (t) {
      case 'expense':
        return 'Expense';
      case 'income':
        return 'Income';
      case 'transfer':
        return 'Transfer';
    }
    return t;
  }

  Color _typeAccent(String t) {
    switch (t) {
      case 'expense':
        return Colors.red.shade600;
      case 'income':
        return Colors.green.shade700;
      case 'transfer':
        return Colors.blue.shade600;
    }
    return Colors.grey;
  }

  List<LedgerEntry> _applyFilters(List<LedgerEntry> input) {
    return input.where((e) {
      if (!_activeTypes.contains(e.type)) return false;
      if (_dateRange != null) {
        final dayEnd = _dateRange!.end.add(const Duration(days: 1));
        if (e.date.isBefore(_dateRange!.start) || !e.date.isBefore(dayEnd)) {
          return false;
        }
      }
      if (_minCents != null && e.amount < _minCents!) return false;
      if (_maxCents != null && e.amount > _maxCents!) return false;
      if (_selectedAccounts.isNotEmpty &&
          !_selectedAccounts.contains(e.sourceId)) {
        return false;
      }
      if (_selectedTagIds.isNotEmpty &&
          !_selectedTagIds.contains(e.categoryId)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _hasExtraFilters =>
      _dateRange != null ||
      _minCents != null ||
      _maxCents != null ||
      _selectedAccounts.isNotEmpty ||
      _selectedTagIds.isNotEmpty;

  Widget _tagFilterChip(ColorScheme cs) {
    final selected = _selectedTagIds.isNotEmpty;
    final label = selected
        ? 'Tag (${_selectedTagIds.length})'
        : 'Tag';
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: _openTagFilter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.15)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 14,
                color: selected ? cs.primary : cs.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTagFilter() async {
    final cs = Theme.of(context).colorScheme;
    final draft = Set<int>.from(_selectedTagIds);
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filter by tag',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setSheet(draft.clear),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((c) {
                      final sel = draft.contains(c.id);
                      return GestureDetector(
                        onTap: () => setSheet(() {
                          if (sel) {
                            draft.remove(c.id);
                          } else {
                            draft.add(c.id!);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: sel
                                ? cs.primary.withValues(alpha: 0.18)
                                : cs.surfaceContainerHighest,
                            border: Border.all(
                              color: sel ? cs.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.icon,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: sel
                                      ? cs.primary
                                      : cs.onSurface,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() => _selectedTagIds = draft);
    }
  }

  Widget _typeFilterPill(ColorScheme cs) {
    const all = {'expense', 'income', 'transfer'};
    final isAll = _activeTypes.length == 3 && _activeTypes.containsAll(all);
    final label = isAll ? 'All types' : _activeTypes.map(_typeName).join(' + ');
    final accent = _activeTypes.length == 1
        ? _typeAccent(_activeTypes.first)
        : cs.primary;
    final fg = isAll ? cs.onSurface : Colors.white;
    final bg = isAll ? cs.surfaceContainerHighest : accent;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: MenuAnchor(
        controller: _typeMenuCtrl,
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cs.surface),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        menuChildren: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
            child: Text(
              'Show entries of type',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          for (final t in const ['expense', 'income', 'transfer'])
            InkWell(
              onTap: () => _toggleType(t),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _activeTypes.contains(t)
                            ? _typeAccent(t)
                            : Colors.transparent,
                        border: Border.all(color: _typeAccent(t), width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _activeTypes.contains(t)
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _typeAccent(t),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _typeName(t),
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
        ],
        builder: (ctx, controller, _) => GestureDetector(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_outlined, size: 12, color: fg),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down, size: 14, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortToggleChip(
    String label,
    RecordSort desc,
    RecordSort asc,
    ColorScheme cs,
  ) {
    final active = _sort == desc || _sort == asc;
    final isAsc = _sort == asc;

    final activeBg = active
        ? (isAsc ? Colors.teal.shade600 : Colors.deepOrange.shade600)
        : cs.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => _setSort(!active ? desc : (isAsc ? desc : asc)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : cs.onSurface,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                active
                    ? (isAsc ? Icons.arrow_upward : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 11,
                color: active
                    ? Colors.white
                    : cs.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterButton(ColorScheme cs) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.tune, size: 20, color: cs.onSurface),
          if (_hasExtraFilters)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Filters',
      onPressed: _openFilterSheet,
    );
  }

  Future<void> _openFilterSheet() async {
    final cs = Theme.of(context).colorScheme;
    final minCtrl = TextEditingController(
      text: _minCents == null ? '' : formatMoneyCompact(_minCents!),
    );
    final maxCtrl = TextEditingController(
      text: _maxCents == null ? '' : formatMoneyCompact(_maxCents!),
    );
    DateTimeRange? draftRange = _dateRange;
    Set<int> draftAccts = Set<int>.from(_selectedAccounts);
    final activeAccts = sources.where((s) => !s.isArchived).toList();

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setSheet(() {
                        draftRange = null;
                        minCtrl.clear();
                        maxCtrl.clear();
                        draftAccts.clear();
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Date range',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(
                          draftRange == null
                              ? 'Whole month'
                              : '${DateFormat('MMM d').format(draftRange!.start)} → ${DateFormat('MMM d').format(draftRange!.end)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () async {
                          final monthStart = DateTime(
                            currentMonth.year,
                            currentMonth.month,
                            1,
                          );
                          final monthEnd = DateTime(
                            currentMonth.year,
                            currentMonth.month + 1,
                            0,
                          );
                          final picked = await showDateRangePicker(
                            context: ctx,
                            firstDate: monthStart,
                            lastDate: monthEnd,
                            initialDateRange: draftRange,
                          );
                          if (picked != null) {
                            setSheet(() => draftRange = picked);
                          }
                        },
                      ),
                    ),
                    if (draftRange != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setSheet(() => draftRange = null),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Amount range',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Min',
                          isDense: true,
                          prefixIcon: amountPrefixIcon(ctx, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Max',
                          isDense: true,
                          prefixIcon: amountPrefixIcon(ctx, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Income Sources',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                ...activeAccts.map((s) {
                  final selected = draftAccts.contains(s.id);
                  return InkWell(
                    onTap: () => setSheet(() {
                      if (selected) {
                        draftAccts.remove(s.id);
                      } else {
                        draftAccts.add(s.id!);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 20,
                            color: selected
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(s.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (applied == true && mounted) {
      setState(() {
        _dateRange = draftRange;
        _minCents = parseCents(minCtrl.text);
        _maxCents = parseCents(maxCtrl.text);
        _selectedAccounts = draftAccts;
      });
    }
    minCtrl.dispose();
    maxCtrl.dispose();
  }

  @override
  void dispose() {
    _graphAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    categories = await db.getCategories();
    sources = await db.getAllSources();
    entries = await db.getEntriesForMonth(currentMonth);
    setState(() {});
  }

  void _changeMonth(int delta) {
    final next = DateTime(currentMonth.year, currentMonth.month + delta);
    if (next.isAfter(_now)) return;
    setState(() => currentMonth = next);
    _load();
  }

  Widget _swipeArrowOverlay(
    double dx,
    double threshold,
    Color color, {
    bool Function(int dir)? canCommit,
  }) {
    final intensity = (dx.abs() / threshold).clamp(0.0, 1.0);
    if (intensity <= 0) return const SizedBox.shrink();
    final goingLeft = dx > 0;
    final dir = goingLeft ? -1 : 1;
    if (canCommit != null && !canCommit(dir)) return const SizedBox.shrink();
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

  void _toggleGraph() {
    setState(() => _showGraph = !_showGraph);
    RecordsScreen.showingGraph.value = _showGraph;
    if (_showGraph) {
      _graphAnim.forward();
    } else {
      _graphAnim.reverse();
    }
    TutorialNavObserver.instance.notifyDismiss();
  }

  Future<void> _pickMonth() async {
    final earliest = DateTime(2020, 1);
    final months = <DateTime>[];
    var m = DateTime(_now.year, _now.month);
    while (!m.isBefore(earliest)) {
      months.add(m);
      m = DateTime(m.year, m.month - 1);
    }
    DateTime selected = currentMonth;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final Map<int, List<DateTime>> byYear = {};
          for (final mo in months) {
            byYear.putIfAbsent(mo.year, () => []).add(mo);
          }
          final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            expand: false,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select Month',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: years
                        .map(
                          (year) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 8,
                                ),
                                child: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.8,
                                children: (byYear[year] ?? []).map((mo) {
                                  final isSel =
                                      mo.year == selected.year &&
                                      mo.month == selected.month;
                                  return GestureDetector(
                                    onTap: () {
                                      setSheet(() => selected = mo);
                                      Navigator.pop(ctx);
                                      setState(() => currentMonth = mo);
                                      _load();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          DateFormat('MMM').format(mo),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSel
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSel
                                                ? Colors.white
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Category? _catOf(int id) => categories.where((c) => c.id == id).firstOrNull;
  IncomeSource? _srcOf(int id) => sources.where((s) => s.id == id).firstOrNull;

  List<_CatSpend> _categorySpending() {
    final map = <int, int>{};
    for (final e in entries) {
      if (e.type == 'expense') {
        map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
      }
    }
    final list = map.entries.map((e) {
      final cat = _catOf(e.key);
      return _CatSpend(
        icon: cat?.icon ?? '📦',
        name: cat?.name ?? 'Other',
        amount: e.value,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(currentMonth);
    int totalIncome = 0, totalExpenses = 0;
    for (final e in entries) {
      if (e.type == 'income') totalIncome += e.amount;
      if (e.type == 'expense') totalExpenses += e.amount;
    }
    final net = totalIncome - totalExpenses;

    final displayEntries = _applyFilters(entries);

    final Map<String, List<LedgerEntry>> byDay = {};
    for (final e in displayEntries) {
      byDay
          .putIfAbsent(DateFormat('yyyy-MM-dd').format(e.date), () => [])
          .add(e);
    }

    final days = byDay.keys.toList()
      ..sort(
        (a, b) => _sort == RecordSort.dateAsc ? a.compareTo(b) : b.compareTo(a),
      );

    final List<LedgerEntry> flatSorted = () {
      if (_sort == RecordSort.dateDesc || _sort == RecordSort.dateAsc) {
        return const <LedgerEntry>[];
      }
      final list = [...displayEntries];
      list.sort(
        (a, b) => _sort == RecordSort.amountDesc
            ? b.amount.compareTo(a.amount)
            : a.amount.compareTo(b.amount),
      );
      return list;
    }();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        titleSpacing: 8,
        leadingWidth: 80,
        centerTitle: true,
        leading: buildShellBackButton(context),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulsingGlowIcon(
              icon: Icons.history,
              size: 22,
              color: Colors.blue,
              glowColor: Colors.blue,
              maxBlur: 10,
              minOpacity: 0.10,
              maxOpacity: 0.40,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Records & Graph',
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const LearnButton(page: MainScreen.records),
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
      bottomNavigationBar: shellBottomBar(
        BigActionButton(
          icon: _showGraph ? Icons.bar_chart : Icons.access_time,
          tint: Colors.blue,
          tooltip: _showGraph ? 'Show records' : 'Show chart',
          onTap: _toggleGraph,
          onSwipeUp: () =>
              showMainMenuSheet(context, current: MainScreen.records),
          onLongPress: () => MainShell.maybeOf(
            context,
          )?.gotoPage(MainScreen.dashboard, animate: false, fade: true),
        ),
        current: MainScreen.records,
      ),
      body: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              setState(() => _headerSwipeDx = 0);
            },
            onHorizontalDragUpdate: (d) {
              setState(() => _headerSwipeDx += d.delta.dx);
            },
            onHorizontalDragEnd: (d) {
              final dx = _headerSwipeDx;
              final v = d.primaryVelocity ?? 0;
              setState(() => _headerSwipeDx = 0);
              if (dx.abs() < 40 && v.abs() < 250) return;
              final dir = (v != 0 ? v > 0 : dx > 0) ? -1 : 1;
              _lastMonthDir = dir;
              _changeMonth(dir);
            },
            child: Stack(
              children: [
                _swipeArrowOverlay(
                  _headerSwipeDx,
                  80,
                  Colors.white,
                  canCommit: (dir) {
                    if (dir > 0) {
                      final next = DateTime(
                        currentMonth.year,
                        currentMonth.month + 1,
                      );
                      return !next.isAfter(_now);
                    }
                    return true;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Opacity(
                        opacity: _headerSwipeDx > 4 ? 0 : 1,
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            size: 30,
                            color: cs.onSurface,
                          ),
                          onPressed: () {
                            _lastMonthDir = -1;
                            _changeMonth(-1);
                          },
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ClipRect(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) {
                                final incoming =
                                    (child.key == ValueKey(monthLabel));
                                final from = incoming
                                    ? (_lastMonthDir > 0 ? 1.0 : -1.0)
                                    : (_lastMonthDir > 0 ? -1.0 : 1.0);
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
                              child: GestureDetector(
                                key: ValueKey(monthLabel),
                                onTap: _pickMonth,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      monthLabel,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 22,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _headerSwipeDx < -4 ? 0 : 1,
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            size: 30,
                            color: currentMonth.isBefore(_now)
                                ? cs.onSurface
                                : cs.outline,
                          ),
                          onPressed: () {
                            _lastMonthDir = 1;
                            _changeMonth(1);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryCell('Income', totalIncome, Colors.green),
                    ),
                    _divider(),
                    Expanded(
                      child: _summaryCell('Spent', totalExpenses, Colors.red),
                    ),
                    _divider(),
                    Expanded(
                      child: _summaryCell(
                        'Net',
                        net,
                        net >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_showGraph)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 2),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _typeFilterPill(cs),
                          Container(
                            width: 1,
                            height: 18,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            color: cs.outline.withValues(alpha: 0.4),
                          ),
                          _sortToggleChip(
                            'Date',
                            RecordSort.dateDesc,
                            RecordSort.dateAsc,
                            cs,
                          ),
                          _sortToggleChip(
                            'Amount',
                            RecordSort.amountDesc,
                            RecordSort.amountAsc,
                            cs,
                          ),
                          _tagFilterChip(cs),
                        ],
                      ),
                    ),
                  ),
                  _filterButton(cs),
                ],
              ),
            ),
          const Divider(height: 1),

          Expanded(
            child: (_showGraph && entries.isNotEmpty)
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      setState(() => _bodySwipeDx = 0);
                    },
                    onHorizontalDragUpdate: (d) {
                      setState(() => _bodySwipeDx += d.delta.dx);
                    },
                    onHorizontalDragEnd: (d) {
                      final dx = _bodySwipeDx;
                      setState(() => _bodySwipeDx = 0);
                      if (dx.abs() < 60) return;
                      final dir = dx > 0 ? -1 : 1;
                      _lastGraphDir = dir;
                      _cycleGraph(dir);
                    },
                    child: Stack(
                      children: [
                        _bodyContent(cs, flatSorted, byDay, days),
                        _swipeArrowOverlay(_bodySwipeDx, 80, Colors.blue),
                      ],
                    ),
                  )
                : _bodyContent(cs, flatSorted, byDay, days),
          ),
        ],
      ),
    );
  }

  Widget _bodyContent(
    ColorScheme cs,
    List<LedgerEntry> flatSorted,
    Map<String, List<LedgerEntry>> byDay,
    List<String> days,
  ) {
    return entries.isEmpty
        ? Center(
            child: Text(
              'No records this month',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 17,
              ),
            ),
          )
        : _showGraph
        ? FadeTransition(
            opacity: _graphFade,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final incoming = (child.key == ValueKey(_graphMode));
                  final from = incoming
                      ? (_lastGraphDir > 0 ? 1.0 : -1.0)
                      : (_lastGraphDir > 0 ? -1.0 : 1.0);
                  return SlideTransition(
                    position: anim.drive(
                      Tween<Offset>(begin: Offset(from, 0), end: Offset.zero),
                    ),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_graphMode),
                  child: _buildGraph(),
                ),
              ),
            ),
          )
        : flatSorted.isNotEmpty
        ? ListView(children: flatSorted.map((e) => _tile(e)).toList())
        : ListView(
            children: days.map((dayKey) {
              final dayEntries = byDay[dayKey]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                    child: Text(
                      DateFormat('EEE, dd').format(DateTime.parse(dayKey)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  ...dayEntries.map((e) => _tile(e)),
                ],
              );
            }).toList(),
          );
  }

  Widget _buildGraph() {
    final cs = Theme.of(context).colorScheme;
    final catSpends = _categorySpending();
    final daily = _dailyExpenseTotals();
    final hasAny = catSpends.isNotEmpty || daily.any((v) => v > 0);
    if (!hasAny) {
      return Center(
        child: Text(
          'No expenses this month',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    Widget body;
    switch (_graphMode) {
      case GraphMode.categoryBar:
        body = _graphCategoryBar(catSpends, cs);
        break;
      case GraphMode.categoryDonut:
        body = _graphCategoryDonut(catSpends, cs);
        break;
      case GraphMode.dailyLine:
        body = _graphDailyLine(daily, cs);
        break;
      case GraphMode.dailyBar:
        body = _graphDailyBar(daily, cs);
        break;
    }

    return Column(
      children: [
        _graphHeader(cs),
        Expanded(child: body),
      ],
    );
  }

  Widget _graphHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, size: 26, color: cs.onSurface),
            tooltip: 'Previous chart',
            onPressed: () => _cycleGraph(-1),
          ),
          Expanded(
            child: Text(
              _graphModeLabel(_graphMode),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, size: 26, color: cs.onSurface),
            tooltip: 'Next chart',
            onPressed: () => _cycleGraph(1),
          ),
        ],
      ),
    );
  }

  List<int> _dailyExpenseTotals() {
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    final daily = List<int>.filled(daysInMonth, 0);
    for (final e in entries.where((e) => e.type == 'expense')) {
      final i = e.date.day - 1;
      if (i >= 0 && i < daysInMonth) daily[i] += e.amount;
    }
    return daily;
  }

  Widget _graphCategoryBar(List<_CatSpend> catSpends, ColorScheme cs) {
    if (catSpends.isEmpty) {
      return Center(
        child: Text(
          'No tag data',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }
    final maxAmount = catSpends.first.amount;
    final totalSpent = catSpends.fold(0, (s, e) => s + e.amount);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...catSpends.asMap().entries.map((entry) {
            final i = entry.key;
            final spend = entry.value;
            final color = _graphPalette[i % _graphPalette.length];
            final fraction = maxAmount > 0 ? spend.amount / maxAmount : 0.0;
            final pct = totalSpent > 0
                ? (spend.amount / totalSpent * 100).round()
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(spend.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          spend.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoney(spend.amount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 10,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            height: 10,
                            width: constraints.maxWidth * fraction,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withValues(alpha: 0.7), color],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total spent',
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                formatMoney(totalSpent),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _graphCategoryDonut(List<_CatSpend> catSpends, ColorScheme cs) {
    if (catSpends.isEmpty) {
      return Center(
        child: Text(
          'No tag data',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }
    final totalSpent = catSpends.fold(0, (s, e) => s + e.amount);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _DonutPainter(catSpends, _graphPalette, cs.surface),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(totalSpent),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...catSpends.asMap().entries.map((entry) {
            final i = entry.key;
            final spend = entry.value;
            final color = _graphPalette[i % _graphPalette.length];
            final pct = totalSpent > 0
                ? (spend.amount / totalSpent * 100).round()
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(spend.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      spend.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatMoney(spend.amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _graphDailyLine(List<int> daily, ColorScheme cs) {
    final total = daily.fold<int>(0, (s, v) => s + v);
    final maxV = daily.isEmpty ? 0 : daily.reduce(math.max);
    if (total == 0) {
      return Center(
        child: Text(
          'No daily data',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peak day: ${formatMoney(maxV)}',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(
                daily,
                cs.primary,
                cs.outline.withValues(alpha: 0.3),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '${(daily.length / 2).round()}',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '${daily.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total spent',
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                formatMoney(total),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _graphDailyBar(List<int> daily, ColorScheme cs) {
    final total = daily.fold<int>(0, (s, v) => s + v);
    final maxV = daily.isEmpty ? 0 : daily.reduce(math.max);
    if (total == 0) {
      return Center(
        child: Text(
          'No daily data',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peak day: ${formatMoney(maxV)}',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(daily.length, (i) {
                final h = maxV > 0 ? daily[i] / maxV : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: (200 * h).clamp(0.0, 200.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                cs.primary.withValues(alpha: 0.6),
                                cs.primary,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '${(daily.length / 2).round()}',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '${daily.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total spent',
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                formatMoney(total),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, int amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatMoney(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: Theme.of(context).colorScheme.outline,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  Widget _tile(LedgerEntry e) {
    final cat = _catOf(e.categoryId);
    final src = _srcOf(e.sourceId);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String icon;
    Color amountColor;
    Color bgColor;
    Color borderColor;
    String prefix;
    String typeLabel;
    switch (e.type) {
      case 'income':
        icon = '💰';
        amountColor = Colors.green.shade700;
        prefix = '+';
        bgColor = isDark ? const Color(0xFF0A2A0A) : Colors.green.shade100;
        borderColor = isDark ? const Color(0xFF1A4A1A) : Colors.green.shade200;
        typeLabel = src?.name ?? '';
        break;
      case 'transfer':
        icon = '🔄';
        amountColor = Colors.blue.shade700;
        prefix = '';
        bgColor = isDark ? const Color(0xFF0A1A2A) : Colors.blue.shade100;
        borderColor = isDark ? const Color(0xFF1A3A5A) : Colors.blue.shade200;
        typeLabel = e.toSourceId != null
            ? '${src?.name ?? '?'} → ${_srcOf(e.toSourceId!)?.name ?? '?'}'
            : src?.name ?? '';
        break;
      default:
        icon = cat?.icon ?? '📦';
        amountColor = e.status == 'due'
            ? Colors.orange.shade800
            : Colors.red.shade700;
        // Expense and due entries both get a proper pastel card now
        // — previously expense fell back to Colors.transparent which
        // melted into the new mint scaffold and read as a "no card"
        // ghost row.
        if (e.status == 'due') {
          bgColor = isDark ? const Color(0xFF2A1A00) : Colors.orange.shade100;
          borderColor = isDark
              ? const Color(0xFF4A2A00)
              : Colors.orange.shade200;
        } else {
          bgColor = isDark ? const Color(0xFF2A1414) : Colors.red.shade50;
          borderColor = isDark ? const Color(0xFF3A1A1A) : Colors.red.shade100;
        }
        prefix = '-';
        typeLabel = src?.name ?? '';
        if (e.status == 'due') typeLabel += ' · due';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            // White-ish chip in light mode lifts the icon off the
            // pastel tile bg. Dark mode keeps the surface variant.
            color: isDark ? cs.surface : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Center(
            child: e.type == 'expense'
                ? RawCategoryIcon(icon: icon, color: cat?.color, size: 22)
                : Text(icon, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          e.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? cs.onSurface : Colors.black87,
          ),
        ),
        subtitle: typeLabel.isNotEmpty
            ? Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? cs.onSurface.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.55),
                ),
              )
            : null,
        trailing: Text(
          '$prefix${formatMoney(e.amount)}',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        onLongPress: () => _showEntryActions(e),
      ),
    );
  }

  void _showEntryActions(LedgerEntry e) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (e.type == 'expense')
              ListTile(
                leading: const Icon(Icons.edit, size: 24),
                title: const Text('Edit', style: TextStyle(fontSize: 17)),
                onTap: () async {
                  Navigator.pop(context);
                  final c = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEntryScreen(existing: e),
                    ),
                  );
                  if (c == true) _load();
                },
              ),
            if (e.type == 'income')
              ListTile(
                leading: const Icon(Icons.edit, size: 24),
                title: const Text('Edit', style: TextStyle(fontSize: 17)),
                onTap: () async {
                  Navigator.pop(context);
                  await _editIncomeDialog(e);
                },
              ),
            if (e.type == 'transfer')
              ListTile(
                leading: const Icon(Icons.edit, size: 24),
                title: const Text('Edit', style: TextStyle(fontSize: 17)),
                onTap: () async {
                  Navigator.pop(context);
                  await _editTransferDialog(e);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red, size: 24),
              title: const Text(
                'Delete',
                style: TextStyle(fontSize: 17, color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _confirmDelete(e);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(LedgerEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?', style: TextStyle(fontSize: 20)),
        content: Text(
          'Delete "${e.name}" (${formatMoney(e.amount)})?\n\n'
          'This will adjust your income source balance and cannot be undone.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseHelper.instance.deleteEntry(e.id!);
    _load();
  }

  Future<void> _editIncomeDialog(LedgerEntry e) async {
    final src = _srcOf(e.sourceId);
    final nameCtrl = TextEditingController(text: e.name);
    final amountCtrl = TextEditingController(
      text: formatMoneyCompact(e.amount),
    );
    DateTime date = e.date;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Edit Income', style: TextStyle(fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (p != null) setDlg(() => date = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEE, dd MMM yyyy').format(date),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (src != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(src.color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(src.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(src.name, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(labelText: 'What is this?'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
                  inputFormatters: [MoneyInputFormatter()],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final newAmount = parseCents(amountCtrl.text) ?? 0;
    if (newAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than zero.')),
      );
      return;
    }
    final updated = LedgerEntry(
      id: e.id,
      type: 'income',
      categoryId: e.categoryId,
      sourceId: e.sourceId,
      amount: newAmount,
      name: nameCtrl.text.trim().isEmpty ? e.name : nameCtrl.text.trim(),
      date: date,
    );
    await DatabaseHelper.instance.updateIncomeEntry(e, updated);
    _load();
  }

  Future<void> _editTransferDialog(LedgerEntry e) async {
    final activeSources = sources.where((s) => !s.isArchived).toList();
    IncomeSource? fromSrc =
        sources.where((s) => s.id == e.sourceId).firstOrNull ??
        activeSources.firstOrNull;
    IncomeSource? toSrc = e.toSourceId != null
        ? sources.where((s) => s.id == e.toSourceId).firstOrNull
        : (activeSources.length > 1 ? activeSources[1] : null);
    if (fromSrc != null && fromSrc.isArchived) {
      fromSrc = activeSources.firstOrNull ?? fromSrc;
    }
    if (toSrc != null && toSrc.isArchived) {
      toSrc = activeSources.length > 1
          ? activeSources[1]
          : activeSources.firstOrNull ?? toSrc;
    }
    final amountCtrl = TextEditingController(
      text: formatMoneyCompact(e.amount),
    );
    final noteCtrl = TextEditingController(text: e.name);
    DateTime date = e.date;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Edit Transfer', style: TextStyle(fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (p != null) setDlg(() => date = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEE, dd MMM yyyy').format(date),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'From',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                _srcDropdown(
                  activeSources,
                  fromSrc,
                  (s) => setDlg(() => fromSrc = s),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Icon(
                    Icons.arrow_downward,
                    size: 22,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'To',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                _srcDropdown(
                  activeSources,
                  toSrc,
                  (s) => setDlg(() => toSrc = s),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
                  inputFormatters: [MoneyInputFormatter()],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: amountPrefixIcon(ctx),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (fromSrc == null || toSrc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick both a From and a To income source.'),
        ),
      );
      return;
    }
    if (fromSrc!.id == toSrc!.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From and To must be different income sources.'),
        ),
      );
      return;
    }
    final from = fromSrc!;
    final to = toSrc!;
    final newAmount = parseCents(amountCtrl.text) ?? 0;
    if (newAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than zero.')),
      );
      return;
    }
    if (from.id == to.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To must be different.')),
      );
      return;
    }
    final noteFinal = noteCtrl.text.trim().isEmpty
        ? '${from.name} → ${to.name}'
        : noteCtrl.text.trim();
    final updated = LedgerEntry(
      id: e.id,
      type: 'transfer',
      categoryId: 0,
      sourceId: from.id!,
      toSourceId: to.id!,
      amount: newAmount,
      name: noteFinal,
      date: date,
    );
    await DatabaseHelper.instance.updateTransferEntry(e, updated);
    _load();
  }

  Widget _srcDropdown(
    List<IncomeSource> list,
    IncomeSource? value,
    ValueChanged<IncomeSource?> onChange,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: value?.id,
        isExpanded: true,
        underline: const SizedBox(),
        items: list
            .map(
              (s) => DropdownMenuItem<int>(
                value: s.id,
                child: Row(
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(s.name, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (id) => onChange(list.firstWhere((s) => s.id == id)),
      ),
    );
  }
}

class _CatSpend {
  final String icon, name;
  final int amount;
  const _CatSpend({
    required this.icon,
    required this.name,
    required this.amount,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_CatSpend> data;
  final List<Color> colors;
  final Color holeColor;
  _DonutPainter(this.data, this.colors, this.holeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<int>(0, (s, c) => s + c.amount);
    if (total == 0) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    double startAngle = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = 2 * math.pi * data[i].amount / total;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      startAngle += sweep;
    }
    canvas.drawCircle(center, radius * 0.58, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.data != data || old.holeColor != holeColor;
}

class _LineChartPainter extends CustomPainter {
  final List<int> daily;
  final Color line;
  final Color grid;
  _LineChartPainter(this.daily, this.line, this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    if (daily.isEmpty) return;
    final maxV = daily.reduce(math.max);
    if (maxV == 0) return;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final n = daily.length;
    final stepX = n > 1 ? size.width / (n - 1) : size.width;

    final fillPath = Path()..moveTo(0, size.height);
    for (var i = 0; i < n; i++) {
      final x = i * stepX;
      final y = size.height - (daily[i] / maxV) * size.height;
      fillPath.lineTo(x, y);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = line.withValues(alpha: 0.18));

    final linePath = Path();
    for (var i = 0; i < n; i++) {
      final x = i * stepX;
      final y = size.height - (daily[i] / maxV) * size.height;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = line;
    for (var i = 0; i < n; i++) {
      if (daily[i] > 0) {
        final x = i * stepX;
        final y = size.height - (daily[i] / maxV) * size.height;
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.daily != daily || old.line != line;
}
