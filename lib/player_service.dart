import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'audio_service_task.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._();

  PlayerService._();

  static PlayerService get instance => _instance;

  AudioHandler? audioHandler;

  bool isInitialising = false;

  Future<void> init() async {
    if (isInitialising) return;
    isInitialising = true;
    await _initSession();
    await _initAudioService();
    await play();
    isInitialising = false;
  }

  Future<void> _initSession() async {
    try {
      final AudioSession session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (err, stack) {
      debugPrintStack(label: err.toString(), stackTrace: stack);
    }
  }

  Future<void> _initAudioService() async {
    if (audioHandler != null) return;
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      audioHandler = await AudioService.init(
        config: AudioServiceConfig(
          androidNotificationChannelId: info.packageName.isNotEmpty == true ? "${info.packageName}.channel.audio" : null,
          androidNotificationIcon: "drawable/ic_notification",
          androidNotificationOngoing: true,
          notificationColor: Colors.red,
          androidNotificationChannelName: "Lecteur de musique",
          androidNotificationChannelDescription: "Cette notification doit être activée pour afficher le player dans la zone de notification",
        ),
        builder: () => AudioServiceTask(),
      );
    } catch (err, stack) {
      debugPrintStack(label: err.toString(), stackTrace: stack);
    }
  }

  bool isRunning() => audioHandler?.playbackState.value.processingState == AudioProcessingState.ready;

  Future<void> pause() async {
    await audioHandler?.pause();
  }

  Future<void> play({final double? volume}) async {
    if (!isRunning()) await init();

    try {
      await audioHandler?.playMediaItem(
        MediaItem(
          id: "https://mfm.ice.infomaniak.ch/mfm-64.aac",
          album: "CELINE DION - Parler A Mon Père",
          title: "Live",
          artUri: Uri.tryParse("https://covers.eg-ad.fr/celinedion-parler.jpg"),
        ),
      );
    } on PlatformException catch (err, stack) {
      debugPrintStack(label: err.toString(), stackTrace: stack);
    } catch (err, stack) {
      debugPrintStack(label: err.toString(), stackTrace: stack);
      await pause();
    }
  }

  void dispose() {
    audioHandler?.stop();
  }
}
