import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../tutorial/learn_button.dart';
import '../data/notification_service.dart';
import '../models/income_source.dart';
import '../models/income_template.dart';
import '../models/transfer_template.dart';
import '../models/ledger_entry.dart';
import '../utils/emoji_suggestions.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import '../widgets/main_shell.dart';
import '../utils/currency_symbol.dart';
import '../utils/money_input.dart';
import '../utils/notif_permission.dart';
import '../widgets/live_icon.dart';
import '../widgets/big_action_button.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/auto_scroll.dart';
import '../widgets/main_menu_sheet.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_service.dart';
import '../tutorial/tutorial_targets.dart';

const _sourceColors = [
  0xFF4CAF50,
  0xFF2196F3,
  0xFFFF9800,
  0xFF9C27B0,
  0xFFE91E63,
  0xFF00BCD4,
  0xFF795548,
  0xFF607D8B,
];

const accountIconPalette = [
  '💵',
  '🏦',
  '📱',
  '💳',
  '🪙',
  '👛',
  '💰',
  '🏧',
  '💴',
  '💶',
  '💷',
  '🤑',
  '💎',
  '🪪',
  '🧾',
  '📲',
  '🐷',
  '🏠',
  '🚗',
  '✈️',
  '🛒',
  '🎓',
  '🧧',
  '📈',
];

const incomeIconPalette = [
  '💰',
  '💵',
  '💸',
  '💴',
  '💶',
  '💷',
  '🤑',
  '💲',
  '🏦',
  '🏧',
  '💳',
  '🧾',
  '📈',
  '🏆',
  '🎁',
  '👛',
  '🪙',
  '💎',
  '🏠',
  '🚗',
  '💼',
  '📱',
  '🎓',
  '🛒',
];

class IncomeSourcesScreen extends StatefulWidget {
  const IncomeSourcesScreen({super.key});
  @override
  State<IncomeSourcesScreen> createState() => _IncomeSourcesScreenState();
}

