import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class GlobalMusicPlayer {
  static final AudioPlayer player = AudioPlayer();
  static Map<String, dynamic>? currentTrack;
  static bool isPlaying = false;
  static String? currentAudioUrl;
}

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final TextEditingController _queryController = TextEditingController();
  final YoutubeExplode _yt = YoutubeExplode();

  bool _isLoading = false;
  bool _isDownloading = false;
  String? _error;
  List<Map<String, dynamic>> _searchResults = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<List<int>>? _downloadSubscription;

  final Color bloodRed = const Color(0xFFD32F2F);
  final Color darkRed = const Color(0xFF8E0000);
  final Color lightRed = const Color(0xFFFFEAEA);
  final Color deepBlack = const Color(0xFF0D0D0D);
  final Color cardDark = const Color(0xFF1C1C1C);
  final Color textGrey = const Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    GlobalMusicPlayer.player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    GlobalMusicPlayer.player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });
    GlobalMusicPlayer.player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          GlobalMusicPlayer.isPlaying = state.playing;
        });
      }
    });
  }

  String? _extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final shortMatch = RegExp(
      r'youtu\.be\/([a-zA-Z0-9_-]{11})',
    ).firstMatch(trimmed);
    if (shortMatch != null) return shortMatch.group(1);

    final watchMatch = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(trimmed);
    if (watchMatch != null) return watchMatch.group(1);

    final embedMatch = RegExp(
      r'(?:embed|shorts)\/([a-zA-Z0-9_-]{11})',
    ).firstMatch(trimmed);
    if (embedMatch != null) return embedMatch.group(1);

    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  String _thumbFor(String videoId) =>
      'https://img.youtube.com/vi/$videoId/0.jpg';

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<Video?> _getVideoFromInput(String input) async {
    final videoId = _extractVideoId(input);
    if (videoId == null) return null;
    return _yt.videos.get(videoId);
  }

  Future<List<Map<String, dynamic>>> _searchYouTube(String input) async {
    final directVideo = await _getVideoFromInput(input);
    if (directVideo != null) {
      return [_videoToTrack(directVideo)];
    }

    final searchList = await _yt.search.search(input);
    final results = <Map<String, dynamic>>[];
    for (final video in searchList.whereType<Video>()) {
      results.add(_videoToTrack(video));
      if (results.length >= 20) {
        break;
      }
    }
    return results;
  }

  Map<String, dynamic> _videoToTrack(Video video) {
    return {
      'id': video.id.value,
      'title': video.title,
      'url': 'https://www.youtube.com/watch?v=${video.id.value}',
      'channel': video.author,
      'thumbnail': _thumbFor(video.id.value),
      'duration': _formatDuration(video.duration ?? Duration.zero),
    };
  }

  Future<AudioOnlyStreamInfo> _resolveBestAudioStream(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final audioOnly = manifest.audioOnly;
    if (audioOnly.isEmpty) {
      throw Exception('Stream audio tidak ditemukan.');
    }

    final preferred =
        audioOnly
            .where((e) => e.container.name.toLowerCase().contains('mp4'))
            .toList()
          ..sort(
            (a, b) =>
                b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
          );

    if (preferred.isNotEmpty) {
      return preferred.first;
    }

    final fallback = audioOnly.toList()
      ..sort(
        (a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
      );
    return fallback.first;
  }

  Future<void> _fetchMusic() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults.clear();
    });

    try {
      final results = await _searchYouTube(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _error = 'Tidak ada hasil ditemukan.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Pencarian gagal: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playMusic(Map<String, dynamic> track) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final videoId = (track['id'] ?? '').toString();
      if (videoId.isEmpty) {
        throw Exception('Video ID tidak valid.');
      }

      final audioStream = await _resolveBestAudioStream(videoId);
      final audioUrl = audioStream.url.toString();

      await GlobalMusicPlayer.player.stop();
      await GlobalMusicPlayer.player.setAudioSource(
        AudioSource.uri(Uri.parse(audioUrl)),
      );

      GlobalMusicPlayer.currentTrack = track;
      GlobalMusicPlayer.currentAudioUrl = audioUrl;
      await GlobalMusicPlayer.player.play();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now playing: ${track["title"]}'),
          backgroundColor: darkRed,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Playback gagal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlayPause() async {
    if (GlobalMusicPlayer.isPlaying) {
      await GlobalMusicPlayer.player.pause();
    } else if (GlobalMusicPlayer.currentTrack != null) {
      await GlobalMusicPlayer.player.play();
    }
  }

  Future<void> _downloadMusic(Map<String, dynamic> track) async {
    try {
      setState(() {
        _isDownloading = true;
        _error = null;
      });

      final videoId = (track['id'] ?? '').toString();
      if (videoId.isEmpty) {
        throw Exception('Video ID tidak valid.');
      }

      final audioStream = await _resolveBestAudioStream(videoId);
      final stream = _yt.videos.streamsClient.get(audioStream);
      final baseDir =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final downloadDir = Directory(
        '${baseDir.path}${Platform.pathSeparator}MusicDownloads',
      );
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final safeTitle = (track['title'] ?? 'track')
          .toString()
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final extension = audioStream.container.name;
      final file = File(
        '${downloadDir.path}${Platform.pathSeparator}$safeTitle.$extension',
      );

      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();
      _downloadSubscription = stream.listen(
        sink.add,
        onDone: () async {
          await sink.flush();
          await sink.close();
        },
      );
      await _downloadSubscription!.asFuture<void>();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sliderMax = _duration.inSeconds <= 0
        ? 1.0
        : _duration.inSeconds.toDouble();
    final sliderValue = _position.inSeconds.toDouble().clamp(0.0, sliderMax);

    return Scaffold(
      backgroundColor: deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkRed, bloodRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'MUSIC PLAYER',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search music or paste YouTube URL...',
                          hintStyle: TextStyle(color: textGrey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          prefixIcon: Icon(Icons.search, color: textGrey),
                        ),
                        onSubmitted: (_) => _fetchMusic(),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [bloodRed, darkRed]),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, color: Colors.white),
                        onPressed: _isLoading ? null : _fetchMusic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading && _searchResults.isEmpty
                  ? Center(child: CircularProgressIndicator(color: bloodRed))
                  : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note, size: 80, color: cardDark),
                          const SizedBox(height: 20),
                          Text(
                            'Search for music',
                            style: TextStyle(fontSize: 20, color: textGrey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enter song name or YouTube URL',
                            style: TextStyle(color: textGrey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final track = _searchResults[index];
                        final isCurrent =
                            GlobalMusicPlayer.currentTrack?['id'] ==
                            track['id'];

                        return Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardDark,
                            borderRadius: BorderRadius.circular(15),
                            border: isCurrent
                                ? Border.all(color: bloodRed, width: 1.1)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _playMusic(track),
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        track['thumbnail'] ?? '',
                                        width: 80,
                                        height: 45,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Container(
                                                width: 80,
                                                height: 45,
                                                color: darkRed,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: bloodRed,
                                                      ),
                                                ),
                                              );
                                            },
                                        errorBuilder: (_, __, ___) {
                                          return Container(
                                            width: 80,
                                            height: 45,
                                            color: darkRed,
                                            child: Icon(
                                              Icons.music_note,
                                              color: bloodRed,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            track['title'] ?? 'Unknown Title',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            track['channel'] ??
                                                'Unknown Channel',
                                            style: TextStyle(
                                              color: textGrey,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            track['duration'] ?? '',
                                            style: TextStyle(
                                              color: bloodRed,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: _isDownloading
                                          ? Icon(
                                              Icons.downloading_rounded,
                                              color: bloodRed,
                                            )
                                          : Icon(
                                              Icons.download_rounded,
                                              color: bloodRed,
                                            ),
                                      onPressed: _isDownloading
                                          ? null
                                          : () => _downloadMusic(track),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (GlobalMusicPlayer.currentTrack != null)
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardDark, darkRed.withValues(alpha: 0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(color: textGrey, fontSize: 12),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: bloodRed,
                                inactiveTrackColor: cardDark,
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: sliderValue,
                                max: sliderMax,
                                onChanged: (value) async {
                                  await GlobalMusicPlayer.player.seek(
                                    Duration(seconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(color: textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    GlobalMusicPlayer.currentTrack?['title'] ??
                                        'Unknown Track',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    GlobalMusicPlayer
                                            .currentTrack?['channel'] ??
                                        'Unknown Artist',
                                    style: TextStyle(
                                      color: textGrey,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.replay_10_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  final target =
                                      _position - const Duration(seconds: 10);
                                  await GlobalMusicPlayer.player.seek(
                                    target.isNegative ? Duration.zero : target,
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [bloodRed, darkRed],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    GlobalMusicPlayer.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: _togglePlayPause,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.forward_10_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  await GlobalMusicPlayer.player.seek(
                                    _position + const Duration(seconds: 10),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    _queryController.dispose();
    GlobalMusicPlayer.player.dispose();
    _yt.close();
    super.dispose();
  }
}
