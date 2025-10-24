import 'package:flutter/material.dart';

enum Difficulty { easy, medium, hard }

enum OpponentType { ai, local }

extension DifficultyDisplay on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };

  IconData get icon => switch (this) {
        Difficulty.easy => Icons.sentiment_satisfied,
        Difficulty.medium => Icons.sentiment_neutral,
        Difficulty.hard => Icons.sentiment_very_dissatisfied,
      };

  Color get color => switch (this) {
        Difficulty.easy => Colors.green,
        Difficulty.medium => Colors.orange,
        Difficulty.hard => Colors.red,
      };

  String get description => switch (this) {
        Difficulty.easy => 'Relaxed play with quick responses.',
        Difficulty.medium => 'Balanced challenge for regular players.',
        Difficulty.hard => 'Tactical AI that looks ahead for advantages.',
      };
}

extension OpponentTypeDisplay on OpponentType {
  String get label => switch (this) {
        OpponentType.ai => 'AI Opponent',
        OpponentType.local => 'Local Multiplayer',
      };

  IconData get icon => switch (this) {
        OpponentType.ai => Icons.smart_toy,
        OpponentType.local => Icons.people,
      };

  String get description => switch (this) {
        OpponentType.ai => 'Play against the built-in engine with selectable difficulty.',
        OpponentType.local => 'Take turns on a single device with a friend.',
      };
}
