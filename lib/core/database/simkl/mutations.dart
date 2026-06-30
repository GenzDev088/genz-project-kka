import 'dart:convert';

import 'package:otax/core/app/env.dart';
import 'package:otax/core/database/simkl/login.dart';
import 'package:otax/core/database/types.dart';
import 'package:http/http.dart';

import 'package:otax/core/commons/enums.dart';
import 'package:otax/core/data/secureStorage.dart';
import 'package:otax/core/database/database.dart';
import 'package:otax/core/database/simkl/types.dart';

class SimklMutation extends DatabaseMutation {
  @override
  Future<SimklMutationResult?> mutateAnimeList({
    required int id,
    int? progress = 0,
    MediaStatus? status,
    MediaStatus? previousStatus,
  }) async {








    if (!(await SimklLogin.isLoggedIn())) return null;


    if (previousStatus?.name == status?.name)
      syncToHistory(id, progress!);
    else
      addToList(id, status ?? MediaStatus.CURRENT);

    return SimklMutationResult();
  }

  @override
  Future<DatabaseMutationResult?> deleteAnimeEntry({required int id}) async {
    final url = "https://api.simkl.com/sync/history/remove";
    final body = jsonEncode({
      'shows': [
        {
          'ids': {'simkl': id},
        },
      ],
    });

    final header = await getHeader();

    await post(Uri.parse(url), headers: header, body: body);
    return null;
  }

  Future addToList(int id, MediaStatus status) async {
    final url = "https://api.simkl.com/sync/add-to-list";
    final body = jsonEncode({
      'shows': [
        {
          'to': getStatusString(status),
          'ids': {'simkl': id},
        },
      ],
    });

    final header = await getHeader();

    await post(Uri.parse(url), headers: header, body: body);





  }

  Future syncToHistory(
    int id,
    int progress, {
    String? bodyString = null,
  }) async {
    final url = "https://api.simkl.com/sync/history";
    List<Map<String, int>> episodes = [];

    String body = bodyString ?? '';

    if (bodyString == null) {

      for (int i = 0; i < progress; i++) {
        episodes.add({'number': i + 1});
      }

      body = jsonEncode({
        'shows': [
          {
            'ids': {'simkl': id},
            'seasons': [
              {'number': 1, "episodes": episodes},
            ],
          },
        ],
      });
    }

    final header = await getHeader();
    final res = await post(Uri.parse(url), headers: header, body: body);
    if (res.statusCode != 201) {

      throw Exception("Couldnt Sync Simkl [maybe false report]");
    }
  }

  static Future<Map<String, String>> getHeader() async {
    final token = await getSecureVal(SecureStorageKey.simklToken);
    if (token == null) {
      throw Exception("SIMKL_SYNC: TOKEN NOT FOUND");
    }
    return {
      'Content-Type': "application/json",
      'Authorization': "Bearer $token",
      'simkl-api-key': AnimeStreamEnvironment.simklClientId,
    };
  }

  String getStatusString(MediaStatus status) {
    switch (status) {
      case MediaStatus.COMPLETED:
        return "completed";
      case MediaStatus.CURRENT:
        return "watching";
      case MediaStatus.DROPPED:
        return "dropped";
      case MediaStatus.PAUSED:
        return "onhold";
      case MediaStatus.PLANNING:
        return "plantowatch";


    }
  }
}
