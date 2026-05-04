import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/goal.dart';
import '../models/income_source.dart';
import '../theme/app_colors.dart';
import '../utils/currency_symbol.dart';
import '../utils/money_input.dart';
import '../widgets/big_action_button.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/live_icon.dart';
import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';
import 'settings_screen.dart';
import '../tutorial/tutorial_targets.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_service.dart';

const goalIconPalette = [
  '🎯',
  '💰',
  '🏠',
  '🚗',
  '✈️',
  '🎓',
  '💍',
  '👶',
  '🐶',
  '💻',
  '📱',
  '🎮',
  '📚',
  '🎸',
  '🎹',
  '🎨',
  '🏋️',
  '🚲',
  '⛺',
  '🛏️',
  '🛋️',
  '🏝️',
  '🛍️',
  '💎',
];

const goalColorPalette = [
  0xFF009688,
  0xFF4CAF50,
  0xFF2196F3,
  0xFF9C27B0,
  0xFFFF9800,
  0xFFE91E63,
  0xFF795548,
  0xFF607D8B,
];

const Map<String, List<String>> goalEmojiSuggestions = {
  '🎯': ['Emergency fund', 'Dream goal', 'Savings target'],
  '💰': ['Savings goal', 'Emergency fund', 'Investment fund'],
  '🏠': ['Home down payment', 'House fund', 'Rent advance'],
  '🚗': ['Car fund', 'Vehicle down payment', 'Car upgrade'],
  '✈️': ['Travel fund', 'Vacation fund', 'Trip budget'],
  '🎓': ['Education fund', 'Tuition fund', 'Course fee'],
  '💍': ['Wedding fund', 'Ring fund', 'Engagement budget'],
  '👶': ['Baby fund', 'Family fund', 'Childcare fund'],
  '🐶': ['Pet care fund', 'Pet emergency', 'Pet supplies'],
  '💻': ['Laptop fund', 'Work setup', 'Tech upgrade'],
  '📱': ['Phone upgrade', 'Device fund', 'Gadget fund'],
  '🎮': ['Gaming setup', 'Console fund', 'Hobby fund'],
  '📚': ['Books fund', 'Learning fund', 'Exam prep'],
  '🎸': ['Music gear', 'Instrument fund', 'Studio setup'],
  '🎹': ['Keyboard fund', 'Music setup', 'Instrument fund'],
  '🎨': ['Art supplies', 'Creative fund', 'Studio fund'],
  '🏋️': ['Fitness fund', 'Gym plan', 'Health goal'],
  '🚲': ['Bike fund', 'Cycling gear', 'Fitness setup'],
  '⛺': ['Camping fund', 'Outdoor gear', 'Adventure fund'],
  '🛏️': ['Bedroom upgrade', 'Furniture fund', 'Home comfort'],
  '🛋️': ['Living room upgrade', 'Furniture fund', 'Home decor'],
  '🏝️': ['Holiday fund', 'Beach trip', 'Vacation savings'],
  '🛍️': ['Shopping budget', 'Wishlist fund', 'Style upgrade'],
  '💎': ['Gold savings', 'Jewelry fund', 'Investment fund'],
};

