import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioServiceTask extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioServiceTask() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    super.onTaskRemoved();
  }

  PlaybackState _transformEvent(final PlaybackEvent event) {
    return PlaybackState(
      controls: <MediaControl>[
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const <MediaAction>{},
      // Seems like Oppo device didn't support this option
      // android.app.RemoteServiceException$BadForegroundServiceNotificationException: Bad notification setShowActionsInCompactView: action 1 out of bounds (max 0)
      androidCompactActionIndices: const <int>[0, 1],
      processingState: const <ProcessingState, AudioProcessingState>{
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> playMediaItem(final MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);

    /// if preload ios while display play button then pause button
    await _player.setUrl(mediaItem.id, preload: false);
    await play();
  }

  @override
  Future<void> updateMediaItem(final MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play() async {
    await _player.seek(null);
    // do not await play
    _player.play();
  }

  @override
  Future<void> stop() async {
    await _player.pause();
    await _player.stop();
  }
}
