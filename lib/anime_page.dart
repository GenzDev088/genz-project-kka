import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:otax/core/anime/providers/animeonsen.dart';
import 'package:otax/core/app/logging.dart';
import 'package:otax/core/app/runtimeDatas.dart';
import 'package:otax/core/app/version.dart';
import 'package:otax/core/data/preferences.dart';
import 'package:otax/core/data/settings.dart';
import 'package:otax/core/data/theme.dart';
import 'package:otax/ui/models/notification.dart';
import 'package:otax/ui/models/providers/appProvider.dart';
import 'package:otax/ui/models/providers/mainNavProvider.dart';
import 'package:otax/ui/models/snackBar.dart';
import 'package:otax/ui/models/sources.dart';
import 'package:otax/ui/models/widgets/appWrapper.dart';
import 'package:otax/ui/pages/info.dart';
import 'package:otax/ui/pages/mainNav.dart';
import 'package:otax/ui/theme/manta.dart';
import 'package:otax/ui/theme/themes.dart';
import 'package:otax/ui/theme/types.dart';

void main(List<String> args) async {
  try {
    if (runWebViewTitleBarWidget(args)) {
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();


    AppVersion.init();

    await Hive.initFlutter(!Platform.isAndroid ? "animestream" : null);

    await loadAndAssignSettings();

    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );




      await windowManager.setResizable(true);
    }

    AnimeOnsen().checkAndUpdateToken();

    NotificationService().init();


    final sm = SourceManager.instance;

    sm
      ..addSources(sm.inbuiltSources)
      ..loadProviders(clearBeforeLoading: false);

















    runApp(
      ChangeNotifierProvider(
        create: (context) => AppProvider(),
        child: const AnimeStream(isStandalone: true),
      ),
    );
  } catch (err) {

    Logs.app.log(err.toString(), addToBuffer: true);
    Logs.app.log("state: Crashed", addToBuffer: true);
    await Logs.writeAllLogs();

    print("[CRASH] logged the error to logs folder");
    rethrow;
  }
}

Future<void> loadAndAssignSettings() async {
  await Settings().getSettings().then(
    (settings) => {
      currentUserSettings = settings,
      Logs.app.log("[STARTUP] Loaded user settings"),
    },
  );

  await UserPreferences.getUserPreferences().then((pref) {
    userPreferences = pref;
    Logs.app.log("[STARTUP] Loaded user preferences");
  });


  await getTheme().then((themeId) {

    if ((themeId > availableThemes.length && !kDebugMode) || themeId < 1) {
      Logs.app.log(
        "[STARTUP] Failed to apply theme with ID $themeId, Applying default theme",
      );
      showToast("Failed to apply theme. Using default theme");
      setTheme(11);
      themeId = 11;
    }

    final darkMode = currentUserSettings!.darkMode!;

    ThemeItem? theme = availableThemes
        .where((theme) => theme.id == themeId)
        .toList()
        .firstOrNull;

    if (theme == null) {

      theme = MantaTheme();
      Logs.app.log(
        "[STARTUP] Failed to apply theme with ID $themeId, Applying default theme",
      );
    }

    if (darkMode) {
      appTheme = theme.theme;
      appTheme.backgroundColor =
          (currentUserSettings!.amoledBackground ?? false)
          ? Colors.black
          : theme.theme.backgroundColor;
    } else {
      appTheme = AnimeStreamTheme(
        accentColor: theme.lightVariant.accentColor,
        textMainColor: theme.lightVariant.textMainColor,
        textSubColor: theme.lightVariant.textSubColor,
        backgroundColor: theme.lightVariant.backgroundColor,
        backgroundSubColor: theme.lightVariant.backgroundSubColor,
        modalSheetBackgroundColor: theme.lightVariant.modalSheetBackgroundColor,
        onAccent: theme.lightVariant.onAccent,
      );
    }

    Logs.app.log("[STARTUP] Loaded theme of ID $themeId (${theme.name})");
  });
}

class AnimeStream extends StatefulWidget {
  final bool isStandalone;
  const AnimeStream({super.key, this.isStandalone = false});

  static final GlobalKey<ScaffoldMessengerState> snackbarKey =
      GlobalKey<ScaffoldMessengerState>();

  static final navigatorKey = GlobalKey<NavigatorState>();
  @override
  State<AnimeStream> createState() => _AnimeStreamState();
}

class _AnimeStreamState extends State<AnimeStream> {
  StreamSubscription<Uri>? _sub;
  late AppLinks _appLinks;

