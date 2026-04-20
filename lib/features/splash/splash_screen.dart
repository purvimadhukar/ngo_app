import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/role_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Blob drift controllers
  late final AnimationController _blob1;
  late final AnimationController _blob2;
  late final AnimationController _blob3;
  // Content entrance
  late final AnimationController _enter;
  // Loader spinner
  late final AnimationController _loader;

  late final Animation<double> _wordFade;
  late final Animation<double> _wordSlide;
  late final Animation<double> _tagFade;
  late final Animation<double> _loaderFade;

  static const _bg     = Color(0xFF07070A);
  static const _green  = Color(0xFF1DB884);
  static const _purple = Color(0xFF1DB884);
  static const _coral  = Color(0xFFE8654A);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _bg,
    ));

    // Blobs — each on its own slow loop, slightly different durations
    _blob1 = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);
    _blob2 = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _blob3 = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);

    // Content entrance (1.6 s)
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    _wordFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _enter, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _wordSlide = Tween<double>(begin: 24, end: 0).animate(CurvedAnimation(parent: _enter, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));
    _tagFade   = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _enter, curve: const Interval(0.4, 0.75, curve: Curves.easeOut)));
    _loaderFade= Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _enter, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)));

    // Loader ring
    _loader = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

    _enter.forward();

    Future.delayed(const Duration(milliseconds: 3600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RoleRouter(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 800),
      ));
    });
  }

  @override
  void dispose() {
    _blob1.dispose(); _blob2.dispose(); _blob3.dispose();
    _enter.dispose(); _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_blob1, _blob2, _blob3, _enter, _loader]),
        builder: (_, __) {
          return Stack(
            fit: StackFit.expand,
            children: [

              // ── Fluid mesh gradient background ──────────────────────────────
              CustomPaint(
                painter: _MeshPainter(
                  t1: _blob1.value,
                  t2: _blob2.value,
                  t3: _blob3.value,
                  size: size,
                ),
              ),

              // ── Noise grain overlay ─────────────────────────────────────────
              Opacity(
                opacity: 0.03,
                child: CustomPaint(painter: _GrainPainter(seed: (_loader.value * 60).toInt())),
              ),

              // ── Center content ──────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Wordmark — Bricolage Grotesque
                    Transform.translate(
                      offset: Offset(0, _wordSlide.value),
                      child: Opacity(
                        opacity: _wordFade.value,
                        child: Column(
                          children: [
                            // Icon badge with glow
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_green, _purple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: _green.withValues(alpha: 0.35 + 0.2 * _blob1.value),
                                    blurRadius: 28, spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: _purple.withValues(alpha: 0.2 + 0.15 * _blob2.value),
                                    blurRadius: 40, offset: const Offset(8, 14),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 34),
                            ),

                            const Gap(20),

                            // AidBridge — Bricolage Grotesque w800
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: 'Aid',
                                  style: GoogleFonts.bricolageGrotesque(
                                    color: Colors.white,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -3,
                                    height: 1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Bridge',
                                  style: GoogleFonts.bricolageGrotesque(
                                    color: _green,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -3,
                                    height: 1,
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Gap(14),

                    // Tagline — Syne
                    Opacity(
                      opacity: _tagFade.value,
                      child: Text(
                        'BRIDGE HEARTS · BUILD FUTURES',
                        style: GoogleFonts.syne(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                    const Gap(64),

                    // Loader — uiverse-inspired ring spinner
                    Opacity(
                      opacity: _loaderFade.value,
                      child: _AidRingLoader(progress: _loader.value),
                    ),
                  ],
                ),
              ),

              // Bottom label
              Positioned(
                bottom: 36, left: 0, right: 0,
                child: Opacity(
                  opacity: _loaderFade.value,
                  child: Text(
                    'Making a difference, one bridge at a time',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.22),
                      fontSize: 11,
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

// ─── Fluid mesh gradient painter ─────────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  final double t1, t2, t3;
  final Size size;
  const _MeshPainter({required this.t1, required this.t2, required this.t3, required this.size});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    // Blob 1 — emerald, top-left drifting
    _drawBlob(canvas, s,
      cx: w * (0.1 + 0.25 * t1),
      cy: h * (0.1 + 0.2 * t1),
      r: w * 0.55,
      color: const Color(0xFF1DB884),
      opacity: 0.18,
    );

    // Blob 2 — purple, bottom-right drifting
    _drawBlob(canvas, s,
      cx: w * (0.75 - 0.2 * t2),
      cy: h * (0.75 - 0.15 * t2),
      r: w * 0.6,
      color: const Color(0xFF1DB884),
      opacity: 0.16,
    );

    // Blob 3 — coral accent, top-right small
    _drawBlob(canvas, s,
      cx: w * (0.85 + 0.1 * sin(t3 * pi)),
      cy: h * (0.15 + 0.1 * cos(t3 * pi)),
      r: w * 0.3,
      color: const Color(0xFFE8654A),
      opacity: 0.10,
    );

    // Blob 4 — blue accent, bottom-left
    _drawBlob(canvas, s,
      cx: w * (0.1 - 0.05 * t1),
      cy: h * (0.8 + 0.1 * t2),
      r: w * 0.35,
      color: const Color(0xFF1DB884),
      opacity: 0.12,
    );
  }

  void _drawBlob(Canvas canvas, Size s, {
    required double cx, required double cy,
    required double r, required Color color, required double opacity,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  @override
  bool shouldRepaint(_MeshPainter old) =>
      old.t1 != t1 || old.t2 != t2 || old.t3 != t3;
}

// ─── Grain texture painter ────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  final int seed;
  const _GrainPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (var i = 0; i < 800; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.seed != seed;
}

// ─── Ring loader (uiverse-inspired) ──────────────────────────────────────────

class _AidRingLoader extends StatelessWidget {
  final double progress; // 0.0 → 1.0 looping
  const _AidRingLoader({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, height: 44,
      child: CustomPaint(painter: _RingPainter(progress: progress)),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  static const _green  = Color(0xFF1DB884);
  static const _purple = Color(0xFF1DB884);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 4;

    // Track ring
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Animated arc — sweeps from 0 to ~270° and back using sine
    final sweep = (0.3 + 0.7 * sin(progress * 2 * pi).abs()) * 2 * pi * 0.75;
    final startAngle = progress * 2 * pi * 2; // rotates continuously

    final shader = SweepGradient(
      colors: [_purple, _green, _green],
      startAngle: 0,
      endAngle: sweep,
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle - pi / 2,
      sweep,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Leading dot
    final dotAngle = startAngle + sweep - pi / 2;
    final dotX = cx + r * cos(dotAngle);
    final dotY = cy + r * sin(dotAngle);
    canvas.drawCircle(
      Offset(dotX, dotY), 3,
      Paint()..color = _green,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
