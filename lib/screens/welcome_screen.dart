import 'package:flutter/material.dart';
import '../data/settings_service.dart';
import '../utils/strings.dart';
import '../widgets/live_icon.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onDone;
  const WelcomeScreen({super.key, required this.onDone});

  Future<void> _continue() async {
    await SettingsService.instance.markWelcomeSeen();
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              AppearOnMount(
                duration: const Duration(milliseconds: 600),
                fromScale: 0.6,
                child: const _BreathingLogo(),
              ),
              const SizedBox(height: 24),
              AppearOnMount(
                delay: const Duration(milliseconds: 220),
                duration: const Duration(milliseconds: 480),
                fromScale: 0.92,
                child: Text(
                  S.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppearOnMount(
                delay: const Duration(milliseconds: 360),
                duration: const Duration(milliseconds: 480),
                fromScale: 0.96,
                child: Text(
                  S.welcomeBlurb,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ),
              const SizedBox(height: 56),
              AppearOnMount(
                delay: const Duration(milliseconds: 560),
                duration: const Duration(milliseconds: 540),
                fromScale: 0.88,
                child: _LearnHero(
                  scaffoldBg: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              const SizedBox(height: 32),
              AppearOnMount(
                delay: const Duration(milliseconds: 820),
                duration: const Duration(milliseconds: 460),
                fromScale: 0.85,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 56,
                        vertical: 18,
                      ),
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingLogo extends StatefulWidget {
  const _BreathingLogo();

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _breath.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal = const Color(0xFF26A69A);
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _orbit,
              builder: (_, _) => CustomPaint(
                size: const Size(200, 200),
                painter: _LogoHaloPainter(
                  progress: _orbit.value,
                  color: teal,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _orbit,
              builder: (_, _) {
                final t = ((_orbit.value + 0.5) % 1.0);
                final size = 130 + 60 * t;
                final opacity = (1 - t).clamp(0.0, 1.0);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: teal.withValues(alpha: 0.45 * opacity),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _orbit,
              builder: (_, _) {
                final t = _orbit.value;
                final size = 130 + 60 * t;
                final opacity = (1 - t).clamp(0.0, 1.0);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: teal.withValues(alpha: 0.30 * opacity),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _breath,
              builder: (_, _) {
                final t = Curves.easeInOut.transform(_breath.value);
                final scale = 1.0 + 0.04 * t;
                return Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoHaloPainter extends CustomPainter {
  final double progress;
  final Color color;
  _LogoHaloPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.20),
          color.withValues(alpha: 0.06),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant _LogoHaloPainter old) =>
      old.progress != progress || old.color != color;
}

class _LearnHero extends StatefulWidget {
  final Color scaffoldBg;
  const _LearnHero({required this.scaffoldBg});

  @override
  State<_LearnHero> createState() => _LearnHeroState();
}

class _LearnHeroState extends State<_LearnHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const learnColor = Color(0xFFFFA000);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 36),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          decoration: BoxDecoration(
            color: learnColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: learnColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Tap to learn at any time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Every page has this icon at the top right. Tap it '
                'when you want a walkthrough.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: cs.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ring,
                builder: (_, _) {
                  final t = _ring.value;
                  final size = 60 + 28 * t;
                  final opacity = (1 - t).clamp(0.0, 1.0);
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: learnColor.withValues(alpha: 0.55 * opacity),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _ring,
                builder: (_, _) {
                  final t = ((_ring.value + 0.5) % 1.0);
                  final size = 60 + 28 * t;
                  final opacity = (1 - t).clamp(0.0, 1.0);
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: learnColor.withValues(alpha: 0.40 * opacity),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: widget.scaffoldBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: learnColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: learnColor.withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const PulsingGlowIcon(
                    icon: Icons.school_outlined,
                    size: 32,
                    color: Colors.white,
                    glowColor: Colors.white,
                    maxBlur: 8,
                    minOpacity: 0.10,
                    maxOpacity: 0.32,
                    duration: Duration(milliseconds: 1600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
