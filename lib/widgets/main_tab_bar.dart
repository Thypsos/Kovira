import 'package:flutter/material.dart';
import '../screens/records_screen.dart';
import 'main_menu_sheet.dart';
import 'main_shell.dart';

class MainTabBar extends StatelessWidget {
  final MainScreen current;
  final void Function(MainScreen target)? onTabTap;
  final bool transparentBg;
  const MainTabBar({
    super.key,
    required this.current,
    this.onTabTap,
    this.transparentBg = false,
  });

  static const List<MainScreen> _order = [
    MainScreen.records,
    MainScreen.budget,
    MainScreen.accounts,
    MainScreen.dashboard,
    MainScreen.bills,
    MainScreen.categories,
    MainScreen.goals,
  ];

  String _shortLabel(MainScreen s) {
    switch (s) {
      case MainScreen.records:
        return 'Records';
      case MainScreen.budget:
        return 'Budget';
      case MainScreen.accounts:
        return 'Sources';
      case MainScreen.dashboard:
        return 'Expenses';
      case MainScreen.bills:
        return 'Bills';
      case MainScreen.categories:
        return 'Tags';
      case MainScreen.goals:
        return 'Goals';
    }
  }

  IconData _idleIcon(MainScreen s) {
    switch (s) {
      case MainScreen.records:
        return Icons.history;
      case MainScreen.budget:
        return Icons.pie_chart_outline;
      case MainScreen.accounts:
        return Icons.account_balance_wallet_outlined;
      case MainScreen.dashboard:
        return Icons.shopping_bag_outlined;
      case MainScreen.bills:
        return Icons.receipt_long;
      case MainScreen.categories:
        return Icons.category_outlined;
      case MainScreen.goals:
        return Icons.flag_outlined;
    }
  }

  Color _color(MainScreen s) => MainScreenChrome.of(s).color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: transparentBg ? Colors.transparent : cs.surface,
      elevation: transparentBg ? 0 : 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _order
                .map(
                  (s) => Expanded(
                    child: _Tab(
                      page: s,
                      active: s == current,
                      color: _color(s),
                      idleIcon: _idleIcon(s),
                      label: _shortLabel(s),
                      isDark: isDark,
                      customTap: onTabTap == null ? null : () => onTabTap!(s),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final MainScreen page;
  final bool active;
  final Color color;
  final IconData idleIcon;
  final String label;
  final bool isDark;
  final VoidCallback? customTap;

  const _Tab({
    required this.page,
    required this.active,
    required this.color,
    required this.idleIcon,
    required this.label,
    required this.isDark,
    this.customTap,
  });

  void _onTap(BuildContext context) {
    if (customTap != null) {
      customTap!();
      return;
    }
    final shell = MainShell.maybeOf(context);
    if (shell == null) return;
    if (active) {
      shell.fireCurrentPagePrimaryAction();
    } else {
      shell.gotoPage(page);
    }
  }

  IconData _activeActionIcon(bool isGraph) {
    if (page == MainScreen.records) {
      return isGraph ? Icons.history : Icons.bar_chart;
    }
    return Icons.add;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? color : color.withValues(alpha: 0.40);
    final labelColor = active ? color : color.withValues(alpha: 0.55);

    return InkWell(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (!active)
                    Center(child: Icon(idleIcon, size: 22, color: iconColor))
                  else
                    Positioned(
                      top: -22,
                      child: _ActiveFloatingButton(
                        page: page,
                        color: color,
                        iconBuilder: _activeActionIcon,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFloatingButton extends StatelessWidget {
  final MainScreen page;
  final Color color;
  final IconData Function(bool isGraph) iconBuilder;

  const _ActiveFloatingButton({
    required this.page,
    required this.color,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: scaffoldBg, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: page == MainScreen.records
          ? ValueListenableBuilder<bool>(
              valueListenable: RecordsScreen.showingGraph,
              builder: (_, isGraph, _) =>
                  Icon(iconBuilder(isGraph), size: 26, color: Colors.white),
            )
          : Icon(iconBuilder(false), size: 26, color: Colors.white),
    );
  }
}
