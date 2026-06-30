import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/tetris_models.dart';



class TetrisController extends ChangeNotifier {

  GameState _gameState = GameState.playing;
  late List<List<BoardCell>> _board;
  ActivePiece? _currentPiece;
  ActivePiece? _ghostPiece;
  ActivePiece? _heldPiece;
  bool _canHold = true;


  final List<Tetromino> _nextPieces = [];


  GameStats _stats = const GameStats();


  Timer? _dropTimer;
  Timer? _gameTimer;
  DateTime? _gameStartTime;


  LineClearAnimation? _lineClearAnimation;
  Timer? _lineClearTimer;


  final math.Random _random = math.Random();


  GameState get gameState => _gameState;
  List<List<BoardCell>> get board => _board;
  ActivePiece? get currentPiece => _currentPiece;
  ActivePiece? get ghostPiece => _ghostPiece;
  ActivePiece? get heldPiece => _heldPiece;
  bool get canHold => _canHold;
  List<Tetromino> get nextPieces => _nextPieces;
  GameStats get stats => _stats;
  LineClearAnimation? get lineClearAnimation => _lineClearAnimation;


  bool get isGameOver => _gameState == GameState.gameOver;
  bool get isPaused => _gameState == GameState.paused;
  bool get isPlaying => _gameState == GameState.playing;
  bool get isLineClearing => _gameState == GameState.lineClearing;


  void initialize() {
    _initializeBoard();
    _fillNextPieces();
    _spawnNewPiece();
    _startGameTimer();
    _startDropTimer();
    _gameStartTime = DateTime.now();
  }


  void _initializeBoard() {
    _board = List.generate(
      TetrisConstants.boardHeight + TetrisConstants.bufferHeight,
      (row) =>
          List.generate(TetrisConstants.boardWidth, (col) => const BoardCell()),
    );
  }


  void _fillNextPieces() {
    while (_nextPieces.length < TetrisConstants.previewCount + 1) {
      _nextPieces.add(Tetromino.getRandom());
    }
  }


  void _spawnNewPiece() {
    if (_nextPieces.isEmpty) {
      _fillNextPieces();
    }

    final tetromino = _nextPieces.removeAt(0);
    _fillNextPieces();

    _currentPiece = ActivePiece(
      tetromino: tetromino,
      position: TetrisConstants.spawnPosition,
    );

    _updateGhostPiece();
    _canHold = true;


    if (_isCollision(_currentPiece!)) {
      _gameState = GameState.gameOver;
      _dropTimer?.cancel();
      _gameTimer?.cancel();
    }


    _stats = _stats.copyWith(pieces: _stats.pieces + 1);
    notifyListeners();
  }


  void _updateGhostPiece() {
    if (_currentPiece == null) return;

    _ghostPiece = _currentPiece!.copyWith();


    while (!_isCollision(_ghostPiece!)) {
      _ghostPiece!.move(1, 0);
    }
    _ghostPiece!.move(-1, 0); // Move back up one step
  }


  BoardCell getBoardCell(int row, int col) {

    if (_currentPiece != null) {
      final currentPositions = _currentPiece!.getOccupiedPositions();
      for (final pos in currentPositions) {
        if (pos.row == row && pos.col == col) {
          return BoardCell(
            isOccupied: true,
            color: _currentPiece!.tetromino.color,
            gradient: _currentPiece!.tetromino.gradient,
            glowColor: _currentPiece!.tetromino.glowColor,
          );
        }
      }
    }


    if (_ghostPiece != null && _currentPiece != null) {
      final ghostPositions = _ghostPiece!.getOccupiedPositions();
      for (final pos in ghostPositions) {
        if (pos.row == row && pos.col == col) {

          final currentPositions = _currentPiece!.getOccupiedPositions();
          final isCurrentPiece = currentPositions.any(
            (cp) => cp.row == row && cp.col == col,
          );

          if (!isCurrentPiece) {
            return BoardCell(
              isOccupied: true,
              color: _ghostPiece!.tetromino.color.withOpacity(0.3),
              gradient: LinearGradient(
                colors: [
                  _ghostPiece!.tetromino.color.withOpacity(0.3),
                  _ghostPiece!.tetromino.color.withOpacity(0.1),
                ],
              ),
              glowColor: _ghostPiece!.tetromino.glowColor.withOpacity(0.3),
            );
          }
        }
      }
    }


    if (row >= 0 && row < _board.length && col >= 0 && col < _board[0].length) {
      return _board[row][col];
    }

    return const BoardCell();
  }


