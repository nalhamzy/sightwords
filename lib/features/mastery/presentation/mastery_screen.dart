import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/tokens.dart';
import '../../../data/word_lists/all_lists.dart';
import '../../../providers.dart';
import '../../quiz/presentation/quiz_screen.dart';

class MasteryScreen extends ConsumerWidget {
  const MasteryScreen({super.key, required this.wordList});
  final WordList wordList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(masteryProvider);

    final mastered = wordList.words.where((w) => (mastery[w.text] ?? 0) == 2).length;
    final learning = wordList.words.where((w) => (mastery[w.text] ?? 0) == 1).length;
    final notStarted = wordList.words.where((w) => (mastery[w.text] ?? 0) == 0).length;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          '${wordList.displayName} — Mastery',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Summary row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SummaryChip(
                    count: mastered,
                    label: 'Mastered',
                    color: kSuccess,
                  ),
                  _SummaryChip(
                    count: learning,
                    label: 'Learning',
                    color: kWarning,
                  ),
                  _SummaryChip(
                    count: notStarted,
                    label: 'Not started',
                    color: kHairline,
                    textColor: kInkSoft,
                  ),
                ],
              ),
            ),
          ),
          // Word chip grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: wordList.words.length,
              itemBuilder: (context, index) {
                final word = wordList.words[index];
                final level = mastery[word.text] ?? 0;
                final color = level == 2
                    ? kSuccess
                    : level == 1
                        ? kWarning
                        : kHairline;
                final textColor =
                    (level == 0) ? kInkSoft : Colors.white;

                return Tooltip(
                  message: '${word.emoji} ${word.definition}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      word.text,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
          // Start Quiz CTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: kMinTapTarget + 4,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => QuizScreen(wordList: wordList),
                  ),
                ),
                icon: const Icon(Icons.quiz),
                label: const Text('Start Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
  });

  final int count;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: kInkSoft)),
      ],
    );
  }
}
