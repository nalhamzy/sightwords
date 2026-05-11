// Design tokens for Sight Words Flash Cards.
// ui-ux-designer fills in the final values. These are placeholder defaults.
// Light mode only — dark mode is explicitly excluded (SPEC §10 item 6).

import 'package:flutter/material.dart';

// Primary palette — bright, high-contrast, kid-friendly
const Color kPrimary   = Color(0xFF4A90D9);  // sky blue — CTA buttons
const Color kSuccess   = Color(0xFF4CAF50);  // green — mastered words
const Color kWarning   = Color(0xFFFFC107);  // amber — learning words
const Color kBg        = Color(0xFFF9F9F9);  // off-white background
const Color kCard      = Color(0xFFFFFFFF);  // card surface
const Color kInk       = Color(0xFF1A1A1A);  // body text
const Color kInkSoft   = Color(0xFF757575);  // secondary text
const Color kHairline  = Color(0xFFE0E0E0);  // dividers

// Minimum tap target: 48 × 48 logical pixels (SPEC §13, Kids Category)
const double kMinTapTarget = 48.0;

// Word card font sizes
const double kWordFontSizeFront = 64.0;  // front of flashcard
const double kWordFontSizeBack  = 36.0;  // back of flashcard (smaller)
const double kEmojiFontSize     = 72.0;  // emoji on back of card
