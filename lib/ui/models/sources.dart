import 'package:otax/core/anime/providers/animeonsen.dart';
import 'package:otax/core/anime/providers/animepahe.dart';
import 'package:otax/core/anime/providers/anizone.dart';
import 'package:otax/core/anime/providers/gojo.dart';
import 'package:otax/core/anime/providers/animeProvider.dart';
import 'package:otax/core/anime/providers/providerDetails.dart';
import 'package:otax/core/anime/providers/providerManager.dart';
import 'package:otax/core/anime/providers/providerPlugin.dart';
import 'package:otax/core/anime/providers/types.dart';
import 'package:otax/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';



class SourceManager {
  SourceManager._();

  static final SourceManager instance = SourceManager._();

  final List<ProviderDetails> inbuiltSources =
      [
            "Animepahe",
            "AnimeOnsen",

            "AniZone",
            "Gojo",
          ]
          .map(
            (e) => ProviderDetails(
              name: e,
              identifier: e.toLowerCase() + "_inbuilt",
              version: "0.0.0.0",
              supportDownloads: e != "AnimeOnsen",
            ),
          )
          .toList();


  bool _useInbuiltProviders = true;

  bool get useInbuiltProviders => _useInbuiltProviders;

  set useInbuiltProviders(bool val) => _useInbuiltProviders = val;

  final List<ProviderDetails> _sources = [];

  final ProviderPlugin _plugin = ProviderPlugin();

  List<ProviderDetails> get sources => _sources;

  void addSource(ProviderDetails source) {
    _sources.add(source);
  }

  void addSources(List<ProviderDetails> sources) {
    _sources.addAll(sources);
  }

  void removeSource(String identifier) {
    _sources.removeWhere((e) => e.identifier == identifier);
  }

  Future<void> loadProviders({bool clearBeforeLoading = true}) async {
    final providers = await ProviderManager().getSavedProviders();
    if (clearBeforeLoading) _sources.clear();
    _sources.addAll(providers);
  }

  Future<List<Map<String, String?>>> searchInSource(
    String source,
    String query,
  ) async {
    if (query.isEmpty) throw new Exception("ERR_EMPTY_QUERY");
    final searchResults = await (await _getProvider(source)).search(query);
    return searchResults;
  }

  Future<List<EpisodeDetails>> getAnimeEpisodes(
    String source,
    String link, {
    bool dub = false,
  }) async {
    final info = await (await _getProvider(
      source,
    )).getAnimeEpisodeLink(link, dub: dub);


    return info.map((e) => EpisodeDetails.fromMap(e)).toList();
  }

  Future<void> getDownloadSources(
    String source,
    String episodeUrl,
    Function(List<VideoStream>, bool) updateFunction, {
    bool dub = false,
    String? metadata,
  }) async {
    await (await _getProvider(source)).getDownloadSources(
      episodeUrl,
      updateFunction,
      dub: dub,
      metadata: metadata,
    );
  }

  Future<void> getStreams(
    String source,
    String episodeId,
    void Function(List<VideoStream>, bool) updateFunction, {
    bool dub = false,
    String? metadata,
  }) async {
    await (await _getProvider(
      source,
    )).getStreams(episodeId, updateFunction, dub: dub, metadata: metadata);
  }

  Future<AnimeProvider> _getProvider(String identifier) async {
    final AnimeProvider? provider = _useInbuiltProviders
        ? getClass(identifier)
        : await _plugin.getProvider(identifier);
    if (provider == null) throw Exception("$identifier Provider doesnt exist!");
    return provider;
  }
}














final Map<String, AnimeProvider> sources = {
  "animepahe": AnimePahe(),
  "animeonsen": AnimeOnsen(),
  "gojo": Gojo(),
  "anizone": AniZone(),
};

AnimeProvider getClass(String source) {
  final match =
      sources[source.replaceAll(
        "_inbuilt",
        "",
      )]; // for ignoring _inbuilt suffix
  if (match == null) {
    throw Exception("Invalid Source!");
  }

  return match;














}

List<DropdownMenuEntry> getSourceDropdownList() {
  List<DropdownMenuEntry> widget = [];
  final sources = SourceManager.instance.sources;
  int count = 0;
  for (final source in sources) {
    widget.add(
      DropdownMenuEntry(
        value: source,
        label:
            "${source.name}${source.version == "0.0.0.0" ? "" : " [Plugin]"}",
        trailingIcon:
            source.identifier == currentUserSettings?.preferredProvider
            ? Icon(Icons.star_border_rounded)
            : null,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(appTheme.textMainColor),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              color: appTheme.textMainColor,
              fontFamily: "Rubik",
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
    count = count++;
  }
  return widget;
}
