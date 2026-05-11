import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../purchases/iap_constants.dart';

/// Mastery levels:
///   0 = unseen
///   1 = learning  (swipe left / "Still learning")
///   2 = mastered  (swipe right / "I knew it")
class MasteryNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    // Start empty; loadFromPrefs() is called immediately after build.
    _loadFromPrefs();
    return {};
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SightWordsPrefsKeys.masteryMap);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SightWordsPrefsKeys.masteryMap, jsonEncode(state));
  }

  /// Sets the mastery level for [word], clamped to 0–2.
  Future<void> setLevel(String word, int level) async {
    final clamped = level.clamp(0, 2);
    state = {...state, word: clamped};
    await _persist();
  }

  /// Returns the mastery level for [word] (0 if unseen).
  int getLevel(String word) => state[word] ?? 0;

  /// Returns percentage of [words] that are at level 2.
  double masteryPercent(List<String> words) {
    if (words.isEmpty) return 0.0;
    final mastered = words.where((w) => getLevel(w) == 2).length;
    return mastered / words.length;
  }
}

final masteryProvider =
    NotifierProvider<MasteryNotifier, Map<String, int>>(MasteryNotifier.new);
