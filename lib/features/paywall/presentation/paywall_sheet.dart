import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/constants/tokens.dart';
import '../../../providers.dart';
import '../../../purchases/iap_constants.dart';

class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  bool _loading = false;
  String? _errorMessage;

  ProductDetails? _fullUnlockProduct;
  ProductDetails? _familyProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final service = ref.read(iapServiceProvider);
    final products = await service.queryProducts();
    if (mounted) {
      setState(() {
        _loading = false;
        for (final p in products) {
          if (p.id == SightWordsProductIds.fullUnlock) _fullUnlockProduct = p;
          if (p.id == SightWordsProductIds.familyAnnual) _familyProduct = p;
        }
      });
    }
  }

  Future<void> _purchase(ProductDetails product, bool isSubscription) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final service = ref.read(iapServiceProvider);
      if (isSubscription) {
        await service.buySubscription(product);
      } else {
        await service.buyNonConsumable(product);
      }
      // Delivery is handled via IapService callback → EntitlementsNotifier.
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Purchase could not be completed. Please try again.';
        });
      }
    }
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final service = ref.read(iapServiceProvider);
      await service.restorePurchases();
      await ref.read(entitlementsProvider.notifier).refresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Could not restore purchases.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kHairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unlock all 520 sight words',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kInk,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              '\u{2713}  All 220 Dolch words',
              '\u{2713}  All 300 Fry words',
              '\u{2713}  Full progress tracking',
              '\u{2713}  Quiz mode for every list',
            ].map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  bullet,
                  style: const TextStyle(fontSize: 15, color: kInk),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Full unlock button
              SizedBox(
                width: double.infinity,
                height: kMinTapTarget + 8,
                child: ElevatedButton(
                  onPressed: _fullUnlockProduct != null
                      ? () => _purchase(_fullUnlockProduct!, false)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _fullUnlockProduct != null
                        ? 'Unlock Forever — ${_fullUnlockProduct!.price}'
                        : 'Unlock Forever — \$2.99',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Family plan button
              SizedBox(
                width: double.infinity,
                height: kMinTapTarget + 8,
                child: OutlinedButton(
                  onPressed: _familyProduct != null
                      ? () => _purchase(_familyProduct!, true)
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: const BorderSide(color: kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _familyProduct != null
                        ? 'Family Plan — ${_familyProduct!.price}/year (up to 4 kids)'
                        : 'Family Plan — \$4.99/year (up to 4 kids)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _loading ? null : _restore,
                child: const Text(
                  'Restore Purchases',
                  style: TextStyle(
                    color: kInkSoft,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
