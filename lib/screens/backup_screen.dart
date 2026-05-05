import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/backup_service.dart';
import '../widgets/live_icon.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String? _googleUserEmail;
  bool _loadingGoogle = false;
  bool _loadingBackup = false;

  @override
  void initState() {
    super.initState();
    _checkSignIn();
  }

  Future<void> _checkSignIn() async {
    final user = await BackupService.instance.currentUser;
    if (mounted) setState(() => _googleUserEmail = user?.email);
  }

  Future<void> _signIn() async {
    setState(() => _loadingGoogle = true);
    final user = await BackupService.instance.signIn();
    if (!mounted) return;
    setState(() => _loadingGoogle = false);
    if (user == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            'Google sign-in not set up',
            style: TextStyle(fontSize: 20),
          ),
          content: const Text(
            'Google Drive backup requires a one-time setup in the Google Cloud Console.\n\n'
            'Until that is done, use Manual Backup to save your data as a file.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _googleUserEmail = user.email);
  }

  Future<void> _signOut() async {
    await BackupService.instance.signOut();
    if (mounted) setState(() => _googleUserEmail = null);
  }

  Future<void> _exportFile() async {
    setState(() => _loadingBackup = true);
    await BackupService.instance.exportToFile(context);
    if (mounted) setState(() => _loadingBackup = false);
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    final raw = await File(result.files.single.path!).readAsString();
    if (!mounted) return;
    final confirm = await BackupService.instance.confirmRestore(context);
    if (!confirm || !mounted) return;
    final ok = await BackupService.instance.importFromRaw(context, raw);
    if (ok && mounted) {
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
                    Icons.download_done_outlined,
                    size: 16,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Restored from backup file',
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
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        leadingWidth: 80,
        centerTitle: true,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 20, color: Colors.white),
                SizedBox(width: 2),
                SpinningIcon(
                  icon: Icons.settings_outlined,
                  size: 18,
                  color: Colors.white,
                  period: Duration(seconds: 18),
                ),
              ],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            PulsingGlowIcon(
              icon: Icons.backup_outlined,
              size: 22,
              color: Colors.indigo,
              glowColor: Colors.indigo,
              maxBlur: 10,
              minOpacity: 0.10,
              maxOpacity: 0.40,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Backup & Restore',
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _staggered(0, _manualSection(cs)),
          const SizedBox(height: 28),
          _staggered(120, _driveSection(cs)),
          const SizedBox(height: 28),
          _staggered(240, _warningBox(cs)),
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

  Widget _manualSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          cs,
          icon: Icons.lock_outline,
          iconColor: Colors.green,
          title: 'Manual Backup',
        ),
        const SizedBox(height: 6),
        Text(
          'Encrypted with your backup password — same password '
          'restores anywhere: another phone, after reinstall, or '
          'after a factory reset. Lose the password and the backup '
          'cannot be opened.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 14),
        _actionTile(
          icon: Icons.upload_file,
          label: 'Export encrypted backup',
          subtitle: 'Saves .enc file · option to share',
          color: Colors.green,
          loading: _loadingBackup,
          onTap: _exportFile,
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.download,
          label: 'Restore from backup file',
          subtitle: 'Pick a .enc backup file',
          color: Colors.blue,
          onTap: _importFile,
        ),
      ],
    );
  }

  Widget _driveSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          cs,
          icon: Icons.cloud_outlined,
          iconColor: Colors.blue,
          title: 'Google Drive Backup',
        ),
        const SizedBox(height: 6),
        Text(
          'Saves an encrypted copy to your Google Drive. Restores '
          'anywhere you sign in with this Google account, as long '
          'as you also have the backup password.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 14),
        if (_googleUserEmail == null) ...[
          if (_loadingGoogle)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            _actionTile(
              icon: Icons.login,
              label: 'Sign in with Google',
              subtitle: 'Connect to enable Drive backup',
              color: Colors.orange,
              onTap: _signIn,
            ),
        ] else ...[
          _signedInPill(cs),
          const SizedBox(height: 12),
          _actionTile(
            icon: Icons.cloud_upload,
            label: 'Back up to Drive now',
            subtitle: 'Encrypted · saves as kovira_backup.enc',
            color: Colors.green,
            loading: _loadingBackup,
            onTap: () async {
              setState(() => _loadingBackup = true);
              await BackupService.instance.backupToDrive(context);
              if (mounted) setState(() => _loadingBackup = false);
            },
          ),
          const SizedBox(height: 10),
          _actionTile(
            icon: Icons.cloud_download,
            label: 'Restore from Drive',
            subtitle: 'Replaces current data with Drive backup',
            color: Colors.blue,
            onTap: () => BackupService.instance.restoreFromDrive(context),
          ),
        ],
      ],
    );
  }

  Widget _signedInPill(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.green.withValues(alpha: 0.12)
        : Color.lerp(Colors.green, Colors.white, 0.20)!;
    final borderCol = isDark
        ? Colors.green.withValues(alpha: 0.35)
        : Color.lerp(Colors.green, Colors.white, 0.05)!;
    final fg = isDark ? cs.onSurface : Colors.white;
    final iconColor = isDark ? Colors.green : Colors.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Signed in as $_googleUserEmail',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          TextButton(
            onPressed: _signOut,
            style: TextButton.styleFrom(foregroundColor: fg),
            child: const Text(
              'Sign out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBox(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Restoring a backup will permanently replace your current '
              'data. Export a backup first if you want to keep it.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    ColorScheme cs, {
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark
        ? iconColor.withValues(alpha: 0.15)
        : Color.lerp(iconColor, Colors.white, 0.18)!;
    final chipFg = isDark ? iconColor : Colors.white;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: chipFg),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? color.withValues(alpha: 0.10)
        : Color.lerp(color, Colors.white, 0.18)!;
    final borderCol = isDark
        ? color.withValues(alpha: 0.30)
        : Color.lerp(color, Colors.white, 0.05)!;
    final fg = isDark ? color : Colors.white;
    final chipBg = isDark
        ? color.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.22);
    final labelColor = isDark ? cs.onSurface : Colors.white;
    final subtitleColor = isDark
        ? cs.onSurface.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.85);
    final chevronColor = isDark
        ? cs.onSurface.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.7);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Icon(icon, color: fg, size: 22),
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
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: chevronColor),
          ],
        ),
      ),
    );
  }
}
