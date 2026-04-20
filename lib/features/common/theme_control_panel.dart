import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/theme_service.dart';

class ThemeControlPanel extends StatefulWidget {
  const ThemeControlPanel({super.key});

  @override
  State<ThemeControlPanel> createState() => _ThemeControlPanelState();
}

class _ThemeControlPanelState extends State<ThemeControlPanel>
    with SingleTickerProviderStateMixin {
  late AppThemeConfig _draft;
  bool _saving = false;
  late AnimationController _bgCtrl;

  // ── Palette options ─────────────────────────────────────────────────────────
  static const _colors = [
    _Swatch(label: 'Teal',    value: 0xFF24A3BE, hex: '#24A3BE'),
    _Swatch(label: 'Blue',    value: 0xFF2B8CE6, hex: '#2B8CE6'),
    _Swatch(label: 'Magenta', value: 0xFF9B4189, hex: '#9B4189'),
    _Swatch(label: 'Emerald', value: 0xFF1DB884, hex: '#1DB884'),
    _Swatch(label: 'Coral',   value: 0xFFE8654A, hex: '#E8654A'),
    _Swatch(label: 'Amber',   value: 0xFFF0A500, hex: '#F0A500'),
    _Swatch(label: 'Violet',  value: 0xFF7C4DFF, hex: '#7C4DFF'),
    _Swatch(label: 'Rose',    value: 0xFFE91E8C, hex: '#E91E8C'),
    _Swatch(label: 'Slate',   value: 0xFF6B7AE8, hex: '#6B7AE8'),
    _Swatch(label: 'White',   value: 0xFFF2F2F3, hex: '#F2F2F3'),
  ];

  static const _backgrounds = [
    _BgOption(id: 'pure_dark', label: 'Pure Dark',  colors: [Color(0xFF07070A), Color(0xFF111116)]),
    _BgOption(id: 'teal',      label: 'Deep Teal',  colors: [Color(0xFF030D10), Color(0xFF24A3BE)]),
    _BgOption(id: 'blue',      label: 'Dark Blue',  colors: [Color(0xFF04040E), Color(0xFF2B8CE6)]),
    _BgOption(id: 'magenta',   label: 'Magenta',    colors: [Color(0xFF08040A), Color(0xFF9B4189)]),
    _BgOption(id: 'forest',    label: 'Forest',     colors: [Color(0xFF030A05), Color(0xFF1DB884)]),
    _BgOption(id: 'slate',     label: 'Slate',      colors: [Color(0xFF060810), Color(0xFF6B7AE8)]),
  ];

  static const _cardStyles = [
    _CardOption(id: 'glass',    label: 'Glass',    icon: Icons.blur_on_rounded),
    _CardOption(id: 'solid',    label: 'Solid',    icon: Icons.square_rounded),
    _CardOption(id: 'outlined', label: 'Outlined', icon: Icons.crop_square_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _draft = ThemeService.config.value;
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    await ThemeService.save(_draft);
    if (mounted) setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme updated!',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
          backgroundColor: _draft.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _draft.primaryColor;

    return Scaffold(
      backgroundColor: _draft.scaffoldColor,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, child) => Stack(
          children: [
            // Live animated background preview
            Positioned.fill(
              child: CustomPaint(
                painter: _PreviewMeshPainter(
                  t: _bgCtrl.value,
                  blobColor: _draft.blobColor,
                ),
              ),
            ),
            child!,
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text('Customise App',
                        style: GoogleFonts.bricolageGrotesque(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        )),
                    ),
                    // Apply button
                    GestureDetector(
                      onTap: _saving ? null : _apply,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 16, offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _saving
                            ? SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Apply',
                                style: GoogleFonts.syne(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                )),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(4),

              // ── Scrollable sections ───────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [

                    // ── Live preview card ─────────────────────────────────────
                    _Section(
                      title: 'Live Preview',
                      child: _LivePreviewCard(config: _draft),
                    ),

                    // ── Accent colour ─────────────────────────────────────────
                    _Section(
                      title: 'Accent Colour',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _colors.map((s) {
                          final selected = _draft.primaryColorValue == s.value;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _draft = _draft.copyWith(primaryColorValue: s.value)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: Color(s.value),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: selected ? 3 : 1,
                                ),
                                boxShadow: selected
                                    ? [BoxShadow(
                                        color: Color(s.value).withValues(alpha: 0.5),
                                        blurRadius: 16, spreadRadius: 2)]
                                    : [],
                              ),
                              child: selected
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 22)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── Background style ──────────────────────────────────────
                    _Section(
                      title: 'Background',
                      child: Column(
                        children: _backgrounds.map((bg) {
                          final selected = _draft.backgroundStyle == bg.id;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _draft = _draft.copyWith(backgroundStyle: bg.id)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 10),
                              height: 62,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: bg.colors,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.white.withValues(alpha: 0.06),
                                  width: selected ? 2 : 1,
                                ),
                                boxShadow: selected
                                    ? [BoxShadow(
                                        color: bg.colors.last.withValues(alpha: 0.35),
                                        blurRadius: 20)]
                                    : [],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Row(
                                  children: [
                                    // Mini gradient dots
                                    Row(
                                      children: bg.colors.map((c) => Container(
                                        width: 12, height: 12,
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: c,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2)),
                                        ),
                                      )).toList(),
                                    ),
                                    const Gap(12),
                                    Text(bg.label,
                                      style: GoogleFonts.syne(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      )),
                                    const Spacer(),
                                    if (selected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: Text('Active',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          )),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── Card style ────────────────────────────────────────────
                    _Section(
                      title: 'Card Style',
                      child: Row(
                        children: _cardStyles.map((opt) {
                          final selected = _draft.cardStyle == opt.id;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _draft = _draft.copyWith(cardStyle: opt.id)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(
                                  right: opt.id != 'outlined' ? 10 : 0),
                                height: 72,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accent.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? accent.withValues(alpha: 0.7)
                                        : Colors.white.withValues(alpha: 0.08),
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(opt.icon,
                                      color: selected ? accent : Colors.white54,
                                      size: 22),
                                    const Gap(6),
                                    Text(opt.label,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── Font scale ────────────────────────────────────────────
                    _Section(
                      title: 'Text Size',
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('A', style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white54, fontSize: 12)),
                              Text('A', style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white, fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: accent,
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                              thumbColor: accent,
                              overlayColor: accent.withValues(alpha: 0.2),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _draft.fontScale,
                              min: 0.85,
                              max: 1.20,
                              divisions: 7,
                              onChanged: (v) => setState(
                                  () => _draft = _draft.copyWith(fontScale: v)),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Small', style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white38, fontSize: 11)),
                              Text(
                                '${(_draft.fontScale * 100).round()}%',
                                style: GoogleFonts.spaceGrotesk(
                                  color: accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text('Large', style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live preview mini card ────────────────────────────────────────────────────

class _LivePreviewCard extends StatelessWidget {
  final AppThemeConfig config;
  const _LivePreviewCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final accent = config.primaryColor;
    final cardColor = switch (config.cardStyle) {
      'glass'    => Colors.white.withValues(alpha: 0.08),
      'outlined' => Colors.transparent,
      _          => const Color(0xFF111116),
    };
    final cardBorder = switch (config.cardStyle) {
      'outlined' => Border.all(color: accent.withValues(alpha: 0.5)),
      _          => Border.all(color: Colors.white.withValues(alpha: 0.06)),
    };

    return Container(
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.scaffoldColor, config.blobColor.withValues(alpha: 0.25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Mini card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: cardBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sample Post',
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 12 * config.fontScale,
                        fontWeight: FontWeight.w700,
                      )),
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('Donate',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 10 * config.fontScale,
                            fontWeight: FontWeight.w700,
                          )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(12),
            // Mini accent dot + info
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: accent.withValues(alpha: 0.5),
                      blurRadius: 12,
                    )],
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 16),
                ),
                const Gap(8),
                Text(
                  config.cardStyle[0].toUpperCase() +
                  config.cardStyle.substring(1),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            )),
          const Gap(14),
          child,
        ],
      ),
    );
  }
}

// ─── Animated background mesh ──────────────────────────────────────────────────

class _PreviewMeshPainter extends CustomPainter {
  final double t;
  final Color blobColor;
  const _PreviewMeshPainter({required this.t, required this.blobColor});

  @override
  void paint(Canvas canvas, Size s) {
    _blob(canvas, s,
      cx: s.width * (0.15 + 0.2 * t), cy: s.height * (0.2 + 0.15 * t),
      r: s.width * 0.55, color: blobColor, opacity: 0.14);
    _blob(canvas, s,
      cx: s.width * (0.8 - 0.15 * t), cy: s.height * (0.7 - 0.1 * t),
      r: s.width * 0.50, color: blobColor, opacity: 0.10);
    _blob(canvas, s,
      cx: s.width * (0.9 + 0.08 * sin(t * pi)), cy: s.height * 0.1,
      r: s.width * 0.25, color: blobColor, opacity: 0.06);
  }

  void _blob(Canvas c, Size s, {
    required double cx, required double cy,
    required double r, required Color color, required double opacity,
  }) {
    c.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
  }

  @override
  bool shouldRepaint(_PreviewMeshPainter o) => o.t != t || o.blobColor != blobColor;
}

// ─── Data models ───────────────────────────────────────────────────────────────

class _Swatch {
  final String label;
  final int    value;
  final String hex;
  const _Swatch({required this.label, required this.value, required this.hex});
}

class _BgOption {
  final String       id;
  final String       label;
  final List<Color>  colors;
  const _BgOption({required this.id, required this.label, required this.colors});
}

class _CardOption {
  final String  id;
  final String  label;
  final IconData icon;
  const _CardOption({required this.id, required this.label, required this.icon});
}
