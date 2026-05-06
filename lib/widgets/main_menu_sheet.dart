import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_shell.dart';
import 'main_tab_bar.dart';

enum MainScreen {
  dashboard,
  records,
  accounts,
  categories,
  bills,
  budget,
  goals,
}

class MainScreenChrome {
  final IconData icon;
  final Color color;
  final String label;
  const MainScreenChrome(this.icon, this.color, this.label);

  static MainScreenChrome of(MainScreen s) {
    switch (s) {
      case MainScreen.dashboard:
        return const MainScreenChrome(
          Icons.shopping_bag_outlined,
          PageColors.dashboard,
          'Expenses',
        );
      case MainScreen.records:
        return const MainScreenChrome(
          Icons.history,
          PageColors.records,
          'Records',
        );
      case MainScreen.accounts:
        return const MainScreenChrome(
          Icons.account_balance_wallet_outlined,
          PageColors.accounts,
          'Income Sources',
        );
      case MainScreen.bills:
        return const MainScreenChrome(
          Icons.receipt_long,
          PageColors.bills,
          'Bills',
        );
      case MainScreen.categories:
        return const MainScreenChrome(
          Icons.category_outlined,
          PageColors.categories,
          'Tags',
        );
      case MainScreen.budget:
        return const MainScreenChrome(
          Icons.pie_chart_outline,
          PageColors.budget,
          'Budget',
        );
      case MainScreen.goals:
        return const MainScreenChrome(
          Icons.flag_outlined,
          PageColors.goals,
          'Goals',
        );
    }
  }
}

Future<void> showMainMenuSheet(
  BuildContext context, {
  required MainScreen current,
  Future<bool> Function(String action)? requireSource,
  VoidCallback? onReturn,
}) async {
  final cs = Theme.of(context).colorScheme;

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Navigate',
    barrierColor: Colors.black.withValues(alpha: 0.22),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (sheetCtx, anim, _) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(
        begin: const Offset(0, 1.0),
        end: Offset.zero,
      ).animate(curved);
      final panel = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {},
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: MainTabBar(
            current: current,
            transparentBg: true,
            onTabTap: (target) {
              Navigator.pop(sheetCtx);
              if (!context.mounted) return;
              MainShell.maybeOf(context)?.gotoPage(target);
              onReturn?.call();
            },
          ),
        ),
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: slide,
              child: FadeTransition(opacity: curved, child: panel),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, _, _, child) => child,
  );
}