List<String> goalSuggestionsForEmoji(String emoji) {
  return goalEmojiSuggestions[emoji] ?? const [];
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> implements ShellRefreshable {
  @override
  void refreshFromShell() => _load();

  List<Goal> _goals = [];

  List<IncomeSource> _sources = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goals = await DatabaseHelper.instance.getGoals(includeArchived: true);
    final sources = await DatabaseHelper.instance.getActiveSources();
    if (!mounted) return;

    int rank(Goal g) => g.archived ? 2 : (g.inactive ? 1 : 0);
    setState(() {
      _sources = sources;
      _goals = goals
        ..sort((a, b) {
          final r = rank(a).compareTo(rank(b));
          if (r != 0) return r;
          return b.createdAt.compareTo(a.createdAt);
        });
    });
  }

  Future<void> _addOrEditGoal({Goal? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final target = TextEditingController(
      text: existing != null ? formatMoneyCompact(existing.targetAmount) : '',
    );
    final saved = TextEditingController(
      text: existing != null ? formatMoneyCompact(existing.savedAmount) : '',
    );
    final nameFocus = FocusNode();
    final targetFocus = FocusNode();
    final scrollCtrl = ScrollController();

    targetFocus.addListener(() {
      if (!targetFocus.hasFocus) return;
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!scrollCtrl.hasClients) return;
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    });

    String icon = existing?.icon ?? '';
    int color = existing?.color ?? goalColorPalette[0];
    DateTime? date = existing?.targetDate;
    String? nameError;
    String? targetError;

    final result = await showDialog<Goal?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return AlertDialog(
            insetPadding: TutorialService.instance.dialogInsetsFor(
              TutorialIds.goalDialogFields,
            ),
            title: Text(existing == null ? 'New goal' : 'Edit goal'),
            content: SizedBox(
              width: 320,
              child: TutorialFireOnMount(
                messageId: TutorialIds.goalDialogFields,
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TutorialTarget(
                        id: TutorialTargetIds.goalDialogName,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                EmojiPlaceholderBox(
                                  value: icon,
                                  tint: Color(color),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: name,
                                    focusNode: nameFocus,
                                    autofocus: existing == null,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      hintText: 'New laptop, vacation…',
                                      errorText: nameError,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InlineEmojiPalette(
                              palette: goalIconPalette,
                              selected: icon,
                              tint: Color(color),
                              onPicked: (e) => setS(() => icon = e),
                            ),
                            if (icon.isNotEmpty &&
                                goalSuggestionsForEmoji(icon).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Quick names for $icon:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(ctx).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: goalSuggestionsForEmoji(icon).map((
                                  s,
                                ) {
                                  return GestureDetector(
                                    onTap: () {
                                      setS(() => name.text = s);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            targetFocus.requestFocus();
                                          });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            icon,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
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
                                            Icons.arrow_upward,
                                            size: 12,
                                            color: Theme.of(
                                              ctx,
                                            ).colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: goalColorPalette.map((c) {
                          final sel = c == color;
                          return GestureDetector(
                            onTap: () => setS(() => color = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: sel ? 32 : 28,
                              height: sel ? 32 : 28,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: sel
                                    ? Border.all(
                                        color: Theme.of(
                                          ctx,
                                        ).colorScheme.onSurface,
                                        width: 2.5,
                                      )
                                    : null,
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: Color(
                                            c,
                                          ).withValues(alpha: 0.6),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: target,
                        focusNode: targetFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Target',
                          prefixIcon: amountPrefixIcon(ctx),
                          errorText: targetError,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: saved,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Already saved',
                          prefixIcon: amountPrefixIcon(ctx),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.event_outlined, size: 18),
                              label: Text(
                                date == null
                                    ? 'Pick deadline (optional)'
                                    : 'Deadline: ${date!.toIso8601String().split('T').first}',
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate:
                                      date ??
                                      DateTime.now().add(
                                        const Duration(days: 90),
                                      ),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                );
                                if (picked != null) setS(() => date = picked);
                              },
                            ),
                          ),
                          if (date != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setS(() => date = null),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final n = name.text.trim();
                  final tCents = parseCents(target.text) ?? 0;
                  final sCents = parseCents(saved.text) ?? 0;
                  setS(() {
                    nameError = n.isEmpty ? 'Give the goal a name' : null;
                    targetError = tCents <= 0 ? 'Set a target amount' : null;
                  });
                  if (nameError != null) {
                    nameFocus.requestFocus();
                    return;
                  }
                  if (targetError != null) {
                    targetFocus.requestFocus();
                    return;
                  }
                  final g = (existing ?? Goal(name: n)).copyWith(
                    name: n,
                    icon: icon.isEmpty ? '🎯' : icon,
                    color: color,
                    targetAmount: tCents,
                    savedAmount: sCents,
                    targetDate: date,
                    clearTargetDate: date == null,
                  );
                  Navigator.pop(ctx, g);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;
    final wasFirstGoal = result.id == null && _goals.isEmpty;
    final db = DatabaseHelper.instance;
    if (result.id == null) {
      await db.addGoal(result);
    } else {
      await db.updateGoal(result);
    }
    await _load();
    if (!mounted) return;
    if (wasFirstGoal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        TutorialService.instance.show(context, TutorialIds.goalsCardTapHint);
      });
    }
  }

  Future<void> _contribute(Goal g) async {
    if (_sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add an income source first — goals move money to '
            'and from your income sources.',
          ),
        ),
      );
      return;
    }
    final ctrl = TextEditingController();
    bool subtract = false;

    int sourceId = _sources.first.id!;
    String? amountError;
    final result = await showDialog<({int delta, int sourceId})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final src = _sources.firstWhere((s) => s.id == sourceId);
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            title: Row(
              children: [
                Text(g.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Flexible(child: Text(g.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Saved ${formatMoney(g.savedAmount)} / '
                    '${formatMoney(g.targetAmount)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [MoneyInputFormatter()],
                    onChanged: (_) {
                      if (amountError != null) {
                        setS(() => amountError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: subtract ? 'Withdraw' : 'Add',
                      prefixIcon: amountPrefixIcon(ctx),
                      errorText: amountError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    subtract ? 'Withdraw to:' : 'From income source:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: sourceId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _sources
                        .map(
                          (s) => DropdownMenuItem<int>(
                            value: s.id,
                            child: Row(
                              children: [
                                Text(
                                  s.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    s.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatMoney(s.balance),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(ctx).colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setS(() => sourceId = v);
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtract
                        ? 'Goes back to ${src.name} balance.'
                        : '${src.name} balance: ${formatMoney(src.balance)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Withdraw instead'),
                    value: subtract,
                    onChanged: (v) => setS(() => subtract = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final c = parseCents(ctrl.text) ?? 0;
                  if (c <= 0) {
                    setS(() => amountError = 'Enter an amount');
                    return;
                  }

                  if (subtract && c > g.savedAmount) {
                    setS(
                      () => amountError =
                          'Goal only has ${formatMoney(g.savedAmount)} saved',
                    );
                    return;
                  }
                  Navigator.pop(ctx, (
                    delta: subtract ? -c : c,
                    sourceId: sourceId,
                  ));
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (result == null) return;
    await DatabaseHelper.instance.contributeToGoal(
      g.id!,
      result.delta,
      sourceId: result.sourceId,
    );
    _load();
  }

  Future<void> _confirmDelete(Goal g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('This removes "${g.name}" — saved progress is lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseHelper.instance.deleteGoal(g.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        leading: buildShellBackButton(context),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulsingGlowIcon(
              icon: Icons.flag_outlined,
              size: 22,
              color: Colors.teal,
              glowColor: Colors.teal,
              maxBlur: 10,
              minOpacity: 0.10,
              maxOpacity: 0.40,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Goals',
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
      body: _goals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text(
                      'No goals yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set a savings target and track progress as you put money aside.',
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
              children: _goals.asMap().entries.map((entry) {
                final card = _goalCard(entry.value, cs);
                return entry.key == 0
                    ? TutorialTarget(
                        id: TutorialTargetIds.goalsFirstCard,
                        child: card,
                      )
                    : card;
              }).toList(),
            ),
      bottomNavigationBar: TutorialTarget(
        id: TutorialTargetIds.goalsAddBtn,
        child: BigActionButton(
          icon: Icons.flag_outlined,
          tint: Colors.teal,
          tooltip: 'Add goal · swipe up for menu',
          onTap: _addOrEditGoal,
          onSwipeUp: () =>
              showMainMenuSheet(context, current: MainScreen.goals),
          onLongPress: () => MainShell.maybeOf(
            context,
          )?.gotoPage(MainScreen.dashboard, animate: false, fade: true),
        ),
      ),
    );
  }

  Color _progressColor(double ratio) => ProgressColors.goalProgress(ratio);

  Widget _goalCard(Goal g, ColorScheme cs) {
    final ratio = g.progress;
    final tint = Color(g.color);

    final Color fill;
    if (g.archived) {
      fill = Colors.green.shade600;
    } else if (g.inactive) {
      fill = cs.outline;
    } else {
      fill = _progressColor(ratio);
    }
    final bool muted = g.archived || g.inactive;

    final displayRatio = g.archived ? 1.0 : (g.inactive ? 0.0 : ratio);
    return Opacity(
      opacity: muted ? 0.6 : 1.0,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          onTap: (g.archived || g.inactive) ? null : () => _contribute(g),
          onLongPress: () async {
            final action = await showModalBottomSheet<String>(
              context: context,
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!g.archived && !g.inactive)
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('Add / withdraw'),
                        onTap: () => Navigator.pop(context, 'contribute'),
                      ),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit'),
                      onTap: () => Navigator.pop(context, 'edit'),
                    ),

                    if (g.archived)
                      ListTile(
                        leading: const Icon(
                          Icons.unarchive_outlined,
                          color: Colors.teal,
                        ),
                        title: const Text('Restore to active'),
                        onTap: () => Navigator.pop(context, 'unarchive'),
                      ),
                    if (g.inactive)
                      ListTile(
                        leading: const Icon(
                          Icons.play_arrow_outlined,
                          color: Colors.teal,
                        ),
                        title: const Text('Resume tracking'),
                        onTap: () => Navigator.pop(context, 'reactivate'),
                      ),
                    if (!g.archived && !g.inactive) ...[
                      ListTile(
                        leading: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        title: const Text('Mark as achieved'),
                        onTap: () => Navigator.pop(context, 'archive'),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.pause_circle_outline,
                          color: Colors.grey,
                        ),
                        title: const Text('Mark as inactive'),
                        onTap: () => Navigator.pop(context, 'inactivate'),
                      ),
                    ],
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => Navigator.pop(context, 'delete'),
                    ),
                  ],
                ),
              ),
            );
            if (action == 'contribute') _contribute(g);
            if (action == 'edit') _addOrEditGoal(existing: g);
            if (action == 'archive') {
              await DatabaseHelper.instance.setGoalArchived(g.id!, true);
              _load();
            }
            if (action == 'unarchive') {
              await DatabaseHelper.instance.setGoalArchived(g.id!, false);
              _load();
            }
            if (action == 'inactivate') {
              await DatabaseHelper.instance.setGoalInactive(g.id!, true);
              _load();
            }
            if (action == 'reactivate') {
              await DatabaseHelper.instance.setGoalInactive(g.id!, false);
              _load();
            }
            if (action == 'delete') _confirmDelete(g);
          },
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Color.alphaBlend(
                    Colors.black.withValues(alpha: muted ? 0.10 : 0.08),
                    fill.withValues(alpha: muted ? 0.24 : 0.20),
                  ),
                ),
              ),

              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: displayRatio.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          Colors.black.withValues(alpha: muted ? 0.12 : 0.08),
                          fill.withValues(alpha: muted ? 0.52 : 0.62),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _GoalCardContent(
                g: g,
                cs: cs,
                tint: tint,
                ratio: ratio,
                fill: fill,
                textColor: Theme.of(context).brightness == Brightness.dark
                    ? cs.onSurface
                    : Colors.black87,
              ),
              Positioned.fill(
                child: ClipRect(
                  clipper: _LeftRatioClipper(displayRatio.clamp(0.0, 1.0)),
                  child: _GoalCardContent(
                    g: g,
                    cs: cs,
                    tint: tint,
                    ratio: ratio,
                    fill: fill,
                    textColor: Colors.white,
                    overFill: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCardContent extends StatelessWidget {
  final Goal g;
  final ColorScheme cs;
  final Color tint;
  final double ratio;
  final Color fill;
  final Color textColor;
  final bool overFill;

  const _GoalCardContent({
    required this.g,
    required this.cs,
    required this.tint,
    required this.ratio,
    required this.fill,
    required this.textColor,
    this.overFill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(g.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            g.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              decoration: g.archived
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (g.archived || g.inactive)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                g.archived ? 'achieved' : 'inactive',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (g.targetDate != null)
                      Text(
                        'by ${g.targetDate!.toIso8601String().split('T').first}',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
              if (g.archived)
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${formatMoney(g.savedAmount)} / ${formatMoney(g.targetAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: overFill ? textColor : fill,
                ),
              ),
            ],
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
