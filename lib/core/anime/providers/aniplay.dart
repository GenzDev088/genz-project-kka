import 'dart:convert';

import 'package:otax/core/anime/providers/animeProvider.dart';
import 'package:otax/core/anime/providers/types.dart';
import 'package:otax/core/app/runtimeDatas.dart';
import 'package:otax/core/database/anilist/anilist.dart';
import 'package:http/http.dart';

class AniPlay extends AnimeProvider {
  final String providerName = "aniplay";

  static const baseUrl = "https://aniplaynow.live";

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(
    String aliasId, {
    bool dub = false,
  }) async {
    final serversAndEps = await _getAllServerLinks(aliasId.split('\$')[0]);

    final List<dynamic> eps = serversAndEps[0]['episodes'];
    final List<Map<String, dynamic>> details = [];
    for (int i = 0; i < eps.length; i++) {

      String serverString = "";

      String idString = "";
      serversAndEps.forEach((it) {
        try {
          final List<dynamic> ep = it['episodes'];
          idString += "${idString.isEmpty ? "" : ","}${ep[i]['id']}";
          serverString += "${serverString.isEmpty ? "" : ","}${it['server']}";
        } catch (er) {
          print(er.toString());
          print("Index cooked!");
        }
      });


      details.add({
        'episodeLink': "$idString+$serverString+$aliasId+${eps[i]['number']}",
        'episodeNumber': eps[i]['number'],
        'episodeTitle': (eps[i]["title"]?.isEmpty ?? true)
            ? null
            : eps[i]["title"],
        'thumbnail': (eps[i]['img']?.isEmpty ?? true) ? null : eps[i]["img"],
        'hasDub': eps[i]['hasDub'] ?? false,
        'isFiller': eps[i]['isFiller'] ?? false,
      });
    }

    return details;
  }

