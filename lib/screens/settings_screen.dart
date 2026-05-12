import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../data/settings_service.dart';
import '../data/database_helper.dart';
import '../tutorial/learn_service.dart';
import '../tutorial/tutorial_ids.dart';
import '../tutorial/tutorial_service.dart';
import '../tutorial/tutorial_targets.dart';
import '../utils/currency_symbol.dart';
import '../utils/money_input.dart';
import '../widgets/live_icon.dart';
import '../widgets/main_shell.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _theme;
  late bool _useThousandSep;
  late bool _smartDecimals;

  @override
  void initState() {
    super.initState();
    _theme = themeModeNotifier.value;
    _useThousandSep = SettingsService.instance.useThousandSep;
    _smartDecimals = SettingsService.instance.smartDecimals;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TutorialService.instance.show(context, TutorialIds.settingsBackup);
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    await SettingsService.instance.setThemeMode(mode);
    themeModeNotifier.value = mode;
    setState(() => _theme = mode);
  }

  Future<void> _setBottomBarMode(BottomBarMode mode) async {
    await SettingsService.instance.setBottomBarMode(mode);
    bottomBarModeNotifier.value = mode;
    if (mounted) setState(() {});
  }

  IconData _numberFormatIcon(bool sep, bool smart) {
    if (sep && smart) return Icons.auto_awesome;
    if (sep && !smart) return Icons.format_list_numbered;
    if (!sep && smart) return Icons.short_text;
    return Icons.pin_outlined;
  }

  Future<void> _resetAllData() async {
    Widget warningBox({
      required BuildContext ctx,
      required String message,
      required Color accent,
      required IconData icon,
    }) {
      final cs = Theme.of(ctx).colorScheme;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?', style: TextStyle(fontSize: 20)),
        content: warningBox(
          ctx: ctx,
          accent: Colors.red,
          icon: Icons.delete_forever,
          message:
              'This will permanently delete all your income sources, '
              'transactions, categories, and settings. This cannot be '
              'undone.',
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirm1 != true) return;
    if (!mounted) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?', style: TextStyle(fontSize: 20)),
        content: warningBox(
          ctx: ctx,
          accent: Colors.red,
          icon: Icons.warning_amber_rounded,
          message:
              'All data will be gone. Export a backup first if you want '
              'to keep it.',
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
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirm2 != true) return;

    await DatabaseHelper.instance.resetAllData();

    MainShell.refreshAllPages();
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
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
              border: Border.all(color: Colors.red, width: 1.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'All data has been reset',
                  style: TextStyle(
                    color: Colors.red,
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
    Navigator.pop(context, true);
  }

  Future<void> _replayTutorial() async {
    await LearnService.instance.resetAll();
    await TutorialService.instance.resetAll();
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
                const Icon(Icons.refresh, size: 16, color: orange),
                const SizedBox(width: 8),
                const Text(
                  'Learn progress reset',
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        leadingWidth: 80,
        centerTitle: true,
        leading: buildModalBackButton(context),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SpinningIcon(
              icon: Icons.settings_outlined,
              size: 22,
              period: Duration(seconds: 18),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Settings',
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _staggered(0, _backupSection(cs)),
          const SizedBox(height: 20),
          _staggered(80, _personalizationSection(cs)),
          const SizedBox(height: 20),
          _staggered(160, _helpSection(cs)),
          const SizedBox(height: 20),
          _staggered(240, _aboutSection(cs)),
        ],
      ),
    );
  }

  Widget _staggered(int ms, Widget child) => AppearOnMount(
    delay: Duration(milliseconds: ms),
    duration: const Duration(milliseconds: 420),
    fromScale: 0.96,
    child: child,
  );

  Widget _backupSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Backup & Data', cs),
        Card(
          child: Column(
            children: [
              TutorialTarget(
                id: TutorialTargetIds.settingsBackupTile,
                child: ListTile(
                  leading: const PulsingGlowIcon(
                    icon: Icons.backup_outlined,
                    size: 26,
                    color: Colors.indigo,
                    glowColor: Colors.indigo,
                    maxBlur: 10,
                    minOpacity: 0.15,
                    maxOpacity: 0.45,
                  ),
                  title: const Text(
                    'Backup & Restore',
                    style: TextStyle(fontSize: 17),
                  ),
                  subtitle: const Text(
                    'Export or restore your data',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  ),
                ),
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: cs.outline),
              ListTile(
                leading: const PulsingGlowIcon(
                  icon: Icons.delete_forever_outlined,
                  size: 26,
                  color: Colors.red,
                  glowColor: Colors.red,
                  maxBlur: 14,
                  minOpacity: 0.20,
                  maxOpacity: 0.55,
                  duration: Duration(milliseconds: 1400),
                ),
                title: const Text(
                  'Reset all data',
                  style: TextStyle(fontSize: 17, color: Colors.red),
                ),
                subtitle: const Text(
                  'Permanently delete everything',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: _resetAllData,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showSupportDialog() async {
    const supportEmail = 'glosper.dev@gmail.com';
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Support development'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kovira is free, ad-free, and built solo. If you find it useful '
                'and would like to support continued development, get in touch.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: SelectableText(
                        supportEmail,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy email',
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: supportEmail),
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Email copied'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The app stays free either way.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _personalizationSection(ColorScheme cs) {
    IconData themeIcon() {
      switch (_theme) {
        case ThemeMode.light:
          return Icons.light_mode;
        case ThemeMode.dark:
          return Icons.dark_mode;
        case ThemeMode.system:
          return Icons.brightness_auto;
      }
    }

    final divider = Divider(
      height: 1,
      color: cs.outline.withValues(alpha: 0.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Personalization', cs),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Icon(
                        themeIcon(),
                        key: ValueKey(_theme),
                        size: 24,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Theme', style: TextStyle(fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _themeBtn('Light', ThemeMode.light, cs),
                    const SizedBox(width: 8),
                    _themeBtn('Dark', ThemeMode.dark, cs),
                    const SizedBox(width: 8),
                    _themeBtn('Auto', ThemeMode.system, cs),
                  ],
                ),
                const SizedBox(height: 18),
                divider,
                const SizedBox(height: 14),
                Row(
                  children: [
                    ValueListenableBuilder<BottomBarMode>(
                      valueListenable: bottomBarModeNotifier,
                      builder: (_, mode, _) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: Tween<double>(
                            begin: 0.75,
                            end: 1,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          mode == BottomBarMode.tabs
                              ? Icons.touch_app_outlined
                              : Icons.view_carousel_outlined,
                          key: ValueKey(mode),
                          size: 24,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Navigation', style: TextStyle(fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<BottomBarMode>(
                  valueListenable: bottomBarModeNotifier,
                  builder: (_, mode, _) => Row(
                    children: [
                      _barModeBtn('Tabs', BottomBarMode.tabs, mode, cs),
                      const SizedBox(width: 8),
                      _barModeBtn(
                        'Dedicated',
                        BottomBarMode.dedicated,
                        mode,
                        cs,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                divider,
                const SizedBox(height: 14),
                ValueListenableBuilder<String>(
                  valueListenable: handednessNotifier,
                  builder: (_, hand, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              transitionBuilder: (child, anim) =>
                                  RotationTransition(
                                    turns: Tween<double>(
                                      begin: 0.75,
                                      end: 1,
                                    ).animate(anim),
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                              child: Icon(
                                hand == 'left'
                                    ? Icons.swipe_left_outlined
                                    : Icons.swipe_right_outlined,
                                key: ValueKey(hand),
                                size: 24,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Handedness',
                              style: TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _handednessBtn('Left', 'left', hand, cs),
                            const SizedBox(width: 8),
                            _handednessBtn('Right', 'right', hand, cs),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                divider,
                const SizedBox(height: 14),
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Icon(
                        _numberFormatIcon(_useThousandSep, _smartDecimals),
                        key: ValueKey('${_useThousandSep}_$_smartDecimals'),
                        size: 24,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Number format', style: TextStyle(fontSize: 17)),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                      child: Builder(
                        key: ValueKey(
                          '${_useThousandSep}_${_smartDecimals}_preview',
                        ),
                        builder: (bctx) {
                          final dark =
                              Theme.of(bctx).brightness == Brightness.dark;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.green.withValues(alpha: 0.28)
                                  : Colors.green.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: dark
                                    ? Colors.green.withValues(alpha: 0.65)
                                    : Colors.green.withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              formatMoney(123450),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: dark
                                    ? const Color(0xFFA5E8A8)
                                    : const Color(0xFF1B5E20),
                                fontFamily: 'monospace',
                                letterSpacing: 0.2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Thousand separator',
                    style: TextStyle(fontSize: 15),
                  ),
                  value: _useThousandSep,
                  onChanged: (v) async {
                    await SettingsService.instance.setUseThousandSep(v);
                    if (mounted) setState(() => _useThousandSep = v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Smart decimals',
                    style: TextStyle(fontSize: 15),
                  ),
                  value: _smartDecimals,
                  onChanged: (v) async {
                    await SettingsService.instance.setSmartDecimals(v);
                    if (mounted) setState(() => _smartDecimals = v);
                  },
                ),
                const SizedBox(height: 6),
                divider,
                const SizedBox(height: 14),
                ValueListenableBuilder<int>(
                  valueListenable: currencySymbolNotifier,
                  builder: (_, _, _) => _currencyRow(cs),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _currencyRow(ColorScheme cs) {
    final override = SettingsService.instance.currencyOverride;
    final auto = autoDetectedCurrencySymbol();
    final shown = override ?? auto;
    final label = override == null ? 'Auto · $auto' : 'Manual override';
    return InkWell(
      onTap: _openCurrencyPicker,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.attach_money_outlined, size: 24, color: cs.primary),
            const SizedBox(width: 16),
            const Text('Currency', style: TextStyle(fontSize: 17)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shown,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCurrencyPicker() async {
    final cs = Theme.of(context).colorScheme;
    final auto = autoDetectedCurrencySymbol();
    final searchCtrl = TextEditingController();
    final entries = targetMarketSymbols.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final query = searchCtrl.text.trim().toUpperCase();
          final filtered = query.isEmpty
              ? entries
              : entries
                    .where(
                      (e) =>
                          e.key.contains(query) ||
                          e.value.toUpperCase().contains(query),
                    )
                    .toList();
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Currency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          await SettingsService.instance.setCurrencyOverride(
                            null,
                          );
                          currencySymbolNotifier.value++;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text('Use auto ($auto)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setSheet(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by country code or symbol',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        final selected =
                            SettingsService.instance.currencyOverride ==
                            e.value;
                        return ListTile(
                          dense: true,
                          leading: SizedBox(
                            width: 38,
                            child: Center(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: selected
                              ? Icon(Icons.check, color: cs.primary)
                              : null,
                          onTap: () async {
                            await SettingsService.instance.setCurrencyOverride(
                              e.value,
                            );
                            currencySymbolNotifier.value++;
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _handednessBtn(
    String label,
    String value,
    String current,
    ColorScheme cs,
  ) {
    final sel = current == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? cs.surfaceContainerHighest
        : Color.lerp(cs.primary, Colors.white, 0.78)!;
    final unselectedBorder = isDark
        ? Colors.transparent
        : Color.lerp(cs.primary, Colors.white, 0.55)!;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setHandedness(value),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: sel ? 1.04 : 1.0,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? cs.primary : unselectedBg,
              borderRadius: BorderRadius.circular(10),
              border: sel
                  ? null
                  : Border.all(color: unselectedBorder, width: 1),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  value == 'left'
                      ? Icons.back_hand_outlined
                      : Icons.front_hand_outlined,
                  size: 18,
                  color: sel ? cs.onPrimary : cs.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: sel ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setHandedness(String value) async {
    await SettingsService.instance.setHandedness(value);
    handednessNotifier.value = value;
  }

  Widget _barModeBtn(
    String label,
    BottomBarMode mode,
    BottomBarMode current,
    ColorScheme cs,
  ) {
    final sel = current == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? cs.surfaceContainerHighest
        : Color.lerp(cs.primary, Colors.white, 0.78)!;
    final unselectedBorder = isDark
        ? Colors.transparent
        : Color.lerp(cs.primary, Colors.white, 0.55)!;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setBottomBarMode(mode),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: sel ? 1.04 : 1.0,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? cs.primary : unselectedBg,
              borderRadius: BorderRadius.circular(10),
              border: sel
                  ? null
                  : Border.all(color: unselectedBorder, width: 1),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: sel ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _helpSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Help', cs),
        Card(
          child: ListTile(
            leading: const PulsingGlowIcon(
              icon: Icons.school_outlined,
              size: 26,
              color: Colors.amber,
              glowColor: Colors.amber,
              maxBlur: 10,
              minOpacity: 0.18,
              maxOpacity: 0.50,
            ),
            title: const Text(
              'Reset learn progress',
              style: TextStyle(fontSize: 17),
            ),
            subtitle: const Text(
              'Bring the Learn icon back on every page',
              style: TextStyle(fontSize: 13),
            ),
            trailing: const Icon(Icons.refresh),
            onTap: _replayTutorial,
          ),
        ),
      ],
    );
  }

  Widget _aboutSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('About', cs),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const PulsingGlowIcon(
                  icon: Icons.favorite_border,
                  size: 26,
                  color: Color(0xFFE91E63),
                  glowColor: Color(0xFFE91E63),
                  maxBlur: 12,
                  minOpacity: 0.18,
                  maxOpacity: 0.50,
                  duration: Duration(milliseconds: 1100),
                ),
                title: const Text(
                  'Support development',
                  style: TextStyle(fontSize: 17),
                ),
                subtitle: const Text(
                  'Optional — Kovira stays free',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                onTap: _showSupportDialog,
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: cs.outline),
              ListTile(
                leading: const _GlowingLogo(color: Color(0xFF26A69A)),
                title: const Text(
                  'Kovira',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Personal ledger app',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.55),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'BETA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE65100),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'v3.0.2',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _themeBtn(String label, ThemeMode mode, ColorScheme cs) {
    final sel = _theme == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? cs.surfaceContainerHighest
        : Color.lerp(cs.primary, Colors.white, 0.78)!;
    final unselectedBorder = isDark
        ? Colors.transparent
        : Color.lerp(cs.primary, Colors.white, 0.55)!;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTheme(mode),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: sel ? 1.04 : 1.0,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? cs.primary : unselectedBg,
              borderRadius: BorderRadius.circular(10),
              border: sel
                  ? null
                  : Border.all(color: unselectedBorder, width: 1),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: sel ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingLogo extends StatefulWidget {
  final Color color;
  const _GlowingLogo({required this.color});

  @override
  State<_GlowingLogo> createState() => _GlowingLogoState();
}

class _GlowingLogoState extends State<_GlowingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final alpha = 0.18 + 0.32 * t;
        final blur = 4 + 14 * t;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: alpha),
                blurRadius: blur,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/logo.png', width: 36, height: 36),
          ),
        );
      },
    );
  }
}
