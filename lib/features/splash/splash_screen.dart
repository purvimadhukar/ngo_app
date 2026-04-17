import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../widgets/role_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _contentCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _dotsOpacity;

  static const _emerald = Color(0xFF1DB884);
  static const _purple  = Color(0xFF8B7FE8);
  static const _amber   = Color(0xFFE8654A);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF060608),
    ));

    // Looping background pulse
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // One-shot content entrance
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.45, 0.7, curve: Curves.easeOut),
      ),
    );
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentCtrl.forward();

    Future.delayed(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RoleRouter(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060608),
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _contentCtrl]),
        builder: (context, _) {
          final t = _bgCtrl.value;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Animated glow background ────────────────────────────────────
              CustomPaint(painter: _GlowPainter(t: t, size: size)),

              // ── Fine grid overlay ───────────────────────────────────────────
              CustomPaint(painter: _GridPainter()),

              // ── Main content ────────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo icon + wordmark
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Column(
                          children: [
                            // Glowing icon tile
                            AnimatedBuilder(
                              animation: _bgCtrl,
                              builder: (_, __) => Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_emerald, _purple],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _emerald.withValues(alpha: 0.2 + 0.25 * t),
                                      blurRadius: 24 + 16 * t,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: _purple.withValues(alpha: 0.15 + 0.2 * (1 - t)),
                                      blurRadius: 32,
                                      offset: const Offset(8, 12),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.volunteer_activism_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                              ),
                            ),

                            const Gap(22),

                            // AidBridge wordmark
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Aid',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                      height: 1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Bridge',
                                    style: TextStyle(
                                      color: _emerald,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Gap(16),

                    // Tagline
                    FadeTransition(
                      opacity: _taglineFade,
                      child: const Text(
                        'BRIDGE HEARTS · BUILD FUTURES',
                        style: TextStyle(
                          color: Color(0xFF5A5A70),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),

                    const Gap(72),

                    // Pulse dots
                    FadeTransition(
                      opacity: _dotsOpacity,
                      child: const _PulseDots(),
                    ),
                  ],
                ),
              ),

              // ── Bottom version label ─────────────────────────────────────────
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _dotsOpacity,
                  child: const Text(
                    'Making a difference, one bridge at a time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF3A3A50),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Animated radial glow background ─────────────────────────────────────────

class _GlowPainter extends CustomPainter {
  final double t;
  final Size size;
  const _GlowPainter({required this.t, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // Base dark fill
    canvas.drawRect(
      Offset.zero & canvasSize,
      Paint()..color = const Color(0xFF060608),
    );

    // Emerald — top-left, pulses brighter
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.12, size.height * 0.22),
      radius: size.width * 0.75,
      color: const Color(0xFF1DB884),
      opacity: 0.18 + 0.18 * t,
    );

    // Purple — bottom-right, counter-pulse
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.88, size.height * 0.78),
      radius: size.width * 0.7,
      color: const Color(0xFF8B7FE8),
      opacity: 0.16 + 0.16 * (1 - t),
    );

    // Subtle amber mid-center
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.5, size.height * 0.5),
      radius: size.width * 0.5,
      color: const Color(0xFFE8654A),
      opacity: 0.04 + 0.04 * sin(t * pi),
    );
  }

  void _drawGlow(Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..blendMode = BlendMode.screen,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}

// ─── Subtle dot-grid overlay ──────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E28)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─── Animated loading dots ────────────────────────────────────────────────────

class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final wave  = sin(phase * pi).clamp(0.0, 1.0).toDouble();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF2A2A3A),
                  const Color(0xFF1DB884),
                  wave,
                ),
                shape: BoxShape.circle,
                boxShadow: wave > 0.5
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1DB884)
                              .withValues(alpha: wave * 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
