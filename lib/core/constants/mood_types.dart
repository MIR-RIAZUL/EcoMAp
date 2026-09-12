import 'package:flutter/material.dart';

enum Mood {
  happy(
    id: 'happy',
    label: 'Happy',
    emoji: '😊',
    color: Color(0xFFF4B400),
    lightBg: Color(0xFFFFF8E1),
    darkBg: Color(0xFF332A00),
  ),
  sad(
    id: 'sad',
    label: 'Sad',
    emoji: '😢',
    color: Color(0xFF4285F4),
    lightBg: Color(0xFFE8F0FE),
    darkBg: Color(0xFF0D254C),
  ),
  love(
    id: 'love',
    label: 'Love',
    emoji: '❤️',
    color: Color(0xFFE91E63),
    lightBg: Color(0xFFFCE4EC),
    darkBg: Color(0xFF420B1D),
  ),
  excited(
    id: 'excited',
    label: 'Excited',
    emoji: '🔥',
    color: Color(0xFFFF6D00),
    lightBg: Color(0xFFFFE0B2),
    darkBg: Color(0xFF421D00),
  ),
  peaceful(
    id: 'peaceful',
    label: 'Peaceful',
    emoji: '😌',
    color: Color(0xFF0F9D58),
    lightBg: Color(0xFFE8F5E9),
    darkBg: Color(0xFF0A2E16),
  ),
  angry(
    id: 'angry',
    label: 'Angry',
    emoji: '😡',
    color: Color(0xFFEA4335),
    lightBg: Color(0xFFFFEBEE),
    darkBg: Color(0xFF400B07),
  ),
  neutral(
    id: 'neutral',
    label: 'Neutral',
    emoji: '😐',
    color: Color(0xFF78909C),
    lightBg: Color(0xFFECEFF1),
    darkBg: Color(0xFF263238),
  );

  final String id;
  final String label;
  final String emoji;
  final Color color;
  final Color lightBg;
  final Color darkBg;

  const Mood({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    required this.lightBg,
    required this.darkBg,
  });

  Color getBackgroundColor(bool isDark) => isDark ? darkBg : lightBg;

  static Mood fromString(String? name) {
    if (name == null) return Mood.happy;
    for (final mood in Mood.values) {
      if (mood.id.toLowerCase() == name.toLowerCase() ||
          mood.label.toLowerCase() == name.toLowerCase()) {
        return mood;
      }
    }
    return Mood.happy;
  }
}