  bool _isCollision(ActivePiece piece) {
    final positions = piece.getOccupiedPositions();

    for (final pos in positions) {

      if (pos.row >= _board.length ||
          pos.col < 0 ||
          pos.col >= TetrisConstants.boardWidth) {
        return true;
      }


      if (pos.row >= 0 && _board[pos.row][pos.col].isOccupied) {
        return true;
      }
    }

    return false;
  }


  bool moveLeft() {
    if (_currentPiece == null || _gameState != GameState.playing) return false;

    _currentPiece!.move(0, -1);
    if (_isCollision(_currentPiece!)) {
      _currentPiece!.move(0, 1); // Revert
      return false;
    }

    _updateGhostPiece();
    HapticFeedback.lightImpact();
    notifyListeners();
    return true;
  }


  bool moveRight() {
    if (_currentPiece == null || _gameState != GameState.playing) return false;

    _currentPiece!.move(0, 1);
    if (_isCollision(_currentPiece!)) {
      _currentPiece!.move(0, -1); // Revert
      return false;
    }

    _updateGhostPiece();
    HapticFeedback.lightImpact();
    notifyListeners();
    return true;
  }


  bool moveDown() {
    if (_currentPiece == null || _gameState != GameState.playing) return false;

    _currentPiece!.move(1, 0);
    if (_isCollision(_currentPiece!)) {
      _currentPiece!.move(-1, 0); // Revert
      _lockPiece();
      return false;
    }


    _stats = _stats.copyWith(
      score: _stats.score + TetrisConstants.softDropPoints,
    );
    notifyListeners();
    return true;
  }


  void hardDrop() {
    if (_currentPiece == null || _gameState != GameState.playing) return;

    int dropDistance = 0;
    while (moveDown()) {
      dropDistance++;
    }


    final hardDropPoints = dropDistance * TetrisConstants.hardDropMultiplier;
    _stats = _stats.copyWith(score: _stats.score + hardDropPoints);

    HapticFeedback.heavyImpact();
    notifyListeners();
  }


  bool rotate() {
    if (_currentPiece == null || _gameState != GameState.playing) return false;

    final originalRotation = _currentPiece!.rotation;
    _currentPiece!.rotate();


    if (_isCollision(_currentPiece!)) {
      final kicks = _getWallKicks(
        _currentPiece!.tetromino.type,
        originalRotation,
        _currentPiece!.rotation,
      );

      bool kicked = false;
      for (final kick in kicks) {
        _currentPiece!.move(kick.row, kick.col);
        if (!_isCollision(_currentPiece!)) {
          kicked = true;
          break;
        }
        _currentPiece!.move(-kick.row, -kick.col); // Revert kick
      }

      if (!kicked) {
        _currentPiece!.rotation = originalRotation; // Revert rotation
        return false;
      }
    }

    _updateGhostPiece();
    HapticFeedback.lightImpact();
    notifyListeners();
    return true;
  }


  List<Position> _getWallKicks(
    TetrominoType type,
    int fromRotation,
    int toRotation,
  ) {

    return [
      const Position(0, -1),
      const Position(0, 1),
      const Position(-1, 0),
      const Position(1, 0),
      const Position(-1, -1),
      const Position(-1, 1),
      const Position(1, -1),
      const Position(1, 1),
    ];
  }


  void hold() {
    if (_currentPiece == null || !_canHold || _gameState != GameState.playing)
      return;

    if (_heldPiece == null) {

      _heldPiece = ActivePiece(
        tetromino: _currentPiece!.tetromino,
        position: TetrisConstants.spawnPosition,
      );
      _spawnNewPiece();
    } else {

      final currentTetromino = _currentPiece!.tetromino;
      _currentPiece = ActivePiece(
        tetromino: _heldPiece!.tetromino,
        position: TetrisConstants.spawnPosition,
      );
      _heldPiece = ActivePiece(
        tetromino: currentTetromino,
        position: TetrisConstants.spawnPosition,
      );
      _updateGhostPiece();
    }

    _canHold = false;
    HapticFeedback.lightImpact();
    notifyListeners();
  }


