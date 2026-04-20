import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/layout/adaptive_layout.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/desktop/presentation/desktop_shell_screen.dart';
import 'features/mobile/presentation/mobile_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(TeslaMobileApp(
    authController: AuthController(TokenStorage()),
  ));
}

class TeslaMobileApp extends StatefulWidget {
  const TeslaMobileApp({super.key, required this.authController});

  final AuthController authController;

  @override
  State<TeslaMobileApp> createState() => _TeslaMobileAppState();
}

class _TeslaMobileAppState extends State<TeslaMobileApp> {
  bool _loading = true;
  final FocusNode _activityFocusNode = FocusNode(debugLabel: 'activity-root');

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _activityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await widget.authController.restoreSession();
    } catch (_) {
      // Evita bloqueo infinito del splash ante fallos de almacenamiento/plataforma.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tesla Mobile',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F4EA),
            useMaterial3: true,
          ),
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (widget.authController.isAuthenticated) {
                  widget.authController.registerActivity();
                }
                return false;
              },
              child: Focus(
                focusNode: _activityFocusNode,
                autofocus: true,
                onKeyEvent: (_, __) {
                  if (widget.authController.isAuthenticated) {
                    widget.authController.registerActivity();
                  }
                  return KeyEventResult.ignored;
                },
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) =>
                      widget.authController.registerActivity(),
                  onPointerMove: (_) =>
                      widget.authController.registerActivity(),
                  onPointerSignal: (_) =>
                      widget.authController.registerActivity(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.authController.registerActivity,
                    child: content,
                  ),
                ),
              ),
            );
          },
          home: _loading
              ? const SplashScreen()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop =
                        AdaptiveLayout.isDesktopWidth(constraints.maxWidth);

                    if (!widget.authController.isAuthenticated) {
                      return LoginScreen(
                        authController: widget.authController,
                      );
                    }

                    return isDesktop
                        ? DesktopShellScreen(
                            authController: widget.authController,
                          )
                        : MobileShellScreen(
                            authController: widget.authController,
                          );
                  },
                ),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B3B36), Color(0xFF0F766E), Color(0xFFE9C46A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 80, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Tesla System',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Base movil interna',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
