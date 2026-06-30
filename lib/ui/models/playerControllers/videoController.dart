import 'dart:async';
import 'package:otax/core/commons/extractQuality.dart';
import 'package:flutter/material.dart';

class Player extends StatelessWidget {
  late final VideoController controller;
  Player(VideoController controller) {
    this.controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: controller.getWidget());
  }
}

abstract class VideoController {

  Future<void> play();


  Future<void> pause();


  Future<void> initiateVideo(
    String url, {
    Map<String, String>? headers = null,
    bool offline = false,
  });


  Widget getWidget();


  Future<void> seekTo(Duration duration);



  Future<void> setSpeed(double speed);



  Future<void> setVolume(double volume);

  void dispose();


  void addListener(VoidCallback cb);


  void removeListener(VoidCallback cb);


  void setFit(BoxFit fit);


  Future<void> setPip(bool value);


  bool? get isPlaying;


  bool? get isBuffering;


  int? get position;


  int? get duration;


  int? get buffered;


  double? get volume;


  String? get activeMediaUrl;


  bool? get isInitialized;



  void setAudioTrack(AudioStream aud);

  void setQuality(QualityStream qs);
}
