// Central barrel for all top-level Riverpod providers.
// Import this file in screens — do not import individual provider files directly
// unless the file is only used in one location.

export 'core/services/mastery_notifier.dart';
export 'purchases/entitlements_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'purchases/iap_constants.dart';

// ---------------------------------------------------------------------------
// Voice speed
// ---------------------------------------------------------------------------

class VoiceSpeedNotifier extends Notifier<double> {
  static const _defaultSpeed = 0.48;

  @override
  double build() {
    _load();
    return _defaultSpeed;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(SightWordsPrefsKeys.voiceSpeed);
    if (saved != null) state = saved;
  }

  Future<void> setSpeed(double speed) async {
    state = speed.clamp(0.1, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(SightWordsPrefsKeys.voiceSpeed, state);
  }
}

final voiceSpeedProvider =
    NotifierProvider<VoiceSpeedNotifier, double>(VoiceSpeedNotifier.new);

// ---------------------------------------------------------------------------
// Quiz speech enabled toggle
// ---------------------------------------------------------------------------

class QuizSpeechNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(SightWordsPrefsKeys.quizSpeechEnabled) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SightWordsPrefsKeys.quizSpeechEnabled, state);
  }

  Future<void> setValue(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SightWordsPrefsKeys.quizSpeechEnabled, value);
  }
}

final quizSpeechProvider =
    NotifierProvider<QuizSpeechNotifier, bool>(QuizSpeechNotifier.new);

// ---------------------------------------------------------------------------
// TTS service (singleton FlutterTts instance)
// ---------------------------------------------------------------------------

final ttsServiceProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage('en-US');
  return tts;
});
