import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_/main.dart';
import 'package:app_/models/quiz_models.dart';
import 'package:app_/providers/game_state_provider.dart';
import 'package:app_/screens/main_navigation_screen.dart';
import 'package:app_/screens/quiz_play_screen.dart';
import 'package:app_/services/quiz_repository.dart';
import 'package:app_/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  QuizRepository createMockRepository() {
    final repo = QuizRepository();
    repo.categories = [
      QuizCategory(
        id: 'rpl_history',
        title: 'История и Чемпионы РПЛ',
        description: 'Золотые сезоны и рекорды',
        icon: 'emoji_events',
        color: const Color(0xFFF8FF13),
        questions: [
          QuizQuestion(
            id: 1,
            question: 'Какой клуб завоевал больше всего титулов?',
            options: ['Спартак', 'ЦСКА', 'Зенит', 'Локомотив'],
            correctIndex: 0,
            explanation: 'Спартак 10 раз побеждал.',
            points: 100,
          ),
        ],
      ),
    ];
    repo.words = [
      WordPuzzle(
        word: 'ПЕНАЛЬТИ',
        hint: 'Одиннадцатиметровый удар',
        category: 'Правила',
        difficulty: 'Легкий',
        points: 100,
      ),
    ];
    repo.dailyChallenges = [
      DailyChallenge(
        id: 'daily_1',
        title: 'Матчевый марафон',
        description: 'Пройдите 2 квиза',
        targetCount: 2,
        rewardCoins: 250,
        icon: 'sports_soccer',
      ),
    ];
    repo.loyaltyStore = [
      LoyaltyReward(
        id: 'reward_trophy_cup',
        title: 'Кубок Эксперта',
        cost: 100,
        icon: 'emoji_events',
        description: 'Почетный трофей',
        category: 'Трофеи',
      ),
    ];
    repo.fanLevels = [
      FanLevel(
        level: 1,
        name: 'Новичок Трибун',
        minXp: 0,
        color: const Color(0xFFF8FF13),
      ),
    ];
    repo.isLoaded = true;
    return repo;
  }

  Widget createTestWidget({required Widget child}) {
    final provider = GameStateProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameStateProvider>.value(value: provider),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('Navigation & 4 Tabs Verification', () {
    testWidgets('BottomNavigationBar has exactly 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: MainNavigationScreen(repository: createMockRepository()),
        ),
      );
      await tester.pumpAndSettle();

      final bottomNavBarFinder = find.byType(BottomNavigationBar);
      expect(bottomNavBarFinder, findsOneWidget);

      final BottomNavigationBar bottomNavBar = tester.widget(bottomNavBarFinder);
      expect(bottomNavBar.items.length, 4);

      expect(find.text('Квизы'), findsOneWidget);
      expect(find.text('Слова'), findsOneWidget);
      expect(find.text('Награды'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('Can switch between all 4 tabs smoothly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: MainNavigationScreen(repository: createMockRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 1: Квизы
      expect(find.text('Категории викторин'), findsOneWidget);

      // Tap Tab 2: Слова
      await tester.tap(find.text('Слова'));
      await tester.pumpAndSettle();
      expect(find.text('Футбольные Слова'), findsOneWidget);

      // Tap Tab 3: Награды
      await tester.tap(find.text('Награды'));
      await tester.pumpAndSettle();
      expect(find.text('Баланс Лояльности'), findsOneWidget);

      // Tap Tab 4: Профиль
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();
      expect(find.text('Статистика болельщика'), findsOneWidget);
    });
  });

  group('RenderFlex Overflow Checks Across Screen Sizes', () {
    final List<Size> testSizes = [
      const Size(320, 480),   // Compact / Small Phone
      const Size(390, 844),   // Standard Phone
      const Size(412, 915),   // Large Phone
      const Size(800, 1280),  // Tablet
    ];

    for (final size in testSizes) {
      testWidgets('No RenderFlex overflow on ${size.width.toInt()}x${size.height.toInt()} across all tabs', (WidgetTester tester) async {
        final List<FlutterErrorDetails> errors = [];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.exceptionAsString().contains('RenderFlex overflowed') ||
              details.exceptionAsString().contains('A RenderFlex overflowed')) {
            errors.add(details);
          }
          originalOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = originalOnError;
        });

        await tester.pumpWidget(
          createTestWidget(
            child: MainNavigationScreen(repository: createMockRepository()),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to all 4 tabs and check for overflow
        final tabs = ['Квизы', 'Слова', 'Награды', 'Профиль'];
        for (int i = 0; i < tabs.length; i++) {
          await tester.tap(find.text(tabs[i]));
          await tester.pumpAndSettle();

          final scrollables = find.byType(SingleChildScrollView);
          if (scrollables.evaluate().length > i) {
            await tester.drag(scrollables.at(i), const Offset(0, -60));
            await tester.pumpAndSettle();
          }
        }

        expect(errors, isEmpty, reason: 'RenderFlex overflow detected on size $size');
      });
    }

    testWidgets('QuizPlayScreen has no RenderFlex overflow on small screen', (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          errors.add(details);
        }
        originalOnError?.call(details);
      };

      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });

      final testCategory = QuizCategory(
        id: 'test_cat',
        title: 'Тестовая категория РПЛ',
        description: 'Описание категории с текстом',
        icon: 'sports_soccer',
        color: const Color(0xFFF8FF13),
        questions: [
          QuizQuestion(
            id: 1,
            question: 'Какой футбольный клуб стал победителем чемпионата России?',
            options: ['Спартак', 'Зенит', 'ЦСКА', 'Локомотив'],
            correctIndex: 0,
            explanation: '«Спартак» завоевал 10 чемпионских титулов в высшей лиге.',
            points: 100,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(child: QuizPlayScreen(category: testCategory)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Спартак'));
      await tester.tap(find.text('Спартак'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Завершить викторину'));
      expect(find.text('Завершить викторину'), findsOneWidget);
      expect(errors, isEmpty, reason: 'RenderFlex overflow in QuizPlayScreen');
    });
  });

  group('MainApp smoke test', () {
    testWidgets('MainApp builds successfully with MaterialApp', (WidgetTester tester) async {
      final provider = GameStateProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameStateProvider>.value(value: provider),
          ],
          child: const MainApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
