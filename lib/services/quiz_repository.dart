import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quiz_models.dart';

class QuizRepository {
  List<QuizCategory> categories = [];
  List<WordPuzzle> words = [];
  List<DailyChallenge> dailyChallenges = [];
  List<LoyaltyReward> loyaltyStore = [];
  List<FanLevel> fanLevels = [];
  bool isLoaded = false;

  Future<void> loadData() async {
    if (isLoaded) return;
    try {
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/words.json');
      } catch (_) {
        jsonString = await rootBundle.loadString('assets/quiz_data.json');
      }

      final Map<String, dynamic> data = json.decode(jsonString) as Map<String, dynamic>;

      if (data['categories'] != null) {
        categories = (data['categories'] as List<dynamic>)
            .map((c) => QuizCategory.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      if (data['words'] != null) {
        words = (data['words'] as List<dynamic>)
            .map((w) => WordPuzzle.fromJson(w as Map<String, dynamic>))
            .toList();
      }

      if (data['daily_challenges'] != null) {
        dailyChallenges = (data['daily_challenges'] as List<dynamic>)
            .map((d) => DailyChallenge.fromJson(d as Map<String, dynamic>))
            .toList();
      }

      if (data['loyalty_store'] != null) {
        loyaltyStore = (data['loyalty_store'] as List<dynamic>)
            .map((s) => LoyaltyReward.fromJson(s as Map<String, dynamic>))
            .toList();
      }

      if (data['fan_levels'] != null) {
        fanLevels = (data['fan_levels'] as List<dynamic>)
            .map((l) => FanLevel.fromJson(l as Map<String, dynamic>))
            .toList();
      }

      isLoaded = true;
    } catch (e) {
      debugPrint('Error loading quiz data from JSON: $e');
    }
  }

  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'stadium':
        return Icons.stadium_rounded;
      case 'sports':
      case 'sports_soccer':
        return Icons.sports_soccer_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'filter_2':
        return Icons.filter_2_rounded;
      case 'verified_user':
        return Icons.verified_user_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'style':
        return Icons.style_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'spellcheck':
        return Icons.spellcheck_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'palette':
        return Icons.palette_rounded;
      default:
        return Icons.sports_soccer_rounded;
    }
  }
}
