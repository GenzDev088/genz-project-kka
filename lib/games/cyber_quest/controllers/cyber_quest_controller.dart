import 'package:flutter/foundation.dart';
import '../models/cyber_quest_models.dart';






class CyberQuestController extends ChangeNotifier {
  CyberQuestState _state = CyberQuestState();


  CyberQuestState get state => _state;


  void initialize() {
    _state = CyberQuestState(
      gameState: CyberQuestGameState.initial,
      currentLocation: 'Neo-Tokyo Central',
      score: 0,
    );
    notifyListeners();
  }


  void createCharacter(String name, CharacterClass characterClass) {
    if (name.isEmpty) return;

    final character = Character(name: name, characterClass: characterClass);

    _state = _state.copyWith(
      character: character,
      gameState: CyberQuestGameState.playing,
    );

    notifyListeners();
  }


  void startGame() {
    if (_state.character == null) return;

    _state = _state.copyWith(gameState: CyberQuestGameState.playing);

    notifyListeners();
  }


  void pauseGame() {
    if (_state.gameState == CyberQuestGameState.playing) {
      _state = _state.copyWith(gameState: CyberQuestGameState.paused);
      notifyListeners();
    }
  }


  void resumeGame() {
    if (_state.gameState == CyberQuestGameState.paused) {
      _state = _state.copyWith(gameState: CyberQuestGameState.playing);
      notifyListeners();
    }
  }


  void endGame() {
    _state = _state.copyWith(gameState: CyberQuestGameState.gameOver);
    notifyListeners();
  }


  void resetGame() {
    _state = CyberQuestState(
      gameState: CyberQuestGameState.initial,
      currentLocation: 'Neo-Tokyo Central',
      score: 0,
    );
    notifyListeners();
  }


  void moveToLocation(String location) {
    if (_state.gameState != CyberQuestGameState.playing) return;

    _state = _state.copyWith(currentLocation: location);
    notifyListeners();
  }


  void addExperience(int experience) {
    final character = _state.character;
    if (character == null || _state.gameState != CyberQuestGameState.playing) {
      return;
    }

    character.addExperience(experience);
    notifyListeners();
  }


  void addCredits(int credits) {
    final character = _state.character;
    if (character == null || _state.gameState != CyberQuestGameState.playing) {
      return;
    }

    character.addCredits(credits);
    notifyListeners();
  }


  bool spendCredits(int credits) {
    final character = _state.character;
    if (character == null || _state.gameState != CyberQuestGameState.playing) {
      return false;
    }

    final success = character.spendCredits(credits);
    if (success) {
      notifyListeners();
    }
    return success;
  }


  void takeDamage(int damage) {
    final character = _state.character;
    if (character == null || _state.gameState != CyberQuestGameState.playing) {
      return;
    }

    character.takeDamage(damage);


    if (!character.isAlive) {
      endGame();
    } else {
      notifyListeners();
    }
  }


  void heal(int amount) {
    final character = _state.character;
    if (character == null || _state.gameState != CyberQuestGameState.playing) {
      return;
    }

    character.heal(amount);
    notifyListeners();
  }


  void updateScore(int newScore) {
    _state = _state.copyWith(score: newScore);
    notifyListeners();
  }


  void addScore(int points) {
    _state = _state.copyWith(score: _state.score + points);
    notifyListeners();
  }


  Map<String, dynamic> getCharacterStats() {
    final character = _state.character;
    if (character == null) return {};

    return {
      'name': character.name,
      'class': character.characterClass.displayName,
      'level': character.level,
      'experience': character.experience,
      'experienceToNext': character.experienceToNextLevel,
      'health': character.health,
      'maxHealth': character.maxHealth,
      'credits': character.credits,
      'intelligence': character.intelligence,
      'strength': character.strength,
      'dexterity': character.dexterity,
      'charisma': character.charisma,
      'tech': character.tech,
    };
  }


  Map<String, dynamic> getGameStateSummary() {
    return {
      'gameState': _state.gameState.toString(),
      'currentLocation': _state.currentLocation,
      'score': _state.score,
      'hasCharacter': _state.character != null,
      'characterName': _state.character?.name ?? 'None',
    };
  }


  bool get isGameActive => _state.gameState == CyberQuestGameState.playing;


  bool get isGamePaused => _state.gameState == CyberQuestGameState.paused;


  bool get isGameOver => _state.gameState == CyberQuestGameState.gameOver;


  bool get isGameInitial => _state.gameState == CyberQuestGameState.initial;


  bool get hasCharacter => _state.character != null;


  Character? get currentCharacter => _state.character;


  String get currentLocation => _state.currentLocation;


  int get currentScore => _state.score;

  @override
  void dispose() {

    super.dispose();
  }
}
