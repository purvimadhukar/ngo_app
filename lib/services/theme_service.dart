import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── App Theme Config ──────────────────────────────────────────────────────────

class AppThemeConfig {
  final int   primaryColorValue;   // stored as int in Firestore
  final String backgroundStyle;   // 'pure_dark' | 'teal' | 'blue' | 'magenta' | 'forest' | 'slate'
  final String cardStyle;         // 'glass' | 'solid' | 'outlined'
  final double fontScale;         // 0.85 – 1.20

  const AppThemeConfig({
    required this.primaryColorValue,
    required this.backgroundStyle,
    required this.cardStyle,
    required this.fontScale,
  });

  Color get primaryColor => Color(primaryColorValue);

  // Dark base for each background style
  Color get scaffoldColor => switch (backgroundStyle) {
    'teal'    => const Color(0xFF030D10),
    'blue'    => const Color(0xFF04040E),
    'magenta' => const Color(0xFF08040A),
    'forest'  => const Color(0xFF030A05),
    'slate'   => const Color(0xFF060810),
    _         => const Color(0xFF07070A),   // pure_dark
  };

  // Accent blob color for animated backgrounds
  Color get blobColor => switch (backgroundStyle) {
    'teal'    => const Color(0xFF24A3BE),
    'blue'    => const Color(0xFF2B8CE6),
    'magenta' => const Color(0xFF9B4189),
    'forest'  => const Color(0xFF1DB884),
    'slate'   => const Color(0xFF6B7AE8),
    _         => const Color(0xFF2B8CE6),
  };

  static const AppThemeConfig defaults = AppThemeConfig(
    primaryColorValue: 0xFF2B8CE6,
    backgroundStyle:   'blue',
    cardStyle:         'glass',
    fontScale:         1.0,
  );

  factory AppThemeConfig.fromMap(Map<String, dynamic> m) => AppThemeConfig(
    primaryColorValue: (m['primaryColor'] as int?) ?? defaults.primaryColorValue,
    backgroundStyle:   (m['backgroundStyle'] as String?) ?? defaults.backgroundStyle,
    cardStyle:         (m['cardStyle'] as String?) ?? defaults.cardStyle,
    fontScale:         (m['fontScale'] as num?)?.toDouble() ?? defaults.fontScale,
  );

  Map<String, dynamic> toMap() => {
    'primaryColor':    primaryColorValue,
    'backgroundStyle': backgroundStyle,
    'cardStyle':       cardStyle,
    'fontScale':       fontScale,
  };

  AppThemeConfig copyWith({
    int? primaryColorValue,
    String? backgroundStyle,
    String? cardStyle,
    double? fontScale,
  }) => AppThemeConfig(
    primaryColorValue: primaryColorValue ?? this.primaryColorValue,
    backgroundStyle:   backgroundStyle   ?? this.backgroundStyle,
    cardStyle:         cardStyle         ?? this.cardStyle,
    fontScale:         fontScale         ?? this.fontScale,
  );
}

// ─── Theme Service ─────────────────────────────────────────────────────────────

class ThemeService {
  ThemeService._();

  static final _doc = FirebaseFirestore.instance
      .collection('config')
      .doc('appTheme');

  /// Live notifier — the entire app listens to this
  static final config = ValueNotifier<AppThemeConfig>(AppThemeConfig.defaults);

  /// Call once in main() before runApp
  static Future<void> load() async {
    try {
      final snap = await _doc.get().timeout(const Duration(seconds: 5));
      if (snap.exists && snap.data() != null) {
        config.value = AppThemeConfig.fromMap(snap.data()!);
      }
    } catch (_) {
      // Fallback to defaults — no crash
    }
  }

  /// Update locally + persist to Firestore
  static Future<void> save(AppThemeConfig cfg) async {
    config.value = cfg;
    try {
      await _doc.set(cfg.toMap());
    } catch (_) {}
  }
}
