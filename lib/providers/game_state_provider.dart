import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_models.dart';

class GameStateProvider with ChangeNotifier {
  int _coins = 450; // Starter coins for immediate loyalty engagement
  int _xp = 150;
  int _quizzesCompleted = 0;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  int _wordsSolved = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  int _boosterFiftyCount = 2; // Starter 50/50 boosters
  int _boosterSkipCount = 1; // Starter immunity booster
  bool _boosterDoubleActive = false;

  final Set<String> _purchasedRewardIds = {};
  final Set<String> _claimedChallengeIds = {};
  final Map<String, int> _challengeProgress = {};

  bool _isLoaded = false;

  int get coins => _coins;
  int get xp => _xp;
  int get quizzesCompleted => _quizzesCompleted;
  int get questionsAnswered => _questionsAnswered;
  int get correctAnswers => _correctAnswers;
  int get wordsSolved => _wordsSolved;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get boosterFiftyCount => _boosterFiftyCount;
  int get boosterSkipCount => _boosterSkipCount;
  bool get boosterDoubleActive => _boosterDoubleActive;
  bool get isLoaded => _isLoaded;

  Set<String> get purchasedRewardIds => _purchasedRewardIds;
  Set<String> get claimedChallengeIds => _claimedChallengeIds;

  int get accuracyPercentage {
    if (_questionsAnswered == 0) return 100;
    return ((_correctAnswers / _questionsAnswered) * 100).round();
  }

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _coins = prefs.getInt('loyalty_coins') ?? 450;
      _xp = prefs.getInt('loyalty_xp') ?? 150;
      _quizzesCompleted = prefs.getInt('quizzes_completed') ?? 0;
      _questionsAnswered = prefs.getInt('questions_answered') ?? 0;
      _correctAnswers = prefs.getInt('correct_answers') ?? 0;
      _wordsSolved = prefs.getInt('words_solved') ?? 0;
      _currentStreak = prefs.getInt('current_streak') ?? 0;
      _bestStreak = prefs.getInt('best_streak') ?? 0;
      _boosterFiftyCount = prefs.getInt('booster_fifty') ?? 2;
      _boosterSkipCount = prefs.getInt('booster_skip') ?? 1;

      final purchased = prefs.getStringList('purchased_rewards') ?? [];
      _purchasedRewardIds.addAll(purchased);

