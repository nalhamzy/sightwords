/// Immutable data model for a single sight word.
/// All instances are compile-time constants bundled with the app.
/// No serialization needed — word data is Dart const, not JSON.
///
/// [text]        The word itself, e.g. 'jump'
/// [listName]    Human-readable list name, e.g. 'Dolch Pre-Primer'
/// [gradeLevel]  0 = Pre-K/Pre-Primer, 1 = Grade 1, etc.
/// [definition]  Kid-friendly definition, max 10 words
/// [emoji]       Single emoji that illustrates the word, e.g. '🐘'
class WordEntry {
  final String text;
  final String listName;
  final int gradeLevel;
  final String definition;
  final String emoji;

  const WordEntry({
    required this.text,
    required this.listName,
    required this.gradeLevel,
    required this.definition,
    required this.emoji,
  });
}
