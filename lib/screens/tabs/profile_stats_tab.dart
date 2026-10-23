import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_state_provider.dart';
import '../../services/quiz_repository.dart';
import '../../theme/app_theme.dart';

class ProfileStatsTab extends StatelessWidget {
  final QuizRepository repository;

  const ProfileStatsTab({super.key, required this.repository});

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        title: Text(
          'Сбросить прогресс?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Все заработанные очки, разблокированные трофеи и статистика будут сброшены до начальных настроек.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Отмена',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRose,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<GameStateProvider>().resetProgress();
              Navigator.of(ctx).pop();
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    final fanLevels = repository.fanLevels;
    final currentLevel = gameState.getCurrentFanLevel(fanLevels);
    final nextLevel = gameState.getNextFanLevel(fanLevels);
    final progressToNext = gameState.getLevelProgress(fanLevels);
    final purchasedItems = repository.loyaltyStore
        .where((item) => gameState.purchasedRewardIds.contains(item.id))
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fan Profile & Rank Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceCard,
                  AppTheme.surfaceCard.withAlpha(220),
                  currentLevel.color.withAlpha(35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: currentLevel.color.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(color: currentLevel.color, width: 2),
                      ),
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        color: currentLevel.color,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: currentLevel.color.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Уровень ${currentLevel.level}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: currentLevel.color,
                                  ),
                                ),
                              ),
                              Text(
                                '${gameState.xp} XP',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentLevel.name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextLevel != null
                                ? 'До «${nextLevel.name}»: ${nextLevel.minXp - gameState.xp} XP'
                                : 'Максимальный ранг достигнут!',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressToNext,
                    minHeight: 8,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(currentLevel.color),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Statistics Grid
          Text(
            'Статистика болельщика',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildStatCard(
                title: 'Сыграно квизов',
                value: '${gameState.quizzesCompleted}',
                icon: Icons.emoji_events_rounded,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'Отгадано слов',
                value: '${gameState.wordsSolved}',
                icon: Icons.spellcheck_rounded,
                color: AppTheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                title: 'Точность ответов',
                value: '${gameState.accuracyPercentage}%',
                icon: Icons.track_changes_rounded,
                color: AppTheme.accentPurple,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'Лучшая серия',
                value: '${gameState.bestStreak}',
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.accentGold,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Boosters in Inventory
          Text(
            'Инвентарь бустеров',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInventoryPill(
                  icon: Icons.filter_2_rounded,
                  label: '50/50',
                  count: '${gameState.boosterFiftyCount}',
                  color: AppTheme.primary,
                ),
                _buildInventoryPill(
                  icon: Icons.verified_user_rounded,
                  label: 'Иммунитет',
                  count: '${gameState.boosterSkipCount}',
                  color: AppTheme.secondary,
                ),
                _buildInventoryPill(
                  icon: Icons.trending_up_rounded,
                  label: 'Удвоитель',
                  count: gameState.boosterDoubleActive ? 'АКТИВЕН' : '0',
                  color: AppTheme.accentGold,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Trophy Cabinet
          Text(
            'Коллекция наград (${purchasedItems.length})',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (purchasedItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.military_tech_outlined,
                    color: AppTheme.textMuted,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Пока нет купленных трофеев',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Загляните в раздел «Награды», чтобы пополнить витрину!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: purchasedItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = purchasedItems[idx];
                final iconData = QuizRepository.getIconData(item.icon);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(iconData, color: AppTheme.secondary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              item.description,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.secondary,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Reset Progress Button
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentRose,
                side: BorderSide(color: AppTheme.accentRose.withAlpha(100)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => _showResetDialog(context),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Сбросить прогресс',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryPill({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
