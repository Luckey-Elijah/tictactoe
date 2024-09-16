import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mix/mix.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameCubit(),
      child: const MaterialApp(home: Material(child: TicTacToe())),
    );
  }
}

class TicTacToe extends StatelessWidget {
  const TicTacToe({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameCubit>().state;
    return Center(
      child: Column(
        children: [
          Flexible(
            child: SizedBox(
              width: 800,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: state.values.length,
                itemBuilder: (context, index) {
                  final val = state.values[index];
                  final canPress = state.winner == null && val == null;
                  final hover = canPress
                      ? $on.hover($box.color.lightBlue.lighten(30))
                      : null;
                  final winningSquare =
                      state.winner?.winningRow.any((w) => w == index) ?? false;
                  final color = winningSquare ? $box.color.green() : null;
                  return PressableBox(
                    style: Style(
                      $box.alignment.center(),
                      $box.border.all(),
                      $box.margin.all(4),
                      $box.borderRadius(4),
                      hover,
                      color,
                    ),
                    onPress: canPress
                        ? () => context.read<GameCubit>().turn(index)
                        : null,
                    child: switch (val) {
                      Turn.x => StyledIcon(Icons.close),
                      Turn.o => StyledIcon(Icons.circle),
                      _ => SizedBox.shrink(),
                    },
                  );
                },
              ),
            ),
          ),
          WinnerBox(),
        ],
      ),
    );
  }
}

class WinnerBox extends StatelessWidget {
  const WinnerBox({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final winner = context.select(
      (GameCubit bloc) => bloc.state.winner?.winner.name.toUpperCase(),
    );
    return Center(
      child: Visibility(
        visible: winner != null,
        child: PressableBox(
          onPress: context.read<GameCubit>().reset,
          style: Style(
            $box.border.all(),
            $box.padding.all(8),
            $box.margin.all(8),
            $box.borderRadius.all(8),
            $box.color.lightBlue(),
            $text.style.fontWeight.bold(),
            $text.style.fontSize(40),
            $on.hover($box.color.lightBlue.lighten(10)),
          ),
          child: StyledText(
            '$winner wins!',
          ),
        ),
      ),
    );
  }
}

class GameCubit extends Cubit<GameState> {
  GameCubit()
      : super(
          GameState(
            currentTurn: Turn.x,
            values: List.generate(9, (_) => null),
            winner: null,
          ),
        );

  void reset() {
    emit(
      GameState(
        currentTurn: Turn.x,
        values: List.generate(9, (_) => null),
        winner: null,
      ),
    );
  }

  void turn(int index) {
    state.values[index] = state.currentTurn;
    emit(
      state.copyWith(
        currentTurn: state.currentTurn.next(),
        values: [...state.values],
      ),
    );

    emit(state.copyWith(winner: () => findWinner(state.values)));
  }
}

Winner? findWinner(List<Turn?> boardState) {
  assert(
    boardState.length == 9,
    'Invalid length. needs to be [9] is currently [${boardState.length}]',
  );

  const indexesGroups = <List<int>>[
    [0, 1, 2], // horizontals
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6], // verticals
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8], // diagonals
    [2, 4, 6],
  ];

  for (final indexes in indexesGroups) {
    final [a, b, c] = indexes;
    final turnA = boardState[a];
    final turnB = boardState[b];
    final turnC = boardState[c];
    if (turnA != null && turnA == turnB && turnB == turnC) {
      return Winner(winner: turnA, winningRow: indexes);
    }
  }

  return null;
}

enum Turn {
  x,
  o;

  Turn next() => this == Turn.x ? Turn.o : Turn.x;
}

class GameState {
  GameState({
    required this.values,
    required this.currentTurn,
    required this.winner,
  });

  final List<Turn?> values;
  final Turn currentTurn;
  final Winner? winner;

  GameState copyWith({
    List<Turn?>? values,
    Turn? currentTurn,
    ValueGetter<Winner?>? winner,
  }) =>
      GameState(
        values: values ?? this.values,
        currentTurn: currentTurn ?? this.currentTurn,
        winner: winner != null ? winner() : this.winner,
      );
}

class Winner {
  const Winner({required this.winner, required this.winningRow});

  final Turn winner;
  final List<int> winningRow;
}
