import 'package:otax/core/app/logging.dart';
import 'package:otax/core/app/runtimeDatas.dart';
import 'package:otax/core/commons/enums/hiveEnums.dart';
import 'package:otax/core/data/hive.dart';
import 'package:otax/core/data/types.dart';
import 'package:otax/core/database/database.dart';
import 'package:hive/hive.dart';


const int _animeInfoLruCapacity = 40;

final String _boxName = HiveBox.animeInfo.boxName;


Future<AnimeSpecificPreference?> getAnimeSpecificPreference(
  String anilistId,
) async {

  if (currentUserSettings?.database != Databases.anilist) return null;

  var box = await Hive.openBox(_boxName);
  if (!box.isOpen) {
    box = await Hive.openBox(_boxName);
  }

  String? manSearch, provider;
  Map<dynamic, dynamic>? lastWatch;

  final Map<dynamic, dynamic> asp =
      await box.get(HiveKey.animeSpecificPreference.name) ?? {};
  if (asp.isEmpty) {
    Logs.app.log("EMPTY MAP 'animeSpecificPreference'");
  }

  final Map<String, dynamic> item = Map.castFrom(asp[anilistId] ?? {});
  manSearch = item["manualSearchQuery"];
  lastWatch = item['lastWatchDuration'];
  provider = item['preferredProvider'];
  Logs.app.log(item.toString());


  if (item.isNotEmpty) {
    item['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;
    asp[anilistId] = item;
    await box.put(HiveKey.animeSpecificPreference.name, asp);
  }

  await box.close();

  return AnimeSpecificPreference(
    lastWatchDuration: lastWatch,
    manualSearchQuery: manSearch,
    preferredProvider: provider,
  );
}

Future<void> saveAnimeSpecificPreference(
  String anilistId,
  AnimeSpecificPreference preference,
) async {
  Map<dynamic, dynamic> map = Map.castFrom(
    await getVal(HiveKey.animeSpecificPreference, boxName: HiveBox.animeInfo) ??
        {},
  );



  final item = map[anilistId] ?? {};


  final prefMap = preference.toMap();

  if (prefMap['lastWatchDuration'] != null) {
    final Map<dynamic, dynamic> existing = Map<dynamic, dynamic>.from(
      item['lastWatchDuration'] ?? {},
    );
    final Map<dynamic, dynamic> incoming = Map<dynamic, dynamic>.from(
      prefMap['lastWatchDuration'] as Map,
    );
    existing.addAll(incoming);
    item['lastWatchDuration'] = existing;
  }


  for (final entry in prefMap.entries) {
    if (entry.key == 'lastWatchDuration') continue; // already merged above
    if (entry.value != null) {
      item[entry.key] = entry.value;
    }
  }


  item['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;

  map[anilistId] = item;


  Map<dynamic, dynamic> finalMap = map;
  if (map.length > _animeInfoLruCapacity) {
    final List<MapEntry<dynamic, dynamic>> entries = map.entries.toList();

    entries.sort((a, b) {
      final aTs = (a.value is Map && (a.value)['lastAccessed'] is num)
          ? (a.value)['lastAccessed'] as num
          : 0;
      final bTs = (b.value is Map && (b.value)['lastAccessed'] is num)
          ? (b.value)['lastAccessed'] as num
          : 0;
      return bTs.compareTo(aTs);
    });
    finalMap = Map<dynamic, dynamic>.fromEntries(
      entries.take(_animeInfoLruCapacity),
    );
  }

  await storeVal(
    HiveKey.animeSpecificPreference,
    finalMap,
    boxName: HiveBox.animeInfo,
  );
}
