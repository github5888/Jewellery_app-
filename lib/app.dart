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
            theme: AppTheme.fromPersonalTheme(_controller.personalTheme),
            builder: (ctx, child) {
              // On mobile devices (<= 540px), render 100% native edge-to-edge.
              // On wide desktop browsers (e.g. Chrome on Windows), frame inside a
              // crisp 430px mobile viewport matching the Nurse Portal design.
              return LayoutBuilder(
                builder: (ctx, constraints) {
                  if (constraints.maxWidth <= 540) {
                    return child ?? const SizedBox.shrink();
                  }
                  return ColoredBox(
                    color: const Color(0xFFD9E7FA),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 430,
                            maxHeight: 920,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFC2D7F4),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26083B78),
                                blurRadius: 32,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MediaQuery(
                            data: MediaQuery.of(ctx).copyWith(
                              size: Size(
                                430,
                                (constraints.maxHeight - 28).clamp(480, 920),
                              ),
                            ),
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
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
