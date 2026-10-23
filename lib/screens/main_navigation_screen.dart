import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../services/quiz_repository.dart';
import '../theme/app_theme.dart';
import 'tabs/loyalty_store_tab.dart';
import 'tabs/profile_stats_tab.dart';
import 'tabs/quizzes_tab.dart';
import 'tabs/word_guess_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  final QuizRepository? repository;

  const MainNavigationScreen({super.key, this.repository});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final QuizRepository _repository;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repository = widget.repository!;
      _isLoading = false;
    } else {
      _repository = QuizRepository();
      _initData();
    }
  }

  Future<void> _initData() async {
    await _repository.loadData();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    final currentLevel = gameState.getCurrentFanLevel(_repository.fanLevels);

    final List<Widget> tabs = [
      QuizzesTab(repository: _repository),
      WordGuessTab(repository: _repository),
      LoyaltyStoreTab(repository: _repository),
      ProfileStatsTab(repository: _repository),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_soccer_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Матч-Центр РПЛ',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Coins and Level Chips
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppTheme.accentGold,
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  '${gameState.coins}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 12,
                  color: AppTheme.surfaceBorder,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ур. ${currentLevel.level}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: currentLevel.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : IndexedStack(
                index: _currentIndex,
                children: tabs,
              ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer_rounded),
              activeIcon: Icon(Icons.sports_soccer_rounded),
              label: 'Квизы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.spellcheck_rounded),
              activeIcon: Icon(Icons.spellcheck_rounded),
              label: 'Слова',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard_rounded),
              activeIcon: Icon(Icons.card_giftcard_rounded),
              label: 'Награды',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}
