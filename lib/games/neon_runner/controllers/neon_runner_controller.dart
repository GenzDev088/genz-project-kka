import 'dart:math' as math;
import '../models/neon_runner_models.dart';

class NeonRunnerController {
  static const double gravity = 1200.0; // Increased for snappier feel
  static const double jumpVelocity = -500.0; // Increased for higher jumps
  static const double minObstacleDistance = 250.0; // Increased for fair spacing
  static const double maxObstacleDistance = 450.0; // Increased for fair spacing
  static const double speedIncrement = 20.0; // Increased for faster progression
  static const int scoreIncrement = 1;
  static const int speedIncrementInterval =
      50; // Reduced for faster progression

  final math.Random _random = math.Random();
  int _frameCount = 0;


  NeonRunnerState updateGame(NeonRunnerState state, double deltaTime) {
    if (!state.isPlaying) return state;

    _frameCount++;


    int newScore = state.score + scoreIncrement;


    double newSpeed = state.gameSpeed;
    if (_frameCount % speedIncrementInterval == 0) {
      newSpeed += speedIncrement;
    }


    Player updatedPlayer = _updatePlayer(
      state.player,
      state.groundY,
      deltaTime,
    );


    List<Obstacle> updatedObstacles = _updateObstacles(
      state.obstacles,
      state.gameWidth,
      state.groundY,
      newSpeed,
      deltaTime,
    );


    List<Cloud> updatedClouds = state.clouds;
    if (_frameCount % 3 == 0) {
      updatedClouds = _updateClouds(
        state.clouds,
        state.gameWidth,
        state.gameHeight,
        deltaTime,
      );
    }


    bool hasCollision = _checkCollisions(updatedPlayer, updatedObstacles);

    if (hasCollision) {
      int newHighScore = math.max(state.highScore, newScore);
      return state.copyWith(
        gameState: NeonRunnerGameState.gameOver,
        score: newScore,
        highScore: newHighScore,
      );
    }

    return state.copyWith(
      player: updatedPlayer,
      obstacles: updatedObstacles,
      clouds: updatedClouds,
      score: newScore,
      gameSpeed: newSpeed,
    );
  }


  NeonRunnerState jump(NeonRunnerState state) {
    if (!state.isPlaying) return state;


    if (state.isPlayerOnGround && !state.player.isJumping) {
      Player updatedPlayer = state.player.copyWith(
        velocityY: jumpVelocity,
        isJumping: true,
      );

      return state.copyWith(player: updatedPlayer);
    }

    return state;
  }


  NeonRunnerState duck(NeonRunnerState state, bool isDucking) {
    if (!state.isPlaying) return state;

    double newHeight = isDucking ? 30.0 : 60.0;
    Player updatedPlayer = state.player.copyWith(
      isDucking: isDucking,
      height: newHeight,
    );


    if (isDucking && state.isPlayerOnGround) {
      updatedPlayer = updatedPlayer.copyWith(y: state.groundY - newHeight);
    }

    return state.copyWith(player: updatedPlayer);
  }


  NeonRunnerState startGame(NeonRunnerState state) {
    if (state.isPlaying) return state;

    _frameCount = 0;
    List<Cloud> initialClouds = _generateInitialClouds(
      state.gameWidth,
      state.gameHeight,
    );

    return state.copyWith(
      gameState: NeonRunnerGameState.playing,
      clouds: initialClouds,
    );
  }


  NeonRunnerState resetGame(NeonRunnerState state) {
    _frameCount = 0;
    return NeonRunnerState.initial(
      gameWidth: state.gameWidth,
      gameHeight: state.gameHeight,
      highScore: state.highScore,
    );
  }


  Player _updatePlayer(Player player, double groundY, double deltaTime) {
    double newY = player.y;
    double newVelocityY = player.velocityY;
    bool newIsJumping = player.isJumping;


    if (player.isJumping || player.y < groundY - player.height) {
      newVelocityY += gravity * deltaTime;
      newY += newVelocityY * deltaTime;


      if (newY >= groundY - player.height) {
        newY = groundY - player.height;
        newVelocityY = 0;
        newIsJumping = false;
      }
    }

    return player.copyWith(
      y: newY,
      velocityY: newVelocityY,
      isJumping: newIsJumping,
    );
  }


