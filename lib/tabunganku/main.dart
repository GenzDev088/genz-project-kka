import 'dart:ui';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'features/settings/presentation/providers/security_provider.dart';
import 'features/auth/presentation/pages/lock_screen.dart';
import 'core/widgets/notification_observer.dart';
import 'core/config/app_config.dart';
import 'core/providers/module_providers.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);


  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (androidPlugin != null) {
    await androidPlugin.requestNotificationsPermission();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isFirebaseEnabled) {

  }


  try {
    tz_data.initializeTimeZones();
    final dynamic location = await FlutterTimezone.getLocalTimezone();

    final String locationName = location is String
        ? location
        : (location as dynamic).identifier.toString();
    tz.setLocalLocation(tz.getLocation(locationName));
    debugPrint('Timezone set to: $locationName');
  } catch (e) {
    debugPrint(
      'Gagal mendeteksi timezone otomatis: $e. Menggunakan Asia/Jakarta sebagai default.',
    );
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      debugPrint('Fallback Asia/Jakarta juga gagal. Menggunakan UTC.');
    }
  }


  await _initNotifications();


  await initializeDateFormatting('id_ID', null);


  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };


  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true; // true = error sudah ditangani, jangan crash
  };

  runApp(const ProviderScope(child: TabunganKuApp()));
}

class TabunganKuModule extends StatelessWidget {
  final VoidCallback? onExit;
  const TabunganKuModule({super.key, this.onExit});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: TabunganKuApp(onExit: onExit),
    );
  }
}

class TabunganKuApp extends ConsumerStatefulWidget {
  final VoidCallback? onExit;
  const TabunganKuApp({super.key, this.onExit});

  @override
  ConsumerState<TabunganKuApp> createState() => _TabunganKuAppState();
}

class _TabunganKuAppState extends ConsumerState<TabunganKuApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(moduleExitProvider) != widget.onExit) {
        ref.read(moduleExitProvider.notifier).state = widget.onExit;
      }
    });

    final appRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return NotificationObserver(
      child: MaterialApp.router(
        title: 'TabunganKu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerDelegate: appRouter.routerDelegate,
        routeInformationParser: appRouter.routeInformationParser,
        routeInformationProvider: appRouter.routeInformationProvider,
        builder: (innerContext, child) {
          return Consumer(
            builder: (context, ref, _) {
              final security = ref.watch(securityProvider);
              final router = ref.watch(appRouterProvider);

              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;


                  final navigator = rootNavigatorKey.currentState;
                  if (navigator != null && navigator.canPop()) {
                    navigator.pop();
                    return;
                  }


                  final currentTab = ref.read(dashboardTabIndexProvider);
                  if (currentTab != 0) {

                    ref.read(dashboardTabIndexProvider.notifier).state = 0;
                    return;
                  }


                  final onExit = ref.read(moduleExitProvider);
                  if (onExit != null) {
                    onExit();
                    return;
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: Builder(builder: (context) {

                    String location = '/';
                    try {
                      location =
                          router.routerDelegate.currentConfiguration.fullPath;
                    } catch (_) {}

                    final isLockableRoute = location != '/' &&
                        location != '/splash' &&
                        location != '/pin-setup' &&
                        location != '/lock';

                    final isSecurityEnabled =
                        security.hasPin || security.isBiometricEnabled;

                    if (isSecurityEnabled &&
                        !security.isAuthorized &&
                        isLockableRoute) {
                      return Stack(
                        children: [
                          if (child != null) child,
                          const LockScreen()
                        ],
                      );
                    }
                    return child ?? const SizedBox();
                  }),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
