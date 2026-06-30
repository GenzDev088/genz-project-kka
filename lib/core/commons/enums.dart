import 'package:flutter/foundation.dart';

enum RequestType { recentlyUpdatedAnime, media, mutate }

enum ServerSheetType { watch, download }

enum MediaStatus { CURRENT, PLANNING, COMPLETED, DROPPED, PAUSED }

enum SortType { AtoZ, RecentlyUpdated, TopRated }

enum EpisodeViewModes { tile, grid, list }

enum SubtitleFormat {
  ASS,
  VTT,
  SRT;

  static SubtitleFormat fromName(String name) {
    return switch (name.toLowerCase()) {
      "vtt" => SubtitleFormat.VTT,
      "ass" => SubtitleFormat.ASS,
      "srt" => SubtitleFormat.SRT,
      _ => SubtitleFormat.VTT, // Safe fallback
    };
  }
}

enum SecureStorageKey {

  simklToken("simkl_token"),
  anilistToken("anilist_token"),
  malToken("mal_token"),


  malAuthResponse("mal_auth_response"),


  malChallengeVerifier("mal_challenge_verifier");

  final String _rawName;

  const SecureStorageKey(this._rawName);


  String get value {
    if (kDebugMode) {
      return "dev_$_rawName";
    }
    return _rawName;
  }
}

enum PlayerState { playing, paused, buffering }
