import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:otax/core/app/runtimeDatas.dart';
import 'package:otax/core/app/update.dart';
import 'package:otax/core/commons/utils.dart';
import 'package:otax/core/data/downloadHistory.dart';
import 'package:otax/ui/models/providers/mainNavProvider.dart';
import 'package:otax/ui/models/widgets/bottomBar.dart';
import 'package:otax/ui/models/widgets/cards.dart';
import 'package:otax/ui/models/snackBar.dart';
import 'package:otax/ui/pages/discover.dart';
import 'package:otax/ui/pages/home.dart';
import 'package:otax/ui/pages/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MainNavigator extends StatefulWidget {
  final bool isStandalone;
  const MainNavigator({super.key, this.isStandalone = false});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    final provider = context.read<MainNavProvider>();

    isTv().then((value) => provider.tv = value);


    DownloadHistory.initBox();


    checkForUpdates().then(
      (data) => {
        if (data != null)
          {
            showUpdateSheet(
              context,
              data.description,
              data.downloadLink,
              data.preRelease,
              data.latestVersion,

            ),
          },
      },
    );


    provider.init();
  }

  AnimeStreamBottomBarController _barController =
      AnimeStreamBottomBarController(length: 3);

  bool popInvoked = false;



  late MainNavProvider mainNavProvider;

  void rebuildCards() {
    mainNavProvider.recentlyUpdatedList.clear();

    final isMobile = !mainNavProvider.tv && mainNavProvider.isAndroid;

    mainNavProvider.recentlyUpdatedListData.forEach((elem) {
      final title = elem.title['english'] ?? elem.title['romaji'] ?? '';
      mainNavProvider.recentlyUpdatedList.add(
        Cards.animeCard(
          elem.id,
          (currentUserSettings?.nativeTitle ?? false)
              ? elem.title['native'] ?? title
              : title,
          elem.cover,
          rating: (elem.rating ?? 0) / 10,
          isMobile: isMobile,
        ),
      );
    });

    mainNavProvider.recommendedList.clear();
    mainNavProvider.recommendedListData.forEach((item) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      mainNavProvider.recommendedList.add(
        Cards.animeCard(
          item.id,
          (currentUserSettings?.nativeTitle ?? false)
              ? item.title['native'] ?? title
              : title,
          item.cover,
          rating: item.rating,
          isMobile: isMobile,
        ),
      );
    });

    mainNavProvider.thisSeason.clear();
    mainNavProvider.thisSeasonData.forEach((item) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      mainNavProvider.thisSeason.add(
        Cards.animeCard(
          item.id,
          (currentUserSettings?.nativeTitle ?? false)
              ? item.title['native'] ?? title
              : title,
          item.cover,
          rating: item.rating,
          isMobile: isMobile,
        ),
      );
    });

    setState(() {});
  }


  Future<void> popTimeoutWindow() async {
    await Future.delayed(Duration(seconds: 3));
    popInvoked = false;
  }

  @override
  Widget build(BuildContext context) {
    mainNavProvider = context.watch<MainNavProvider>();

    if (mainNavProvider.recentlyUpdatedList.isNotEmpty &&
        mainNavProvider.thisSeason.isNotEmpty) {
      rebuildCards();
    }
    double blurSigmaValue = currentUserSettings!.navbarTranslucency ?? 5;
    if (blurSigmaValue <= 1) {
      blurSigmaValue = blurSigmaValue * 10;
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) async {
        if (didPop) return;

        if (_barController.currentIndex != 0) {
          _barController.currentIndex = 0;
          return;
        }

        if (popInvoked) {
          if (widget.isStandalone) {
            await SystemNavigator.pop();
          } else {
            Navigator.of(context, rootNavigator: true).pop();
          }
          return;
        }

        floatingSnackBar(
          widget.isStandalone
              ? "Tekan sekali lagi untuk keluar dari aplikasi"
              : "Tekan sekali lagi untuk menutup Anime",
        );
        popInvoked = true;
        popTimeoutWindow();
      },
      child: Scaffold(
        body:
            MediaQuery.of(context).orientation == Orientation.landscape ||
                (!kIsWeb && Platform.isWindows)
            ? Row(
                children: [










                  NavigationRail(
                    onDestinationSelected: (value) {
                      _barController.currentIndex = value;
                      setState(() {});
                    },
                    backgroundColor: appTheme.backgroundColor,
                    elevation: 1,
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorColor: appTheme.accentColor,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.home,
                          color: _barController.currentIndex == 0
                              ? appTheme.onAccent
                              : appTheme.textMainColor,
                        ),
                        label: Text("Home", style: TextStyle(fontSize: 18)),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.auto_awesome,
                          color: _barController.currentIndex == 1
                              ? appTheme.onAccent
                              : appTheme.textMainColor,
                        ),
                        label: Text("Discover", style: TextStyle(fontSize: 18)),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.search_rounded,
                          color: _barController.currentIndex == 2
                              ? appTheme.onAccent
                              : appTheme.textMainColor,
                        ),
                        label: Text("Search", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                    selectedIndex: _barController.currentIndex,
                  ),
                  Expanded(
                    child: BottomBarView(
                      controller: _barController,

                      children: [
                        Home(mainNavProvider: mainNavProvider),
                        Discover(mainNavProvider: mainNavProvider),
                        Search(),
                      ],
                    ),
                  ),
                ],
              )
            : _bottomBar(context, blurSigmaValue),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, double blurSigmaValue) {
    return Stack(
      children: [
        BottomBarView(
          controller: _barController,
          children: [
            Home(key: ValueKey("0"), mainNavProvider: mainNavProvider),
            Discover(key: ValueKey("1"), mainNavProvider: mainNavProvider),
            Search(key: ValueKey("2")),
          ],
        ),
        AnimeStreamBottomBar(
          controller: _barController,
          accentColor: appTheme.accentColor,
          backgroundColor: appTheme.backgroundSubColor.withValues(
            alpha: currentUserSettings?.navbarTranslucency ?? 0.5,
          ),
          borderRadius: 10,
          items: [
            BottomBarItem(title: 'Home', icon: Icon(Icons.home)),
            BottomBarItem(title: 'Discover', icon: Icon(Icons.auto_awesome)),
            BottomBarItem(title: 'Search', icon: Icon(Icons.search)),
          ],
        ),
      ],
    );
  }
}
