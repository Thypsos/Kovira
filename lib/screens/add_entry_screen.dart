import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/income_source.dart';
import '../models/ledger_entry.dart';
import '../widgets/category_icon.dart';
import '../utils/emoji_suggestions.dart';
import '../utils/currency_symbol.dart';
import '../utils/money_input.dart';
import '../tutorial/learn_service.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_service.dart';
import '../tutorial/tutorial_targets.dart';
import '../widgets/live_icon.dart';

class AddEntryScreen extends StatefulWidget {
  final LedgerEntry? existing;
  const AddEntryScreen({super.key, this.existing});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

enum _Phase { paidOrDue, source, category, name, amount }

class _AddEntryScreenState extends State<AddEntryScreen>
    with TickerProviderStateMixin {
  String _status = 'paid';
  bool _statusChosen = false;
  IncomeSource? _src;
  Category? _cat;
  String _name = '';
  int _amount = 0;
  late DateTime _date;

  _Phase _phase = _Phase.paidOrDue;
  List<IncomeSource> _sources = [];
  List<Category> _categories = [];
  List<String> _suggestions = [];

  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  String? _amountError;
  final _nameFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? DateTime.now();
    _loadData();
    if (widget.existing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (LearnService.instance.consumePendingDialog('expense')) {
          _runDialogTutorial();
        }
      });
    }
  }

  bool _dialogTutorialInFlight = false;

  Future<void> _runDialogTutorial() async {
    if (_dialogTutorialInFlight) return;
    _dialogTutorialInFlight = true;
    try {
      await _runDialogTutorialChain();
    } finally {
      _dialogTutorialInFlight = false;
    }
  }

  Future<void> _runDialogTutorialChain() async {
    final svc = TutorialService.instance;
    await svc.show(
      context,
      TutorialIds.learnExpenseDialogIntro,
      force: true,
      forced: false,
    );
    if (!mounted) return;
    await svc.show(
      context,
      TutorialIds.learnExpenseDialogPaidDue,
      force: true,
      forced: false,
    );
    if (!mounted) return;
    await svc.show(
      context,
      TutorialIds.learnExpenseDialogSource,
      force: true,
      forced: false,
    );
    if (!mounted) return;
    await svc.show(
      context,
      TutorialIds.learnExpenseDialogTag,
      force: true,
      forced: false,
    );
    if (!mounted) return;
    await svc.show(
      context,
      TutorialIds.learnExpenseDialogAmount,
      force: true,
      forced: false,
    );
    if (!mounted) return;
    await svc.show(
      context,
      TutorialIds.learnExpenseDialogName,
      force: true,
      forced: false,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _nameFocus.dispose();
    _amountFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    _sources = await db.getActiveSources();
    _categories = await db.getCategoriesByUsage();

    if (widget.existing != null) {
      final e = widget.existing!;
      _status = e.status;
      _amount = e.amount;
      _name = e.name;
      _nameCtrl.text = _name;
      _amountCtrl.text = formatMoneyCompact(_amount);
      if (_sources.isNotEmpty) {
        _src =
            _sources.where((s) => s.id == e.sourceId).firstOrNull ??
            _sources.first;
      }
      if (_categories.isNotEmpty) {
        _cat =
            _categories.where((c) => c.id == e.categoryId).firstOrNull ??
            _categories.first;
        _suggestions = await db.getSuggestions(_cat!.id!);
      }
      _statusChosen = true;
      _phase = _Phase.amount;
    }
    if (mounted) setState(() {});
  }

  _Phase _nextOf(_Phase cur) {
    if (cur == _Phase.paidOrDue) {
      return _status == 'due' ? _Phase.category : _Phase.source;
    }
    if (cur == _Phase.source) return _Phase.category;

    if (cur == _Phase.category) return _Phase.amount;
    if (cur == _Phase.name) return _Phase.amount;
    return _Phase.amount;
  }

  void _maybeTriggerTutorial(_Phase phase) {
    if (!mounted) return;
    String? tutorialId;

    switch (phase) {
      case _Phase.source:
        tutorialId = TutorialIds.entrySourcePicker;
        break;
      case _Phase.category:
        tutorialId = TutorialIds.entryCategoryIntro;
        break;
      case _Phase.amount:
        tutorialId = TutorialIds.entryAmountInput;
        break;
      case _Phase.name:
        tutorialId = TutorialIds.entryNameOptional;
        break;
      case _Phase.paidOrDue:
        break;
    }

    if (tutorialId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          TutorialService.instance.show(context, tutorialId!);
        }
      });
    }
  }

  _Phase _prevOf(_Phase cur) {
    if (cur == _Phase.amount) return _Phase.category;
    if (cur == _Phase.name) return _Phase.category;
    if (cur == _Phase.category) {
      return _status == 'due' ? _Phase.paidOrDue : _Phase.source;
    }
    if (cur == _Phase.source) return _Phase.paidOrDue;
    return _Phase.paidOrDue;
  }

  void _advance() {
    final next = _nextOf(_phase);
    setState(() => _phase = next);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (next == _Phase.name) _nameFocus.requestFocus();
      if (next == _Phase.amount) _amountFocus.requestFocus();
      _scrollToBottom();
    });
    _maybeTriggerTutorial(next);
  }

  void _editChip(_Phase target) {
    FocusScope.of(context).unfocus();
    setState(() => _phase = target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (target == _Phase.name) _nameFocus.requestFocus();
      if (target == _Phase.amount) _amountFocus.requestFocus();
      _scrollToBottom();
    });
  }

  bool _back() {
    if (_phase == _Phase.paidOrDue) return false;
    FocusScope.of(context).unfocus();
    setState(() => _phase = _prevOf(_phase));
    return true;
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _save() async {
    _amount = parseCents(_amountCtrl.text) ?? _amount;
    if (_cat == null) {
      _snack('Pick a tag for this expense.');
      return;
    }
    if (_status != 'due' && _src == null) {
      _snack('Pick which income source you paid from.');
      return;
    }
    if (_amount <= 0) {
      setState(() => _amountError = 'Enter an amount');
      return;
    }
    if (_amountError != null) setState(() => _amountError = null);
    final name = _name.isEmpty ? (_cat?.name ?? 'Expense') : _name;
    final srcId = _status == 'due'
        ? (_sources.isNotEmpty ? _sources.first.id! : 1)
        : _src!.id!;
    final entry = LedgerEntry(
      id: widget.existing?.id,
      type: 'expense',
      categoryId: _cat?.id ?? 1,
      sourceId: srcId,
      amount: _amount,
      name: name,
      date: _date,
      status: _status,
    );
    if (widget.existing != null) {
      await DatabaseHelper.instance.deleteEntry(widget.existing!.id!);
    }
    await DatabaseHelper.instance.addExpense(entry);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase == _Phase.paidOrDue,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leadingWidth: 96,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 28),
                onPressed: () {
                  if (!_back()) Navigator.pop(context);
                },
              ),

              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 26,
                  color: Color(0xFFB71C1C),
                ),
              ),
            ],
          ),
          title: Text(
            widget.existing == null ? 'Add Expense' : 'Edit Expense',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: 'Tap to learn this dialog',
              onPressed: _runDialogTutorial,
              icon: const PulsingGlowIcon(
                icon: Icons.school_outlined,
                size: 24,
                color: Color(0xFFFFA000),
                glowColor: Color(0xFFFFA000),
                maxBlur: 14,
                minOpacity: 0.30,
                maxOpacity: 0.75,
                duration: Duration(milliseconds: 1300),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _progressBubbles(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBubbles() {
    final cs = Theme.of(context).colorScheme;

    final phases = _status == 'due'
        ? [_Phase.paidOrDue, _Phase.category, _Phase.amount, _Phase.name]
        : [
            _Phase.paidOrDue,
            _Phase.source,
            _Phase.category,
            _Phase.amount,
            _Phase.name,
          ];

    Widget bubble(_Phase p) {
      final idx = phases.indexOf(p);
      final curIdx = phases.indexOf(_phase);
      final completed = idx < curIdx || (idx == curIdx && _isPhaseFilled(p));
      final isCurrent = idx == curIdx;

      Widget inner;
      if (completed) {
        inner = _bubbleIcon(p);
      } else if (isCurrent) {
        inner = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.primary, width: 2.5),
          ),
        );
      } else {
        inner = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surfaceContainerHighest,
            border: Border.all(color: cs.outline),
          ),
        );
      }

      Color completedBg() {
        switch (p) {
          case _Phase.category:
            return Colors.purple.withValues(alpha: 0.18);
          case _Phase.source:
            return Colors.green.withValues(alpha: 0.18);
          case _Phase.amount:
            return Colors.red.withValues(alpha: 0.15);
          case _Phase.name:
            return Colors.indigo.withValues(alpha: 0.15);
          case _Phase.paidOrDue:
            return cs.primaryContainer;
        }
      }

      return GestureDetector(
        onTap: completed ? () => _editChip(p) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? completedBg() : Colors.transparent,
          ),
          child: Center(child: inner),
        ),
      );
    }

    final widgets = <Widget>[];
    for (int i = 0; i < phases.length; i++) {
      widgets.add(bubble(phases[i]));
      if (i < phases.length - 1) {
        widgets.add(
          Container(
            width: 14,
            height: 2,
            color: cs.outline.withValues(alpha: 0.4),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widgets,
      ),
    );
  }

  bool _isPhaseFilled(_Phase p) {
    switch (p) {
      case _Phase.paidOrDue:
        return _statusChosen;
      case _Phase.source:
        return _src != null;
      case _Phase.category:
        return _cat != null;
      case _Phase.name:
        return _name.isNotEmpty;
      case _Phase.amount:
        return _amount > 0;
    }
  }

  Widget _bubbleIcon(_Phase p) {
    switch (p) {
      case _Phase.paidOrDue:
        return Text(
          _status == 'due' ? '📝' : '✅',
          style: const TextStyle(fontSize: 22),
        );
      case _Phase.source:
        return Text(_src?.icon ?? '?', style: const TextStyle(fontSize: 22));
      case _Phase.category:
        if (_cat == null) return const Icon(Icons.help_outline, size: 22);
        return RawCategoryIcon(icon: _cat!.icon, color: _cat!.color, size: 18);
      case _Phase.name:
        return const Icon(Icons.label_outline, size: 20, color: Colors.indigo);
      case _Phase.amount:
        return const Icon(
          Icons.shopping_bag_outlined,
          size: 20,
          color: Color(0xFFB71C1C),
        );
    }
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_phase == _Phase.paidOrDue) _datePickerCard(),

        ..._completedChips(),

        const SizedBox(height: 8),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Container(key: ValueKey(_phase), child: _activeInput()),
        ),
      ],
    );
  }

  Widget _datePickerCard() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: cs.surfaceContainerHighest,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat('EEE, dd MMM yyyy').format(_date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _completedChips() {
    final out = <Widget>[];

    if (_phase != _Phase.paidOrDue) {
      out.add(
        _chip(
          emoji: _status == 'due' ? '📝' : '✅',
          label: _status == 'due' ? 'Due / Owe' : 'Paid',
          onTap: () => _editChip(_Phase.paidOrDue),
        ),
      );
    }

    if (_status != 'due' &&
        _phase.index > _Phase.source.index &&
        _src != null) {
      out.add(
        _chip(
          emoji: _src!.icon,
          label: _src!.name,
          onTap: () => _editChip(_Phase.source),
        ),
      );
    }

    if (_phase.index > _Phase.category.index && _cat != null) {
      out.add(
        _chip(
          widget: RawCategoryIcon(
            icon: _cat!.icon,
            color: _cat!.color,
            size: 16,
          ),
          label: _cat!.name,
          onTap: () => _editChip(_Phase.category),
        ),
      );
    }

    if (_name.isNotEmpty) {
      out.add(
        _chip(emoji: '🏷️', label: _name, onTap: () => _editChip(_Phase.name)),
      );
    }

    return out;
  }

  Widget _chip({
    String? emoji,
    Widget? widget,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                if (widget != null) widget,
                if (emoji != null)
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onPrimaryContainer,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeInput() {
    switch (_phase) {
      case _Phase.paidOrDue:
        return _inPaidOrDue();
      case _Phase.source:
        return _inSource();
      case _Phase.category:
        return _inCategory();
      case _Phase.name:
        return _inName();
      case _Phase.amount:
        return _inAmount();
    }
  }

  Widget _inPaidOrDue() {
    return TutorialTarget(
      id: TutorialTargetIds.entryPaidDue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              'Is this paid or do you owe it?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          _bigOption(
            icon: '✅',
            label: 'Paid',
            subtitle: 'Already spent the money',
            onTap: () {
              setState(() {
                _status = 'paid';
                _statusChosen = true;
              });
              _advance();
            },
          ),
          const SizedBox(height: 12),
          _bigOption(
            icon: '📝',
            label: 'Due / Owe',
            subtitle: 'Will pay later',
            onTap: () {
              setState(() {
                _status = 'due';
                _statusChosen = true;
              });
              _advance();
            },
          ),
        ],
      ),
    );
  }

  Widget _inSource() {
    final cs = Theme.of(context).colorScheme;
    return TutorialTarget(
      id: TutorialTargetIds.entrySourcePicker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 10),
            child: Text(
              'Which income source?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          if (_sources.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No income sources yet. Add one from Menu → Income Sources.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ..._sources.map((s) {
            final isSel = _src?.id == s.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _src = s);
                    _advance();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSel
                          ? Color(s.color).withValues(alpha: 0.18)
                          : cs.surfaceContainerHighest,
                      border: isSel
                          ? Border.all(color: Color(s.color), width: 2)
                          : Border.all(
                              color: cs.outline.withValues(alpha: 0.4),
                            ),
                    ),
                    child: Row(
                      children: [
                        Text(s.icon, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatMoney(s.balance),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _inCategory() {
    return TutorialTarget(
      id: TutorialTargetIds.entryCategoryPicker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 10),
            child: Text(
              'Which tag?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
            children: _categoryTiles(),
          ),
        ],
      ),
    );
  }

  List<Widget> _categoryTiles() {
    final cs = Theme.of(context).colorScheme;
    final sorted = List<Category>.from(_categories.reversed);
    final widgets = <Widget>[];

    widgets.add(
      GestureDetector(
        onTap: _addNewCategory,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cs.surfaceContainerHighest,
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 30,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'New',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    for (final c in sorted) {
      widgets.add(
        GestureDetector(
          onTap: () async {
            setState(() => _cat = c);
            _suggestions = await DatabaseHelper.instance.getSuggestions(c.id!);
            _advance();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: cs.surfaceContainerHighest,
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RawCategoryIcon(icon: c.icon, color: c.color, size: 26),
                const SizedBox(height: 6),
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _inName() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 10),
          child: Text(
            'What was it for?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),

        _amountField(autofocus: false, hero: false),
        const SizedBox(height: 14),
        TextField(
          controller: _nameCtrl,
          focusNode: _nameFocus,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,

          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 17),
          onSubmitted: (v) {
            setState(() => _name = v.trim());
            _commitFromName();
          },
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Lunch, Bus fare, Groceries',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        if (_suggestions.isNotEmpty) ...[
          Text(
            'Suggestions from past entries:',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.reversed
                .map(
                  (s) => GestureDetector(
                    onTap: () {
                      _nameCtrl.text = s;
                      setState(() => _name = s);
                      _commitFromName();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        _primaryButton(widget.existing == null ? 'Save' : 'Update', () {
          setState(() => _name = _nameCtrl.text.trim());
          _commitFromName();
        }, big: true),
      ],
    );
  }

  Widget _inAmount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 10),
          child: Text(
            'How much?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        TutorialTarget(
          id: TutorialTargetIds.entryAmountField,
          child: _amountField(autofocus: true, hero: true),
        ),
        const SizedBox(height: 16),

        _optionalNameChip(),
        const SizedBox(height: 20),
        _primaryButton(
          widget.existing == null ? 'Save' : 'Update',
          _save,
          big: true,
        ),
      ],
    );
  }

  Widget _amountField({required bool autofocus, required bool hero}) {
    final cs = Theme.of(context).colorScheme;
    final fs = hero ? 28.0 : 22.0;
    return TextField(
      controller: _amountCtrl,
      focusNode: _amountFocus,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(
        signed: false,
        decimal: true,
      ),
      inputFormatters: [MoneyInputFormatter()],
      style: TextStyle(
        fontSize: fs,
        fontWeight: FontWeight.w800,
        color: cs.primary,
      ),
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.next,
      onChanged: (v) => setState(() {
        _amount = parseCents(v) ?? 0;
        if (_amount > 0) _amountError = null;
      }),
      onSubmitted: (_) {
        final amt = parseCents(_amountCtrl.text) ?? 0;
        if (amt <= 0) {
          setState(() => _amountError = 'Enter an amount');
          return;
        }

        if (_phase != _Phase.name) {
          _editChip(_Phase.name);
        } else {
          _nameFocus.requestFocus();
        }
      },
      decoration: InputDecoration(
        labelText: 'Amount',
        errorText: _amountError,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: Center(
            widthFactor: 1,
            child: Text(
              deviceCurrencySymbol(context),
              style: TextStyle(
                fontSize: fs,
                fontWeight: FontWeight.w700,
                color: cs.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
    );
  }

  void _commitFromName() {
    final amt = parseCents(_amountCtrl.text) ?? 0;
    if (amt <= 0) {
      setState(() => _amountError = 'Enter an amount');
      _amountFocus.requestFocus();
      return;
    }
    _save();
  }

  Widget _optionalNameChip() {
    final cs = Theme.of(context).colorScheme;
    if (_name.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return TutorialTarget(
      id: TutorialTargetIds.entryNameChip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),

          onTap: () => _editChip(_Phase.name),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: cs.surfaceContainerHighest,
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.4),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 8),
                Text(
                  'Name it (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigOption({
    required String icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cs.primaryContainer.withValues(alpha: 0.6),
            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: cs.onPrimaryContainer.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap, {bool big = false}) {
    return SizedBox(
      width: double.infinity,
      height: big ? 58 : 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: big ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _addNewCategory() async {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    const suggested = [
      '🍔',
      '🍕',
      '☕',
      '🍺',
      '🍰',
      '🍜',
      '🥗',
      '🍎',
      '🚕',
      '🚌',
      '🚗',
      '⛽',
      '✈️',
      '🚂',
      '🛵',
      '🚲',
      '🏠',
      '⚡',
      '💡',
      '🚰',
      '🔥',
      '🛋️',
      '🧹',
      '📶',
      '🎮',
      '🎬',
      '🎵',
      '📺',
      '🎨',
      '🎭',
      '🎸',
      '📷',
      '🛒',
      '👕',
      '👟',
      '💄',
      '🎁',
      '🛍️',
      '💎',
      '🕶️',
      '💊',
      '🏥',
      '🦷',
      '💪',
      '🧘',
      '🏃',
      '🩺',
      '🧴',
      '📚',
      '✏️',
      '💼',
      '🎓',
      '📝',
      '💻',
      '📊',
      '📞',
      '💰',
      '💳',
      '💵',
      '📱',
      '🧾',
      '🔧',
      '🐶',
      '🎯',
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sl) => AlertDialog(
          title: const Center(
            child: Text('New tag', style: TextStyle(fontSize: 20)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 17),
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pick an emoji (optional):',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),

                  if (iconCtrl.text.isNotEmpty &&
                      suggestionsForEmoji(iconCtrl.text).isNotEmpty) ...[
                    Text(
                      'Quick names for ${iconCtrl.text}:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestionsForEmoji(iconCtrl.text).map((s) {
                        final exists = _categories.any(
                          (c) => c.name.toLowerCase() == s.toLowerCase(),
                        );
                        if (exists) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () {
                            nameCtrl.text = s;
                            Navigator.pop(ctx, true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  iconCtrl.text,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      ctx,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.add_circle,
                                  size: 13,
                                  color: Theme.of(ctx).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: suggested.map((e) {
                          final isSel = iconCtrl.text == e;
                          return GestureDetector(
                            onTap: () => sl(() {
                              iconCtrl.text = isSel ? '' : e;
                            }),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? Theme.of(ctx).colorScheme.primary
                                          .withValues(alpha: 0.2)
                                    : Theme.of(
                                        ctx,
                                      ).colorScheme.surfaceContainerHighest,
                                border: isSel
                                    ? Border.all(
                                        color: Theme.of(
                                          ctx,
                                        ).colorScheme.primary,
                                        width: 2,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave blank to use the first letter',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final catName = nameCtrl.text.trim();
    if (catName.isEmpty) {
      if (!mounted) return;
      _snack('Tag name cannot be empty.');
      return;
    }
    if (_categories.any((c) => c.name.toLowerCase() == catName.toLowerCase())) {
      if (!mounted) return;
      _snack('A tag named "$catName" already exists.');
      return;
    }
    final rawIcon = iconCtrl.text.trim();
    final catIcon = rawIcon.isEmpty ? catName[0].toUpperCase() : rawIcon;
    int? catColor;
    if (catIcon.length == 1 && RegExp(r'[A-Z]').hasMatch(catIcon)) {
      const palette = [
        0xFF4CAF50,
        0xFF2196F3,
        0xFFFF9800,
        0xFF9C27B0,
        0xFFE91E63,
        0xFF00BCD4,
        0xFFFF5722,
        0xFF795548,
        0xFF607D8B,
        0xFF009688,
        0xFFCDDC39,
        0xFF3F51B5,
      ];
      final usedColors = _categories
          .where((x) => x.icon == catIcon)
          .map((x) => x.color ?? 0)
          .toSet();
      catColor = palette.firstWhere(
        (col) => !usedColors.contains(col),
        orElse: () => palette[_categories.length % palette.length],
      );
    }
    final newId = await DatabaseHelper.instance.insertCategory(
      Category(name: catName, icon: catIcon, color: catColor),
    );
    _categories = await DatabaseHelper.instance.getCategoriesByUsage();
    _cat =
        _categories.where((x) => x.id == newId).firstOrNull ??
        _categories.first;
    _suggestions = await DatabaseHelper.instance.getSuggestions(_cat!.id!);
    if (!mounted) return;
    setState(() {});
    _advance();
  }
}
