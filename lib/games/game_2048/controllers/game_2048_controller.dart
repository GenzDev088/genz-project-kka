import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/game_models.dart';
import '../../../core/constants/app_constants.dart';


class Game2048Controller extends ChangeNotifier {
  Game2048State _state;
  final Random _random = Random();

  Game2048Controller({Game2048State? initialState})
    : _state = initialState ?? Game2048State.initial();


  Game2048State get state => _state;


  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final bestScore = prefs.getInt(GameConstants.game2048BestScoreKey) ?? 0;

    _state = Game2048State.initial(bestScore: bestScore);
    notifyListeners();
  }


  Future<void> newGame() async {
    final prefs = await SharedPreferences.getInstance();
    final bestScore = prefs.getInt(GameConstants.game2048BestScoreKey) ?? 0;

    _state = Game2048State.initial(bestScore: bestScore);
    notifyListeners();
  }


  Future<void> move(Direction direction) async {
    if (_state.gameOver || _state.won) return;

    final moveResult = _performMove(direction);

    if (!moveResult.moved) return;

    var newState = _state.copyWith(
      tiles: moveResult.tiles,
      score: _state.score + moveResult.score,
      moves: _state.moves + 1,
      gameOver: moveResult.gameOver,
      won: moveResult.won,
    );


    newState = newState.saveToHistory();


    if (!newState.gameOver && !newState.won) {
      newState = _addNewTile(newState);


      if (!newState.canMove) {
        newState = newState.copyWith(gameOver: true);
      }
    }


    if (newState.score > newState.bestScore) {
      newState = newState.copyWith(bestScore: newState.score);
      await _saveBestScore(newState.bestScore);
    }

    _state = newState;
    notifyListeners();
  }


  MoveResult _performMove(Direction direction) {
    final tiles = List<Tile>.from(_state.tiles);
    final movedTiles = <Tile>[];
    int scoreGained = 0;
    bool moved = false;




    final traversals = _buildTraversals(direction);


    for (final tile in tiles) {
      tile.copyWith(wasMerged: false);
    }


    for (final row in traversals.rows) {
      for (final col in traversals.cols) {
        final position = Position(row, col);
        final tile = _getTileAt(tiles, position);

        if (tile != null) {
          final positions = _findFarthestPosition(tiles, position, direction);
          final next = _getTileAt(tiles, positions.next);


          if (next != null && tile.canMergeWith(next) && !next.wasMerged) {

            final mergedTile = next.merge(tile);
            movedTiles.add(mergedTile);
            tiles.remove(tile);
            tiles.remove(next);
            scoreGained += mergedTile.value;
            moved = true;
          } else {

            final movedTile = tile.moveTo(positions.farthest);
            movedTiles.add(movedTile);
            tiles.remove(tile);

            if (movedTile.position != tile.position) {
              moved = true;
            }
          }
        }
      }
    }


    tiles.addAll(movedTiles);


    final won = tiles.any(
      (tile) => tile.value >= GameConstants.game2048WinValue,
    );


    final gameOver = !_canMove(tiles);

    return MoveResult(
      tiles: tiles,
      score: scoreGained,
      moved: moved,
      gameOver: gameOver,
      won: won && !_state.won, // Only trigger win once
    );
  }


  ({List<int> rows, List<int> cols}) _buildTraversals(Direction direction) {
    final rows = List.generate(4, (i) => i);
    final cols = List.generate(4, (i) => i);


    switch (direction) {
      case Direction.down:
        rows.sort((a, b) => b.compareTo(a));
        break;
      case Direction.right:
        cols.sort((a, b) => b.compareTo(a));
        break;
      case Direction.up:
      case Direction.left:

        break;
    }

    return (rows: rows, cols: cols);
  }


  ({Position farthest, Position next}) _findFarthestPosition(
    List<Tile> tiles,
    Position position,
    Direction direction,
  ) {
    Position previous = position;
    Position current = position.move(direction);

    while (current.isValid && _getTileAt(tiles, current) == null) {
      previous = current;
      current = current.move(direction);
    }

    return (farthest: previous, next: current);
  }


  Tile? _getTileAt(List<Tile> tiles, Position position) {
    try {
      return tiles.firstWhere((tile) => tile.position == position);
    } catch (e) {
      return null;
    }
  }


  bool _canMove(List<Tile> tiles) {

    if (tiles.length < 16) return true;


    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        final position = Position(row, col);
        final tile = _getTileAt(tiles, position);

        if (tile != null) {

          for (final direction in Direction.values) {
            final adjacentPos = position.move(direction);
            if (adjacentPos.isValid) {
              final adjacentTile = _getTileAt(tiles, adjacentPos);
              if (adjacentTile != null && tile.canMergeWith(adjacentTile)) {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }


  Game2048State _addNewTile(Game2048State state) {
    final emptyPositions = state.emptyPositions;

    if (emptyPositions.isEmpty) {
      return state;
    }


    final randomIndex = _random.nextInt(emptyPositions.length);
    final position = emptyPositions[randomIndex];


    final newTile = Tile.random(position);


    final newTiles = List<Tile>.from(state.tiles);
    newTiles.add(newTile);

    return state.copyWith(tiles: newTiles);
  }


  void undo() {
    if (_state.canUndo) {
      _state = _state.undo();
      notifyListeners();
    }
  }


  void continueGame() {
    if (_state.won) {
      _state = _state.copyWith(won: false);
      notifyListeners();
    }
  }


  Future<void> _saveBestScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(GameConstants.game2048BestScoreKey, score);
  }


  Offset getTileOffset(Position position, double gridSize, double tileSize) {
    const spacing = GameConstants.game2048GridSpacing;
    final x = position.col * (tileSize + spacing) + spacing;
    final y = position.row * (tileSize + spacing) + spacing;
    return Offset(x, y);
  }


  Tile? getTileAtPosition(Position position) {
    return _state.getTileAt(position);
  }


  List<Tile> get tiles => _state.tiles;


  int get score => _state.score;


  int get bestScore => _state.bestScore;


  bool get isGameOver => _state.gameOver;


  bool get isWon => _state.won;


  bool get canUndo => _state.canUndo;


  int get moves => _state.moves;


  int get highestTileValue => _state.highestTileValue;


  String get statusMessage => _state.statusMessage;
}
