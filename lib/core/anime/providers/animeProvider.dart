import 'package:otax/core/anime/providers/types.dart';

abstract class AnimeProvider {

  String get providerName;


  Future<List<Map<String, String?>>> search(String query);


  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(
    String aliasId, {
    bool dub = false,
  });


  Future<void> getStreams(
    String episodeId,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  });





  Future<void> getDownloadSources(
    String episodeUrl,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  });
}