      final claimed = prefs.getStringList('claimed_challenges') ?? [];
      _claimedChallengeIds.addAll(claimed);

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading game state prefs: $e');
      _isLoaded = true;
    }
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('loyalty_coins', _coins);
      await prefs.setInt('loyalty_xp', _xp);
      await prefs.setInt('quizzes_completed', _quizzesCompleted);
      await prefs.setInt('questions_answered', _questionsAnswered);
      await prefs.setInt('correct_answers', _correctAnswers);
      await prefs.setInt('words_solved', _wordsSolved);
      await prefs.setInt('current_streak', _currentStreak);
      await prefs.setInt('best_streak', _bestStreak);
      await prefs.setInt('booster_fifty', _boosterFiftyCount);
      await prefs.setInt('booster_skip', _boosterSkipCount);
      await prefs.setStringList('purchased_rewards', _purchasedRewardIds.toList());
      await prefs.setStringList('claimed_challenges', _claimedChallengeIds.toList());
    } catch (e) {
      debugPrint('Error saving game state prefs: $e');
    }
  }

  void addCoins(int amount) {
    _coins += amount;
    _savePrefs();
    notifyListeners();
  }

  void addXp(int amount) {
    final mult = _boosterDoubleActive ? 2 : 1;
    _xp += amount * mult;
    _savePrefs();
    notifyListeners();
  }

  void recordAnswer(bool isCorrect, int points) {
    _questionsAnswered++;
    if (isCorrect) {
      _correctAnswers++;
      _currentStreak++;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
      final mult = _boosterDoubleActive ? 2 : 1;
      _coins += points * mult;
      _xp += (points ~/ 2) * mult;

      // Update streak challenge progress
      _updateChallengeProgress('daily_3', _currentStreak);
    } else {
      _currentStreak = 0;
    }
    _savePrefs();
    notifyListeners();
  }

  void recordQuizFinished({
    required int total,
    required int correct,
    required int earnedCoins,
    required int earnedXp,
  }) {
    _quizzesCompleted++;
    _boosterDoubleActive = false; // Reset booster after game
    _updateChallengeProgress('daily_1', _quizzesCompleted);
    _savePrefs();
    notifyListeners();
  }

  void recordWordSolved(int points) {
    _wordsSolved++;
    final mult = _boosterDoubleActive ? 2 : 1;
    _coins += points * mult;
    _xp += (points ~/ 2) * mult;
    _updateChallengeProgress('daily_2', _wordsSolved);
    _savePrefs();
    notifyListeners();
  }

  bool purchaseReward(LoyaltyReward reward) {
    if (_coins < reward.cost) return false;

    // If it's a booster, add inventory
    if (reward.id == 'reward_booster_fifty') {
      _coins -= reward.cost;
      _boosterFiftyCount++;
      _savePrefs();
      notifyListeners();
      return true;
    }

    if (reward.id == 'reward_booster_skip') {
      _coins -= reward.cost;
      _boosterSkipCount++;
      _savePrefs();
      notifyListeners();
      return true;
    }

    if (reward.id == 'reward_booster_double') {
      _coins -= reward.cost;
      _boosterDoubleActive = true;
      _savePrefs();
      notifyListeners();
      return true;
    }

    // Permanent trophy / badge / status
    if (!_purchasedRewardIds.contains(reward.id)) {
      _coins -= reward.cost;
      _purchasedRewardIds.add(reward.id);
      addXp(100); // Bonus XP for purchasing loyalty rewards
      _savePrefs();
      notifyListeners();
      return true;
    }

    return false;
  }

  bool useFiftyFifty() {
    if (_boosterFiftyCount > 0) {
      _boosterFiftyCount--;
      _savePrefs();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool useSkip() {
    if (_boosterSkipCount > 0) {
      _boosterSkipCount--;
      _savePrefs();
      notifyListeners();
      return true;
    }
    return false;
  }

  int getChallengeProgress(String challengeId) {
    return _challengeProgress[challengeId] ?? 0;
  }

  void _updateChallengeProgress(String challengeId, int value) {
    _challengeProgress[challengeId] = value;
  }

  bool isChallengeClaimed(String challengeId) {
    return _claimedChallengeIds.contains(challengeId);
  }

  bool canClaimChallenge(DailyChallenge challenge) {
    if (isChallengeClaimed(challenge.id)) return false;
    final progress = getChallengeProgress(challenge.id);
    return progress >= challenge.targetCount;
  }

  void claimChallengeReward(DailyChallenge challenge) {
    if (!canClaimChallenge(challenge)) return;
    _claimedChallengeIds.add(challenge.id);
    addCoins(challenge.rewardCoins);
    addXp(150);
    _savePrefs();
    notifyListeners();
  }

  FanLevel getCurrentFanLevel(List<FanLevel> levels) {
    if (levels.isEmpty) {
      return FanLevel(
        level: 1,
        name: 'Новичок Трибун',
        minXp: 0,
        color: Color(0xFFF8FF13),
      );
    }
    FanLevel current = levels.first;
    for (final lvl in levels) {
      if (_xp >= lvl.minXp) {
        current = lvl;
      }
    }
    return current;
  }

  FanLevel? getNextFanLevel(List<FanLevel> levels) {
    for (final lvl in levels) {
      if (_xp < lvl.minXp) {
        return lvl;
      }
    }
    return null; // Max level reached
  }

  double getLevelProgress(List<FanLevel> levels) {
    if (levels.isEmpty) return 0.0;
    final current = getCurrentFanLevel(levels);
    final next = getNextFanLevel(levels);
    if (next == null) return 1.0;
    final range = next.minXp - current.minXp;
    if (range <= 0) return 1.0;
    final currentProgress = _xp - current.minXp;
    return (currentProgress / range).clamp(0.0, 1.0);
  }

  Future<void> resetProgress() async {
    _coins = 450;
    _xp = 150;
    _quizzesCompleted = 0;
    _questionsAnswered = 0;
    _correctAnswers = 0;
    _wordsSolved = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _boosterFiftyCount = 2;
    _boosterSkipCount = 1;
    _boosterDoubleActive = false;
    _purchasedRewardIds.clear();
    _claimedChallengeIds.clear();
    _challengeProgress.clear();
    await _savePrefs();
    notifyListeners();
  }
}