  @override
  Future<void> getStreams(
    String episodeId,
    Function(List<VideoStream> p1, bool p2) update, {
    bool dub = false,
    String? metadata,
  }) async {
    final epIdSplit = episodeId.split("+");
    final epId = epIdSplit[0].split(",");
    final servers = epIdSplit[1].split(",");
    final anilistId = epIdSplit[2].split("\$")[0];

    final epNum = epIdSplit[3];

    int serversFetched = 0;

    servers.forEach((it) {
      final itIndex = servers.indexOf(it);
      final currentServersEpId = epId[itIndex];
      final link = getWatchUrl(
        it,
        epNum,
        anilistId,
        currentServersEpId,
        dub: dub,
      );

      final resFuture = get(
        Uri.parse(link),
        headers: {
          "Content-Type": "text/plain;charset=UTF-8",
          "Referer":
              "https://aniplaynow.live/anime/watch/$anilistId?host=$it&ep=$epNum&type=${dub ? 'dub' : 'sub'}",

        },
      );

      resFuture.onError((e, st) {
        print(e.toString());
        return Response("", 401);
      });
      resFuture.then((res) {

        final Map<dynamic, dynamic>? parsed = jsonDecode(res.body);

        if (parsed == null) {
          serversFetched++;
          update([], serversFetched == servers.length);
          return;
        }



        final List<Map<String, dynamic>>? sources = List.castFrom(
          parsed['sources'] ?? [],
        );

        if (sources == null || sources.isEmpty) {
          serversFetched++;
          update([], serversFetched == servers.length);

          return;
        }

        final List<Map<String, dynamic>>? subtitleArr = List.castFrom(
          parsed['subtitles'] ?? [],
        );
        final Map<String, String> headers = Map.from(
          parsed['headers'] ?? {},
        ).cast<String, String>();


        final String preferredLang =
            (currentUserSettings?.preferredSubtitleLanguage ?? "Indonesian")
                .toLowerCase();

        Map<String, dynamic>? subtitleItem;


        if (subtitleArr != null && subtitleArr.isNotEmpty) {
          subtitleItem = subtitleArr
              .where(
                (st) => st['label']?.toString().toLowerCase() == preferredLang,
              )
              .firstOrNull;
        }


        if ((subtitleItem == null || subtitleItem.isEmpty) &&
            (preferredLang == "indonesian" || preferredLang == "indonesia")) {
          subtitleItem = subtitleArr?.where((st) {
            final label = st['label']?.toString().toLowerCase() ?? "";
            return label == "id" ||
                label == "indo" ||
                label == "indonesia" ||
                label == "indonesian" ||
                label.contains("indo");
          }).firstOrNull;
        }


        if (subtitleItem == null || subtitleItem.isEmpty) {
          subtitleItem = subtitleArr
              ?.where((st) => (st['default']) == true)
              .firstOrNull;
        }


        if (subtitleItem == null || subtitleItem.isEmpty) {
          subtitleItem = subtitleArr
              ?.where((st) => st['label']?.toLowerCase() == "english")
              .firstOrNull;
        }


        if (subtitleItem == null || subtitleItem.isEmpty) {
          subtitleItem = subtitleArr?.firstOrNull;
        }

        print("Selected subtitle: $subtitleItem");


        if (headers.isEmpty) headers['Referer'] = "https://megaplay.buzz/";


        final stream = sources
            .where((element) => element['quality'] == "default")
            .firstOrNull;
        if (stream != null) {
          serversFetched++;
          update([
            VideoStream(
              quality: "multi-quality",
              url: stream['url'],
              customHeaders: headers,
              subtitle: subtitleItem?['url'],
              subtitleFormat: subtitleItem?['url'] != null
                  ? subtitleItem!['url'].split('.').last
                  : null,
              server: it,
              backup: false,
            ),
          ], serversFetched == servers.length);
        } else {

          final List<VideoStream> srcs = [];
          serversFetched++;
          for (final str in sources) {
            if (str['url'] == null) continue;
            try {
              srcs.add(
                VideoStream(
                  quality: "multi-quality", // yeah most times (assumptions...)
                  url: str['url'],
                  server: it,
                  backup: str['quality'] == "backup",
                  customHeaders: headers,
                  subtitle: subtitleItem?['url'],
                  subtitleFormat: subtitleItem?['url'] != null
                      ? subtitleItem!['url'].split('.').last
                      : null,
                ),
              );
            } catch (err) {
              print(err);
              rethrow;
            }
          }
          update(srcs, serversFetched == servers.length);
        }
      });
    });
    return;
  }

  String getWatchUrl(
    String server,
    String epnum,
    String anilistId,
    String epId, {
    bool dub = false,
  }) {
    return "https://aniplaynow.live/api/anime/sources?id=$anilistId&provider=$server&epId=$epId&epNum=$epnum&subType=${dub ? 'dub' : 'sub'}&cache=true";

  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {

    final sr = await Anilist().search(query);
    final List<Map<String, String>> res = [];
    for (final item in sr) {
      res.add({
        'name': item.title['english'] ?? item.title['romaji'] ?? "_null_",
        'alias': item.id.toString() + "\$" + item.idMal.toString(),
        'imageUrl': item.cover,
      });
    }
    return res;
  }

  Future<List<dynamic>> _getAllServerLinks(String id) async {
    final l = "$baseUrl/api/anime/episodes?id=$id&releasing=true&refresh=false";


    final res = await get(
      Uri.parse(l),
      headers: {
        'Referer': "$baseUrl/anime/info/$id",
        "Content-Type": "text/plain;charset=UTF-8",

      },
    );

    final Map<dynamic, dynamic> parsed = jsonDecode(res.body);

    final List<dynamic> main = parsed['episodes'];

    final List<dynamic> servers = [];

    for (final item in main) {
      servers.add({'server': item['providerId'], 'episodes': item['episodes']});
    }

    return servers;
  }

  @override
  Future<void> getDownloadSources(
    String episodeUrl,
    Function(List<VideoStream> p1, bool p2) update, {
    bool dub = false,
    String? metadata,
  }) {
    throw UnimplementedError();
  }

















































}
