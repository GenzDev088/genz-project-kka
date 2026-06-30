



library cyber_quest_models;


enum CyberQuestGameState { initial, playing, paused, gameOver }


enum CharacterClass {
  hacker,
  netrunner,
  techie,
  corporate;


  String get displayName {
    switch (this) {
      case CharacterClass.hacker:
        return 'Hacker';
      case CharacterClass.netrunner:
        return 'Netrunner';
      case CharacterClass.techie:
        return 'Techie';
      case CharacterClass.corporate:
        return 'Corporate';
    }
  }


  String get description {
    switch (this) {
      case CharacterClass.hacker:
        return 'Master of code and digital infiltration. High intelligence and hacking skills.';
      case CharacterClass.netrunner:
        return 'Neural interface specialist. Can directly interface with the net.';
      case CharacterClass.techie:
        return 'Technology expert and gadget specialist. Great with hardware and repairs.';
      case CharacterClass.corporate:
        return 'Business-savvy with resources and connections. High charisma and credits.';
    }
  }
}


class Character {
  final String name;
  final CharacterClass characterClass;
  int level;
  int experience;
  int health;
  int maxHealth;
  int credits;


  int intelligence;
  int strength;
  int dexterity;
  int charisma;
  int tech;

  Character({
    required this.name,
    required this.characterClass,
    this.level = 1,
    this.experience = 0,
    this.health = 100,
    this.maxHealth = 100,
    this.credits = 1000,
    this.intelligence = 10,
    this.strength = 10,
    this.dexterity = 10,
    this.charisma = 10,
    this.tech = 10,
  }) {

    switch (characterClass) {
      case CharacterClass.hacker:
        intelligence += 5;
        tech += 3;
        credits += 500;
        break;
      case CharacterClass.netrunner:
        intelligence += 3;
        tech += 5;
        dexterity += 2;
        break;
      case CharacterClass.techie:
        tech += 5;
        intelligence += 2;
        strength += 3;
        break;
      case CharacterClass.corporate:
        charisma += 5;
        credits += 2000;
        intelligence += 2;
        break;
    }
  }


  int get experienceToNextLevel => level * 100;


  bool get canLevelUp => experience >= experienceToNextLevel;


  void levelUp() {
    if (canLevelUp) {
      level++;
      experience -= experienceToNextLevel;
      maxHealth += 10;
      health = maxHealth; // Full heal on level up


      switch (characterClass) {
        case CharacterClass.hacker:
          intelligence += 2;
          tech += 1;
          break;
        case CharacterClass.netrunner:
          intelligence += 1;
          tech += 2;
          dexterity += 1;
          break;
        case CharacterClass.techie:
          tech += 2;
          strength += 1;
          intelligence += 1;
          break;
        case CharacterClass.corporate:
          charisma += 2;
          intelligence += 1;
          credits += 500;
          break;
      }
    }
  }


  void takeDamage(int damage) {
    health = (health - damage).clamp(0, maxHealth);
  }


  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
  }


  bool get isAlive => health > 0;


  void addExperience(int exp) {
    experience += exp;
    while (canLevelUp) {
      levelUp();
    }
  }


  void addCredits(int amount) {
    credits += amount;
  }


  bool spendCredits(int amount) {
    if (credits >= amount) {
      credits -= amount;
      return true;
    }
    return false;
  }
}


class CyberQuestState {
  CyberQuestGameState gameState;
  Character? character;
  String currentLocation;
  int score;

  CyberQuestState({
    this.gameState = CyberQuestGameState.initial,
    this.character,
    this.currentLocation = 'Neo-Tokyo Central',
    this.score = 0,
  });


  CyberQuestState copyWith({
    CyberQuestGameState? gameState,
    Character? character,
    String? currentLocation,
    int? score,
  }) {
    return CyberQuestState(
      gameState: gameState ?? this.gameState,
      character: character ?? this.character,
      currentLocation: currentLocation ?? this.currentLocation,
      score: score ?? this.score,
    );
  }
}


class Item {
  final String id;
  final String name;
  final String description;
  final int value;
  final ItemType type;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.value,
    required this.type,
  });
}


enum ItemType { weapon, armor, consumable, quest, misc }


class Quest {
  final String id;
  final String title;
  final String description;
  final int reward;
  final int expReward;
  bool isCompleted;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.expReward,
    this.isCompleted = false,
  });

  void complete() {
    isCompleted = true;
  }
}
