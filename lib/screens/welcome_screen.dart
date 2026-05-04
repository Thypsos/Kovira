import 'package:flutter/material.dart';
import '../data/settings_service.dart';
import '../tutorial/tutorial_service.dart';
import '../utils/strings.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onDone;
  const WelcomeScreen({super.key, required this.onDone});

  Future<void> _pick(BuildContext context, bool assisted) async {
    await SettingsService.instance.setAssistedMode(assisted);

    await TutorialService.instance.setSkipAll(!assisted);
    await SettingsService.instance.markWelcomeSeen();
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Image.asset('assets/logo.png', width: 72, height: 72),
              ),
              const SizedBox(height: 18),
              Text(
                S.welcomeTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.welcomeBlurb,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              _OptionCard(
                icon: Icons.lightbulb_outline,
                title: S.welcomeAssist,
                subtitle: S.welcomeAssistBlurb,
                color: cs.primary,
                onTap: () => _pick(context, true),
              ),
              const SizedBox(height: 12),
              _OptionCard(
                icon: Icons.fast_forward_outlined,
                title: S.welcomeNoAssist,
                subtitle: S.welcomeNoAssistBlurb,
                color: cs.onSurface.withValues(alpha: 0.6),
                onTap: () => _pick(context, false),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.6),
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
}
