import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/main_shell.dart';
import 'database_helper.dart';
import 'encryption_service.dart';
import 'notification_service.dart';

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _driveFileName = 'kovira_backup.enc';

  static const _prefsPassphraseKey = 'backup_passphrase_v1';
  static const _driveScope = drive.DriveApi.driveFileScope;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [_driveScope]);

  Future<Map<String, dynamic>> _buildBackupJson() async {
    final db = DatabaseHelper.instance;
    final sources = await db.getAllSources();
    final cats = await db.getCategories();
    final entries = await db.getAllEntries();
    final bills = await db.getBillTemplates();
    final incomeTemplates = await db.getIncomeTemplates();
    final transferTemplates = await db.getTransferTemplates();
    final suggestions = await db.getCategorySuggestionsRaw();
    final budgets = await db.getCategoryBudgetsRaw();
    final budgetMonths = await db.getCategoryBudgetMonthsRaw();
    final goals = await db.getGoals(includeArchived: true);
    return {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'sources': sources.map((s) => s.toMap()).toList(),
      'categories': cats.map((c) => c.toMap()).toList(),
      'entries': entries.map((e) => e.toMap()).toList(),
      'bills': bills.map((b) => b.toMap()).toList(),
      'incomeTemplates': incomeTemplates.map((t) => t.toMap()).toList(),
      'transferTemplates': transferTemplates.map((t) => t.toMap()).toList(),
      'categorySuggestions': suggestions,
      'categoryBudgets': budgets,
      'categoryBudgetMonths': budgetMonths,
      'goals': goals.map((g) => g.toMap()).toList(),
    };
  }

  Future<String?> getStoredPassphrase() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_prefsPassphraseKey);
  }

  Future<void> setStoredPassphrase(String passphrase) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_prefsPassphraseKey, passphrase);
  }

  Future<void> clearStoredPassphrase() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_prefsPassphraseKey);
  }

  Future<String> _buildEncryptedBackup(String passphrase) async {
    final json = await _buildBackupJson();
    final plaintext = const JsonEncoder.withIndent('  ').convert(json);
    return EncryptionService.instance.encryptWithPassphrase(
      plaintext,
      passphrase,
    );
  }

  Future<Map<String, dynamic>> _decodeBackup(
    String raw, {
    String? passphrase,
  }) async {
    final trimmed = raw.trim();
    if (EncryptionService.isPassphraseFormat(trimmed)) {
      if (passphrase == null) {
        throw const _NeedsPassphraseException();
      }
      final plaintext = EncryptionService.instance.decryptWithPassphrase(
        trimmed,
        passphrase,
      );
      return jsonDecode(plaintext) as Map<String, dynamic>;
    }
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    }
    final plaintext = await EncryptionService.instance.decryptLegacy(trimmed);
    return jsonDecode(plaintext) as Map<String, dynamic>;
  }

  Future<void> exportToFile(BuildContext context) async {
    try {
      final passphrase = await _ensurePassphraseForExport(context);
      if (passphrase == null) return;
      if (!context.mounted) return;
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final fileName = 'kovira_backup_$ts.enc';
      final body = await _buildEncryptedBackup(passphrase);

      String? savedPath;
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final file = File('${downloadsDir.path}/$fileName');
          await file.writeAsString(body);
          savedPath = file.path;
        }
      } catch (_) {}

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(body);

      if (!context.mounted) return;

      if (savedPath != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Backup saved', style: TextStyle(fontSize: 20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saved to Downloads:',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  fileName,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Plain JSON — restorable on any phone, after reinstall, '
                  'or after a phone reset. Treat the file as private; '
                  'anyone with it can read your records.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                const Text(
                  'You can also share it via WhatsApp, email, etc.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([
                    XFile(tempFile.path),
                  ], text: 'Kovira backup');
                },
              ),
            ],
          ),
        );
      } else {
        await Share.shareXFiles([XFile(tempFile.path)], text: 'Kovira backup');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Export failed: $e');
    }
  }

  Future<bool> importFromRaw(BuildContext context, String raw) async {
    final isPwdFormat = EncryptionService.isPassphraseFormat(raw);
    String? passphrase;
    Map<String, dynamic>? data;
    if (isPwdFormat) {
      passphrase = await getStoredPassphrase();
      if (passphrase != null) {
        try {
          data = await _decodeBackup(raw, passphrase: passphrase);
        } catch (_) {
          passphrase = null;
        }
      }

      final hadStored = (await getStoredPassphrase()) != null;
      final firstMsg = hadStored
          ? 'That password didn\'t unlock the backup. Try again, or cancel.'
          : 'Enter the backup password used when this backup was made.';
      while (data == null) {
        if (!context.mounted) return false;
        final entered = await _promptForPassphrase(context, message: firstMsg);
        if (entered == null) return false;
        try {
          data = await _decodeBackup(raw, passphrase: entered);
          passphrase = entered;
        } catch (_) {}
      }
    } else {
      try {
        data = await _decodeBackup(raw);
      } catch (e) {
        if (!context.mounted) return false;
        _showError(context, _decodeErrorMessage(e));
        return false;
      }
    }

    String stage = 'cancel notifications';
    try {
      try {
        await NotificationService.instance.cancelAll();
      } catch (_) {}
      stage = 'database insert';
      await DatabaseHelper.instance.restoreFromBackup(data);
      stage = 'reschedule reminders';
      try {
        await _rescheduleAllReminders();
      } catch (_) {}

      if (passphrase != null && (await getStoredPassphrase()) == null) {
        await setStoredPassphrase(passphrase);
      }
      MainShell.refreshAllPages();
      return true;
    } catch (e, stack) {
      debugPrint('Restore failed at $stage stage: $e\n$stack');
      if (!context.mounted) return false;
      await _showErrorDialog(
        context,
        title: 'Restore failed',
        body: 'Stage: $stage\n\n${e.runtimeType}: $e',
      );
      return false;
    }
  }

  Future<void> _showErrorDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              body,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _ensurePassphraseForExport(BuildContext context) async {
    final stored = await getStoredPassphrase();
    if (stored != null) return stored;
    if (!context.mounted) return null;
    final created = await _promptForNewPassphrase(context);
    if (created == null) return null;
    await setStoredPassphrase(created);
    return created;
  }

  String _decodeErrorMessage(Object e) {
    if (e is FormatException) {
      return 'Backup file is not readable — it looks truncated, edited, '
          'or in an old encrypted format from a different install.\n\n'
          '${e.message}';
    }
    return 'Couldn\'t open this backup. If it was made by an older '
        'version of Kovira on a different phone or before a reinstall, '
        'the encryption key for it is gone.\n\n$e';
  }

  Future<void> _rescheduleAllReminders() async {
    final db = DatabaseHelper.instance;
    final notif = NotificationService.instance;
    final incomeTemplates = await db.getIncomeTemplates();
    for (final t in incomeTemplates) {
      if (t.reminderDay != null) {
        try {
          await notif.scheduleIncomeReminder(t);
        } catch (_) {}
      }
    }
    final transferTemplates = await db.getTransferTemplates();
    final sources = await db.getAllSources();
    for (final t in transferTemplates) {
      if (t.reminderDay == null) continue;
      final fromSrc = sources.where((s) => s.id == t.fromSourceId).firstOrNull;
      final toSrc = sources.where((s) => s.id == t.toSourceId).firstOrNull;
      if (fromSrc == null || toSrc == null) continue;
      try {
        await notif.scheduleTransferReminder(t, fromSrc: fromSrc, toSrc: toSrc);
      } catch (_) {}
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _ensureDriveScope(BuildContext context) async {
    try {
      final granted = await _googleSignIn.requestScopes([_driveScope]);
      if (granted) return true;
      if (!context.mounted) return false;
      _showError(context, 'Drive permission was not granted.');
      return false;
    } catch (e) {
      if (!context.mounted) return false;
      _showError(context, 'Drive permission check failed: $e');
      return false;
    }
  }

  Future<void> signOut() async => _googleSignIn.signOut();

  Future<GoogleSignInAccount?> get currentUser async =>
      _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();

  Future<void> backupToDrive(BuildContext context) async {
    final account = await currentUser;
    if (!context.mounted) return;
    if (account == null) {
      _showError(context, 'Not signed in to Google.');
      return;
    }
    if (!await _ensureDriveScope(context)) return;
    if (!context.mounted) return;
    try {
      final passphrase = await _ensurePassphraseForExport(context);
      if (passphrase == null) return;
      if (!context.mounted) return;
      final auth = await account.authentication;
      final client = _GoogleAuthClient({
        'Authorization': 'Bearer ${auth.accessToken}',
      });
      final driveApi = drive.DriveApi(client);
      final body = await _buildEncryptedBackup(passphrase);
      final bytes = utf8.encode(body);
      final media = drive.Media(
        Stream.fromIterable([bytes]),
        bytes.length,
        contentType: 'application/octet-stream',
      );
      final existing = await driveApi.files.list(
        q: "name='$_driveFileName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,modifiedTime)',
        orderBy: 'modifiedTime desc',
      );
      final files = existing.files ?? const <drive.File>[];
      if (files.isEmpty) {
        await driveApi.files.create(
          drive.File()..name = _driveFileName,
          uploadMedia: media,
        );
      } else {
        await driveApi.files.update(
          drive.File()..modifiedTime = DateTime.now().toUtc(),
          files.first.id!,
          uploadMedia: media,
        );
        for (var i = 1; i < files.length; i++) {
          try {
            await driveApi.files.delete(files[i].id!);
          } catch (_) {}
        }
      }
      if (!context.mounted) return;
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
                border: Border.all(color: Colors.green, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 16,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Encrypted backup saved to Google Drive',
                    style: TextStyle(
                      color: Colors.green,
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
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Drive backup failed: $e');
    }
  }

  Future<void> restoreFromDrive(BuildContext context) async {
    final account = await currentUser;
    if (account == null) {
      if (!context.mounted) return;
      _showError(context, 'Not signed in to Google.');
      return;
    }
    if (!context.mounted) return;
    if (!await _ensureDriveScope(context)) return;
    if (!context.mounted) return;
    try {
      final auth = await account.authentication;
      final client = _GoogleAuthClient({
        'Authorization': 'Bearer ${auth.accessToken}',
      });
      final driveApi = drive.DriveApi(client);
      final existing = await driveApi.files.list(
        q: "name='$_driveFileName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,modifiedTime)',
        orderBy: 'modifiedTime desc',
      );
      if (existing.files == null || existing.files!.isEmpty) {
        if (!context.mounted) return;
        _showError(
          context,
          'No backup found on Google Drive.',
        ); // ignore: use_build_context_synchronously
        return;
      }
      final media =
          await driveApi.files.get(
                existing.files!.first.id!,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;
      final chunks = await media.stream.toList();
      final raw = utf8.decode(chunks.expand((c) => c).toList());
      if (!context.mounted) return;
      final ok = await confirmRestore(context);
      if (!ok) return;
      if (!context.mounted) return;
      final success = await importFromRaw(context, raw);
      if (success && context.mounted) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.green, width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_download_outlined,
                      size: 16,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Restored from Google Drive',
                      style: TextStyle(
                        color: Colors.green,
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
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Drive restore failed: $e');
    }
  }

  Future<bool> confirmRestore(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Restore backup?',
              style: TextStyle(fontSize: 20),
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 1.5),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will replace all your current data with the '
                      'backup. This cannot be undone.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Restore'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.red, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    msg,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _promptForPassphrase(
    BuildContext context, {
    required String message,
  }) async {
    final ctrl = TextEditingController();
    bool obscure = true;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Backup password', style: TextStyle(fontSize: 20)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) {
                    if (v.isNotEmpty) Navigator.pop(ctx, v);
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) Navigator.pop(ctx, ctrl.text);
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptForNewPassphrase(BuildContext context) async {
    final pwd1 = TextEditingController();
    final pwd2 = TextEditingController();
    bool obscure = true;
    String? error;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text(
            'Set backup password',
            style: TextStyle(fontSize: 20),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You will need this password to restore the backup '
                  'on another phone, after a reinstall, or after a '
                  'factory reset. Kovira cannot recover it for you.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pwd1,
                  autofocus: true,
                  obscureText: obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    border: const OutlineInputBorder(),
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pwd2,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    final ok = _validatePair(pwd1.text, pwd2.text);
                    if (ok != null) {
                      setS(() => error = ok);
                    } else {
                      Navigator.pop(ctx, pwd1.text);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final ok = _validatePair(pwd1.text, pwd2.text);
                if (ok != null) {
                  setS(() => error = ok);
                } else {
                  Navigator.pop(ctx, pwd1.text);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePair(String a, String b) {
    if (a.isEmpty) return 'Enter a password';
    if (a.length < 4) return 'Use at least 4 characters';
    if (a != b) return 'Passwords do not match';
    return null;
  }
}

class _NeedsPassphraseException implements Exception {
  const _NeedsPassphraseException();
}