  void _lockPiece() {
    if (_currentPiece == null) return;

    final positions = _currentPiece!.getOccupiedPositions();
    for (final pos in positions) {
      if (pos.row >= 0 && pos.row < _board.length) {
        _board[pos.row][pos.col] = BoardCell(
          isOccupied: true,
          color: _currentPiece!.tetromino.color,
          gradient: _currentPiece!.tetromino.gradient,
          glowColor: _currentPiece!.tetromino.glowColor,
        );
      }
    }

    HapticFeedback.mediumImpact();
    _checkForCompleteLines();
    _spawnNewPiece();
  }


  void _checkForCompleteLines() {
    final completeRows = <int>[];

    for (int row = 0; row < _board.length; row++) {
      bool isComplete = true;
      for (int col = 0; col < TetrisConstants.boardWidth; col++) {
        if (!_board[row][col].isOccupied) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        completeRows.add(row);
      }
    }

    if (completeRows.isNotEmpty) {
      _startLineClearAnimation(completeRows);
    }
  }


  void _startLineClearAnimation(List<int> rows) {
    _gameState = GameState.lineClearing;
    _dropTimer?.cancel();

    _lineClearAnimation = LineClearAnimation(
      clearingRows: rows,
      progress: 0.0,
      duration: const Duration(milliseconds: 500),
    );


    _lineClearTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = timer.tick * 16;
      final progress = elapsed / _lineClearAnimation!.duration.inMilliseconds;

      if (progress >= 1.0) {
        timer.cancel();
        _completeLinesClearing();
      } else {
        _lineClearAnimation = LineClearAnimation(
          clearingRows: _lineClearAnimation!.clearingRows,
          progress: progress,
          duration: _lineClearAnimation!.duration,
        );
        notifyListeners();
      }
    });
  }


  void _completeLinesClearing() {
    if (_lineClearAnimation == null) return;

    final clearedRows = _lineClearAnimation!.clearingRows;
    final linesCleared = clearedRows.length;


    clearedRows.sort((a, b) => b.compareTo(a)); // Sort descending
    for (final row in clearedRows) {
      _board.removeAt(row);

      _board.insert(
        0,
        List.generate(TetrisConstants.boardWidth, (col) => const BoardCell()),
      );
    }


    final lineScore = _stats.getLineScore(linesCleared);
    final newLines = _stats.lines + linesCleared;
    final newLevel = (newLines ~/ TetrisConstants.linesPerLevel) + 1;

    _stats = _stats.copyWith(
      score: _stats.score + lineScore,
      lines: newLines,
      level: newLevel,
    );


    if (linesCleared == 4) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }


    if (newLevel != _stats.level) {
      _updateDropTimer();
    }

    _lineClearAnimation = null;
    _gameState = GameState.playing;
    _startDropTimer();
    notifyListeners();
  }


  void togglePause() {
    if (_gameState == GameState.gameOver) return;

    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      _dropTimer?.cancel();
    } else if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      _startDropTimer();
    }

    notifyListeners();
  }


  void newGame() {

    _dropTimer?.cancel();
    _gameTimer?.cancel();
    _lineClearTimer?.cancel();


    _gameState = GameState.playing;
    _currentPiece = null;
    _ghostPiece = null;
    _heldPiece = null;
    _canHold = true;
    _nextPieces.clear();
    _stats = const GameStats();
    _lineClearAnimation = null;


    initialize();
    notifyListeners();
  }


  void _startDropTimer() {
    _dropTimer?.cancel();
    final dropSpeed = _stats.getDropSpeed();

    _dropTimer = Timer.periodic(dropSpeed, (timer) {
      if (_gameState == GameState.playing) {
        moveDown();
      }
    });
  }


  void _updateDropTimer() {
    if (_gameState == GameState.playing) {
      _startDropTimer();
    }
  }


  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState == GameState.playing) {
        final elapsed = DateTime.now().difference(_gameStartTime!);
        _stats = _stats.copyWith(gameTime: elapsed);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _dropTimer?.cancel();
    _gameTimer?.cancel();
    _lineClearTimer?.cancel();
    super.dispose();
  }
}