class _IncomeSourcesScreenState extends State<IncomeSourcesScreen>
    implements ShellRefreshable, ShellPrimaryAction {
  @override
  void firePrimaryAction() => _addOrEditAccount();

  @override
  bool get hasData => activeSources.isNotEmpty;

  @override
  void refreshFromShell() => _load();
  List<IncomeSource> activeSources = [];
  List<IncomeSource> archivedSources = [];
  List<IncomeTemplate> templates = [];
  List<TransferTemplate> transferTemplates = [];

  int? _expandedId;
  final ScrollController _recentScrollCtrl = ScrollController();
  final Map<int, GlobalKey> _cardKeys = {};

  List<LedgerEntry> recentEntries = [];

  int? _tutPrevRecentCount;
  int? _tutPrevFirstDiff;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final all = await db.getAllSources();
    activeSources = all.where((s) => !s.isArchived).toList();
    archivedSources = all.where((s) => s.isArchived).toList();
    templates = await db.getIncomeTemplates();
    transferTemplates = await db.getTransferTemplates();
    recentEntries = await db.getRecentEntries(limit: 5);
    if (!mounted) return;
    setState(() {});
    _checkTutorialTransitions();
  }

  void _checkTutorialTransitions() {
    final recentCount = recentEntries.length;
    final firstDiffAbs = activeSources.isEmpty
        ? 0
        : (activeSources.first.balance - activeSources.first.monthlyStart)
              .abs();
    final prevRecent = _tutPrevRecentCount;
    final prevDiff = _tutPrevFirstDiff;
    _tutPrevRecentCount = recentCount;
    _tutPrevFirstDiff = firstDiffAbs;
    if (prevRecent == null || prevDiff == null) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (prevRecent == 0 && recentCount > 0) {
        TutorialService.instance.show(context, TutorialIds.accountsRecentStrip);
      }
      if (prevDiff == 0 && firstDiffAbs > 0) {
        TutorialService.instance.show(
          context,
          TutorialIds.accountsCardActivity,
        );
      }
    });
  }

  IncomeSource? _srcOf(int id) => [
    ...activeSources,
    ...archivedSources,
  ].where((s) => s.id == id).firstOrNull;

  Future<void> _addOrEditAccount({IncomeSource? existing}) async {
    final wasFirstAccount = existing == null && activeSources.isEmpty;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: existing != null ? formatMoneyCompact(existing.balance) : '',
    );
    final nameFocus = FocusNode();
    final balanceFocus = FocusNode();

    String selectedIcon = existing?.icon ?? '';
    int selectedColor = existing?.color ?? _sourceColors[0];
    final isNew = existing == null;
    String? nameError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          insetPadding: TutorialService.instance.dialogInsetsFor(
            TutorialIds.acctDialogFields,
          ),
          title: Center(
            child: Text(
              isNew ? 'Add Income Source' : 'Edit Income Source',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          content: SizedBox(
            width: 320,
            child: TutorialFireOnMount(
              messageId: TutorialIds.acctDialogFields,
              pendingDialogKey: 'account',
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TutorialTarget(
                      id: TutorialTargetIds.acctDialogName,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              EmojiPlaceholderBox(
                                value: selectedIcon,
                                tint: Color(selectedColor),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: nameCtrl,
                                  focusNode: nameFocus,
                                  autofocus: isNew,
                                  style: const TextStyle(fontSize: 17),
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    hintText: 'Bank, Cash, Wallet…',
                                    errorText: nameError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InlineEmojiPalette(
                            palette: accountIconPalette,
                            selected: selectedIcon,
                            tint: Color(selectedColor),
                            onPicked: (e) => setDlg(() => selectedIcon = e),
                          ),
                        ],
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: balanceCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        focusNode: balanceFocus,
                        inputFormatters: [MoneyInputFormatter()],
                        style: const TextStyle(fontSize: 17),
                        decoration: InputDecoration(
                          labelText: 'Current balance',
                          prefixIcon: amountPrefixIcon(ctx),
                        ),
                      ),
                    ],
                    if (accountSuggestionsForEmoji(
                      selectedIcon,
                    ).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Quick names for $selectedIcon:',
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
                        children: accountSuggestionsForEmoji(selectedIcon)
                            .map(
                              (s) => GestureDetector(
                                onTap: () {
                                  setDlg(() => nameCtrl.text = s);
                                  if (isNew) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          balanceFocus.requestFocus();
                                        });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      selectedColor,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Color(
                                        selectedColor,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Text('Color', style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _sourceColors
                          .map(
                            (col) => GestureDetector(
                              onTap: () => setDlg(() => selectedColor = col),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(col),
                                  border: col == selectedColor
                                      ? Border.all(
                                          color: Theme.of(
                                            ctx,
                                          ).colorScheme.onSurface,
                                          width: 3,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) {
                  setDlg(() => nameError = 'Give the income source a name');

                  nameFocus.requestFocus();
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    if (isNew) {
      final srcId = await DatabaseHelper.instance.addIncomeSource(
        nameCtrl.text.trim(),
        selectedIcon.isEmpty ? '💰' : selectedIcon,
        selectedColor,
        parseCents(balanceCtrl.text) ?? 0,
      );
      if (!mounted) return;

      await _offerIncomeButton(
        srcId: srcId,
        accountName: nameCtrl.text.trim(),
        accountIcon: selectedIcon.isEmpty ? '💰' : selectedIcon,
        accountColor: selectedColor,
      );
      if (!mounted) return;
      if (wasFirstAccount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          TutorialService.instance.show(context, TutorialIds.accountsCardTap);
        });
      }
    } else {
      await DatabaseHelper.instance.updateIncomeSource(
        existing.id!,
        nameCtrl.text.trim(),
        selectedIcon.isEmpty ? '💰' : selectedIcon,
        selectedColor,
      );
    }
    _load();
  }

  Future<void> _offerIncomeButton({
    required int srcId,
    required String accountName,
    required String accountIcon,
    required int accountColor,
  }) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final nameFocus = FocusNode();
    final amountFocus = FocusNode();
    bool isFixed = true;
    int? reminderDay;
    bool skipEntirely = false;

    String selIcon = '';
    String? nameError;
    String? amountError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          insetPadding: TutorialService.instance.dialogInsetsFor(
            TutorialIds.incomeDialogIntro,
          ),
          title: const Center(
            child: Text('Recurring income?', style: TextStyle(fontSize: 20)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TutorialFireOnMount(
              messageId: TutorialIds.incomeDialogIntro,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Color(accountColor).withValues(alpha: 0.15),
                        border: Border.all(
                          color: Color(accountColor),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            accountIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'For $accountName',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(accountColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Create a one-tap button to receive money into this income source (optional).',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TutorialTarget(
                      id: TutorialTargetIds.incomeDialogName,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              EmojiPlaceholderBox(
                                value: selIcon,
                                tint: Colors.teal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: nameCtrl,
                                  focusNode: nameFocus,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: isFixed
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onChanged: (_) => setDlg(() {}),
                                  onSubmitted: (_) {
                                    if (isFixed) {
                                      amountFocus.requestFocus();
                                    } else {
                                      FocusScope.of(ctx).unfocus();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Button name',
                                    hintText: 'e.g. Salary, Rent Income',
                                    errorText: nameError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InlineEmojiPalette(
                            palette: incomeIconPalette,
                            selected: selIcon,
                            tint: Colors.teal,
                            onPicked: (e) => setDlg(() => selIcon = e),
                          ),
                        ],
                      ),
                    ),

                    if (incomeButtonSuggestionsFor(accountIcon).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Quick names for $accountIcon:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            ctx,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: incomeButtonSuggestionsFor(accountIcon)
                            .map(
                              (s) => GestureDetector(
                                onTap: () {
                                  setDlg(() => nameCtrl.text = s);
                                  if (isFixed) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          amountFocus.requestFocus();
                                        });
                                  }
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
                                      color: Theme.of(ctx).colorScheme.primary
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 12,
                                        color: Theme.of(
                                          ctx,
                                        ).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _TypeBtn(
                            label: 'Fixed\namount',
                            icon: Icons.lock_outline,
                            selected: isFixed,
                            onTap: () => setDlg(() => isFixed = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeBtn(
                            label: 'Variable\n(ask each time)',
                            icon: Icons.edit_outlined,
                            selected: !isFixed,
                            onTap: () => setDlg(() => isFixed = false),
                          ),
                        ),
                      ],
                    ),
                    if (isFixed) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountCtrl,
                        focusNode: amountFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(ctx).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: amountPrefixIcon(ctx),
                          errorText: amountError,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.notifications_outlined, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Monthly reminder',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (reminderDay != null)
                          TextButton(
                            onPressed: () => setDlg(() => reminderDay = null),
                            child: Text(
                              'Day $reminderDay · clear',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick the day you usually receive this (optional):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 28,
                        itemBuilder: (_, i) {
                          final day = i + 1;
                          final sel = reminderDay == day;
                          return GestureDetector(
                            onTap: () =>
                                setDlg(() => reminderDay = sel ? null : day),
                            child: Container(
                              width: 38,
                              height: 38,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Theme.of(
                                        ctx,
                                      ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: sel
                                      ? Theme.of(ctx).colorScheme.onPrimary
                                      : Theme.of(ctx).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (reminderDay != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "You'll be reminded on day $reminderDay each month.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.primary,
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
              onPressed: () {
                skipEntirely = true;
                Navigator.pop(ctx);
              },
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amt = parseCents(amountCtrl.text) ?? 0;
                setDlg(() {
                  nameError = name.isEmpty ? 'Name the recurring income' : null;
                  amountError = (isFixed && amt <= 0)
                      ? 'Enter an amount'
                      : null;
                });
                if (nameError != null) {
                  nameFocus.requestFocus();
                  return;
                }
                if (amountError != null) {
                  amountFocus.requestFocus();
                  return;
                }
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (skipEntirely) return;
    final btnName = nameCtrl.text.trim().isEmpty
        ? accountName
        : nameCtrl.text.trim();
    final template = IncomeTemplate(
      name: btnName,
      icon: selIcon.isEmpty ? '💰' : selIcon,
      sourceId: srcId,
      amount: isFixed ? (parseCents(amountCtrl.text) ?? 0) : 0,
      isFixed: isFixed,
      reminderDay: reminderDay,
    );
    final tmplId = await DatabaseHelper.instance.addIncomeTemplate(template);
    if (reminderDay != null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) await ensureNotifPermission(context);
      await NotificationService.instance.scheduleIncomeReminder(
        IncomeTemplate(
          id: tmplId,
          name: template.name,
          icon: template.icon,
          sourceId: template.sourceId,
          amount: template.amount,
          isFixed: template.isFixed,
          reminderDay: template.reminderDay,
        ),
      );
    }
  }

  Future<void> _adjustBalance(IncomeSource s) async {
    final ctrl = TextEditingController(text: formatMoneyCompact(s.balance));
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text('Adjust ${s.name}', style: const TextStyle(fontSize: 20)),

        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [MoneyInputFormatter()],
                style: const TextStyle(fontSize: 18),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New balance',
                  prefixIcon: amountPrefixIcon(dlgCtx),
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseHelper.instance.updateSourceBalance(
      s.id!,
      parseCents(ctrl.text) ?? s.balance,
    );
    _load();
  }

  Future<void> _confirmRemove(IncomeSource s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Remove "${s.name}"?',
          style: const TextStyle(fontSize: 20),
        ),
        content: const Text(
          'If this income source has transactions, it will be archived. History stays intact.',
          style: TextStyle(fontSize: 16),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await DatabaseHelper.instance.deleteOrArchiveSource(s.id!);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must keep at least one active income source.'),
        ),
      );
    }
  }

  Future<void> _unarchive(IncomeSource s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Restore "${s.name}"?',
          style: const TextStyle(fontSize: 20),
        ),
        content: const Text(
          'This income source will become active again.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DatabaseHelper.instance.unarchiveSource(s.id!);
    _load();
  }

  Future<void> _addOrEditTemplate({IncomeTemplate? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null && existing.amount > 0
          ? formatMoneyCompact(existing.amount)
          : '',
    );
    final amountFocus = FocusNode();
    bool isFixed = existing?.isFixed ?? true;

    String selIcon = existing?.icon ?? '';
    int? selectedSrcId =
        existing?.sourceId ??
        _preselectedSourceId ??
        (activeSources.isNotEmpty ? activeSources.first.id : null);
    int? reminderDay = existing?.reminderDay;
    String? nameError;
    String? amountError;
    String? sourceError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final selSrc = activeSources
              .where((s) => s.id == selectedSrcId)
              .firstOrNull;
          final acctIcon = selSrc?.icon ?? '💵';

          return AlertDialog(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null
                      ? 'New Recurring Income'
                      : 'Edit Recurring Income',
                  style: const TextStyle(fontSize: 20),
                ),
                if (sourceError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sourceError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selSrc != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Color(selSrc.color).withValues(alpha: 0.15),
                          border: Border.all(
                            color: Color(selSrc.color),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selSrc.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'For ${selSrc.name}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(selSrc.color),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        EmojiPickerButton(
                          value: selIcon,
                          tint: Colors.teal,
                          palette: incomeIconPalette,
                          onPicked: (e) => setDlg(() => selIcon = e),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: isFixed
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onChanged: (_) => setDlg(() {}),
                            onSubmitted: (_) {
                              if (isFixed) {
                                amountFocus.requestFocus();
                              } else {
                                FocusScope.of(ctx).unfocus();
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Button name',
                              hintText: 'e.g. Salary, Rent Income',
                              errorText: nameError,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (incomeButtonSuggestionsFor(acctIcon).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Quick names for $acctIcon:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            ctx,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: incomeButtonSuggestionsFor(acctIcon)
                            .map(
                              (s) => GestureDetector(
                                onTap: () {
                                  setDlg(() => nameCtrl.text = s);
                                  if (isFixed) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          amountFocus.requestFocus();
                                        });
                                  }
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
                                      color: Theme.of(ctx).colorScheme.primary
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 12,
                                        color: Theme.of(
                                          ctx,
                                        ).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _typeToggle(
                            ctx,
                            label: 'Fixed\namount',
                            icon: Icons.lock_outline,
                            selected: isFixed,
                            onTap: () => setDlg(() => isFixed = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _typeToggle(
                            ctx,
                            label: 'Variable\n(ask each time)',
                            icon: Icons.edit_outlined,
                            selected: !isFixed,
                            onTap: () => setDlg(() => isFixed = false),
                          ),
                        ),
                      ],
                    ),

                    if (isFixed) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountCtrl,
                        focusNode: amountFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(ctx).unfocus(),
                        style: const TextStyle(fontSize: 17),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: amountPrefixIcon(ctx),
                          errorText: amountError,
                        ),
                      ),
                    ],

                    if (existing == null && _preselectedSourceId == null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Add to income source',
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      ...activeSources.map((s) {
                        final sel = s.id == selectedSrcId;
                        return GestureDetector(
                          onTap: () => setDlg(() => selectedSrcId = s.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
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
                                Text(
                                  s.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  s.name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                Text(
                                  formatMoney(s.balance),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(ctx).colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.notifications_outlined, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Monthly reminder',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (reminderDay != null)
                          TextButton(
                            onPressed: () => setDlg(() => reminderDay = null),
                            child: Text(
                              'Day $reminderDay · clear',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick the day you usually receive this (optional):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 28,
                        itemBuilder: (_, i) {
                          final day = i + 1;
                          final sel = reminderDay == day;
                          return GestureDetector(
                            onTap: () =>
                                setDlg(() => reminderDay = sel ? null : day),
                            child: Container(
                              width: 38,
                              height: 38,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Theme.of(
                                        ctx,
                                      ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: sel
                                      ? Theme.of(ctx).colorScheme.onPrimary
                                      : Theme.of(ctx).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (reminderDay != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "You'll be reminded on day $reminderDay each month.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () {
                  final n = nameCtrl.text.trim();
                  final amt = parseCents(amountCtrl.text) ?? 0;
                  setDlg(() {
                    nameError = n.isEmpty ? 'Give the button a name' : null;
                    sourceError = selectedSrcId == null
                        ? 'Pick which income source this button is for'
                        : null;
                    amountError = (isFixed && amt <= 0)
                        ? 'Enter an amount'
                        : null;
                  });
                  if (nameError != null ||
                      sourceError != null ||
                      amountError != null) {
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final icon = selIcon.isEmpty
        ? (name.isNotEmpty ? name[0].toUpperCase() : '💰')
        : selIcon;

    if (reminderDay != null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) await ensureNotifPermission(context);
    }

    final t = IncomeTemplate(
      id: existing?.id,
      name: name,
      icon: icon,
      sourceId: selectedSrcId!,
      amount: isFixed ? (parseCents(amountCtrl.text) ?? 0) : 0,
      isFixed: isFixed,
      reminderDay: reminderDay,
    );
    if (existing == null) {
      final id = await DatabaseHelper.instance.addIncomeTemplate(t);
      final saved = IncomeTemplate(
        id: id,
        name: t.name,
        icon: t.icon,
        sourceId: t.sourceId,
        amount: t.amount,
        isFixed: t.isFixed,
        reminderDay: t.reminderDay,
      );
      if (reminderDay != null) {
        await NotificationService.instance.scheduleIncomeReminder(saved);
      }
    } else {
      await DatabaseHelper.instance.updateIncomeTemplate(t);
      if (reminderDay != null) {
        await NotificationService.instance.scheduleIncomeReminder(t);
      } else {
        await NotificationService.instance.cancelIncomeReminder(t.id!);
      }
    }
    _load();
  }

  Widget _typeToggle(
    BuildContext ctx, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(ctx).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? cs.onPrimary : cs.onSurface),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _receiveIncome(IncomeTemplate t) async {
    int amount = t.amount;
    if (!t.isFixed) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (dlgCtx) => AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          title: Center(
            child: Text(
              '${t.icon} ${t.name}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          content: SizedBox(
            width: 240,
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [MoneyInputFormatter()],
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.pop(dlgCtx, true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Amount',
                prefixIcon: amountPrefixIcon(dlgCtx, fontSize: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dlgCtx, true),
              child: const Text('Receive', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
      if (ok != true) return;
      amount = parseCents(ctrl.text) ?? 0;
    }
    if (amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid amount.')));
      return;
    }
    await DatabaseHelper.instance.addIncome(
      LedgerEntry(
        type: 'income',
        categoryId: 0,
        sourceId: t.sourceId,
        amount: amount,
        name: t.name,
        date: DateTime.now(),
      ),
    );
    if (!mounted) return;

    _load();
  }

  Widget _inlineValidationBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _quickAddMoney(IncomeSource src) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? validationError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dlgCtx, setDlg) => AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(src.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add money to ${src.name}',
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (validationError != null)
                _inlineValidationBanner(validationError!),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [MoneyInputFormatter()],
                autofocus: true,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Amount',
                  prefixIcon: amountPrefixIcon(dlgCtx, fontSize: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. freelance, refund',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                final a = parseCents(amountCtrl.text) ?? 0;
                if (a <= 0) {
                  setDlg(
                    () =>
                        validationError = 'Enter an amount greater than zero.',
                  );
                  return;
                }
                Navigator.pop(dlgCtx, true);
              },
              child: const Text('Add', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final amount = parseCents(amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    final note = noteCtrl.text.trim().isEmpty
        ? 'Added to ${src.name}'
        : noteCtrl.text.trim();
    await DatabaseHelper.instance.addIncome(
      LedgerEntry(
        type: 'income',
        categoryId: 0,
        sourceId: src.id!,
        amount: amount,
        name: note,
        date: DateTime.now(),
      ),
    );
    if (!mounted) return;

    _load();
  }

  Future<void> _addOrEditTransferTemplate({
    TransferTemplate? existing,
    int? lockedFromId,
  }) async {
    if (activeSources.length < 2) {
      if (!mounted) return;
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: orange, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz, size: 16, color: orange),
                  const SizedBox(width: 8),
                  const Text(
                    'You need at least two income sources',
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
      return;
    }
    final amountCtrl = TextEditingController(
      text: existing != null && existing.amount > 0
          ? formatMoneyCompact(existing.amount)
          : '',
    );

    bool isFixed = existing?.isFixed ?? false;
    int fromId =
        existing?.fromSourceId ?? lockedFromId ?? activeSources.first.id!;

    int toId =
        existing?.toSourceId ??
        (activeSources
            .firstWhere(
              (s) => s.id != fromId,
              orElse: () => activeSources.first,
            )
            .id!);
    int? reminderDay = existing?.reminderDay;
    String? amountError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final fromSrc = activeSources
              .where((s) => s.id == fromId)
              .firstOrNull;
          final toSrc = activeSources.where((s) => s.id == toId).firstOrNull;
          final toOptions = activeSources.where((s) => s.id != fromId).toList();

          return AlertDialog(
            title: Center(
              child: Text(
                existing == null ? 'New Transfer' : 'Edit Transfer',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fromSrc != null && toSrc != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            ctx,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              fromSrc.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                fromSrc.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward,
                              size: 22,
                              color: Theme.of(
                                ctx,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              toSrc.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                toSrc.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Text(
                      'From',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: activeSources.map((s) {
                        final isSel = s.id == fromId;
                        final isLocked =
                            lockedFromId != null && lockedFromId != s.id;
                        return GestureDetector(
                          onTap: isLocked
                              ? null
                              : () {
                                  setDlg(() {
                                    fromId = s.id!;
                                    if (toId == fromId) {
                                      toId = activeSources
                                          .firstWhere(
                                            (x) => x.id != fromId,
                                            orElse: () => activeSources.first,
                                          )
                                          .id!;
                                    }
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? Color(s.color).withValues(alpha: 0.18)
                                  : Theme.of(
                                      ctx,
                                    ).colorScheme.surfaceContainerHighest,
                              border: Border.all(
                                color: isSel
                                    ? Color(s.color)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Opacity(
                              opacity: isLocked ? 0.35 : 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.icon,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'To',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: toOptions.map((s) {
                        final isSel = s.id == toId;
                        return GestureDetector(
                          onTap: () => setDlg(() => toId = s.id!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? Color(s.color).withValues(alpha: 0.18)
                                  : Theme.of(
                                      ctx,
                                    ).colorScheme.surfaceContainerHighest,
                              border: Border.all(
                                color: isSel
                                    ? Color(s.color)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.icon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _TypeBtn(
                            label: 'Fixed',
                            icon: Icons.lock_outline,
                            selected: isFixed,
                            onTap: () => setDlg(() => isFixed = true),
                            description: 'Same amount each time',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeBtn(
                            label: 'Variable',
                            icon: Icons.tune,
                            selected: !isFixed,
                            onTap: () => setDlg(() => isFixed = false),
                            description: 'Enter amount when tapped',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (isFixed) ...[
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(ctx).unfocus(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Transfer amount',
                          prefixIcon: amountPrefixIcon(ctx, fontSize: 18),
                          errorText: amountError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Text(
                      'Monthly reminder (optional)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: () => setDlg(() => reminderDay = null),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: reminderDay == null
                                    ? Theme.of(ctx).colorScheme.primary
                                          .withValues(alpha: 0.15)
                                    : Theme.of(
                                        ctx,
                                      ).colorScheme.surfaceContainerHighest,
                                border: Border.all(
                                  color: reminderDay == null
                                      ? Theme.of(ctx).colorScheme.primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'None',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          ...List.generate(28, (i) {
                            final d = i + 1;
                            final isSel = reminderDay == d;
                            return GestureDetector(
                              onTap: () => setDlg(() => reminderDay = d),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? Theme.of(ctx).colorScheme.primary
                                            .withValues(alpha: 0.15)
                                      : Theme.of(
                                          ctx,
                                        ).colorScheme.surfaceContainerHighest,
                                  border: Border.all(
                                    color: isSel
                                        ? Theme.of(ctx).colorScheme.primary
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '$d',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () {
                  final amt = parseCents(amountCtrl.text) ?? 0;
                  if (isFixed && amt <= 0) {
                    setDlg(() => amountError = 'Enter an amount');
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    if (reminderDay != null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) await ensureNotifPermission(context);
    }
    final amount = isFixed ? (parseCents(amountCtrl.text) ?? 0) : 0;
    final t = TransferTemplate(
      id: existing?.id,
      fromSourceId: fromId,
      toSourceId: toId,
      amount: amount,
      isFixed: isFixed,
      reminderDay: reminderDay,
    );
    int savedId;
    if (existing == null) {
      savedId = await DatabaseHelper.instance.addTransferTemplate(t);
    } else {
      await DatabaseHelper.instance.updateTransferTemplate(t);
      savedId = existing.id!;
    }

    if (reminderDay != null) {
      final fromSrc = activeSources.firstWhere((s) => s.id == fromId);
      final toSrc = activeSources.firstWhere((s) => s.id == toId);
      try {
        await NotificationService.instance.scheduleTransferReminder(
          TransferTemplate(
            id: savedId,
            fromSourceId: fromId,
            toSourceId: toId,
            amount: amount,
            isFixed: isFixed,
            reminderDay: reminderDay,
          ),
          fromSrc: fromSrc,
          toSrc: toSrc,
        );
      } catch (_) {}
    } else {
      try {
        await NotificationService.instance.cancelTransferReminder(savedId);
      } catch (_) {}
    }
    _load();
  }

  Future<void> _executeTransfer(TransferTemplate t) async {
    final fromSrc = activeSources
        .where((s) => s.id == t.fromSourceId)
        .firstOrNull;
    final toSrc = activeSources.where((s) => s.id == t.toSourceId).firstOrNull;
    if (fromSrc == null || toSrc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer references a missing income source.'),
        ),
      );
      return;
    }

    int amount = t.amount;
    if (!t.isFixed) {
      final ctrl = TextEditingController();
      String? validationError;

      void tryCommit(BuildContext dlgCtx, void Function(VoidCallback) setDlg) {
        final a = parseCents(ctrl.text) ?? 0;
        if (a <= 0) {
          setDlg(() => validationError = 'Enter an amount greater than zero.');
          return;
        }
        if (fromSrc.balance < a) {
          setDlg(() => validationError = '${fromSrc.name} balance is too low.');
          return;
        }
        Navigator.pop(dlgCtx, true);
      }

      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (dlgCtx, setDlg) => AlertDialog(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fromSrc.icon} → ${toSrc.icon}',
                  style: const TextStyle(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                if (validationError != null)
                  _inlineValidationBanner(validationError!),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${fromSrc.name} → ${toSrc.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      dlgCtx,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [MoneyInputFormatter()],
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => tryCommit(dlgCtx, setDlg),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    prefixIcon: amountPrefixIcon(dlgCtx, fontSize: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx, false),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => tryCommit(dlgCtx, setDlg),
                child: const Text('Transfer', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
      if (ok != true) return;
      amount = parseCents(ctrl.text) ?? 0;
    }
    if (amount <= 0 || fromSrc.balance < amount) return;
    await DatabaseHelper.instance.addTransfer(
      fromSourceId: fromSrc.id!,
      toSourceId: toSrc.id!,
      amount: amount,
      name: '${fromSrc.icon} → ${toSrc.icon}',
      date: DateTime.now(),
    );
    if (!mounted) return;

    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthName = DateFormat('MMM').format(DateTime.now());
    final total = activeSources.fold<int>(0, (sum, s) => sum + s.balance);

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
              icon: Icons.account_balance_wallet_outlined,
              size: 22,
              color: Colors.green,
              glowColor: Colors.green,
              maxBlur: 10,
              minOpacity: 0.10,
              maxOpacity: 0.40,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Income Sources',
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const LearnButton(page: MainScreen.accounts),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (recentEntries.isNotEmpty) ...[
            TutorialTarget(
              id: TutorialTargetIds.accountsRecentStrip,
              child: _recentActivityStrip(cs),
            ),
            const SizedBox(height: 10),
          ],

          Builder(
            builder: (_) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              // Light mode: saturated pastel green bg + white text and
              // icon, matching the BigActionButton / EARNED-SPENT-tile
              // recipe so the Total Balance pill speaks the same
              // colour language as the rest of the app's pastel UI.

              final bg = isDark
                  ? cs.primaryContainer
                  : Color.lerp(Colors.green, Colors.white, 0.20)!;
              final fg = isDark ? cs.onPrimaryContainer : Colors.white;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 15,
                      color: fg.withValues(alpha: 0.92),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: fg.withValues(alpha: 0.92),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${deviceCurrencySymbol(context)}${formatMoney(total)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: fg,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (templates.isEmpty &&
              transferTemplates.isEmpty &&
              activeSources.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap an income source to see what it can do. Create Recurring Income or Transfer shortcuts to record repeating activity in one tap.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          ...activeSources.asMap().entries.map(
            (entry) => _buildAccountCard(
              entry.value,
              monthName,
              cs,
              isFirst: entry.key == 0,
            ),
          ),

          if (archivedSources.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  'Archived',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Hidden income sources — transaction history preserved.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 10),
            ...archivedSources.map(
              (s) => Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.icon,
                      style: TextStyle(
                        fontSize: 24,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  title: Text(
                    s.name,
                    style: TextStyle(
                      fontSize: 17,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  subtitle: Text(
                    formatMoney(s.balance),
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.unarchive_outlined, size: 18),
                    label: const Text('Restore'),
                    onPressed: () => _unarchive(s),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),

      bottomNavigationBar: shellBottomBar(
        TutorialTarget(
          id: TutorialTargetIds.accountsAddBtn,
          child: BigActionButton(
            icon: Icons.account_balance_wallet_outlined,
            tint: Colors.green,
            tooltip: 'Add income source · swipe up for menu',
            onTap: () => _addOrEditAccount(),
            onSwipeUp: () =>
                showMainMenuSheet(context, current: MainScreen.accounts),
            onLongPress: () => MainShell.maybeOf(
              context,
            )?.gotoPage(MainScreen.dashboard, animate: false, fade: true),
          ),
        ),
        current: MainScreen.accounts,
      ),
    );
  }

  Widget _recentActivityStrip(ColorScheme cs) {
    final df = DateFormat('MMM d · HH:mm');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecordsScreen()),
        );
        if (!mounted) return;
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),

        child: SizedBox(
          height: 92,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) {
              if (!_recentScrollCtrl.hasClients) return;
              final pos = _recentScrollCtrl.position;
              final next = (pos.pixels - d.delta.dx).clamp(
                pos.minScrollExtent,
                pos.maxScrollExtent,
              );
              _recentScrollCtrl.jumpTo(next);
            },
            child: AutoScroll(
              controller: _recentScrollCtrl,
              child: ListView.separated(
                controller: _recentScrollCtrl,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentEntries.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final e = recentEntries[i];
                  final src = _srcOf(e.sourceId);
                  Color tint;
                  String sign;
                  switch (e.type) {
                    case 'income':
                      tint = Colors.green;
                      sign = '+';
                      break;
                    case 'expense':
                      tint = Colors.red;
                      sign = '−';
                      break;
                    case 'transfer':
                    default:
                      tint = Colors.blue;
                      sign = '';
                      break;
                  }
                  final label = e.type == 'transfer'
                      ? '${src?.name ?? '?'} → ${_srcOf(e.toSourceId ?? -1)?.name ?? '?'}'
                      : (src?.name ?? '?');
                  return Container(
                    constraints: const BoxConstraints(
                      minWidth: 130,
                      maxWidth: 220,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$sign${formatMoney(e.amount)}',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: tint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.1,
                            color: cs.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          df.format(e.date),
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    IncomeSource s,
    String monthName,
    ColorScheme cs, {
    bool isFirst = false,
  }) {
    final diff = s.balance - s.monthlyStart;
    final diffColor = diff >= 0 ? Colors.green : Colors.red;
    final diffSign = diff >= 0 ? '+' : '';

    final isExpanded = _expandedId == s.id;

    final incomeBtns = templates.where((t) => t.sourceId == s.id).toList();
    final outgoingBtns = transferTemplates
        .where((t) => t.fromSourceId == s.id)
        .toList();
    final hasIncome = incomeBtns.isNotEmpty;
    final hasTransfer = outgoingBtns.isNotEmpty;

    final cardKey = _cardKeys.putIfAbsent(s.id!, () => GlobalKey());
    return Card(
      key: cardKey,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              final willExpand = !isExpanded;
              setState(() {
                _expandedId = willExpand ? s.id : null;
              });
              if (willExpand) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final ctx = cardKey.currentContext;
                  if (ctx == null) return;
                  Scrollable.ensureVisible(
                    ctx,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: 0.0,
                  );
                });

                TutorialService.instance.show(
                  context,
                  TutorialIds.accountsCardExpanded,
                );
              }
            },
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
                          'Edit income source',
                          style: TextStyle(fontSize: 17),
                        ),
                        onTap: () => Navigator.pop(context, 'edit'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.tune, size: 24),
                        title: const Text(
                          'Adjust balance',
                          style: TextStyle(fontSize: 17),
                        ),
                        onTap: () => Navigator.pop(context, 'adjust'),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                        title: const Text(
                          'Remove',
                          style: TextStyle(color: Colors.red, fontSize: 17),
                        ),
                        onTap: () => Navigator.pop(context, 'remove'),
                      ),
                    ],
                  ),
                ),
              );
              if (action == 'edit') _addOrEditAccount(existing: s);
              if (action == 'adjust') _adjustBalance(s);
              if (action == 'remove') _confirmRemove(s);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(s.color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(s.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Now: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),

                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatMoney(s.balance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(s.color),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              '$monthName start: ${formatMoney(s.monthlyStart)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            if (isFirst)
                              TutorialTarget(
                                id: TutorialTargetIds.accountsCardDiff,
                                child: Text(
                                  '$diffSign${formatMoney(diff)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: diffColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            else
                              Text(
                                '$diffSign${formatMoney(diff)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: diffColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FeatureStateIcon(
                            icon: Icons.flash_on,
                            active: true,
                            activeColor: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          _FeatureStateIcon(
                            icon: Icons.sync,
                            active: hasIncome,
                            activeColor: Colors.teal,
                          ),
                          const SizedBox(width: 4),
                          _FeatureStateIcon(
                            icon: Icons.swap_horiz,
                            active: hasTransfer,
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),
                      Text(
                        isExpanded ? 'tap to close' : 'tap to open',
                        style: TextStyle(
                          fontSize: 9,
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TutorialTarget(
                            id: TutorialTargetIds.accountsExpandedBtns,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _CreateChip(
                                  icon: Icons.flash_on,
                                  label: 'Quick add money',
                                  color: Colors.green,
                                  onTap: () => _quickAddMoney(s),
                                ),
                                _CreateChip(
                                  icon: Icons.sync,
                                  label: 'New recurring income',
                                  color: Colors.teal,
                                  onTap: () => _addOrEditTemplateForAccount(s),
                                ),
                                _CreateChip(
                                  icon: Icons.swap_horiz,
                                  label: 'New transfer',
                                  color: Colors.blue,
                                  onTap: () => _addOrEditTransferTemplate(
                                    lockedFromId: s.id,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (incomeBtns.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Recurring Income',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...incomeBtns.map(
                              (t) => _buildIncomeTemplateTile(t, cs),
                            ),
                          ],

                          if (outgoingBtns.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Transfers',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...outgoingBtns.map(
                              (t) => _buildTransferTemplateTile(t, cs),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  int? _preselectedSourceId;
  Future<void> _addOrEditTemplateForAccount(IncomeSource s) async {
    _preselectedSourceId = s.id;
    try {
      await _addOrEditTemplate();
    } finally {
      _preselectedSourceId = null;
    }
  }

  Widget _buildIncomeTemplateTile(IncomeTemplate t, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark
        ? Color.lerp(Colors.green, cs.surface, 0.78)!
        : Color.lerp(Colors.green, cs.surface, 0.88)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: tileBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _receiveIncome(t),
          onLongPress: () async {
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
                      leading: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 24,
                      ),
                      title: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 17),
                      ),
                      onTap: () => Navigator.pop(context, 'delete'),
                    ),
                  ],
                ),
              ),
            );
            if (action == 'edit') await _addOrEditTemplate(existing: t);
            if (action == 'delete') {
              await DatabaseHelper.instance.deleteIncomeTemplate(t.id!);
              _load();
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(t.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        t.isFixed ? formatMoney(t.amount) : 'Variable',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.isFixed ? 'Receive' : 'Enter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferTemplateTile(
    TransferTemplate t,
    ColorScheme cs, {
    bool incoming = false,
  }) {
    final fromSrc = _srcOf(t.fromSourceId);
    final toSrc = _srcOf(t.toSourceId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark
        ? Color.lerp(Colors.blue, cs.surface, 0.78)!
        : Color.lerp(Colors.blue, cs.surface, 0.88)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: incoming ? tileBg.withValues(alpha: 0.55) : tileBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _executeTransfer(t),
          onLongPress: () async {
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
                      leading: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 24,
                      ),
                      title: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 17),
                      ),
                      onTap: () => Navigator.pop(context, 'delete'),
                    ),
                  ],
                ),
              ),
            );
            if (action == 'edit') await _addOrEditTransferTemplate(existing: t);
            if (action == 'delete') {
              await DatabaseHelper.instance.deleteTransferTemplate(t.id!);
              _load();
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  fromSrc?.icon ?? '?',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(toSrc?.icon ?? '?', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${fromSrc?.name ?? '?'} → ${toSrc?.name ?? '?'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        t.isFixed ? formatMoney(t.amount) : 'Variable',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.isFixed ? 'Send' : 'Enter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CreateChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Material(
        color: color.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,

            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                Positioned(
                  top: 1,
                  right: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 1.5),
                    ),
                    child: Icon(Icons.add, size: 10, color: cs.surface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureStateIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  const _FeatureStateIcon({
    required this.icon,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: active
            ? activeColor.withValues(alpha: 0.18)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 16,
        color: active ? activeColor : cs.onSurface.withValues(alpha: 0.35),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? description;
  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: cs.primary, width: 2)
                : Border.all(color: cs.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  height: 1.2,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                        : cs.onSurface.withValues(alpha: 0.55),
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
