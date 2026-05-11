import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_constants.dart';
import 'iap_service.dart';

class Entitlements {
  final bool fullAccess;
  const Entitlements({required this.fullAccess});
  static const empty = Entitlements(fullAccess: false);
}

class EntitlementsNotifier extends Notifier<Entitlements> {
  @override
  Entitlements build() {
    _init();
    return Entitlements.empty;
  }

  Future<void> _init() async {
    await _refreshFromPrefs();
    // Wire up the IapService callback so purchases update this notifier.
    ref.read(iapServiceProvider).onPurchaseDelivered = (_) {
      _refreshFromPrefs();
    };
  }

  Future<void> _refreshFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final fullUnlock = prefs.getBool(SightWordsPrefsKeys.iapFullUnlock) ?? false;
    final familyActive =
        prefs.getBool(SightWordsPrefsKeys.iapFamilyActive) ?? false;
    state = Entitlements(fullAccess: fullUnlock || familyActive);
  }

  /// Called after a successful purchase/restore to update state immediately.
  Future<void> refresh() async => _refreshFromPrefs();
}

final entitlementsProvider =
    NotifierProvider<EntitlementsNotifier, Entitlements>(
      EntitlementsNotifier.new,
    );

final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService();
  ref.onDispose(service.dispose);
  return service;
});
