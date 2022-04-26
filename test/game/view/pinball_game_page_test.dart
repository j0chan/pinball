// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinball/game/game.dart';
import 'package:pinball/select_character/select_character.dart';

import '../../helpers/helpers.dart';

void main() {
  final game = PinballTestGame();

  group('PinballGamePage', () {
    late CharacterThemeCubit characterThemeCubit;
    late GameBloc gameBloc;

    setUp(() async {
      await Future.wait<void>(game.preLoadAssets());
      characterThemeCubit = MockCharacterThemeCubit();
      gameBloc = MockGameBloc();

      whenListen(
        characterThemeCubit,
        const Stream<CharacterThemeState>.empty(),
        initialState: const CharacterThemeState.initial(),
      );

      whenListen(
        gameBloc,
        Stream.value(const GameState.initial()),
        initialState: const GameState.initial(),
      );
    });

    testWidgets('renders PinballGameView', (tester) async {
      await tester.pumpApp(
        PinballGamePage(),
        characterThemeCubit: characterThemeCubit,
      );

      expect(find.byType(PinballGameView), findsOneWidget);
    });

    testWidgets(
      'renders the loading indicator while the assets load',
      (tester) async {
        final assetsManagerCubit = MockAssetsManagerCubit();
        final initialAssetsState = AssetsManagerState(
          loadables: [Future<void>.value()],
          loaded: const [],
        );
        whenListen(
          assetsManagerCubit,
          Stream.value(initialAssetsState),
          initialState: initialAssetsState,
        );

        await tester.pumpApp(
          PinballGameView(
            game: game,
          ),
          assetsManagerCubit: assetsManagerCubit,
          characterThemeCubit: characterThemeCubit,
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is LinearProgressIndicator && widget.value == 0.0,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
        'renders PinballGameLoadedView after resources have been loaded',
        (tester) async {
      final assetsManagerCubit = MockAssetsManagerCubit();

      final loadedAssetsState = AssetsManagerState(
        loadables: [Future<void>.value()],
        loaded: [Future<void>.value()],
      );
      whenListen(
        assetsManagerCubit,
        Stream.value(loadedAssetsState),
        initialState: loadedAssetsState,
      );

      await tester.pumpApp(
        PinballGameView(
          game: game,
        ),
        assetsManagerCubit: assetsManagerCubit,
        characterThemeCubit: characterThemeCubit,
        gameBloc: gameBloc,
      );

      await tester.pump();

      expect(find.byType(PinballGameLoadedView), findsOneWidget);
    });

    group('route', () {
      Future<void> pumpRoute({
        required WidgetTester tester,
        required bool isDebugMode,
      }) async {
        await tester.pumpApp(
          Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      PinballGamePage.route(
                        isDebugMode: isDebugMode,
                      ),
                    );
                  },
                  child: const Text('Tap me'),
                );
              },
            ),
          ),
          characterThemeCubit: characterThemeCubit,
        );

        await tester.tap(find.text('Tap me'));

        // We can't use pumpAndSettle here because the page renders a Flame game
        // which is an infinity animation, so it will timeout
        await tester.pump(); // Runs the button action
        await tester.pump(); // Runs the navigation
      }

      testWidgets('route creates the correct non debug game', (tester) async {
        await pumpRoute(tester: tester, isDebugMode: false);
        expect(
          find.byWidgetPredicate(
            (w) => w is PinballGameView && w.game is! DebugPinballGame,
          ),
          findsOneWidget,
        );
      });

      testWidgets('route creates the correct debug game', (tester) async {
        await pumpRoute(tester: tester, isDebugMode: true);
        expect(
          find.byWidgetPredicate(
            (w) => w is PinballGameView && w.game is DebugPinballGame,
          ),
          findsOneWidget,
        );
      });
    });
  });

  group('PinballGameView', () {
    setUp(() async {
      await Future.wait<void>(game.preLoadAssets());
    });

    testWidgets('renders game and a hud', (tester) async {
      final gameBloc = MockGameBloc();
      whenListen(
        gameBloc,
        Stream.value(const GameState.initial()),
        initialState: const GameState.initial(),
      );

      await tester.pumpApp(
        PinballGameView(game: game),
        gameBloc: gameBloc,
      );

      expect(
        find.byWidgetPredicate((w) => w is GameWidget<PinballGame>),
        findsOneWidget,
      );
      expect(
        find.byType(GameHud),
        findsOneWidget,
      );
    });
  });
}
