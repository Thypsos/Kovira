import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../tutorial/learn_button.dart';
import '../models/category.dart';
import '../utils/currency_symbol.dart';
import '../utils/emoji_suggestions.dart';
import '../utils/money_input.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/live_icon.dart';
import '../widgets/big_action_button.dart';
import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';
import 'settings_screen.dart';
import '../tutorial/tutorial_targets.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_service.dart';

class CategoryEditorScreen extends StatefulWidget {
  const CategoryEditorScreen({super.key});
  @override
  State<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

const categoryIconPalette = [
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
  '📦',
];

class _CategoryEditorScreenState extends State<CategoryEditorScreen>
    implements ShellRefreshable, ShellPrimaryAction {
  @override
  void refreshFromShell() => _load();

  @override
  void firePrimaryAction() => _addCategory();

  @override
  bool get hasData => categories.length > 2;

  List<Category> categories = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    categories = await DatabaseHelper.instance.getCategories();
    setState(() {});
  }

  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    final nameFocus = FocusNode();
    String icon = '📦';
    String? nameError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sl) => AlertDialog(
          insetPadding: TutorialService.instance.dialogInsetsFor(
            TutorialIds.catDialogFields,
          ),
          title: const Center(
            child: Text('Add tag', style: TextStyle(fontSize: 20)),
          ),
          content: SizedBox(
            width: 320,
            child: TutorialFireOnMount(
              messageId: TutorialIds.catDialogFields,
              pendingDialogKey: 'tag',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TutorialTarget(
                    id: TutorialTargetIds.catDialogName,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            EmojiPickerButton(
                              value: icon,
                              tint: Colors.purple,
                              palette: categoryIconPalette,
                              onPicked: (e) => sl(() => icon = e),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: nameCtrl,
                                focusNode: nameFocus,
                                autofocus: true,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(fontSize: 17),
                                decoration: InputDecoration(
                                  labelText: 'Tag name',
                                  hintText: 'e.g. Gym, Fuel, Rent',
                                  errorText: nameError,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InlineEmojiPalette(
                          palette: categoryIconPalette,
                          selected: icon,
                          tint: Colors.purple,
                          onPicked: (e) => sl(() => icon = e),
                        ),
                      ],
                    ),
                  ),
                  if (suggestionsForEmoji(icon).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Quick names for $icon:',
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
                      children: suggestionsForEmoji(icon)
                          .map(
                            (s) => GestureDetector(
                              onTap: () => sl(() => nameCtrl.text = s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.purple.withValues(alpha: 0.4),
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
              onPressed: () {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) {
                  sl(() => nameError = 'Give the tag a name');
                  nameFocus.requestFocus();
                  return;
                }
                if (categories.any(
                  (c) => c.name.toLowerCase() == n.toLowerCase(),
                )) {
                  sl(() => nameError = 'A tag with that name already exists');
                  nameFocus.requestFocus();
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();

    int? catColor;
    if (icon.length == 1 && RegExp(r'[A-Z]').hasMatch(icon)) {
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
          .where((x) => x.icon == icon)
          .map((x) => x.color ?? 0)
          .toSet();
      catColor = palette.firstWhere(
        (col) => !usedColors.contains(col),
        orElse: () => palette[categories.length % palette.length],
      );
    }
    final wasFirstCustom = !categories.any((c) => !_isLocked(c));
    await DatabaseHelper.instance.insertCategory(
      Category(name: name, icon: icon, color: catColor),
    );
    await _load();
    if (!mounted) return;
    if (wasFirstCustom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        TutorialService.instance.show(context, TutorialIds.catsCardTapHint);
      });
    }
  }

  Future<void> _deleteCategory(Category c) async {
    try {
      await DatabaseHelper.instance.deleteCategory(c.id!);
      _load();
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('IN_USE')) {
        final uncat = categories.firstWhere(
          (cat) => cat.name == 'Uncategorized',
        );
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              'Remove "${c.name}"?',
              style: const TextStyle(fontSize: 20),
            ),
            content: const Text(
              'Entries will be moved to Uncategorized. History stays intact.',
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
                child: const Text('Move & Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await DatabaseHelper.instance.deleteCategoryAndReassign(
            fromCategoryId: c.id!,
            toCategoryId: uncat.id!,
          );
          _load();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uncategorized cannot be deleted.')),
        );
      }
    }
  }

  bool _isLocked(Category c) =>
      c.name == 'General' || c.name == 'Bills' || c.name == 'Uncategorized';

  Future<void> _showCategoryActions(Category c) async {
    final locked = _isLocked(c);
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(sheetCtx).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(c.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.lock,
                      size: 14,
                      color: Theme.of(
                        sheetCtx,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename / change icon'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _editCategory(c);
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: const Text('Set monthly budget'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _setBudget(c);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: locked ? Theme.of(sheetCtx).disabledColor : Colors.red,
              ),
              title: Text(
                locked ? 'Default — cannot delete' : 'Delete',
                style: TextStyle(
                  color: locked ? Theme.of(sheetCtx).disabledColor : Colors.red,
                ),
              ),
              enabled: !locked,
              onTap: locked
                  ? null
                  : () {
                      Navigator.pop(sheetCtx);
                      _deleteCategory(c);
                    },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _setBudget(Category c) async {
    final current = await DatabaseHelper.instance.getBudgetForCategory(c.id!);
    if (!mounted) return;
    final ctrl = TextEditingController(
      text: current > 0 ? formatMoneyCompact(current) : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(c.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${c.name} · monthly budget',
                style: const TextStyle(fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set the most you want to spend on this category in a month. '
              'Leave blank to clear the budget.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Amount',
                prefixIcon: amountPrefixIcon(ctx, fontSize: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          if (current > 0)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await DatabaseHelper.instance.setBudgetForCategory(c.id!, 0);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Clear'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final cents = parseCents(ctrl.text) ?? 0;
    await DatabaseHelper.instance.setBudgetForCategory(c.id!, cents);
    if (mounted) setState(() {});
  }

  Future<void> _editCategory(Category c) async {
    final nameCtrl = TextEditingController(text: c.name);
    String selIcon = c.icon;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sl) => AlertDialog(
          title: const Center(
            child: Text('Edit tag', style: TextStyle(fontSize: 20)),
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
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Center(
                          widthFactor: 1,
                          child: selIcon.isEmpty
                              ? Icon(
                                  Icons.add_reaction_outlined,
                                  size: 22,
                                  color: Theme.of(ctx).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                )
                              : Text(
                                  selIcon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            const [
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
                            ].map((e) {
                              final sel = selIcon == e;
                              return GestureDetector(
                                onTap: () => sl(() => selIcon = sel ? '' : e),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? Theme.of(ctx).colorScheme.primary
                                              .withValues(alpha: 0.2)
                                        : Theme.of(
                                            ctx,
                                          ).colorScheme.surfaceContainerHighest,
                                    border: sel
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
    final newName = nameCtrl.text.trim();
    if (newName.isEmpty) return;
    final newIcon = selIcon.isEmpty ? newName[0].toUpperCase() : selIcon;
    await DatabaseHelper.instance.updateCategoryNameIcon(
      c.id!,
      newName,
      newIcon,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
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
            const PulsingGlowIcon(
              icon: Icons.category_outlined,
              size: 22,
              color: Colors.purple,
              glowColor: Colors.purple,
              maxBlur: 10,
              minOpacity: 0.10,
              maxOpacity: 0.40,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Tags',
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const LearnButton(page: MainScreen.categories),
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, c) {
            final n = categories.length;
            if (n == 0) {
              return Center(
                child: Text(
                  'No tags yet',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              );
            }

            final w = c.maxWidth - 24;
            final h = c.maxHeight - 24;
            double bestSize = 0;
            for (int col = 1; col <= n; col++) {
              final rows = (n / col).ceil();
              final cell = math.min(w / col, h / rows);
              if (cell > bestSize) bestSize = cell;
            }
            final iconSize = (bestSize * 0.42).clamp(22.0, 60.0);
            final tileFontSize = (bestSize * 0.10).clamp(10.0, 16.0);
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.asMap().entries.map((entry) {
                          final cat = entry.value;
                          final locked = _isLocked(cat);
                          final tile = GestureDetector(
                            onLongPress: () => _showCategoryActions(cat),
                            onTap: () => _showCategoryActions(cat),
                            child: SizedBox(
                              width: bestSize - 8,
                              height: bestSize - 8,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: bestSize * 0.65,
                                        height: bestSize * 0.65,
                                        decoration: BoxDecoration(
                                          color: locked
                                              ? Colors.purple.withValues(
                                                  alpha: 0.18,
                                                )
                                              : cs.surfaceContainerHighest,
                                          border: locked
                                              ? Border.all(
                                                  color: Colors.purple,
                                                  width: 2,
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            bestSize * 0.14,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          cat.icon,
                                          style: TextStyle(fontSize: iconSize),
                                        ),
                                      ),
                                      if (locked)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: Colors.purple,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.lock,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Flexible(
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: tileFontSize,
                                        fontWeight: locked
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: cs.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          return entry.key == 0
                              ? TutorialTarget(
                                  id: TutorialTargetIds.catsFirstCard,
                                  child: tile,
                                )
                              : tile;
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: shellBottomBar(
        TutorialTarget(
          id: TutorialTargetIds.categoriesAddBtn,
          child: BigActionButton(
            icon: Icons.category_outlined,
            tint: Colors.purple,
            tooltip: 'Add tag · swipe up for menu',
            onTap: _addCategory,
            onSwipeUp: () =>
                showMainMenuSheet(context, current: MainScreen.categories),
            onLongPress: () => MainShell.maybeOf(
              context,
            )?.gotoPage(MainScreen.dashboard, animate: false, fade: true),
          ),
        ),
        current: MainScreen.categories,
      ),
    );
  }
}