  List<Obstacle> _updateObstacles(
    List<Obstacle> obstacles,
    double gameWidth,
    double groundY,
    double gameSpeed,
    double deltaTime,
  ) {
    List<Obstacle> updated = [];


    for (Obstacle obstacle in obstacles) {
      double newX = obstacle.x - gameSpeed * deltaTime;


      if (newX + obstacle.width > -50) {
        updated.add(obstacle.copyWith(x: newX));
      }
    }


    if (updated.isEmpty ||
        updated.last.x < gameWidth - _getNextObstacleDistance(gameSpeed)) {
      Obstacle newObstacle = _generateObstacle(gameWidth, groundY);
      updated.add(newObstacle);
    }

    return updated;
  }


  List<Cloud> _updateClouds(
    List<Cloud> clouds,
    double gameWidth,
    double gameHeight,
    double deltaTime,
  ) {
    List<Cloud> updated = [];


    for (Cloud cloud in clouds) {
      double newX = cloud.x - cloud.speed * deltaTime;


      if (newX + cloud.size > -100) {
        updated.add(cloud.copyWith(x: newX));
      }
    }


    if (updated.length < 3) {
      Cloud newCloud = _generateCloud(gameWidth, gameHeight);
      updated.add(newCloud);
    }

    return updated;
  }


  bool _checkCollisions(Player player, List<Obstacle> obstacles) {

    double playerX = player.x + 8;
    double playerY = player.y + 8;
    double playerWidth = player.width - 16;
    double playerHeight = player.height - 16;

    for (Obstacle obstacle in obstacles) {

      if (obstacle.x < player.x + player.width + 20 &&
          obstacle.x + obstacle.width > player.x - 20) {
        if (obstacle.collidesWith(
          playerX,
          playerY,
          playerWidth,
          playerHeight,
        )) {
          return true;
        }
      }
    }

    return false;
  }


  Obstacle _generateObstacle(double gameWidth, double groundY) {
    ObstacleType type =
        ObstacleType.values[_random.nextInt(ObstacleType.values.length)];

    double width = 25.0;
    double height = 50.0;

    switch (type) {
      case ObstacleType.cactus:
        width = 20.0;
        height = 60.0;
        break;
      case ObstacleType.rock:
        width = 35.0;
        height = 25.0;
        break;
      case ObstacleType.spike:
        width = 15.0;
        height = 45.0;
        break;
    }

    return Obstacle(
      x: gameWidth + 50,
      y: groundY - height,
      width: width,
      height: height,
      type: type,
    );
  }


  Cloud _generateCloud(double gameWidth, double gameHeight) {
    return Cloud(
      x: gameWidth + _random.nextDouble() * 200,
      y: _random.nextDouble() * (gameHeight * 0.4) + 20,
      size: _random.nextDouble() * 40 + 20,
      speed: _random.nextDouble() * 20 + 10,
    );
  }


  List<Cloud> _generateInitialClouds(double gameWidth, double gameHeight) {
    List<Cloud> clouds = [];

    for (int i = 0; i < 3; i++) {
      clouds.add(
        Cloud(
          x: _random.nextDouble() * gameWidth,
          y: _random.nextDouble() * (gameHeight * 0.4) + 20,
          size: _random.nextDouble() * 40 + 20,
          speed: _random.nextDouble() * 20 + 10,
        ),
      );
    }

    return clouds;
  }


  double _getNextObstacleDistance(double gameSpeed) {

    double baseDistance = minObstacleDistance;


    double speedBonus =
        (gameSpeed - 200.0) * 0.5; // Extra space for higher speeds
    speedBonus = speedBonus.clamp(0.0, 100.0); // Cap the bonus

    double totalMinDistance = baseDistance + speedBonus;
    double totalMaxDistance = maxObstacleDistance + speedBonus;

    return totalMinDistance +
        _random.nextDouble() * (totalMaxDistance - totalMinDistance);
  }
}
