# Sight Words Flash Cards — SPEC.md
<!-- App Architect · Ideal Intelligence · 2026-05-11 -->

---

## §1 · Product

**One-line description:** A beautiful, offline flashcard and quiz app that teaches K-3 children all 220 Dolch and 300 Fry sight words through tap-to-flip cards, emoji illustrations, TTS read-aloud, and mastery tracking.

**PMF metric (inherited from validation):** Week-2 retention ≥ 35 %; measured as "users who open the app on at least 4 of 7 days in week 2." A child using it as a nightly bedtime routine with a parent is the core signal.

**Source idea + score:** Internal brief — "Sight Words Flash Cards" for Apple Kids Category. Positioned against Sight Words — Learn to Read (category leader). Differentiation score: 7 / 10 on the narrowing axis (deliberate grade-level word list granularity + emoji illustration + offline-first architecture).

---

## §2 · Identity

| Field | Value |
|---|---|
| Display name | Sight Words Flash Cards |
| Slug | `sightwords` |
| Bundle ID | `com.idealai.sightwords` |
| Firebase project | NONE — local-first, no Firebase |
| AdMob | NONE — Apple Kids Category forbids third-party ad SDKs |
| GitHub repo | `IdealIntelligenceMobileApps` (monorepo, `apps/sightwords/`) |
| Target platforms | iOS primary, Android secondary |
| iOS minimum | **14.0** — `in_app_purchase` 3.x requires iOS 11+; `flutter_tts` 4.x requires iOS 12+; `speech_to_text` 7.x requires iOS 14+. The binding constraint is `speech_to_text`. |
| Android minimum | **SDK 23** (Android 6.0) — `in_app_purchase` BILLING v5 requires SDK 21+; `speech_to_text` recommends SDK 21+; SDK 23 gives us clean permissions UX and covers 98 %+ of active Android devices. |

---

## §3 · Architecture Decisions

**Framework:** Flutter (stable channel) + Dart — cross-platform with single codebase, one team, one review. No native-only APIs required.

**State management:** Riverpod 2.x (`flutter_riverpod`) with `NotifierProvider` for mastery state, `Provider` for entitlement gating, `FutureProvider` for IAP product loading. Pattern ported directly from Stride.

**Data layer (word data):** Bundled Dart const lists in `lib/data/word_lists/`. No network, no database — word content is static. Mastery state stored in `SharedPreferences` as a JSON-encoded `Map<String, int>` keyed by word text (0 = unseen, 1 = learning, 2 = mastered). No per-word ID is needed because word text is unique across the 520-word corpus.

**Auth:** NONE. No accounts. The app is anonymous by design; the Kids Category prohibits social sign-in.

