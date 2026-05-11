import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/tokens.dart';
import '../../../data/word_lists/all_lists.dart';
import '../../../providers.dart';

class FlashCardScreen extends ConsumerStatefulWidget {
  const FlashCardScreen({super.key, required this.wordList});
  final WordList wordList;

  @override
  ConsumerState<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends ConsumerState<FlashCardScreen>
    with SingleTickerProviderStateMixin {
  late List<int> _order;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isDone = false;
  late AnimationController _controller;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _order = List.generate(widget.wordList.words.length, (i) => i);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _cardIndex => _order[_currentIndex];
  get _currentWord => widget.wordList.words[_cardIndex];
  int get _total => widget.wordList.words.length;

  Future<void> _flipCard() async {
    if (_controller.isAnimating) return;
    if (!_isFlipped) {
      await _controller.forward();
      setState(() => _isFlipped = true);
      await _speak(_currentWord.text);
    } else {
      await _controller.reverse();
      setState(() => _isFlipped = false);
    }
  }

  Future<void> _speak(String word) async {
    final tts = ref.read(ttsServiceProvider);
    final speed = ref.read(voiceSpeedProvider);
    await tts.setSpeechRate(speed);
    await tts.speak(word);
  }

  Future<void> _advance(int masteryLevel) async {
    await ref
        .read(masteryProvider.notifier)
        .setLevel(_currentWord.text, masteryLevel);

    if (_currentIndex >= _total - 1) {
      setState(() => _isDone = true);
      return;
    }

    if (_isFlipped) {
      await _controller.reverse();
    }
    setState(() {
      _currentIndex++;
      _isFlipped = false;
    });
  }

  void _shuffle() {
    setState(() {
      _order.shuffle();
      _currentIndex = 0;
      _isFlipped = false;
      _controller.reset();
      _isDone = false;
    });
  }

  void _previous() {
    if (_currentIndex == 0) return;
    if (_isFlipped) _controller.reset();
    setState(() {
      _currentIndex--;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          widget.wordList.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: _isDone
          ? null
          : FloatingActionButton(
              onPressed: _shuffle,
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              tooltip: 'Shuffle',
              child: const Icon(Icons.shuffle),
            ),
      body: _isDone ? _buildDoneState() : _buildCardState(),
    );
  }

  Widget _buildCardState() {
    final progress = (_currentIndex + 1) / _total;
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: kHairline,
          color: kPrimary,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_currentIndex + 1} / $_total',
            style: const TextStyle(color: kInkSoft, fontSize: 13),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _flipCard,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -200) {
                // swipe left → still learning
                _advance(1);
              } else if (velocity > 200) {
                // swipe right → mastered
                _advance(2);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, child) {
                  final angle = _flipAnim.value * math.pi;
                  final isFront = _flipAnim.value < 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isFront
                        ? _buildFront()
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildBack(),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
        _buildBottomRow(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentWord.text,
              style: const TextStyle(
                fontSize: kWordFontSizeFront,
                fontWeight: FontWeight.bold,
                color: kInk,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.touch_app, color: kInkSoft, size: 18),
                SizedBox(width: 6),
                Text(
                  'Tap to hear',
                  style: TextStyle(color: kInkSoft, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentWord.emoji,
              style: const TextStyle(fontSize: kEmojiFontSize),
            ),
            const SizedBox(height: 12),
            Text(
              _currentWord.text,
              style: const TextStyle(
                fontSize: kWordFontSizeBack,
                color: kInkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _currentWord.definition,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: kInk),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: kMinTapTarget,
              child: OutlinedButton.icon(
                onPressed: _currentIndex > 0 ? _previous : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(foregroundColor: kPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: kMinTapTarget,
              child: ElevatedButton.icon(
                onPressed: () => _advance(1),
                icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
                label: const Text('Learning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWarning,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: kMinTapTarget,
              child: ElevatedButton.icon(
                onPressed: () => _advance(2),
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                label: const Text('Known'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccess,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneState() {
    final masteryMap = ref.watch(masteryProvider);
    final mastered =
        widget.wordList.words.where((w) => (masteryMap[w.text] ?? 0) == 2).length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('All done! \u{1F389}', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 16),
            Text(
              '$mastered / $_total words known',
              style: const TextStyle(fontSize: 20, color: kInk),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: kMinTapTarget,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _isFlipped = false;
                    _isDone = false;
                    _controller.reset();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                child: const Text(
                  'Go again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
