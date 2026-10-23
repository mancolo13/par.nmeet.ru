import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_models.dart';
import '../../providers/game_state_provider.dart';
import '../../services/quiz_repository.dart';
import '../../theme/app_theme.dart';

class WordGuessTab extends StatefulWidget {
  final QuizRepository repository;

  const WordGuessTab({super.key, required this.repository});

  @override
  State<WordGuessTab> createState() => _WordGuessTabState();
}

class _WordGuessTabState extends State<WordGuessTab> {
  int _currentWordIndex = 0;
  final Set<String> _guessedLetters = {};
  int _mistakes = 0;
  final int _maxMistakes = 6;
  bool _isWordSolved = false;
  bool _isWordFailed = false;

  static const List<String> _cyrillicAlphabet = [
    'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'И', 'К',
    'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф',
    'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ь', 'Э', 'Ю', 'Я',
  ];

  WordPuzzle? get _currentPuzzle {
    if (widget.repository.words.isEmpty) return null;
    return widget.repository.words[_currentWordIndex % widget.repository.words.length];
  }

  void _onLetterTapped(String letter) {
    if (_isWordSolved || _isWordFailed || _currentPuzzle == null) return;
    if (_guessedLetters.contains(letter)) return;

    setState(() {
      _guessedLetters.add(letter);
      final word = _currentPuzzle!.word;

      if (!word.contains(letter)) {
        _mistakes++;
        if (_mistakes >= _maxMistakes) {
          _isWordFailed = true;
        }
      } else {
        // Check if all letters in word are guessed
        bool allGuessed = true;
        for (int i = 0; i < word.length; i++) {
          final char = word[i];
          if (char != ' ' && char != '-' && !_guessedLetters.contains(char)) {
            allGuessed = false;
            break;
          }
        }
        if (allGuessed) {
          _isWordSolved = true;
          final gameState = context.read<GameStateProvider>();
          gameState.recordWordSolved(_currentPuzzle!.points);
        }
      }
    });
  }

  void _nextWord() {
    setState(() {
      _currentWordIndex++;
      _guessedLetters.clear();
      _mistakes = 0;
      _isWordSolved = false;
      _isWordFailed = false;
    });
  }

  void _revealHintLetter() {
    if (_isWordSolved || _isWordFailed || _currentPuzzle == null) return;
    final word = _currentPuzzle!.word;
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      if (char != ' ' && char != '-' && !_guessedLetters.contains(char)) {
        _onLetterTapped(char);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    final puzzle = _currentPuzzle;
    final challenges = widget.repository.dailyChallenges;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Футбольные Слова',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${gameState.wordsSolved} отгадано',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (puzzle == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else ...[
            // Word card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary.withAlpha(50)),
                          ),
                          child: Text(
                            puzzle.category,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, color: AppTheme.accentRose, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Ошибки: $_mistakes/$_maxMistakes',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _mistakes >= 4 ? AppTheme.accentRose : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    puzzle.hint,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Word Letters Display
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(puzzle.word.length, (idx) {
                      final char = puzzle.word[idx];
                      if (char == ' ' || char == '-') {
                        return const SizedBox(width: 14);
                      }
                      final isRevealed = _guessedLetters.contains(char) || _isWordFailed;

                      return Container(
                        width: 36,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isRevealed
                              ? (_isWordFailed
                                  ? AppTheme.accentRose.withAlpha(35)
                                  : AppTheme.secondary.withAlpha(35))
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isRevealed
                                ? (_isWordFailed ? AppTheme.accentRose : AppTheme.secondary)
                                : AppTheme.surfaceBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          isRevealed ? char : '',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isRevealed ? AppTheme.textPrimary : AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  if (_isWordSolved) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondary.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Отгадано! +${puzzle.points} очков',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (_isWordFailed) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRose.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentRose.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.accentRose),
                          const SizedBox(width: 8),
                          Text(
                            'Слово не отгадано! Слово: ${puzzle.word}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentRose,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      if (!_isWordSolved && !_isWordFailed) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.surfaceBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _revealHintLetter,
                            icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                            label: Text(
                              'Подсказка',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _nextWord,
                          icon: const Icon(Icons.skip_next_rounded, size: 18),
                          label: Text(
                            'Следующее слово',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Letter Buttons Grid
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _cyrillicAlphabet.map((letter) {
                  final isUsed = _guessedLetters.contains(letter);
                  final isInWord = puzzle.word.contains(letter);

                  Color btnColor = AppTheme.surface;
                  Color textColor = AppTheme.textPrimary;
                  if (isUsed) {
                    btnColor = isInWord
                        ? AppTheme.secondary.withAlpha(40)
                        : AppTheme.surfaceBorder.withAlpha(80);
                    textColor = isInWord ? AppTheme.secondary : AppTheme.textMuted;
                  }

                  return InkWell(
                    onTap: (isUsed || _isWordSolved || _isWordFailed)
                        ? null
                        : () => _onLetterTapped(letter),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: btnColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUsed ? Colors.transparent : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        letter,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Daily Challenges section
          Text(
            'Дейли-Челленджи',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: challenges.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final currentProgress = gameState.getChallengeProgress(challenge.id);
              final isClaimed = gameState.isChallengeClaimed(challenge.id);
              final canClaim = gameState.canClaimChallenge(challenge);
              final iconData = QuizRepository.getIconData(challenge.icon);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: canClaim
                            ? AppTheme.secondary.withAlpha(30)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: canClaim ? AppTheme.secondary : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        color: canClaim ? AppTheme.secondary : AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            challenge.description,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (currentProgress / challenge.targetCount).clamp(0.0, 1.0),
                                    minHeight: 5,
                                    backgroundColor: AppTheme.surface,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      canClaim ? AppTheme.secondary : AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$currentProgress/${challenge.targetCount}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (isClaimed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Получено',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      )
                    else if (canClaim)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: AppTheme.background,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => gameState.claimChallengeReward(challenge),
                        child: Text(
                          '+${challenge.rewardCoins}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: AppTheme.accentGold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '+${challenge.rewardCoins}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