  @override
  void initState() {
    listenDeepLinkCall();

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.black.withValues(alpha: 0.002),
        systemNavigationBarColor: Colors.black.withValues(alpha: 0.002),
      ),
    );




    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();






    super.dispose();
  }

  void listenDeepLinkCall() {
    _appLinks = AppLinks();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == "astrm") {
        Logs.app.log("Invoked DeepLink uri: ${uri.toString()}");
        String host = uri.host;
        switch (host) {
          case "info":
            {
              final id = int.tryParse(uri.queryParameters['id'] ?? "nothing");
              if (id != null) {
                AnimeStream.navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AppWrapper(firstPage: Info(id: id)),
                      ),
                    ) ??
                    print("Nah");
                break;
              }
            }
          default:
            floatingSnackBar("BAD-DEEPLINK: Host $host not recognized!");
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: (currentUserSettings?.darkMode ?? true)
            ? Brightness.light
            : Brightness.dark,
        statusBarColor: Colors.black.withValues(alpha: 0.002),
        systemNavigationBarColor: Colors.black.withValues(alpha: 0.002),
      ),
      child: DynamicColorBuilder(
        builder: (lightScheme, darkScheme) {
          late AnimeStreamTheme scheme;


          if (currentUserSettings?.darkMode ?? true) {
            scheme = AnimeStreamTheme(
              accentColor: darkScheme?.primary ?? appTheme.accentColor,
              backgroundColor: (currentUserSettings?.amoledBackground ?? false)
                  ? Colors.black
                  : darkScheme?.surface ?? appTheme.backgroundColor,
              backgroundSubColor:
                  darkScheme?.secondaryContainer ?? appTheme.backgroundSubColor,
              textMainColor: darkScheme?.onSurface ?? appTheme.textMainColor,
              textSubColor:
                  darkScheme?.onSurfaceVariant ?? appTheme.textSubColor,
              modalSheetBackgroundColor:
                  darkScheme?.surface ?? appTheme.modalSheetBackgroundColor,
              onAccent: darkScheme?.onPrimary ?? appTheme.onAccent,
            );
          } else {
            scheme = AnimeStreamTheme(
              accentColor: lightScheme?.primary ?? appTheme.accentColor,
              backgroundColor: lightScheme?.surface ?? appTheme.accentColor,
              backgroundSubColor:
                  lightScheme?.secondaryContainer ??
                  appTheme.backgroundSubColor,
              textMainColor: lightScheme?.onSurface ?? appTheme.textMainColor,
              textSubColor:
                  lightScheme?.onSurfaceVariant ?? appTheme.textSubColor,
              modalSheetBackgroundColor:
                  lightScheme?.surface ?? appTheme.modalSheetBackgroundColor,
              onAccent: lightScheme?.onPrimary ?? appTheme.onAccent,
            );
          }

          if (currentUserSettings?.materialTheme ?? false) {
            appTheme = scheme;

          } else {















          }

          final themeProvider = Provider.of<AppProvider>(context);

          final themeData = ThemeData(
            useMaterial3: true,
            brightness: themeProvider.isDark
                ? Brightness.dark
                : Brightness.light,
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: appTheme.textMainColor,
              fontFamily: "NotoSans",
            ),
            scaffoldBackgroundColor: appTheme.backgroundColor,
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: appTheme.modalSheetBackgroundColor,
            ),
            colorScheme: ColorScheme.fromSeed(
              brightness: themeProvider.isDark
                  ? Brightness.dark
                  : Brightness.light,
              seedColor: (currentUserSettings?.materialTheme ?? false)
                  ? scheme.accentColor
                  : appTheme.accentColor,
            ),
            iconTheme: IconThemeData(color: appTheme.textMainColor),
          );

          final mainChild = ChangeNotifierProvider(
            create: (context) => MainNavProvider(),
            child: MainNavigator(isStandalone: widget.isStandalone),
          );

          if (!widget.isStandalone) {
            return Theme(
              data: themeData,
              child: ScaffoldMessenger(
                key: AnimeStream.snackbarKey,
                child: AppWrapper(firstPage: mainChild),
              ),
            );
          }

          return MaterialApp(
            title: 'Animestream',
            navigatorKey: AnimeStream.navigatorKey,
            scaffoldMessengerKey: AnimeStream.snackbarKey,
            theme: themeData,
            home: Platform.isWindows
                ? AppWrapper(firstPage: mainChild)
                : mainChild,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

bool _animeStreamInitialized = false;

Future<void> ensureAnimeStreamInitialized() async {
  if (_animeStreamInitialized) return;
  WidgetsFlutterBinding.ensureInitialized();
  if (!Hive.isBoxOpen('settings')) {
    await Hive.initFlutter(!Platform.isAndroid ? "animestream" : null);
  }
  await loadAndAssignSettings();
  AnimeOnsen().checkAndUpdateToken();
  NotificationService().init();
  final sm = SourceManager.instance;
  sm
    ..addSources(sm.inbuiltSources)
    ..loadProviders(clearBeforeLoading: false);
  _animeStreamInitialized = true;
}
