import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/auth/auth_controller.dart';
import 'core/layout/adaptive_layout.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/desktop/presentation/desktop_shell_screen.dart';
import 'features/mobile/presentation/mobile_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.instance.initialize();

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
    final restoreFuture = widget.authController.restoreSession();

    try {
      await Future.any([
        restoreFuture,
        Future<void>.delayed(const Duration(seconds: 2)),
      ]);
    } catch (_) {
      // Ignorar para no bloquear la UI.
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
            fontFamily: 'TeslaSans',
            scaffoldBackgroundColor: const Color(0xFFF7F4EA),
            useMaterial3: true,
          ),
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();
            final textEditingShortcuts = <ShortcutActivator, Intent>{
              const SingleActivator(LogicalKeyboardKey.keyA, control: true):
                  const SelectAllTextIntent(SelectionChangedCause.keyboard),
              const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
                  const SelectAllTextIntent(SelectionChangedCause.keyboard),
              const SingleActivator(LogicalKeyboardKey.keyC, control: true):
                  CopySelectionTextIntent.copy,
              const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
                  CopySelectionTextIntent.copy,
              const SingleActivator(LogicalKeyboardKey.keyX, control: true):
                  const CopySelectionTextIntent.cut(
                    SelectionChangedCause.keyboard,
                  ),
              const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
                  const CopySelectionTextIntent.cut(
                    SelectionChangedCause.keyboard,
                  ),
              const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                  const PasteTextIntent(SelectionChangedCause.keyboard),
              const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                  const PasteTextIntent(SelectionChangedCause.keyboard),
            };

            return Shortcuts(
              shortcuts: <ShortcutActivator, Intent>{
                ...WidgetsApp.defaultShortcuts,
                ...textEditingShortcuts,
              },
              child: NotificationListener<ScrollNotification>(
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
