import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quiz_models.dart';
import '../providers/game_state_provider.dart';
import '../theme/app_theme.dart';

class QuizPlayScreen extends StatefulWidget {
  final QuizCategory category;

  const QuizPlayScreen({super.key, required this.category});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswerSubmitted = false;
  int _correctCount = 0;
  int _earnedCoins = 0;
  int _earnedXp = 0;

  // Active boosters for current question
  final Set<int> _hiddenOptions = {};
  bool _isImmunityActive = false;

  QuizQuestion get _currentQuestion => widget.category.questions[_currentIndex];

  void _onOptionSelected(int index) {
    if (_isAnswerSubmitted) return;

    setState(() {
      _selectedOptionIndex = index;
      _isAnswerSubmitted = true;
    });

    final isCorrect = (index == _currentQuestion.correctIndex);
    final gameState = context.read<GameStateProvider>();

    if (isCorrect) {
      _correctCount++;
      _earnedCoins += _currentQuestion.points;
      _earnedXp += (_currentQuestion.points ~/ 2);
      gameState.recordAnswer(true, _currentQuestion.points);
    } else {
      if (_isImmunityActive) {
        // Saved by immunity booster!
        _isImmunityActive = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentPurple,
            content: Text(
              'Иммунитет спас вашу серию ответов!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        gameState.recordAnswer(false, 0);
      }
    }
  }

  void _useFiftyFifty() {
    if (_isAnswerSubmitted) return;
    final gameState = context.read<GameStateProvider>();
    if (_hiddenOptions.isNotEmpty) return; // already used on this question

    if (gameState.boosterFiftyCount > 0) {
      final success = gameState.useFiftyFifty();
      if (success) {
        setState(() {
          final correctIdx = _currentQuestion.correctIndex;
          final wrongIndices = <int>[];
          for (int i = 0; i < _currentQuestion.options.length; i++) {
            if (i != correctIdx) wrongIndices.add(i);
          }
          wrongIndices.shuffle();
          // Hide up to 2 wrong options
          _hiddenOptions.addAll(wrongIndices.take(2));
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentRose,
          content: Text(
            'Бустер 50/50 закончился. Приобретите в Магазине Наград!',
            style: GoogleFonts.inter(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _useImmunity() {
    if (_isAnswerSubmitted || _isImmunityActive) return;
    final gameState = context.read<GameStateProvider>();
    if (gameState.boosterSkipCount > 0) {
      final success = gameState.useSkip();
      if (success) {
        setState(() {
          _isImmunityActive = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.secondary,
            content: Text(
              'Иммунитет активирован на этот вопрос!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentRose,
          content: Text(
            'Иммунитет закончился. Приобретите в Магазине Наград!',
            style: GoogleFonts.inter(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _nextQuestion() {
    if (_currentIndex < widget.category.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswerSubmitted = false;
        _hiddenOptions.clear();
        _isImmunityActive = false;
      });
    } else {
      // Quiz finished
      final gameState = context.read<GameStateProvider>();
      gameState.recordQuizFinished(
        total: widget.category.questions.length,
        correct: _correctCount,
        earnedCoins: _earnedCoins,
        earnedXp: _earnedXp,
      );
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final total = widget.category.questions.length;
    final percent = total > 0 ? ((_correctCount / total) * 100).round() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.surfaceBorder),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppTheme.accentGold,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  percent >= 80
                      ? 'Великолепно!'
                      : percent >= 50
                          ? 'Хорошая игра!'
                          : 'Тренируйся еще!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Квиз: ${widget.category.title}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        _buildResultRow(
                          'Результат',
                          '$_correctCount из $total ($percent%)',
                          AppTheme.primary,
                        ),
                        const Divider(color: AppTheme.surfaceBorder, height: 16),
                        _buildResultRow(
                          'Монеты лояльности',
                          '+$_earnedCoins',
                          AppTheme.accentGold,
                        ),
                        const Divider(color: AppTheme.surfaceBorder, height: 16),
                        _buildResultRow(
                          'Опыт болельщика',
                          '+$_earnedXp XP',
                          AppTheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'В меню',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _currentIndex = 0;
                    _selectedOptionIndex = null;
                    _isAnswerSubmitted = false;
                    _correctCount = 0;
                    _earnedCoins = 0;
                    _earnedXp = 0;
                    _hiddenOptions.clear();
                    _isImmunityActive = false;
                  });
                },
                child: Text(
                  'Сыграть снова',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultRow(String title, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    final total = widget.category.questions.length;
    final progress = (total > 0) ? (_currentIndex + 1) / total : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.category.title,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Текущие очки в игре'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.accentGold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_earnedCoins',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar and question counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Вопрос ${_currentIndex + 1} из $total',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${_currentQuestion.points} очков',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceCard,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),

              const SizedBox(height: 16),

              // Boosters row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: (_isAnswerSubmitted || _hiddenOptions.isNotEmpty)
                          ? null
                          : _useFiftyFifty,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hiddenOptions.isNotEmpty
                                ? AppTheme.textMuted
                                : AppTheme.primary.withAlpha(120),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.filter_2_rounded, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '50/50 (${gameState.boosterFiftyCount})',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: (_isAnswerSubmitted || _isImmunityActive)
                          ? null
                          : _useImmunity,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isImmunityActive
                                ? AppTheme.secondary
                                : AppTheme.accentPurple.withAlpha(120),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isImmunityActive
                                  ? Icons.verified_user_rounded
                                  : Icons.shield_outlined,
                              size: 16,
                              color: _isImmunityActive
                                  ? AppTheme.secondary
                                  : AppTheme.accentPurple,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _isImmunityActive
                                    ? 'Активен'
                                    : 'Иммунитет (${gameState.boosterSkipCount})',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _isImmunityActive
                                      ? AppTheme.secondary
                                      : AppTheme.accentPurple,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Text(
                  _currentQuestion.question,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Options list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentQuestion.options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, optIdx) {
                  final optionText = _currentQuestion.options[optIdx];
                  final isHidden = _hiddenOptions.contains(optIdx);

                  if (isHidden) {
                    return const SizedBox.shrink();
                  }

                  Color tileColor = AppTheme.surfaceCard;
                  Color borderColor = AppTheme.surfaceBorder;
                  Color textColor = AppTheme.textPrimary;
                  IconData? statusIcon;

                  if (_isAnswerSubmitted) {
                    if (optIdx == _currentQuestion.correctIndex) {
                      tileColor = AppTheme.secondary.withAlpha(40);
                      borderColor = AppTheme.secondary;
                      textColor = AppTheme.secondary;
                      statusIcon = Icons.check_circle_rounded;
                    } else if (optIdx == _selectedOptionIndex) {
                      tileColor = AppTheme.accentRose.withAlpha(40);
                      borderColor = AppTheme.accentRose;
                      textColor = AppTheme.accentRose;
                      statusIcon = Icons.cancel_rounded;
                    } else {
                      tileColor = AppTheme.surface.withAlpha(120);
                      textColor = AppTheme.textMuted;
                    }
                  }

                  return InkWell(
                    onTap: _isAnswerSubmitted ? null : () => _onOptionSelected(optIdx),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              String.fromCharCode(65 + optIdx), // A, B, C, D
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              optionText,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (statusIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(statusIcon, color: borderColor, size: 20),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Explanation note when answered
              if (_isAnswerSubmitted) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_selectedOptionIndex == _currentQuestion.correctIndex)
                          ? AppTheme.secondary.withAlpha(80)
                          : AppTheme.accentGold.withAlpha(80),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.accentGold,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _currentQuestion.explanation,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _nextQuestion,
                    child: Text(
                      _currentIndex < total - 1
                          ? 'Следующий вопрос'
                          : 'Завершить викторину',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
