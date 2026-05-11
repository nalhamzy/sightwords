import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/tokens.dart';
import '../../../data/word_lists/all_lists.dart';
import '../../../providers.dart';
import '../../flashcard/presentation/flashcard_screen.dart';
import '../../mastery/presentation/mastery_screen.dart';
import '../../paywall/presentation/paywall_sheet.dart';
import '../../quiz/presentation/quiz_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _dolchLists = [
    'dolch_pre_primer',
    'dolch_primer',
    'dolch_grade1',
    'dolch_grade2',
    'dolch_grade3',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(masteryProvider);
    final entitlements = ref.watch(entitlementsProvider);
    final dolch =
        allWordLists.where((l) => _dolchLists.contains(l.id)).toList();
    final fry =
        allWordLists.where((l) => !_dolchLists.contains(l.id)).toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text(
          'Sight Words \u{1F41D}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _sectionHeader('Dolch Words'),
          ...dolch.map(
            (list) => _WordListCard(
              list: list,
              mastery: mastery,
              hasAccess: list.isFree || entitlements.fullAccess,
            ),
          ),
          const SizedBox(height: 12),
          _sectionHeader('Fry Words'),
          ...fry.map(
            (list) => _WordListCard(
              list: list,
              mastery: mastery,
              hasAccess: list.isFree || entitlements.fullAccess,
            ),
          ),
          if (!entitlements.fullAccess) ...[
            const SizedBox(height: 16),
            _PremiumBanner(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: kInk,
        ),
      ),
    );
  }
}

class _WordListCard extends ConsumerWidget {
  const _WordListCard({
    required this.list,
    required this.mastery,
    required this.hasAccess,
  });

  final WordList list;
  final Map<String, int> mastery;
  final bool hasAccess;

  double _masteryPercent() {
    if (list.words.isEmpty) return 0.0;
    final mastered =
        list.words.where((w) => (mastery[w.text] ?? 0) == 2).length;
    return mastered / list.words.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = _masteryPercent();

    return Card(
      color: kCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hasAccess
            ? null
            : () => _showPaywall(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              list.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kInk,
                              ),
                            ),
                            if (!hasAccess) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.lock,
                                size: 16,
                                color: kInkSoft,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                list.gradeLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${list.words.length} words',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kInkSoft,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Mastery ring
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: percent,
                          strokeWidth: 5,
                          backgroundColor: kHairline,
                          color: kSuccess,
                        ),
                        Text(
                          '${(percent * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Flash Cards',
                      icon: Icons.style,
                      enabled: hasAccess,
                      primary: true,
                      onTap: () => _openFlashCards(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Quiz',
                      icon: Icons.quiz,
                      enabled: hasAccess,
                      primary: false,
                      onTap: () => _openQuiz(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MasteryIconButton(
                    onTap: hasAccess
                        ? () => _openMastery(context)
                        : () => _showPaywall(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PaywallSheet(),
    );
  }

  void _openFlashCards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FlashCardScreen(wordList: list),
      ),
    );
  }

  void _openQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(wordList: list),
      ),
    );
  }

  void _openMastery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MasteryScreen(wordList: list),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMinTapTarget,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(enabled ? icon : Icons.lock_outline, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? kPrimary : kCard,
          foregroundColor: primary ? Colors.white : kPrimary,
          side: primary ? null : const BorderSide(color: kPrimary),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: primary ? 1 : 0,
        ),
      ),
    );
  }
}

class _MasteryIconButton extends StatelessWidget {
  const _MasteryIconButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMinTapTarget,
      height: kMinTapTarget,
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.bar_chart, color: kPrimary),
        tooltip: 'View mastery',
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _PremiumBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: kPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const PaywallSheet(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.star, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock all 520 sight words',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'One-time unlock \$2.99 — no ads, no account',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
