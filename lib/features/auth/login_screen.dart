import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscure   = true;
  bool _loading   = false;
  String? _error;

  late final AnimationController _blob1;
  late final AnimationController _blob2;
  late final AnimationController _blob3;
  late final AnimationController _enter;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;

  static const _bg     = Color(0xFF05070A);
  static const _green  = Color(0xFF24A3BE);   // teal/cyan — login theme
  static const _coral  = Color(0xFFE8654A);
  static const _surface = Color(0xFF111115);
  static const _border  = Color(0xFF1E1E26);
  static const _textPrimary = Color(0xFFF0F0F4);
  static const _textMuted   = Color(0xFF6B6B7A);

  @override
  void initState() {
    super.initState();
    _blob1 = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _blob2 = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat(reverse: true);
    _blob3 = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _cardSlide = Tween<double>(begin: 32, end: 0).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _cardFade  = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose();
    _blob1.dispose(); _blob2.dispose(); _blob3.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendly(e.code));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(String code) => switch (code) {
    'user-not-found'    => 'No account found with that email.',
    'wrong-password'    => 'Incorrect password.',
    'invalid-credential'=> 'Incorrect email or password.',
    'invalid-email'     => 'Enter a valid email address.',
    'user-disabled'     => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Try again later.',
    _                   => 'Sign-in failed. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_blob1, _blob2, _blob3, _enter]),
        builder: (_, __) {
          return Stack(
            fit: StackFit.expand,
            children: [

              // ── Fluid mesh background (same as splash) ──────────────────────
              CustomPaint(painter: _LoginMeshPainter(
                t1: _blob1.value, t2: _blob2.value, t3: _blob3.value,
              )),

              // ── Centered card ───────────────────────────────────────────────
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Transform.translate(
                    offset: Offset(0, _cardSlide.value),
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Header ────────────────────────────────────────
                            _buildHeader(),
                            const Gap(36),

                            // ── Glassmorphism card ────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _surface.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: _border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 40, offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildField(
                                      ctrl: _emailCtrl,
                                      label: 'Email address',
                                      hint: 'you@example.com',
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Email is required';
                                        if (!v.contains('@')) return 'Enter a valid email';
                                        return null;
                                      },
                                    ),
                                    const Gap(20),
                                    _buildField(
                                      ctrl: _passwordCtrl,
                                      label: 'Password',
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscure: _obscure,
                                      suffix: GestureDetector(
                                        onTap: () => setState(() => _obscure = !_obscure),
                                        child: Icon(
                                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: _textMuted, size: 18,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Password is required';
                                        if (v.length < 6) return 'At least 6 characters';
                                        return null;
                                      },
                                    ),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _showForgotPassword,
                                        style: TextButton.styleFrom(
                                          foregroundColor: _green,
                                          padding: const EdgeInsets.only(top: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text('Forgot password?',
                                            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500)),
                                      ),
                                    ),

                                    const Gap(8),

                                    // Error
                                    if (_error != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _coral.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _coral.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(children: [
                                          const Icon(Icons.info_outline_rounded, color: _coral, size: 16),
                                          const Gap(10),
                                          Expanded(child: Text(_error!,
                                              style: GoogleFonts.spaceGrotesk(color: _coral, fontSize: 13))),
                                        ]),
                                      ),
                                      const Gap(16),
                                    ],

                                    // Sign in button
                                    _buildSignInButton(),
                                  ],
                                ),
                              ),
                            ),

                            const Gap(16),

                            // DEV quick login
                            _buildDevBar(),

                            const Gap(24),

                            // Sign up link
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.spaceGrotesk(color: _textMuted, fontSize: 13),
                                  children: [
                                    const TextSpan(text: "Don't have an account?  "),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(context,
                                            MaterialPageRoute(builder: (_) => const SignupScreen())),
                                        child: Text('Sign up',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: _green, fontSize: 13, fontWeight: FontWeight.w700,
                                          )),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: _green.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 26),
        ),
        const Gap(20),
        Text(
          'AidBridge',
          style: GoogleFonts.bricolageGrotesque(
            color: _textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
        const Gap(6),
        Text(
          'Sign in to continue making a difference',
          style: GoogleFonts.spaceGrotesk(color: _textMuted, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.spaceGrotesk(
            color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3,
          )),
        const Gap(8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.spaceGrotesk(color: _textPrimary, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(color: _textMuted.withValues(alpha: 0.6), fontSize: 15),
            prefixIcon: Icon(icon, color: _textMuted, size: 18),
            suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix) : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _green, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _coral.withValues(alpha: 0.7))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _coral, width: 1.5)),
            errorStyle: GoogleFonts.spaceGrotesk(color: _coral, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: _loading
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_green, Color(0xFF16A373)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)),
              ),
            )
          : _GradientButton(
              onTap: _signIn,
              label: 'Sign in',
            ),
    );
  }

  static const _devAccounts = [
    {'label': 'NGO', 'email': 'majorprojectclaude@gmail.com', 'pass': 'purvi123'},
  ];

  Widget _buildDevBar() {
    return Column(
      children: [
        Row(children: [
          const Expanded(child: Divider(color: Color(0xFF1A1A22))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('DEV QUICK LOGIN',
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF3A3A4A), fontSize: 10, letterSpacing: 1)),
          ),
          const Expanded(child: Divider(color: Color(0xFF1A1A22))),
        ]),
        const Gap(12),
        Wrap(
          spacing: 8,
          children: _devAccounts.map((a) => GestureDetector(
            onTap: () async {
              _emailCtrl.text = a['email']!;
              _passwordCtrl.text = a['pass']!;
              await _signIn();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFF1E1E26)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                const Gap(7),
                Text(a['label']!,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Future<void> _showForgotPassword() async {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ForgotSheet(ctrl: ctrl),
    );
  }
}

// ─── Gradient CTA button ──────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _GradientButton({required this.onTap, required this.label});
  @override State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _hovered = false;

  // Teal — login theme
  static const _btnColor  = Color(0xFF24A3BE);
  static const _glowColor = Color(0xFF1A8BA8);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: _btnColor,
                borderRadius: BorderRadius.circular(9),
                // Green glow on hover
                boxShadow: _hovered
                    ? [BoxShadow(
                        color: _glowColor.withValues(alpha: 0.85),
                        blurRadius: 56,
                        spreadRadius: -14,
                        offset: const Offset(7, 5),
                      )]
                    : [],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Login mesh background ────────────────────────────────────────────────────

class _LoginMeshPainter extends CustomPainter {
  final double t1, t2, t3;
  const _LoginMeshPainter({required this.t1, required this.t2, required this.t3});

  @override
  void paint(Canvas canvas, Size s) {
    // Teal/cyan blobs — login theme (dark red-black → teal gradient)
    _blob(canvas, s, cx: s.width * (0.1 + 0.15 * t1), cy: s.height * (0.15 + 0.12 * t1),
        r: s.width * 0.55, color: const Color(0xFF0F0202), opacity: 0.60); // dark warmth
    _blob(canvas, s, cx: s.width * (0.75 - 0.15 * t2), cy: s.height * (0.65 - 0.1 * t2),
        r: s.width * 0.65, color: const Color(0xFF24A3BE), opacity: 0.20); // teal glow
    _blob(canvas, s, cx: s.width * (0.85 + 0.08 * sin(t3 * pi)), cy: s.height * (0.12 + 0.06 * t1),
        r: s.width * 0.35, color: const Color(0xFF1A8BA8), opacity: 0.14); // mid teal
    _blob(canvas, s, cx: s.width * (0.2 - 0.08 * t3), cy: s.height * (0.78 + 0.08 * t2),
        r: s.width * 0.3, color: const Color(0xFF24A3BE), opacity: 0.10); // bottom teal
  }

  void _blob(Canvas c, Size s, {required double cx, required double cy,
      required double r, required Color color, required double opacity}) {
    c.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
  }

  @override
  bool shouldRepaint(_LoginMeshPainter o) => o.t1 != t1 || o.t2 != t2 || o.t3 != t3;
}

// ─── Forgot password sheet ────────────────────────────────────────────────────

class _ForgotSheet extends StatefulWidget {
  final TextEditingController ctrl;
  const _ForgotSheet({required this.ctrl});
  @override State<_ForgotSheet> createState() => _ForgotSheetState();
}

class _ForgotSheetState extends State<_ForgotSheet> {
  bool _sent = false, _sending = false;
  String? _error;

  static const _green = Color(0xFF1DB884);
  static const _textPrimary = Color(0xFFF0F0F4);
  static const _textMuted   = Color(0xFF6B6B7A);
  static const _coral = Color(0xFFE8654A);

  Future<void> _send() async {
    final email = widget.ctrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.'); return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: const Color(0xFF2A2A32), borderRadius: BorderRadius.circular(2)))),
        const Gap(24),
        if (_sent) ...[
          const Center(child: Icon(Icons.mark_email_read_outlined, color: _green, size: 48)),
          const Gap(16),
          Center(child: Text('Check your inbox',
              style: GoogleFonts.syne(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w700))),
          const Gap(8),
          Center(child: Text('Reset link sent to ${widget.ctrl.text.trim()}',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(color: _textMuted, fontSize: 14))),
          const Gap(28),
          SizedBox(width: double.infinity, height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Done', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
            )),
        ] else ...[
          Text('Reset password', style: GoogleFonts.syne(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const Gap(6),
          Text("We'll send a reset link to your email.",
              style: GoogleFonts.spaceGrotesk(color: _textMuted, fontSize: 14)),
          const Gap(24),
          TextFormField(
            controller: widget.ctrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.spaceGrotesk(color: _textPrimary),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              hintStyle: GoogleFonts.spaceGrotesk(color: _textMuted),
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: _textMuted, size: 18),
              filled: true, fillColor: const Color(0xFF0D0D0F),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A30))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A30))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
              errorText: _error,
              errorStyle: GoogleFonts.spaceGrotesk(color: _coral, fontSize: 12),
            ),
          ),
          const Gap(20),
          SizedBox(width: double.infinity, height: 50,
            child: FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(backgroundColor: _green,
                  disabledBackgroundColor: _green.withValues(alpha: 0.5),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : Text('Send reset link', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
            )),
        ],
      ]),
    );
  }
}
