/// IAP product IDs for Sight Words Flash Cards.
/// SPEC §7: two products, namespaced per app.
///
/// Registered in App Store Connect + Google Play Console by console-operator
/// on Day 0 before any IAP code is tested.
class SightWordsProductIds {
  SightWordsProductIds._();

  /// Non-consumable — $2.99 — permanent unlock of all 520 words.
  static const fullUnlock = 'com.idealai.sightwords.full_unlock';

  /// Auto-renewable subscription — $4.99/year — all words + future family profiles.
  static const familyAnnual = 'com.idealai.sightwords.family_annual';

  static const Set<String> all = {fullUnlock, familyAnnual};
}

/// Local SharedPreferences keys for cached entitlement state.
/// These are UX-convenience caches ONLY.
/// Do NOT use as sole source of truth — always verify via StoreKit/Play Billing.
class SightWordsPrefsKeys {
  SightWordsPrefsKeys._();

  static const masteryMap       = 'sw_mastery_map';
  static const iapFullUnlock    = 'sw_iap_full_unlock';
  static const iapFamilyActive  = 'sw_iap_family_active';
  static const voiceSpeed       = 'sw_voice_speed';
  static const ttsLanguage      = 'sw_tts_language';
  static const quizSpeechEnabled = 'sw_quiz_speech_enabled';
  static const onboardingDone   = 'sw_onboarding_done';
}
