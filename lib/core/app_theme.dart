import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  AidBridge Design Tokens
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
//  Gradient helpers (Bold & Vibrant style)
// ─────────────────────────────────────────────

class AidGradients {
  AidGradients._();

  static const emerald = LinearGradient(
    colors: [Color(0xFF1DB884), Color(0xFF0F9E6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const donor = LinearGradient(
    colors: [Color(0xFF8B7FE8), Color(0xFF6356C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const volunteer = LinearGradient(
    colors: [Color(0xFFE8654A), Color(0xFFD44A30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const purple = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroCard = LinearGradient(
    colors: [Color(0xFF1A1A1F), Color(0xFF111115)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient roleGradient(String role) {
    switch (role) {
      case 'ngo':
      case 'careHome': return emerald;
      case 'donor':    return donor;
      case 'volunteer':return volunteer;
      default:         return emerald;
    }
  }
}

class AidColors {
  AidColors._();

  // Backgrounds
  static const background  = Color(0xFF0A0A0D);
  static const surface     = Color(0xFF111116);
  static const elevated    = Color(0xFF18181E);
  static const overlay     = Color(0xFF222228);

  // Role accents
  static const ngoAccent       = Color(0xFF1DB884);
  static const ngoAccentMuted  = Color(0xFF0F6E56);
  static const ngoAccentDim    = Color(0xFF0A3D30);

  static const donorAccent      = Color(0xFF8B7FE8);
  static const donorAccentMuted = Color(0xFF534AB7);
  static const donorAccentDim   = Color(0xFF1E1A3D);

  static const volunteerAccent      = Color(0xFFE8654A);
  static const volunteerAccentMuted = Color(0xFF993C1D);
  static const volunteerAccentDim   = Color(0xFF3D1A0E);

  // Semantic
  static const success = Color(0xFF34C77B);
  static const warning = Color(0xFFF0A500);
  static const error   = Color(0xFFE8514A);
  static const info    = Color(0xFF4A90E8);

  // Text
  static const textPrimary   = Color(0xFFF2F2F3);
  static const textSecondary = Color(0xFF9A9AA8);
  static const textMuted     = Color(0xFF9A9AA8);   // alias used across screens
  static const textTertiary  = Color(0xFF5A5A68);
  static const textDisabled  = Color(0xFF3A3A48);

  // Borders
  static const borderSubtle  = Color(0xFF222228);
  static const borderDefault = Color(0xFF2E2E38);
  static const borderStrong  = Color(0xFF44444F);
}

class AidTextStyles {
  AidTextStyles._();

  // ── Base fonts ────────────────────────────────────────────────────────────
  // Space Grotesk  → all body, labels, UI text
  // Syne           → headings & section titles (bold, editorial)
  // Bricolage Grotesque → hero display moments (splash, dashboard titles)

  static TextStyle get _body => GoogleFonts.spaceGrotesk(
    color: AidColors.textPrimary,
    letterSpacing: -0.1,
  );

  static TextStyle get _heading => GoogleFonts.syne(
    color: AidColors.textPrimary,
    letterSpacing: -0.4,
  );

  static TextStyle get _display => GoogleFonts.bricolageGrotesque(
    color: AidColors.textPrimary,
    letterSpacing: -1.0,
  );

  // ── Display — Bricolage Grotesque (splash screens, hero banners) ──────────
  static TextStyle get displayLg => _display.copyWith(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.05);
  static TextStyle get displaySm => _display.copyWith(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.1);

  // ── Headings — Syne (section titles, card titles, screen names) ───────────
  static TextStyle get headingLg => _heading.copyWith(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.2);
  static TextStyle get headingMd => _heading.copyWith(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25);
  static TextStyle get headingSm => _heading.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3);

  // ── Body — Space Grotesk (all UI text, descriptions, labels) ─────────────
  static TextStyle get bodyLg  => _body.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle get bodyMd  => _body.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle get bodySm  => _body.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.55, color: AidColors.textSecondary);
  static TextStyle get labelLg => _body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get labelMd => _body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get labelSm => _body.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3, color: AidColors.textTertiary);
  static TextStyle get mono    => GoogleFonts.robotoMono(fontSize: 13, color: AidColors.textPrimary);

  // Aliases
  static final heading = headingLg;
  static final body    = bodyMd;
  static final caption = labelMd;
}

// ─────────────────────────────────────────────
//  Role Theme Wrapper
// ─────────────────────────────────────────────

enum AidRole { ngo, donor, volunteer }

extension AidRoleTheme on AidRole {
  Color get accent => switch (this) {
    AidRole.ngo       => AidColors.ngoAccent,
    AidRole.donor     => AidColors.donorAccent,
    AidRole.volunteer => AidColors.volunteerAccent,
  };

  Color get accentMuted => switch (this) {
    AidRole.ngo       => AidColors.ngoAccentMuted,
    AidRole.donor     => AidColors.donorAccentMuted,
    AidRole.volunteer => AidColors.volunteerAccentMuted,
  };

  Color get accentDim => switch (this) {
    AidRole.ngo       => AidColors.ngoAccentDim,
    AidRole.donor     => AidColors.donorAccentDim,
    AidRole.volunteer => AidColors.volunteerAccentDim,
  };

  String get label => switch (this) {
    AidRole.ngo       => 'NGO',
    AidRole.donor     => 'Donor',
    AidRole.volunteer => 'Volunteer',
  };
}

// ─────────────────────────────────────────────
//  Smooth slide+fade page transition helper
// ─────────────────────────────────────────────

Route<T> aidRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => page,
  transitionDuration: const Duration(milliseconds: 360),
  reverseTransitionDuration: const Duration(milliseconds: 280),
  transitionsBuilder: (_, anim, secondAnim, child) {
    final slide = Tween(begin: const Offset(0.05, 0.0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(anim);
    final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  },
);

// ─────────────────────────────────────────────
//  Main ThemeData Builder
// ─────────────────────────────────────────────

class AidTheme {
  AidTheme._();

  static ThemeData build({Color roleAccent = AidColors.ngoAccent}) {
    final cs = ColorScheme.dark(
      primary:                     roleAccent,
      onPrimary:                   AidColors.background,
      secondary:                   roleAccent.withValues(alpha: 0.6),
      onSecondary:                 AidColors.textPrimary,
      surface:                     AidColors.surface,
      onSurface:                   AidColors.textPrimary,
      surfaceContainerHighest:     AidColors.elevated,
      error:                       AidColors.error,
      onError:                     Colors.white,
      outline:                     AidColors.borderDefault,
      outlineVariant:              AidColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3:            true,
      colorScheme:             cs,
      scaffoldBackgroundColor: AidColors.background,
      splashFactory:           NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor:       AidColors.background,
        foregroundColor:       AidColors.textPrimary,
        elevation:             0,
        scrolledUnderElevation:0,
        centerTitle:           false,
        titleTextStyle:        AidTextStyles.headingMd,
        iconTheme:             const IconThemeData(color: AidColors.textPrimary, size: 22),
        systemOverlayStyle:    const SystemUiOverlayStyle(
          statusBarBrightness:               Brightness.dark,
          statusBarIconBrightness:           Brightness.light,
          systemNavigationBarColor:          AidColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      AidColors.surface,
        selectedItemColor:    roleAccent,
        unselectedItemColor:  AidColors.textTertiary,
        type:                 BottomNavigationBarType.fixed,
        selectedLabelStyle:   AidTextStyles.labelSm.copyWith(color: roleAccent),
        unselectedLabelStyle: AidTextStyles.labelSm,
        elevation:            0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:  AidColors.surface,
        indicatorColor:   roleAccent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: roleAccent, size: 22);
          }
          return const IconThemeData(color: AidColors.textTertiary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AidTextStyles.labelSm.copyWith(color: roleAccent);
          }
          return AidTextStyles.labelSm;
        }),
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        height:           64,
      ),

      cardTheme: CardThemeData(
        color:            AidColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AidColors.borderSubtle, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:        roleAccent,
          foregroundColor:        AidColors.background,
          disabledBackgroundColor:AidColors.borderDefault,
          disabledForegroundColor:AidColors.textTertiary,
          elevation:              0,
          shadowColor:            Colors.transparent,
          textStyle:              AidTextStyles.labelLg.copyWith(
            color: AidColors.background, fontWeight: FontWeight.w700,
          ),
          padding:                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize:            const Size(0, 52),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: roleAccent,
          side:            BorderSide(color: roleAccent.withValues(alpha: 0.5), width: 1),
          textStyle:       AidTextStyles.labelLg.copyWith(color: roleAccent),
          padding:         const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          minimumSize:     const Size(0, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: roleAccent,
          textStyle:       AidTextStyles.labelLg.copyWith(color: roleAccent),
          padding:         const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: roleAccent.withValues(alpha: 0.15),
          foregroundColor: roleAccent,
          textStyle:       AidTextStyles.labelLg.copyWith(color: roleAccent),
          elevation:       0,
          shadowColor:     Colors.transparent,
          padding:         const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          minimumSize:     const Size(0, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      AidColors.elevated,
        hoverColor:     AidColors.overlay,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AidColors.borderDefault, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AidColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: roleAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AidColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AidColors.error, width: 1.5),
        ),
        labelStyle:          AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
        hintStyle:           AidTextStyles.bodyMd.copyWith(color: AidColors.textTertiary),
        floatingLabelStyle:  AidTextStyles.labelMd.copyWith(color: roleAccent),
        prefixIconColor:     AidColors.textTertiary,
        suffixIconColor:     AidColors.textTertiary,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:     AidColors.elevated,
        selectedColor:       roleAccent.withValues(alpha: 0.2),
        disabledColor:       AidColors.surface,
        side:                const BorderSide(color: AidColors.borderDefault, width: 1),
        labelStyle:          AidTextStyles.labelMd.copyWith(color: AidColors.textSecondary),
        secondaryLabelStyle: AidTextStyles.labelMd.copyWith(color: roleAccent),
        padding:             const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        elevation:           0,
        pressElevation:      0,
      ),

      dividerTheme: const DividerThemeData(
        color:     AidColors.borderSubtle,
        thickness: 1,
        space:     1,
      ),

      listTileTheme: const ListTileThemeData(
        tileColor:       Colors.transparent,
        iconColor:       AidColors.textTertiary,
        textColor:       AidColors.textPrimary,
        contentPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AidColors.overlay,
        contentTextStyle: AidTextStyles.bodyMd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior:         SnackBarBehavior.floating,
        elevation:        0,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:  AidColors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor:  AidColors.borderStrong,
        dragHandleSize:   Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:  AidColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        titleTextStyle:   AidTextStyles.headingMd,
        contentTextStyle: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AidColors.background : AidColors.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? roleAccent : AidColors.overlay),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      textTheme: TextTheme(
        displayLarge:  AidTextStyles.displayLg,
        displayMedium: AidTextStyles.displaySm,
        headlineLarge: AidTextStyles.headingLg,
        headlineMedium:AidTextStyles.headingMd,
        headlineSmall: AidTextStyles.headingSm,
        bodyLarge:     AidTextStyles.bodyLg,
        bodyMedium:    AidTextStyles.bodyMd,
        bodySmall:     AidTextStyles.bodySm,
        labelLarge:    AidTextStyles.labelLg,
        labelMedium:   AidTextStyles.labelMd,
        labelSmall:    AidTextStyles.labelSm,
      ),

      iconTheme:        const IconThemeData(color: AidColors.textSecondary, size: 20),
      primaryIconTheme: IconThemeData(color: roleAccent, size: 20),
    );
  }

  static ThemeData get ngo       => build(roleAccent: AidColors.ngoAccent);
  static ThemeData get donor     => build(roleAccent: AidColors.donorAccent);
  static ThemeData get volunteer => build(roleAccent: AidColors.volunteerAccent);
}