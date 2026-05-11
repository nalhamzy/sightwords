import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/tokens.dart';
import '../../../data/word_lists/all_lists.dart';
import '../../../data/word_lists/word_entry.dart';
import '../../../providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.wordList});
  final WordList wordList;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  static const _sessionSize = 10;

  List<WordEntry> _session = [];
  int _currentIndex = 0;
  int _knownCount = 0;
  bool _sessionDone = false;

  // Speech
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _buildSession();
    _initSpeech();
  }

  void _buildSession() {
    final mastery = ref.read(masteryProvider);
    final all = widget.wordList.words.toList();
    // Sort: level 0 first, level 1 next, level 2 last
    all.sort((a, b) {
      final la = mastery[a.text] ?? 0;
      final lb = mastery[b.text] ?? 0;
      return la.compareTo(lb);
    });
    _session = all.take(_sessionSize).toList();
  }

  Future<void> _initSpeech() async {
    // Do not request permission here — only on user tap.
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    final quizSpeechEnabled = ref.read(quizSpeechProvider);
    if (!quizSpeechEnabled || !_speechAvailable) return;

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final spoken = result.recognizedWords.trim().toLowerCase();
          final target = _session[_currentIndex].text.toLowerCase();
          if (spoken == target) {
            _recordAnswer(knew: true);
          }
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
      localeId: 'en-US',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speak(String word) async {
    final tts = ref.read(ttsServiceProvider);
    final speed = ref.read(voiceSpeedProvider);
    await tts.setSpeechRate(speed);
    await tts.speak(word);
  }

  void _recordAnswer({required bool knew}) {
    final word = _session[_currentIndex];
    ref.read(masteryProvider.notifier).setLevel(word.text, knew ? 2 : 1);
    if (knew) _knownCount++;

    if (_currentIndex >= _session.length - 1) {
      setState(() => _sessionDone = true);
    } else {
      setState(() => _currentIndex++);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.wordList.displayName} Quiz',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _sessionDone ? _buildResults() : _buildQuizCard(),
    );
  }

  Widget _buildQuizCard() {
    final word = _session[_currentIndex];
    final quizSpeechEnabled = ref.watch(quizSpeechProvider);
    final progress = (_currentIndex + 1) / _session.length;

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
            '${_currentIndex + 1} / ${_session.length}',
            style: const TextStyle(color: kInkSoft, fontSize: 13),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              width: double.infinity,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    word.text,
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => _speak(word.text),
                    icon: const Icon(
                      Icons.volume_up,
                      color: kPrimary,
                      size: 36,
                    ),
                    tooltip: 'Hear word',
                  ),
                  if (_speechAvailable && quizSpeechEnabled) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color:
                              _isListening ? Colors.red : kPrimary.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.white : kPrimary,
                          size: 32,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _isListening ? 'Listening...' : 'Tap mic to say word',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kInkSoft,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Answer buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: kMinTapTarget + 8,
                child: ElevatedButton.icon(
                  onPressed: () => _recordAnswer(knew: true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    '\u{2713} I knew it',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSuccess,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: kMinTapTarget + 8,
                child: ElevatedButton.icon(
                  onPressed: () => _recordAnswer(knew: false),
                  icon: const Icon(Icons.highlight_off),
                  label: const Text(
                    '\u{2717} Still learning',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final isHighScore = _knownCount >= 8;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHighScore ? '\u{1F389}\u{1F31F}' : '\u{1F4AA}',
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16),
            Text(
              '$_knownCount / ${_session.length} words known!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isHighScore
                  ? 'Amazing! Keep it up!'
                  : 'Practice makes perfect!',
              style: const TextStyle(fontSize: 16, color: kInkSoft),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: kMinTapTarget + 4,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _knownCount = 0;
                    _currentIndex = 0;
                    _sessionDone = false;
                    _buildSession();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: kMinTapTarget,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
