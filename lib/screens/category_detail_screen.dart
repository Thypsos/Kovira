import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/income_source.dart';
import '../models/ledger_entry.dart';
import '../utils/money_input.dart';
import 'add_entry_screen.dart';
import 'records_screen.dart' show RecordSort;

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  const CategoryDetailScreen({super.key, required this.category});
  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  static const _sortPrefsKey = 'category_detail_sort_mode';

  List<LedgerEntry> entries = [];
  List<IncomeSource> sources = [];
  int _budget = 0;
  RecordSort _sort = RecordSort.dateDesc;
  DateTimeRange? _dateRange;
  int? _minCents;
  int? _maxCents;
  Set<int> _selectedAccounts = <int>{};

  @override
  void initState() {
    super.initState();
    _loadSortPref();
    _load();
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

  void _setSort(RecordSort s) {
    setState(() => _sort = s);
    _saveSortPref(s);
  }

  Future<void> _load() async {
    entries = await DatabaseHelper.instance.getEntriesForCategory(
      widget.category.id!,
      DateTime.now(),
    );
    sources = await DatabaseHelper.instance.getAllSources();
    _budget = await DatabaseHelper.instance.getBudgetForCategory(
      widget.category.id!,
    );
    setState(() {});
  }

  IncomeSource? _sourceOf(int id) =>
      sources.where((s) => s.id == id).firstOrNull;

  Widget _budgetProgressBar(int spent, int budget) {
    final ratio = (spent / budget).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    final over = spent > budget;
    final near = !over && ratio >= 0.85;
    final fillColor = over
        ? Colors.red.shade700
        : (near ? Colors.orange.shade700 : Colors.green.shade600);
    final remaining = budget - spent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.savings_outlined, size: 14, color: Colors.red.shade400),
            const SizedBox(width: 4),
            Text(
              'Monthly budget · ${formatMoney(budget)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fillColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (_, c) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: c.maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: c.maxWidth * ratio,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          over
              ? 'Over by ${formatMoney(-remaining)}'
              : (near
                    ? 'Almost there — ${formatMoney(remaining)} left'
                    : '${formatMoney(remaining)} left this month'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: fillColor,
          ),
        ),
      ],
    );
  }

  List<LedgerEntry> _applyFilters(List<LedgerEntry> input) {
    return input.where((e) {
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
      return true;
    }).toList();
  }

  bool get _hasExtraFilters =>
      _dateRange != null ||
      _minCents != null ||
      _maxCents != null ||
      _selectedAccounts.isNotEmpty;

  List<LedgerEntry> get _sortedEntries {
    final list = _applyFilters(entries);
    switch (_sort) {
      case RecordSort.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case RecordSort.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case RecordSort.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case RecordSort.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
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
                          final now = DateTime.now();
                          final monthStart = DateTime(now.year, now.month, 1);
                          final monthEnd = DateTime(now.year, now.month + 1, 0);
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
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (s, e) => s + e.amount);
    final sorted = _sortedEntries;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.category.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Text(widget.category.name, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.red.shade50,
            child: Column(
              children: [
                Text(
                  'Total this month',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  formatMoney(total),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (_budget > 0) ...[
                  const SizedBox(height: 14),
                  _budgetProgressBar(total, _budget),
                ],
              ],
            ),
          ),
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 2),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _sortToggleChip(
                            'Date',
                            RecordSort.dateDesc,
                            RecordSort.dateAsc,
                            Theme.of(context).colorScheme,
                          ),
                          _sortToggleChip(
                            'Amount',
                            RecordSort.amountDesc,
                            RecordSort.amountAsc,
                            Theme.of(context).colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _filterButton(Theme.of(context).colorScheme),
                ],
              ),
            ),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'No entries',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      final e = sorted[i];
                      final source = _sourceOf(e.sourceId);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        title: Text(
                          e.name,
                          style: const TextStyle(fontSize: 17),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd MMM').format(e.date)}${source != null ? ' · ${source.icon} ${source.name}' : ''}${e.status == 'due' ? ' · due' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Text(
                          formatMoney(e.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                            color: e.status == 'due'
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                        onLongPress: () async {
                          final action = await showModalBottomSheet<String>(
                            context: context,
                            builder: (_) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit, size: 24),
                                    title: const Text(
                                      'Edit',
                                      style: TextStyle(fontSize: 17),
                                    ),
                                    onTap: () => Navigator.pop(context, 'edit'),
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    title: const Text(
                                      'Delete',
                                      style: TextStyle(fontSize: 17),
                                    ),
                                    onTap: () =>
                                        Navigator.pop(context, 'delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (!context.mounted) return;
                          if (action == 'edit') {
                            final c = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEntryScreen(existing: e),
                              ),
                            );
                            if (c == true) _load();
                          } else if (action == 'delete') {
                            await DatabaseHelper.instance.deleteEntry(e.id!);
                            _load();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
