import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'widgets/role_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AidBridgeApp());
}

class AidBridgeApp extends StatelessWidget {
  const AidBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AidBridge',
      debugShowCheckedModeBanner: false,
      theme: AidTheme.build(),
      home: const RoleRouter(),
    );
  }
}
