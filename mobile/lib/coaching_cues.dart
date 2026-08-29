// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_edge_tts/flutter_edge_tts.dart';

import 'domain/models.dart';
import 'domain/feedback_catalog.dart';
import 'domain/squat_rep_detector.dart';
import 'settings_controller.dart';

String coachingText(SquatCoaching coaching) => switch (coaching) {
  SquatCoaching.standTall => 'Stand tall to start',
  SquatCoaching.ready => 'Ready — squat down',
  SquatCoaching.goLower => 'Go lower',
  SquatCoaching.depthGood => 'Stand up',
  SquatCoaching.standUp => 'Stand up',
};

enum CueHaptic { degraded }

class CoachingCueCoordinator {
  CoachingCueCoordinator({
    Future<Uint8List> Function(String)? synthesize,
    Future<void> Function(Uint8List)? play,
    Future<void> Function()? stop,
    Future<void> Function(CueHaptic)? haptic,
    Future<void> Function()? sound,
    Future<void> Function()? close,
    DateTime Function()? now,
    this.cooldown = const Duration(seconds: 2),
  }) : _synthesize = synthesize,
       _play = play,
       _stop = stop,
       _haptic = haptic,
       _sound = sound,
       _close = close,
       _now = now ?? DateTime.now;

  factory CoachingCueCoordinator.production() {
    final tts = FlutterEdgeTts(voice: 'en-US-AriaNeural');
    final player = AudioPlayer();
    return CoachingCueCoordinator(
      synthesize: (text) async => (await tts.synthesize(text)).audioBytes,
      play: (bytes) async {
        await player.stop();
        await player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      },
      stop: player.stop,
      haptic: (_) => HapticFeedback.heavyImpact(),
      sound: () => SystemSound.play(SystemSoundType.alert),
      close: () async {
        await player.dispose();
        await tts.close();
      },
    );
  }

  static final _promptTexts = [
    ...SquatCoaching.values.map(coachingText),
    'Next rep: go slightly lower',
    'Next rep: do not go as deep',
    'Next rep: go lower',
    'Your movement changed from your baseline',
  ];
  final Future<Uint8List> Function(String)? _synthesize;
  final Future<void> Function(Uint8List)? _play;
  final Future<void> Function()? _stop;
  final Future<void> Function(CueHaptic)? _haptic;
  final Future<void> Function()? _sound;
  final Future<void> Function()? _close;
  final DateTime Function() _now;
  final Duration cooldown;
  final Map<String, Uint8List> _audio = {};
  DateTime? _lastSpokenAt;
  String? _lastSpokenText;
  int? _lastSpeechRep;
  final Set<String> _cuedReps = {};
  bool _foreground = true;
  String? _queuedText;
  bool _draining = false;
  int _speechGeneration = 0;

  Future<void> prepare() async {
    if (_synthesize == null) return;
    for (final text in _promptTexts) {
      if (_audio.containsKey(text)) continue;
      try {
        _audio[text] = await _synthesize(text);
      } catch (_) {
        return;
      }
    }
  }

  void handle({
    required CoachingPreferences preferences,
    SquatCoaching? coaching,
    Rep? latestRep,
  }) {
    if (!preferences.ttsEnabled || coaching == null) {
      interrupt();
      return;
    }
    final newFeedback = latestRep != null && latestRep.number != _lastSpeechRep;
    if (newFeedback) _lastSpeechRep = latestRep.number;
    final feedback = latestRep == null ? null : feedbackForRep(latestRep);
    final text = newFeedback && feedback != null
        ? feedback
        : coachingText(coaching);
    _scheduleSpeech(text);
  }

  void handleRepCue({
    required CoachingPreferences preferences,
    required String sessionId,
    required Rep? latestRep,
  }) {
    if (latestRep == null || latestRep.status != RepStatus.degraded) return;
    final key = '$sessionId:${latestRep.number}';
    if (!_cuedReps.add(key) || !_foreground) return;
    if (preferences.hapticsEnabled) {
      unawaited(_haptic?.call(CueHaptic.degraded) ?? Future.value());
    }
    if (preferences.soundEnabled) {
      unawaited(_sound?.call() ?? Future.value());
    }
  }

  void setForeground(bool value) {
    _foreground = value;
    if (!value) interrupt();
  }

  void speak(String text, {required bool enabled}) {
    if (!enabled) {
      interrupt();
      return;
    }
    _scheduleSpeech(text);
  }

  void _scheduleSpeech(String text) {
    if (text == _lastSpokenText || text == _queuedText) return;
    if (_synthesize == null || _play == null) return;
    _queuedText = text;
    _speechGeneration++;
    unawaited(_drainSpeech());
  }

  Future<void> _drainSpeech() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queuedText != null) {
        final text = _queuedText!;
        _queuedText = null;
        final generation = _speechGeneration;
        final elapsed = _lastSpokenAt == null
            ? cooldown
            : _now().difference(_lastSpokenAt!);
        final wait = cooldown - elapsed;
        if (wait > Duration.zero) await Future<void>.delayed(wait);
        if (generation != _speechGeneration) continue;
        try {
          final bytes = _audio[text] ?? await _synthesize!(text);
          _audio[text] = bytes;
          if (generation != _speechGeneration) continue;
          await _play!(bytes);
          _lastSpokenAt = _now();
          _lastSpokenText = text;
        } catch (_) {
          // Visible text remains authoritative when online speech fails.
        }
      }
    } finally {
      _draining = false;
      if (_queuedText != null) unawaited(_drainSpeech());
    }
  }

  void interrupt() {
    _queuedText = null;
    _speechGeneration++;
    unawaited(_stop?.call() ?? Future.value());
  }

  Future<void> close() async {
    interrupt();
    await _close?.call();
  }
}
