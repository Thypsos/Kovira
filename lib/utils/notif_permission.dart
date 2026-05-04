import 'package:flutter/material.dart';
import '../data/notification_service.dart';
import '../data/settings_service.dart';

Future<void> ensureNotifPermission(BuildContext context) async {
  final asked = await SettingsService.instance.hasAskedNotifPerm();
  if (asked) {
    await NotificationService.instance.requestPermission();
    return;
  }
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.notifications_active_outlined,
        size: 40,
        color: Theme.of(ctx).colorScheme.primary,
      ),
      title: const Text(
        'Enable notifications?',
        style: TextStyle(fontSize: 20),
      ),
      content: const Text(
        'Kovira will remind you on the day you picked. '
        'Notifications are only used for reminders you set up '
        'yourself. No marketing, no noise. You can turn them off '
        'any time from your device settings.',
        style: TextStyle(fontSize: 15, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Enable'),
        ),
      ],
    ),
  );
  await SettingsService.instance.markNotifPermAsked();
  if (ok == true) {
    await NotificationService.instance.requestPermission();
  }
}