**Payments:** `in_app_purchase` (Flutter's first-party package). NO RevenueCat — the two SKUs are simple enough (one non-consumable + one auto-renewable sub) that native StoreKit / Google Play Billing direct is lower risk for a Kids Category app. RevenueCat's SDK has historically contained analytics code that draws App Review scrutiny in the Kids Category. This is an intentional deviation from the Stride/Loop pattern.

**Storage:** `shared_preferences` only. Word lists are Dart constants. No file I/O, no SQLite.

**TTS:** `flutter_tts` — device TTS engine, zero cost, zero network, zero privacy concern. Voice speed adjustable in settings. Language fixed to `en-US` in v1.

**Speech recognition:** `speech_to_text` — optional quiz mode input, device on-device recognition where available. Gracefully degrades to "I knew it / Still learning" tap buttons when unavailable.

**Backend:** NONE. Completely offline.

**CI/CD:** Codemagic (same account/workflow as studio). `codemagic.yaml` at repo root.

**Reason for deviating from Firebase default:** Kids Category compliance. Apple's App Review team scrutinizes every third-party SDK in apps targeting children under 13. Firebase Analytics, Crashlytics, and Remote Config all send device data to Google servers. To avoid rejection risk, this app intentionally has zero third-party analytics SDKs. `flutter_tts`, `speech_to_text`, and `in_app_purchase` are all safe categories for the Kids Category.

---

## §4 · Firestore Schema

**NOT APPLICABLE.** This app has no Firebase project and no Firestore. All persistent state lives in `SharedPreferences` on-device.

**SharedPreferences key schema (treated as the canonical data contract):**

| Key | Type | Notes |
|---|---|---|
| `sw_mastery_map` | JSON string | Encodes `Map<String, int>` — word text → mastery level (0/1/2). Written by `MasteryNotifier`. |
| `sw_iap_full_unlock` | bool | Cached entitlement flag for `full_unlock` non-consumable. Refreshed on app launch via `in_app_purchase` query. DO NOT use as sole source of truth — always verify via StoreKit/Play Billing receipt. |
| `sw_iap_family_active` | bool | Cached flag for `family_annual` subscription. Same caveat as above. |
| `sw_voice_speed` | double | 0.1 – 1.0. Default `0.5`. Written by SettingsScreen. |
| `sw_tts_language` | String | BCP-47 tag, default `en-US`. |
| `sw_quiz_speech_enabled` | bool | Whether quiz mode attempts speech recognition. Default `true`. |
| `sw_onboarding_done` | bool | True after first HomeScreen render completes. |

**Security note:** SharedPreferences is not secure storage. No secrets, credentials, or payment receipts must ever be stored in SharedPreferences. Receipt validation happens via StoreKit / Play Billing on-device; the cached booleans are a UX convenience only.

---

## §5 · Screen Inventory

| Screen | Route / Type | Prototype status | What needs to be added |
|---|---|---|---|
| HomeScreen | `/` — full screen | Wireframe needed | Grid of word list cards; lock icon on paid lists; mastery % badge; settings gear; "Unlock All" CTA |
| FlashCardScreen | `/flashcard/:listId` — full screen | Wireframe needed | Swipeable card stack; flip animation; TTS on flip; progress bar; swipe gesture R/L |
| QuizScreen | `/quiz/:listId` — full screen | Wireframe needed | 10-word session; optional speech input; "I knew it" / "Still learning" buttons; session results summary |
| MasteryScreen | `/mastery/:listId` — full screen | Wireframe needed | Per-word heatmap grid (green/yellow/gray); word count summary; "Start Quiz" CTA |
| PaywallSheet | Bottom sheet (modal) | Wireframe needed | $2.99 full unlock CTA; $4.99/yr family CTA; restore purchases button; kids-safe copy |
| SettingsScreen | `/settings` — full screen | Wireframe needed | TTS voice speed slider; language picker; restore purchases; app version; privacy policy link |

`ui-ux-designer` owns visual design for all six screens. Design tokens must follow the Kids Category visual language: large tap targets (min 48 × 48 pt), high contrast text, no dark mode in v1 (reduces complexity for young users).

---

## §6 · MVP Build Order

Each task is ≤ 1 day. Strict dependency order — do not start a task until all prior tasks pass `flutter analyze` clean.

**Task 1 — Project scaffold + word data bundle**
- Run `flutter create --org com.idealai --project-name sightwords .` inside `apps/sightwords/`
- Replace generated `pubspec.yaml` with the one in this repo (see §11)
- Create `lib/data/word_lists/dolch_pre_primer.dart`, `dolch_primer.dart`, `dolch_grade1.dart`, `dolch_grade2.dart`, `dolch_grade3.dart`, and `fry_words.dart` — each exporting a `const List<WordEntry>` with all fields specified in §2 of the product brief (`text`, `listName`, `gradeLevel`, `definition`, `emoji`)
- Create `lib/data/word_lists/word_entry.dart` with the `WordEntry` model (pure Dart, no JSON serialization needed — these are compile-time constants)
- Create `lib/data/word_lists/all_lists.dart` — master registry of all 11 lists (5 Dolch + 6 Fry), each as a `WordList` object with `id`, `displayName`, `gradeLabel`, `words`, `isFree` bool
- Deliverable: `flutter analyze` clean, `flutter test` passes (no tests yet, just scaffolding)

**Task 2 — HomeScreen + list grid + free/locked gating (UI only, no IAP yet)**
- Implement `lib/features/home/presentation/home_screen.dart`
- Grid of `WordListCard` widgets: shows list name, word count, mastery %, lock icon if `!isFree`
- Tapping a free list navigates to FlashCardScreen
- Tapping a locked list shows a placeholder `SnackBar` ("Unlock coming — Task 4")
- Mastery % comes from `masteryProvider` (returns 0 % until Task 3)
- Settings gear icon navigates to SettingsScreen stub
- Deliverable: HomeScreen renders all 11 lists, free lists are tappable, locked lists show lock icon

**Task 3 — FlashCardScreen: flip animation + TTS**
- Implement `lib/features/flashcard/presentation/flashcard_screen.dart`
- Card stack: display one card at a time, `AnimatedContainer` or `Transform` flip on tap
- Front: large word text (min 64 sp), "Tap to hear" icon
- Back: emoji (72 sp), word text (smaller), definition (body text)
- On flip: call `flutter_tts` to speak the word aloud
- Swipe right gesture: mark word as "mastered" (level 2), advance to next card
- Swipe left gesture: mark word as "learning" (level 1), advance to next card
- Progress bar at top: cards seen / total in list
- Mastery writes go through `MasteryNotifier` which persists to SharedPreferences
- Deliverable: Flashcard flip works, TTS fires on flip, swipe gesture records mastery, SharedPreferences key `sw_mastery_map` is written

**Task 4 — IAP wiring: `in_app_purchase` + PaywallSheet + entitlement gate**
- Implement `lib/purchases/iap_service.dart` — wraps `in_app_purchase` with `initialize()`, `queryProducts()`, `buyNonConsumable()`, `buySubscription()`, `restorePurchases()`, `dispose()`
- Implement `lib/purchases/entitlements_provider.dart` — `NotifierProvider<EntitlementsNotifier, Entitlements>` that reads cached SharedPreferences flags and refreshes from `PurchaseDetails` stream
- Implement `lib/features/paywall/presentation/paywall_sheet.dart` — bottom sheet with two CTAs and restore button (pattern from Stride's `StridePaywallSheet`)
- Wire lock tap in HomeScreen to open PaywallSheet
- After successful purchase, locked lists become tappable
- Product IDs: `com.idealai.sightwords.full_unlock`, `com.idealai.sightwords.family_annual`
- Deliverable: PaywallSheet opens, sandbox purchase of `full_unlock` unlocks all lists, restore purchases re-gates correctly

**Task 5 — MasteryScreen: per-word heatmap**
- Implement `lib/features/mastery/presentation/mastery_screen.dart`
- Grid of word chips colored by mastery level: green (2), amber (1), gray (0)
- Summary row: "X mastered · Y learning · Z not started"
- "Start Quiz" CTA routes to QuizScreen for this list
- Tapping a word chip shows a tooltip with the definition and emoji
- Accessible from HomeScreen via a "View mastery" icon on each list card
- Deliverable: MasteryScreen renders correctly for any list, colors update in real-time after FlashCard session

**Task 6 — QuizScreen: 10-word session + mastery updates**
- Implement `lib/features/quiz/presentation/quiz_screen.dart`
- Draw 10 words from the list, weighted toward `level < 2` words (not-yet-mastered first)
- Show the word on a card; optionally activate `speech_to_text` to capture child's attempt
- "I knew it" / "Still learning" buttons always present as fallback
- On session end: results summary screen (X/10 correct, confetti for ≥ 8/10), then back to HomeScreen
- Mastery updates routed through `MasteryNotifier`
- If `speech_to_text` unavailable (permission denied, iOS < 14, simulator), gracefully hide the microphone button — do not crash
- Deliverable: 10-word quiz session completes, mastery updates persist, confetti fires on high score

**Task 7 — SettingsScreen + polish**
- Implement `lib/features/settings/presentation/settings_screen.dart`
- Voice speed slider (0.1–1.0), writes `sw_voice_speed` to SharedPreferences
- TTS language picker (en-US only in v1, extensible row left as stub)
- Toggle: "Use microphone in quiz" — writes `sw_quiz_speech_enabled`
- Restore Purchases button — calls `iapService.restorePurchases()`
- App version from `package_info_plus`
- Privacy policy link (opens URL — must be a real URL, even a placeholder page)
- Deliverable: All settings persist across app restart, restore purchases works in sandbox

**Task 8 — iOS Info.plist + Android Manifest + permissions UX**
- `NSMicrophoneUsageDescription`: "Sight Words uses your microphone so your child can say words aloud in quiz mode."
- `NSSpeechRecognitionUsageDescription`: "Sight Words listens for your child's spoken answers in quiz mode. No audio is stored or transmitted."
- `ITSAppUsesNonExemptEncryption`: false
- `PrivacyInfo.xcprivacy`: declare `NSPrivacyAccessedAPICategoryUserDefaults` (for SharedPreferences), no tracking
- Android: `RECORD_AUDIO`, `INTERNET` (required by `in_app_purchase`), `com.android.vending.BILLING`
- Microphone permission requested lazily (only when child taps the microphone button in QuizScreen for the first time) — not on launch
- Deliverable: `flutter build ipa --no-codesign` succeeds; `flutter build appbundle --release` succeeds; no missing permission strings

**Task 9 — Codemagic CI + codemagic.yaml**
- Wire `codemagic.yaml` at repo root with `sightwords-ios` and `sightwords-android` workflows
- iOS: `flutter build ipa`, Codemagic-managed code signing, upload to TestFlight (manual for v1.0.0 per §14)
- Android: `flutter build appbundle --release`, upload artifact
- Env groups: `sightwords_iap` (no secrets needed — product IDs are hardcoded; group exists for future use)
- Deliverable: Green CI build; IPA artifact downloadable from Codemagic

**Task 10 — QA checklist pass (see §13)**
- Run every item in the §13 Definition of Done
- Fix any issues found
- Deliverable: All §13 checklist items checked off; screenshots captured for ASO

Total: 10 tasks. Within the 12-task cap.

---

## §7 · Monetization Spec

**Primary lever: IAP (non-consumable + subscription). NO AdMob. NO ads.**

Apple Kids Category policy explicitly prohibits behavioral advertising and third-party ad networks. This is non-negotiable.

### Products

| Product ID | Type | Price | Entitlement granted | Notes |
|---|---|---|---|---|
| `com.idealai.sightwords.full_unlock` | Non-consumable IAP | $2.99 (USD) | `full_unlock` | One-time permanent unlock of all 520 words across all 11 lists. Never expires. |
| `com.idealai.sightwords.family_annual` | Auto-renewable subscription | $4.99 / year | `family_full` | All words + up to 4 child profiles with separate mastery tracking. v1 has single profile only — the subscription is the unlock path for multi-profile parents who want to support development. Multi-profile UI is a v1.1 feature (see §10). |

**Why both?** Parents who home-school want permanent ownership ($2.99 non-consumable). Schools and families with multiple children see value in the subscription framing even at v1. The price delta ($2.99 vs $4.99/yr) is intentionally close so neither is obviously "the smart choice" — this prevents cannibalization.

**Entitlement logic (in `EntitlementsNotifier`):**

```
full_access = has(full_unlock) OR has(family_full, active)
```

Free tier: `Dolch Pre-Primer` (40 words) + `Dolch Primer` (52 words) + `Fry 1-50` (50 words) = 142 free words.

### Paywall trigger points

| Trigger | Where | Sheet content |
|---|---|---|
| Tapping any locked list on HomeScreen | HomeScreen | Full paywall sheet with both products |
| Tapping the lock icon badge on a list card | HomeScreen | Full paywall sheet with both products |
| Attempting to start a quiz on a locked list (deep-link or back-nav edge case) | QuizScreen guard | Full paywall sheet |
| Restore Purchases button | SettingsScreen | No sheet — calls restore inline |

### Trial mechanics

- `full_unlock` non-consumable: NO trial. One-time price, no trial concept.
- `family_annual` subscription: NO free trial in v1. Keep it simple. A free trial for a $4.99/yr product adds friction (credit card required on App Store sandbox) without meaningful conversion lift at this price point. Add trial if A/B data supports it in v1.1.

### Restore purchases

Must be present in both PaywallSheet and SettingsScreen. This is mandatory for App Review. Pattern: call `in_app_purchase`'s `restorePurchases()`, listen for `PurchaseStatus.restored` on the purchase stream, update `EntitlementsNotifier`.

---

## §8 · Notification Spec

**v1 has ZERO push notifications and ZERO local notifications.**

Rationale: This is a parent-initiated, session-based app. Parents hand the device to the child; they don't need reminders when the device is already in the child's hands. Adding notifications to a Kids Category app introduces compliance complexity (COPPA, GDPR-K) with no meaningful retention lift at v1 scale.

FCM: NOT integrated. No `firebase_messaging` package.
Local notifications: NOT integrated. No `flutter_local_notifications` package.

Re-evaluate at v1.1 if week-2 retention metric is below 35 %.

---

## §9 · Analytics Events

**v1 has ZERO third-party analytics SDKs.**

Rationale: Apple Kids Category. Firebase Analytics is a Google SDK that collects device identifiers (IDFA, IDFV) and sends them to Google servers. Any analytics SDK that collects device data triggers `NSPrivacyTracking` = YES and requires COPPA / GDPR-K consent flows — which are incompatible with the Kids Category and with the "parent hands device to child" UX model.

Alternative for v1 measurement: Use **App Store Connect Analytics** (free, built-in, Apple-managed) for downloads, sessions, and crash rates. Use **Google Play Console Analytics** for Android. Neither requires an SDK.

Instrument the following App Store Connect custom product page events via **StoreKit's SKAdNetwork** attribution only (no SDK):
- App opens (automatic — App Store Connect provides this)
- First launch (automatic)
- IAP conversions (automatic — App Store Connect reports this per product ID)

If targeted funnel analysis is needed post-launch, add PostHog behind a `__ANALYTICS_ENABLED__` dart-define compile flag, conditioned on consent, in v1.1. Do NOT add it to v1.

**Crash reporting:** Use `FlutterError.onError` + `PlatformDispatcher.instance.onError` to write crash summaries to a local log file (path_provider), max 50 KB. No telemetry. Parent can share the log file via the Settings screen if they choose.

---

## §10 · Non-MVP Scope (mandatory exclusion list)

The following features are explicitly NOT in v1. `mobile-developer` must not implement them. Writing any of this code in v1 is scope creep.

1. **Multiple child profiles** — the Family subscription unlock is sold at v1, but the multi-profile UI (profile switcher, per-child mastery isolation) ships in v1.1. v1 has single-profile mastery only.
2. **Parent PIN / parental gate** — Kids Category does not require it for this content type (educational word lists). Add if Apple Review requests it.
3. **Custom word lists** — parents cannot add their own words. Static corpus only.
4. **Cloud sync / backup** — mastery data lives on-device only. No iCloud sync, no Google Drive export.
5. **Audio pronunciation recordings** — v1 uses device TTS only. No recorded human voice audio files bundled.
6. **Dark mode** — intentionally excluded (see §A). Light mode only.
7. **iPad-optimized layout** — app runs on iPad but uses phone layout constraints. iPad-specific grid is a v1.1 task.
8. **Landscape orientation on iPhone** — portrait only. Flashcard UX is designed for portrait hold (parent and child looking at the same screen).
9. **Gamification / points / streaks / rewards** — no star stickers, no XP, no streak counters in v1. Mastery heatmap is the only progress signal.
10. **Social sharing / share-to-classroom** — Kids Category prohibits social features without COPPA-compliant consent flows.
11. **In-app review prompt** — defer to v1.1 (need real retention data before prompting).
12. **PostHog / any analytics SDK** — see §9.
13. **Fry words beyond 1–50 in the free tier** — Fry 51-300 are paid. Do not expand the free tier without revenue data.
14. **Notifications of any kind** — see §8.
15. **Android tablet layout** — deferred.

---

## §11 · Third-Party SDKs

| SDK | Package | Purpose | License | Cost | iOS min | Notes |
|---|---|---|---|---|---|---|
| flutter_riverpod | `flutter_riverpod: ^2.6.0` | State management | MIT | Free | 12.0 | Provider + Notifier pattern; same as Stride |
| shared_preferences | `shared_preferences: ^2.3.0` | Mastery persistence + settings | BSD-3 | Free | 12.0 | No encryption needed; not storing secrets |
| in_app_purchase | `in_app_purchase: ^3.2.0` | StoreKit / Play Billing IAP | BSD-3 | Free | 12.0 | First-party Flutter package; safer than RevenueCat for Kids Category |
| flutter_tts | `flutter_tts: ^4.2.0` | Text-to-speech read-aloud | BSD-3 | Free | 12.0 | Device TTS engine; en-US default; speed configurable |
| speech_to_text | `speech_to_text: ^7.0.0` | Optional quiz voice input | BSD-3 | Free | **14.0** | iOS 14 requirement drives §2 iOS minimum. Must request permission lazily. |
| package_info_plus | `package_info_plus: ^8.0.0` | App version in settings | BSD-3 | Free | 12.0 | Same version as Stride |
| url_launcher | `url_launcher: ^6.3.0` | Privacy policy link | BSD-3 | Free | 12.0 | Same version as Stride |
| flutter_lints | `flutter_lints: ^4.0.0` | Static analysis | BSD-3 | Free | N/A | Dev only |

**Total third-party SDK count: 7 (runtime), 1 (dev).** This is intentionally minimal. Kids Category App Review counts SDKs; fewer is better.

**Deliberately excluded:**
- `firebase_*` — Kids Category compliance
- `purchases_flutter` (RevenueCat) — see §3 rationale
- `google_mobile_ads` — Kids Category prohibits
- `firebase_analytics` / `firebase_crashlytics` — Kids Category compliance
- `flutter_local_notifications` — not needed in v1 (see §8)

---

## §12 · Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Apple rejects app citing third-party SDK data collection | Low (we have 0 tracking SDKs) | Critical — delays launch | Pre-submission checklist: verify `PrivacyInfo.xcprivacy` declares only UserDefaults; verify no SDK calls `advertisingIdentifier`; confirm `NSPrivacyTracking` = NO |
| Apple rejects app citing Kids Category age-rating noncompliance | Medium | High — requires re-architecture | Ensure zero social features, zero behavioral ads, zero third-party analytics. Age rating: set to 4+ in App Store Connect. |
| `speech_to_text` fails silently on older devices / simulators | High | Medium — quiz mode broken for some users | Always render "I knew it / Still learning" buttons regardless of speech availability. Wrap all `speech_to_text` calls in try/catch. Hide mic button if `speech.isAvailable == false`. |
| `in_app_purchase` purchase stream delivers `PurchaseStatus.error` after user completes payment (rare StoreKit bug) | Low | High — user paid but didn't unlock | Implement `restorePurchases()` prominently. Log error details to local file. Show user-facing "Restore Purchases" prompt on error. |
| Word definition quality varies — parents notice a wrong or confusing definition | Medium | Medium — negative reviews | All 520 definitions reviewed before launch (owner task, not mobile-developer). Definitions stored as Dart constants — a fix is a code push, not a server update. |
| SharedPreferences data loss on Android (Clear Data / uninstall) | High (by design) | Low — data loss is expected, not a bug | In-app copy: "Your progress is saved on this device." No misleading "cloud sync" promise. Family subscription does NOT promise sync. |
| `flutter_tts` voice quality varies significantly by device | High | Low | Settings screen exposes speed slider; language is locked to en-US. No control over voice selection in v1 — document this as known limitation. |
| Cost at scale | Near-zero | N/A | Zero server costs. IAP revenue has 30 % Apple/Google commission. No recurring infrastructure cost. |
| Google Play Billing policy change for `in_app_purchase` | Low | Medium | Monitor Flutter team's `in_app_purchase` changelog. The package abstracts the Billing client version. |
| `family_annual` subscription reviewed as "misleading" (v1 has no family features) | Medium | High — rejection or forced refund | App Store description must NOT mention "family profiles" as a current feature. Copy must say "Family plan — all words + supports future family profiles." Legal copy matters here. |

---

## §13 · Definition of Done for v1

QA-tester runs this checklist line-by-line before sign-off. ALL items must pass.

### Static Analysis + Build
- [ ] `flutter analyze` returns zero issues (errors or warnings)
- [ ] `flutter test` passes (widget_test.dart at minimum)
- [ ] `flutter build ipa --no-codesign` exits 0
- [ ] `flutter build appbundle --release` exits 0
- [ ] No `print()` statements in lib/ (use `debugPrint` or remove)

### Device Matrix — iOS
- [ ] iPhone SE 3rd gen (375 pt width) — all screens render without overflow
- [ ] iPhone 16 Pro Max (430 pt width) — all screens render without overflow
- [ ] iPad Air (768 pt width) — app runs without crash (layout may not be optimized)
- [ ] iOS 14.0 simulator — app launches, TTS fires, IAP sandbox works
- [ ] iOS 17 device (or latest simulator) — app launches, TTS fires, IAP sandbox works

### Device Matrix — Android
- [ ] Pixel 4a equivalent (Android 11, SDK 30) — app launches, TTS fires
- [ ] Large-screen Android (tablet, SDK 33) — app runs without crash

### Word Data
- [ ] All 40 Dolch Pre-Primer words present in `dolch_pre_primer.dart`
- [ ] All 52 Dolch Primer words present in `dolch_primer.dart`
- [ ] All 41 Dolch Grade 1 words present in `dolch_grade1.dart`
- [ ] All 46 Dolch Grade 2 words present in `dolch_grade2.dart`
- [ ] All 41 Dolch Grade 3 words present in `dolch_grade3.dart`
- [ ] Fry 1–50 (50 words) present and marked `isFree: true`
- [ ] Fry 51–300 (250 words across 5 lists) present and marked `isFree: false`
- [ ] Every `WordEntry` has non-empty `definition` and `emoji` fields
- [ ] `all_lists.dart` correctly flags `isFree: true` for Dolch Pre-Primer, Dolch Primer, and Fry 1–50 only

### Free / Paid Gating
- [ ] HomeScreen: Dolch Pre-Primer, Dolch Primer, and Fry 1–50 cards are tappable without purchase
- [ ] HomeScreen: All other 8 list cards show lock icon and open PaywallSheet on tap
- [ ] After sandbox purchase of `full_unlock`: all 11 lists are tappable
- [ ] After sandbox purchase of `family_annual`: all 11 lists are tappable
- [ ] Restore Purchases (PaywallSheet): restores `full_unlock` in sandbox
- [ ] Restore Purchases (SettingsScreen): restores `full_unlock` in sandbox
- [ ] Killing and relaunching app after purchase: entitlement persists (cached in SharedPreferences, verified via StoreKit on launch)

### FlashCard Screen
- [ ] Card flip animation is smooth (no jank on SE-class device)
- [ ] TTS fires within 300 ms of card flip
- [ ] Swipe right marks word as mastered (level 2); word chip turns green on MasteryScreen
- [ ] Swipe left marks word as learning (level 1); word chip turns amber on MasteryScreen
- [ ] Progress bar advances correctly (1/N, 2/N … N/N)
- [ ] At last card: "All done!" state renders, back button navigates to HomeScreen

### Quiz Screen
- [ ] Session draws exactly 10 words (or all words if list has < 10)
- [ ] Words with level 0 or 1 are drawn first before level 2 words
- [ ] "I knew it" button updates mastery to level 2 for that word
- [ ] "Still learning" button updates mastery to level 1 for that word
- [ ] Microphone button is hidden when `speech_to_text` is unavailable (simulator)
- [ ] 10/10 score triggers confetti animation
- [ ] Session results screen shows correct X/10 count

### Mastery Screen
- [ ] Green chips for level-2 words
- [ ] Amber chips for level-1 words
- [ ] Gray chips for level-0 words
- [ ] Summary line is mathematically correct
- [ ] "Start Quiz" routes to QuizScreen for the correct list

### Settings Screen
- [ ] Voice speed slider changes TTS speed immediately (test: tap a card after adjusting)
- [ ] "Use microphone in quiz" toggle persists across app restart
- [ ] Restore Purchases works in sandbox
- [ ] App version string is correct (matches `pubspec.yaml` `version:`)
- [ ] Privacy policy link opens browser (must not 404)

### Permissions
- [ ] Microphone permission is NOT requested on app launch
- [ ] Microphone permission IS requested the first time child taps mic button in QuizScreen
- [ ] If permission denied: mic button hidden gracefully, no crash
- [ ] No camera permission ever requested

### Info.plist / Manifest
- [ ] `NSMicrophoneUsageDescription` present in Info.plist
- [ ] `NSSpeechRecognitionUsageDescription` present in Info.plist
- [ ] `ITSAppUsesNonExemptEncryption` = false in Info.plist
- [ ] `PrivacyInfo.xcprivacy` present, declares UserDefaults, `NSPrivacyTracking` = NO
- [ ] Android `RECORD_AUDIO` permission in AndroidManifest.xml
- [ ] Android `com.android.vending.BILLING` permission in AndroidManifest.xml
- [ ] NO `GADApplicationIdentifier` in Info.plist (AdMob must be absent)

### App Store Connect Readiness
- [ ] Bundle ID `com.idealai.sightwords` registered in Apple Developer
- [ ] Both IAP product IDs registered in App Store Connect
- [ ] App record created in App Store Connect with age rating 4+
- [ ] Kids Category selected in App Store Connect
- [ ] First IPA uploaded manually to TestFlight (auto-publish only from v1.0.5+)

---

## §14 · Build and Release Plan

### Milestone Table

| Milestone | Target date | Owner | Notes |
|---|---|---|---|
| Bundle ID registered in Apple Developer | Day 0 | console-operator | `com.idealai.sightwords` — must be done ≥ 24 h before first iOS build |
| IAP products registered in App Store Connect | Day 0 | console-operator | `com.idealai.sightwords.full_unlock`, `com.idealai.sightwords.family_annual` |
| App record created in App Store Connect | Day 0 | console-operator | Age rating 4+, Kids Category, primary language English |
| Upload keystore generated + committed | Day 0 | ci-cd-engineer | Store in `apps/sightwords/android/keystore/` (gitignored); SHA-1 + SHA-256 registered nowhere (no Firebase) |
| Flutter project scaffold + word data | Day 1 | mobile-developer | Task 1 |
| HomeScreen + FlashCard + TTS | Day 2 | mobile-developer | Tasks 2–3 |
| IAP wiring + PaywallSheet | Day 3 | mobile-developer | Task 4 |
| MasteryScreen + QuizScreen | Day 4 | mobile-developer | Tasks 5–6 |
| SettingsScreen + permissions polish | Day 5 | mobile-developer | Tasks 7–8 |
| Codemagic CI green | Day 6 | ci-cd-engineer | Task 9 |
| QA checklist pass | Day 7 | qa-tester | Task 10 |
| v1.0.0 IPA uploaded to TestFlight manually | Day 7 | ci-cd-engineer | First upload is always manual per Apple policy |
| v1.0.0 AAB uploaded to Google Play Internal manually | Day 7 | ci-cd-engineer | First upload is always manual per Google Play policy |
| v1.0.0 App Store submission | Day 8 | console-operator | Kids Category review takes 3–5 business days typically |
| v1.0.5+ Codemagic auto-publish enabled | Post-launch | ci-cd-engineer | After first manual approval, auto-publish on tag |

### Version bootstrap pattern

```
v1.0.0 — manual upload to TestFlight + Play Internal
v1.0.1 — manual (patch for any App Review rejection)
v1.0.2 — manual (second rejection patch if needed)
v1.0.3 — first Codemagic auto-submit attempt
v1.0.4 — Codemagic auto-submit confirmed working
v1.0.5+ — full auto-publish on git tag
```

### Codemagic workflow names

- `sightwords-ios` — builds IPA, uploads to TestFlight
- `sightwords-android` — builds AAB, uploads artifact to Codemagic (manual Play upload until v1.0.5)

---

## §15 · Stack Summary

| Concern | Choice | Reason |
|---|---|---|
| Framework | Flutter (stable) + Dart | Single codebase, iOS + Android, studio standard |
| State management | Riverpod 2.x (NotifierProvider) | Studio standard; ported from Stride |
| Word data | Dart const lists (bundled) | 520 words × ~5 fields = trivial size; zero network; zero latency; Kids Category safe |
| Mastery persistence | SharedPreferences (`Map<String,int>`) | No relational structure needed; one key per app |
| IAP | `in_app_purchase` (first-party) | Kids Category safe; avoids RevenueCat's analytics SDK risk |
| TTS | `flutter_tts` (device engine) | Zero cost, zero network, zero privacy concern |
| Speech recognition | `speech_to_text` (on-device) | Optional; gracefully degrades; no cloud STT API |
| Analytics | NONE (App Store Connect only) | Kids Category compliance; no tracking SDKs permitted |
| Push notifications | NONE | Not needed for this app model in v1 |
| Backend | NONE | Fully offline; no server cost |
| CI/CD | Codemagic | Studio standard |
| Code signing | Codemagic-managed | Studio standard |
| Minimum iOS | 14.0 | Driven by `speech_to_text` requirement |
| Minimum Android | SDK 23 | Clean permissions UX; 98 %+ device coverage |

---

## §A · What This App Refuses to Do

*(Mandatory adversarial section — do not skip.)*

The category leader is **Sight Words — Learn to Read** by Innovative Mobile Apps (consistently top-5 in Education > Kids on iOS). Here are five things it does that Sight Words Flash Cards deliberately will never do:

---

**Refusal 1: We will never show ads.**

The category leader runs interstitial and banner ads between word sessions. Parents report this in 1-star reviews ("ruined by pop-up ads") constantly.

- What does the user gain from the absence? A session that never gets interrupted. A child in flow state does not tolerate a 5-second rewarded video between flashcards. Parents pay $2.99 once and the ads are gone forever — or they get 142 free words with zero ads, ever.
- Which competitor is most threatened? Sight Words — Learn to Read. Their ad revenue model requires them to keep ads; removing them would collapse their free tier economics.
- Positioning line: "No ads. Ever. Not even in the free tier."

---

**Refusal 2: We will never require an account or login.**

Many competitors in this category require email sign-up to "save progress" or "unlock cloud sync." Parents of young children are highly suspicious of accounts for kids' apps, especially post-2022 COPPA enforcement.

- What does the user gain? Zero friction. Parent opens app, hands to child. No sign-up screen, no email verification, no password. The first card is one tap from launch.
- Which competitor is most threatened? Any competitor with an account wall (e.g., Reading Eggs, Epic!). They cannot credibly remove their account requirement because their entire multi-device sync value prop depends on it.
- Positioning line: "No login. No account. Open and go."

---

**Refusal 3: We will never gamify with streaks, points, or virtual rewards.**

Duolingo-style streaks create anxiety when broken. Star sticker economies create extrinsic motivation that crowds out genuine reading interest. Every major pediatric reading researcher (Willingham, Dehaene) warns against reward-for-reading mechanics.

- What does the user gain? A child who reads for meaning, not for stars. Parents who care about genuine literacy (the app's actual buyer) are already skeptical of gamification. The mastery heatmap is progress visualization, not a reward system.
- Which competitor is most threatened? Bob Books — Reading Magic, which is heavily gamified. Their users are "playing" the app, not learning from it. They cannot de-gamify without losing their existing user base's expectations.
- Positioning line: "No streaks. No stars. Just words — and whether your child knows them."

---

**Refusal 4: We will never add a dark mode.**

Dark mode on a kids' reading app is a distraction debate (backlit screens at night) that is irrelevant to the core use case. The app is designed for daytime, parent-supervised sessions. Building dark mode in v1 adds layout complexity, testing surface, and design tokens without any PMF signal.

- What does the user gain? A simpler, more focused app that ships faster. Light mode is more legible for early readers (higher contrast on white backgrounds matches printed text).
- Which competitor is most threatened? No competitor is specifically threatened — this is a product integrity refusal, not a market positioning one. We gain: faster v1, less QA surface.
- Positioning line: This is an internal design discipline refusal, not a marketing line. Dark mode is §10 non-MVP scope.

---

**Refusal 5: We will never let parents add custom word lists.**

Custom word list editors seem like a power feature. In practice, they are a QA nightmare (emoji picker, definition editor, TTS behavior with misspelled words) and they dilute the "complete and curated" positioning. The 520-word Dolch + Fry corpus is the universally recognized standard; having exactly this corpus is the product.

- What does the user gain? Trust. Teachers and parents who know the Dolch/Fry corpus trust that this app covers exactly what the school system expects. A custom list feature implies the built-in lists might be incomplete — which undermines the core value prop.
- Which competitor is most threatened? Sight Words by Learning Without Tears, which has a "My Words" custom list feature. They cannot credibly remove it because power users have already built lists in the app.
- Positioning line: "All 520 Dolch and Fry words. Complete. Curated. Ready."

---

## §B · The Share Moment

*(Mandatory adversarial section — do not skip.)*

**Persona:** Mia, 29, kindergarten teacher in Austin, Texas. Tuesday at 8:14pm. She just finished grading sight word assessments. Three of her students are struggling with the Pre-Primer list. She downloads the app to vet it for a parent recommendation email she's sending tomorrow.

**The literal text message Mia sends to her teaching partner Jade:**

> "ok this is actually good — no ads, just the dolch words with little emojis and it reads them out loud. free for the first two lists. sending it to the hendersons and kowalskis tomorrow. $3 for all 520 words 👍"

---

**Hook analysis:**

- Does the message have a hook in the first 7 words? Yes: "ok this is actually good — no ads" is the hook. "No ads" is the signal that differentiates this from every other kids word app Jade has recommended and gotten burned by.
- Does it require explanation? No. Jade knows Dolch words. "Reads them out loud" is self-explanatory. "Free for the first two lists" sets the business model in one clause.
- What's sent with it? Mia screenshots the HomeScreen showing the grid of lists with the mastery percentage badges — it looks professional and complete, unlike clip-art-heavy competitors. The screenshot is the proof. It must look clean and trustworthy, not toy-like.
- Would Jade open the App Store? Yes — because the recommendation is from a teacher (trusted source), the price is stated ($3 is impulse purchase territory), and the "no ads" signal resolves the primary objection Jade has from past experience with kids' apps.

**Share artifact that must exist in the MVP:** The HomeScreen list grid with mastery percentage badges. This is the screenshot Mia takes. It must look professional — each list card showing the list name, word count, and a mastery ring or percentage. This is already in the §5 screen inventory and §6 Task 2. Confirmed: no spec amendment needed.

**Organic distribution path:** Teachers recommend to parents. This is a B2B2C path — not viral in the consumer sense, but highly trusted and high-conversion. A single teacher recommendation email to 25 families in a class is worth more than 10,000 impressions on Facebook. The app's job is to be good enough that teachers feel confident putting their name on the recommendation.
