import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_models.dart';
import '../../providers/game_state_provider.dart';
import '../../services/quiz_repository.dart';
import '../../theme/app_theme.dart';

class LoyaltyStoreTab extends StatefulWidget {
  final QuizRepository repository;

  const LoyaltyStoreTab({super.key, required this.repository});

  @override
  State<LoyaltyStoreTab> createState() => _LoyaltyStoreTabState();
}

class _LoyaltyStoreTabState extends State<LoyaltyStoreTab> {
  String _selectedCategory = 'Все';

  static const List<String> _filterCategories = [
    'Все',
    'Бустеры',
    'Трофеи',
    'Бейджи',
    'Статус',
    'Мерч',
  ];

  void _onPurchase(LoyaltyReward reward) {
    final gameState = context.read<GameStateProvider>();
    if (gameState.coins < reward.cost) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.surfaceBorder),
          ),
          title: Text(
            'Недостаточно монет',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Для покупки «${reward.title}» необходимо ${reward.cost} монет. Сыграйте в викторины или отгадайте слова!',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.background,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }

    final success = gameState.purchaseReward(reward);
    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.secondary),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Награда получена!',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Вы приобрели «${reward.title}» за ${reward.cost} монет.',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                '+100 XP к опыту болельщика!',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: AppTheme.background,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отлично!'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    final items = widget.repository.loyaltyStore;

    final filteredItems = _selectedCategory == 'Все'
        ? items
        : items.where((i) => i.category == _selectedCategory).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loyalty Balance Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceCard,
                  AppTheme.surfaceCard.withAlpha(220),
                  AppTheme.accentGold.withAlpha(30),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentGold.withAlpha(60)),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: AppTheme.accentGold,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Баланс Лояльности',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${gameState.coins}',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentGold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'монет',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Обменивай монеты на бустеры и клубные трофеи',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _filterCategories.map((cat) {
                final isSelected = (cat == _selectedCategory);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceCard,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.background : AppTheme.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Items list
          if (filteredItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'В этой категории пока нет товаров',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isPurchased = gameState.purchasedRewardIds.contains(item.id);
                final isBooster = item.category == 'Бустеры';
                final canAfford = gameState.coins >= item.cost;
                final iconData = QuizRepository.getIconData(item.icon);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPurchased
                          ? AppTheme.secondary.withAlpha(80)
                          : AppTheme.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isPurchased
                              ? AppTheme.secondary.withAlpha(25)
                              : AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPurchased
                                ? AppTheme.secondary.withAlpha(60)
                                : AppTheme.primary.withAlpha(50),
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: isPurchased ? AppTheme.secondary : AppTheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      color: AppTheme.accentGold,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.cost} монет',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentGold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isPurchased && !isBooster)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppTheme.secondary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'В коллекции',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canAfford ? AppTheme.primary : AppTheme.surface,
                                      foregroundColor: canAfford ? AppTheme.background : AppTheme.textMuted,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: canAfford ? Colors.transparent : AppTheme.surfaceBorder,
                                        ),
                                      ),
                                    ),
                                    onPressed: () => _onPurchase(item),
                                    child: Text(
                                      isBooster ? 'Купить еще' : 'Купить',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
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
