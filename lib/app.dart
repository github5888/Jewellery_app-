import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/main_navigation_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'state/nurse_portal_controller.dart';

class SmartHospitalNurseApp extends StatefulWidget {
  const SmartHospitalNurseApp({super.key});

  @override
  State<SmartHospitalNurseApp> createState() => _SmartHospitalNurseAppState();
}

class _SmartHospitalNurseAppState extends State<SmartHospitalNurseApp> {
  late final NursePortalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NursePortalController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NursePortalScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          Widget rootScreen;
          switch (_controller.authStage) {
            case AuthStage.initializing:
              rootScreen = const SplashScreen();
              break;
            case AuthStage.unauthenticated:
              rootScreen = const LoginScreen();
              break;
            case AuthStage.authenticated:
              rootScreen = const MainNavigationShell();
              break;
          }

          return MaterialApp(
            title: 'Smart Super Speciality Hospital - Nurse Portal',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: rootScreen,
            ),
          );
        },
      ),
    );
  }
}
