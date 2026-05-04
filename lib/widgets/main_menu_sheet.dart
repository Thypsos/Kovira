import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_shell.dart';

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
          'Dashboard',
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
          'Categories',
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

  Widget tile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await onTap();
        onReturn?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            for (final slot in const [
              MainScreen.records,
              MainScreen.budget,
              MainScreen.accounts,
              MainScreen.bills,
              MainScreen.categories,
              MainScreen.goals,
            ])
              if (slot == current)
                tile(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Dashboard',
                  subtitle: 'Expenses overview',
                  color: const Color(0xFFB71C1C),
                  onTap: () async {
                    MainShell.maybeOf(context)?.gotoPage(MainScreen.dashboard);
                  },
                )
              else if (slot == MainScreen.records)
                tile(
                  icon: Icons.history,
                  label: 'Records & Graph',
                  subtitle: 'Expenses, income, transfers',
                  color: Colors.blue,
                  onTap: () async {
                    MainShell.maybeOf(context)?.gotoPage(MainScreen.records);
                  },
                )
              else if (slot == MainScreen.accounts)
                tile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Income Sources',
                  subtitle: 'Cash, cards, wallets',
                  color: Colors.green,
                  onTap: () async {
                    MainShell.maybeOf(context)?.gotoPage(MainScreen.accounts);
                  },
                )
              else if (slot == MainScreen.categories)
                tile(
                  icon: Icons.category_outlined,
                  label: 'Categories',
                  subtitle: 'Organise expense types',
                  color: Colors.purple,
                  onTap: () async {
                    MainShell.maybeOf(context)?.gotoPage(MainScreen.categories);
                  },
                )
              else if (slot == MainScreen.bills)
                tile(
                  icon: Icons.receipt_long,
                  label: 'Bills',
                  subtitle: 'Recurring bills and dues',
                  color: Colors.orange,
                  onTap: () async {
                    if (requireSource != null &&
                        !await requireSource('use bills')) {
                      return;
                    }
                    if (!context.mounted) return;
                    MainShell.maybeOf(context)?.gotoPage(MainScreen.bills);
                  },
                )
              else if (slot == MainScreen.budget)
                tile(
                  icon: Icons.pie_chart_outline,
                  label: 'Budget',
                  subtitle: 'Monthly category limits',
                  color: Colors.deepOrange,
                  onTap: () async {
                    MainShell.maybeOf(context)?.gotoPage(MainScreen.budget);
                  },
                )
              else
                tile(
                  icon: Icons.flag_outlined,
                  label: 'Goals',
                  subtitle: 'Savings targets',
                  color: Colors.teal,
                  onTap: () async {
                    MainShell.maybeOf(context)?.gotoPage(MainScreen.goals);
                  },
                ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
