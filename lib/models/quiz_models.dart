import 'package:flutter/material.dart';

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int points;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.points,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctIndex: json['correct_index'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
      points: json['points'] as int? ?? 100,
    );
  }
}

class QuizCategory {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final List<QuizQuestion> questions;

  QuizCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.questions,
  });

  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFFF8FF13);
    if (json['color'] != null) {
      final hex = json['color'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('FF$hex', radix: 16));
      }
    }

    final qList = (json['questions'] as List<dynamic>?)
            ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList() ??
        [];

    return QuizCategory(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'sports_soccer',
      color: parsedColor,
      questions: qList,
    );
  }
}

class WordPuzzle {
  final String word;
  final String hint;
  final String category;
  final String difficulty;
  final int points;

  WordPuzzle({
    required this.word,
    required this.hint,
    required this.category,
    required this.difficulty,
    required this.points,
  });

  factory WordPuzzle.fromJson(Map<String, dynamic> json) {
    return WordPuzzle(
      word: (json['word'] as String? ?? '').toUpperCase().trim(),
      hint: json['hint'] as String? ?? '',
      category: json['category'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Легкий',
      points: json['points'] as int? ?? 100,
    );
  }
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int targetCount;
  final int rewardCoins;
  final String icon;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.rewardCoins,
    required this.icon,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetCount: json['target_count'] as int? ?? 1,
      rewardCoins: json['reward_coins'] as int? ?? 100,
      icon: json['icon'] as String? ?? 'sports_soccer',
    );
  }
}

class LoyaltyReward {
  final String id;
  final String title;
  final int cost;
  final String icon;
  final String description;
  final String category;

  LoyaltyReward({
    required this.id,
    required this.title,
    required this.cost,
    required this.icon,
    required this.description,
    required this.category,
  });

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cost: json['cost'] as int? ?? 100,
      icon: json['icon'] as String? ?? 'emoji_events',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Награды',
    );
  }
}

class FanLevel {
  final int level;
  final String name;
  final int minXp;
  final Color color;

  FanLevel({
    required this.level,
    required this.name,
    required this.minXp,
    required this.color,
  });

  factory FanLevel.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFFF8FF13);
    if (json['color'] != null) {
      final hex = json['color'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('FF$hex', radix: 16));
      }
    }

    return FanLevel(
      level: json['level'] as int? ?? 1,
      name: json['name'] as String? ?? 'Новичок',
      minXp: json['min_xp'] as int? ?? 0,
      color: parsedColor,
    );
  }
}
