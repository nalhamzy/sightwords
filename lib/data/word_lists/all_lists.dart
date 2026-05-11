// Master registry of all word lists.
//
// isFree=true  => Dolch Pre-Primer, Dolch Primer, Fry 1-50 (SPEC §7)
// isFree=false => all other 8 lists (require full_unlock or family_annual)

import 'word_entry.dart';
import 'dolch_pre_primer.dart';
import 'dolch_primer.dart';
import 'dolch_grade1.dart';
import 'dolch_grade2.dart';
import 'dolch_grade3.dart';
import 'fry_1_50.dart';
import 'fry_51_100.dart';
import 'fry_101_150.dart';
import 'fry_151_200.dart';
import 'fry_201_250.dart';
import 'fry_251_300.dart';

/// Descriptor for one word list shown on HomeScreen.
class WordList {
  final String id;
  final String displayName;
  final String gradeLabel;
  final List<WordEntry> words;
  final bool isFree;

  const WordList({
    required this.id,
    required this.displayName,
    required this.gradeLabel,
    required this.words,
    required this.isFree,
  });
}

/// All 11 lists in display order.
const List<WordList> allWordLists = [
  WordList(
    id: 'dolch_pre_primer',
    displayName: 'Dolch Pre-Primer',
    gradeLabel: 'Pre-K',
    words: dolchPrePrimerWords,
    isFree: true,
  ),
  WordList(
    id: 'dolch_primer',
    displayName: 'Dolch Primer',
    gradeLabel: 'Kindergarten',
    words: dolchPrimerWords,
    isFree: true,
  ),
  WordList(
    id: 'dolch_grade1',
    displayName: 'Dolch Grade 1',
    gradeLabel: 'Grade 1',
    words: dolchGrade1Words,
    isFree: false,
  ),
  WordList(
    id: 'dolch_grade2',
    displayName: 'Dolch Grade 2',
    gradeLabel: 'Grade 2',
    words: dolchGrade2Words,
    isFree: false,
  ),
  WordList(
    id: 'dolch_grade3',
    displayName: 'Dolch Grade 3',
    gradeLabel: 'Grade 3',
    words: dolchGrade3Words,
    isFree: false,
  ),
  WordList(
    id: 'fry_1_50',
    displayName: 'Fry 1–50',
    gradeLabel: 'Grade 1',
    words: fry1to50Words,
    isFree: true,
  ),
  WordList(
    id: 'fry_51_100',
    displayName: 'Fry 51–100',
    gradeLabel: 'Grade 1–2',
    words: fry51to100Words,
    isFree: false,
  ),
  WordList(
    id: 'fry_101_150',
    displayName: 'Fry 101–150',
    gradeLabel: 'Grade 2',
    words: fry101to150Words,
    isFree: false,
  ),
  WordList(
    id: 'fry_151_200',
    displayName: 'Fry 151–200',
    gradeLabel: 'Grade 2–3',
    words: fry151to200Words,
    isFree: false,
  ),
  WordList(
    id: 'fry_201_250',
    displayName: 'Fry 201–250',
    gradeLabel: 'Grade 3',
    words: fry201to250Words,
    isFree: false,
  ),
  WordList(
    id: 'fry_251_300',
    displayName: 'Fry 251–300',
    gradeLabel: 'Grade 3–4',
    words: fry251to300Words,
    isFree: false,
  ),
];
