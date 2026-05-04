import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/bill_template.dart';
import '../models/category.dart';
import '../models/income_source.dart';
import '../models/ledger_entry.dart';
import '../widgets/category_icon.dart';
import '../utils/emoji_suggestions.dart';
import '../utils/currency_symbol.dart';
import '../utils/money_input.dart';
import '../widgets/live_icon.dart';
import '../widgets/big_action_button.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';
import 'settings_screen.dart';
import '../tutorial/tutorial_targets.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_service.dart';

const billIconPalette = [
  '🧾',
  '💡',
  '⚡',
  '🚰',
  '🔥',
  '📶',
  '📺',
  '🌐',
  '🏠',
  '🏢',
  '🚗',
  '⛽',
  '📱',
  '☎️',
  '🎓',
  '📚',
  '💳',
  '💰',
  '💊',
  '🏥',
  '🍽️',
  '🛒',
  '🎮',
  '🎬',
  '🏋️',
  '🧘',
  '🎵',
  '💼',
  '🧹',
  '🔧',
  '🐶',
  '✂️',
];

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});
  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> implements ShellRefreshable {
  @override
  void refreshFromShell() => _load();
  List<BillTemplate> bills = [];
  List<Category> categories = [];
  List<IncomeSource> sources = [];
  final FocusNode _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    bills = await db.getBillTemplates();
    categories = await db.getCategories();
    sources = await db.getActiveSources();
    setState(() {});
  }

  Category? _catOf(int id) => categories.where((c) => c.id == id).firstOrNull;

  Future<int?> _createCategoryInline() async {
    final nameCtrl = TextEditingController();
    String selectedEmoji = '';
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
    final newId = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('New Category', style: TextStyle(fontSize: 20)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 17),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      hintText: 'e.g. Gym, Fuel, Rent',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Pick an emoji (optional — leave blank to use first letter):',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (selectedEmoji.isNotEmpty &&
                      suggestionsForEmoji(selectedEmoji).isNotEmpty) ...[
                    Text(
                      'Quick names for $selectedEmoji:',
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
                      children: suggestionsForEmoji(selectedEmoji).map((s) {
                        final exists = categories.any(
                          (c) => c.name.toLowerCase() == s.toLowerCase(),
                        );
                        if (exists) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => setDlg(() => nameCtrl.text = s),
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
                                  selectedEmoji,
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
                                  Icons.arrow_upward,
                                  size: 12,
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
                          final isSel = selectedEmoji == e;
                          return GestureDetector(
                            onTap: () => setDlg(() {
                              selectedEmoji = isSel ? '' : e;
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Category name cannot be empty.'),
                    ),
                  );
                  return;
                }
                if (categories.any(
                  (c) => c.name.toLowerCase() == name.toLowerCase(),
                )) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('A category named "$name" already exists.'),
                    ),
                  );
                  return;
                }
                final finalIcon = selectedEmoji.isEmpty
                    ? name[0].toUpperCase()
                    : selectedEmoji;
                int? catColor;
                if (finalIcon.length == 1 &&
                    RegExp(r'[A-Z]').hasMatch(finalIcon)) {
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
                  final usedColors = categories
                      .where((x) => x.icon == finalIcon)
                      .map((x) => x.color ?? 0)
                      .toSet();
                  catColor = palette.firstWhere(
                    (col) => !usedColors.contains(col),
                    orElse: () => palette[categories.length % palette.length],
                  );
                }
                final id = await DatabaseHelper.instance.insertCategory(
                  Category(name: name, icon: finalIcon, color: catColor),
                );
                if (ctx.mounted) Navigator.pop(ctx, id);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (newId != null) {
      categories = await DatabaseHelper.instance.getCategories();
      if (mounted) setState(() {});
    }
    return newId;
  }

  Future<void> _addOrEditBill({BillTemplate? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null && existing.amount > 0
          ? formatMoneyCompact(existing.amount)
          : '',
    );
    final nameFocus = FocusNode();
    bool isFixed = existing?.isFixed ?? true;
    String selectedIcon = (existing?.icon ?? '').isEmpty
        ? '🧾'
        : existing!.icon;
    int? selectedCatId =
        existing?.categoryId ??
        (categories
                .where((c) => c.name == 'Bills')
                .map((c) => c.id)
                .firstOrNull ??
            (categories.isNotEmpty ? categories.first.id : null));
    String? nameError;
    String? amountError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          insetPadding: TutorialService.instance.dialogInsetsFor(
            TutorialIds.billDialogFields,
          ),
          title: Text(
            existing == null ? 'New Bill' : 'Edit Bill',
            style: const TextStyle(fontSize: 20),
          ),
          content: SizedBox(
            width: 320,
            child: TutorialFireOnMount(
              messageId: TutorialIds.billDialogFields,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TutorialTarget(
                      id: TutorialTargetIds.billDialogName,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              EmojiPlaceholderBox(
                                value: selectedIcon,
                                tint: Colors.orange,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: nameCtrl,
                                  focusNode: nameFocus,
                                  autofocus: existing == null,
                                  style: const TextStyle(fontSize: 17),
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    hintText: 'Rent, Electricity…',
                                    errorText: nameError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InlineEmojiPalette(
                            palette: billIconPalette,
                            selected: selectedIcon,
                            tint: Colors.orange,
                            onPicked: (e) => setDlg(() => selectedIcon = e),
                          ),
                        ],
                      ),
                    ),
                    if (suggestionsForEmoji(selectedIcon).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Quick names for $selectedIcon:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: suggestionsForEmoji(selectedIcon)
                            .map(
                              (s) => GestureDetector(
                                onTap: () {
                                  setDlg(() => nameCtrl.text = s);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _amountFocus.requestFocus();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.orange.withValues(
                                        alpha: 0.4,
                                      ),
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
                    const SizedBox(height: 16),
                    const Text('Type', style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Fixed amount'),
                          selected: isFixed,
                          onSelected: (_) => setDlg(() => isFixed = true),
                        ),
                        ChoiceChip(
                          label: const Text('Variable'),
                          selected: !isFixed,
                          onSelected: (_) => setDlg(() => isFixed = false),
                        ),
                      ],
                    ),
                    if (isFixed) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountCtrl,
                        focusNode: _amountFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        inputFormatters: [MoneyInputFormatter()],
                        style: const TextStyle(fontSize: 17),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: amountPrefixIcon(context),
                          errorText: amountError,
                        ),
                      ),
                    ],
                  ],
                ),
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
                final name = nameCtrl.text.trim();
                final amt = parseCents(amountCtrl.text) ?? 0;
                setDlg(() {
                  nameError = name.isEmpty ? 'Give the bill a name' : null;
                  amountError = (isFixed && amt <= 0)
                      ? 'Enter an amount'
                      : null;
                });
                if (nameError != null) {
                  nameFocus.requestFocus();
                  return;
                }
                if (amountError != null) {
                  _amountFocus.requestFocus();
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(
                existing == null ? 'Next →' : 'Save',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();

    int? catId = await _pickCategory(initial: selectedCatId);
    if (catId == null) return;

    final bill = BillTemplate(
      id: existing?.id,
      name: name,
      icon: selectedIcon,
      categoryId: catId,
      sourceId: 0,
      amount: isFixed ? (parseCents(amountCtrl.text) ?? 0) : 0,
      isFixed: isFixed,
    );
    final wasFirstBill = existing == null && bills.isEmpty;
    if (existing == null) {
      await DatabaseHelper.instance.addBillTemplate(bill);
    } else {
      await DatabaseHelper.instance.updateBillTemplate(bill);
    }
    await _load();
    if (!mounted) return;
    if (wasFirstBill) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        TutorialService.instance.show(context, TutorialIds.billsCardTapHint);
      });
    }
  }

  Future<int?> _pickCategory({int? initial}) async {
    int? selected = initial;
    return showDialog<int?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Choose category', style: TextStyle(fontSize: 20)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final navigator = Navigator.of(ctx);
                    final newId = await _createCategoryInline();
                    if (newId != null && mounted) {
                      categories = await DatabaseHelper.instance
                          .getCategories();
                      if (!mounted) return;
                      navigator.pop(newId);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: Theme.of(ctx).colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Create new category',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: categories.map((cat) {
                        final isSel = cat.id == selected;
                        return InkWell(
                          onTap: () => setDlg(() => selected = cat.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isSel
                                  ? Theme.of(ctx).colorScheme.primaryContainer
                                  : Theme.of(
                                      ctx,
                                    ).colorScheme.surfaceContainerHighest,
                              border: isSel
                                  ? Border.all(
                                      color: Theme.of(ctx).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                RawCategoryIcon(
                                  icon: cat.icon,
                                  color: cat.color,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSel
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSel
                                          ? Theme.of(
                                              ctx,
                                            ).colorScheme.onPrimaryContainer
                                          : Theme.of(ctx).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                if (isSel)
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(ctx).colorScheme.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(ctx, selected),
              child: const Text('Save bill', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordBill(BillTemplate bill) async {
    if (sources.isEmpty) return;

    int recordAmount = bill.amount;
    IncomeSource? selectedSrc = sources.first;

    if (!bill.isFixed) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Text(
            '${bill.icon} ${bill.name}',
            style: const TextStyle(fontSize: 20),
          ),

          content: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
                  inputFormatters: [MoneyInputFormatter()],
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => Navigator.pop(context, true),
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    isDense: true,
                    prefixIcon: amountPrefixIcon(context, fontSize: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Next', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
      if (ok != true) return;
      recordAmount = parseCents(ctrl.text) ?? 0;
    }

    if (recordAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Text(
            '${bill.icon} ${bill.name}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20),
          ),
          content: SizedBox(
            width: 280,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording: ${formatMoney(recordAmount)}',
                    style: const TextStyle(fontSize: 16, color: Colors.orange),
                  ),
                  const SizedBox(height: 14),
                  const Text('Deduct from', style: TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  ...sources.map((s) {
                    final sel = s.id == selectedSrc?.id;
                    return GestureDetector(
                      onTap: () => setDlg(() => selectedSrc = s),
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
                            Expanded(
                              child: Text(
                                s.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatMoney(s.balance),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Record', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    if (selectedSrc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an income source to pay from.')),
      );
      return;
    }

    await DatabaseHelper.instance.addExpense(
      LedgerEntry(
        type: 'expense',
        categoryId: bill.categoryId,
        sourceId: selectedSrc!.id!,
        amount: recordAmount,
        name: bill.name,
        date: DateTime.now(),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${bill.icon} ${bill.name} — '
          '${formatMoney(recordAmount)} recorded from ${selectedSrc!.name}',
        ),
        backgroundColor: Colors.green,
      ),
    );
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
            PulsingGlowIcon(
              icon: Icons.receipt_long,
              size: 22,
              color: Colors.orange,
              glowColor: Colors.orange,
              maxBlur: 10,
              minOpacity: 0.10,
              maxOpacity: 0.40,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Bills',
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
      body: bills.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧾', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text(
                      'No bills set up yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your rent, electricity, internet — anything you spend on regularly.',
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  'Tap to record, long-press to edit',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                ...bills.asMap().entries.map((entry) {
                  final b = entry.value;
                  final cat = _catOf(b.categoryId);
                  final card = Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: Text(
                        b.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(
                        b.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${cat?.icon ?? ''} ${cat?.name ?? ''}'
                        '${b.isFixed ? ' · ${formatMoney(b.amount)}' : ' · variable'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          b.isFixed ? 'Record' : 'Enter',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      onTap: () => _recordBill(b),
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
                                  onTap: () => Navigator.pop(context, 'delete'),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (action == 'edit') await _addOrEditBill(existing: b);
                        if (action == 'delete') {
                          await DatabaseHelper.instance.deleteBillTemplate(
                            b.id!,
                          );
                          _load();
                        }
                      },
                    ),
                  );
                  return entry.key == 0
                      ? TutorialTarget(
                          id: TutorialTargetIds.billsFirstCard,
                          child: card,
                        )
                      : card;
                }),
              ],
            ),
      bottomNavigationBar: TutorialTarget(
        id: TutorialTargetIds.billsAddBtn,
        child: BigActionButton(
          icon: Icons.receipt_long,
          tint: Colors.orange,
          tooltip: 'Add bill · swipe up for menu',
          onTap: _addOrEditBill,
          onSwipeUp: () =>
              showMainMenuSheet(context, current: MainScreen.bills),

          onLongPress: () => MainShell.maybeOf(
            context,
          )?.gotoPage(MainScreen.dashboard, animate: false, fade: true),
        ),
      ),
    );
  }
}
