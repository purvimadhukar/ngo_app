import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'services/theme_service.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load saved theme from Firestore before first frame
  await ThemeService.load();

  runApp(const AidBridgeApp());
}

class AidBridgeApp extends StatelessWidget {
  const AidBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder rebuilds MaterialApp whenever ThemeService.save() is called
    return ValueListenableBuilder<AppThemeConfig>(
      valueListenable: ThemeService.config,
      builder: (_, cfg, __) {
        return MaterialApp(
          title: 'AidBridge',
          debugShowCheckedModeBanner: false,
          theme: AidTheme.build(primaryColor: cfg.primaryColor),
          home: const SplashScreen(),
          onGenerateRoute: (settings) => _buildRoute(settings),
        );
      },
    );
  }

  static Route<dynamic> _buildRoute(RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => const SplashScreen(),
      transitionsBuilder: _slideTransition,
      transitionDuration: const Duration(milliseconds: 380),
    );
  }

  static Widget _slideTransition(
    BuildContext context,
    Animation<double> anim,
    Animation<double> secondaryAnim,
    Widget child,
  ) {
    const begin = Offset(0.04, 0.0);
    const end   = Offset.zero;
    final tween = Tween(begin: begin, end: end)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    final fade  = CurvedAnimation(parent: anim, curve: Curves.easeOut);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: anim.drive(tween), child: child),
    );
  }
}
