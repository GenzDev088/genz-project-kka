import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/badge_model.dart';
import 'package:otax/tabunganku/models/notification_model.dart';
import 'package:otax/tabunganku/services/notification_service.dart';


abstract class BadgeService {
  Future<List<BadgeModel>> getAllBadges();
  Future<List<BadgeModel>> getEarnedBadges();
  Future<List<BadgeModel>> getAvailableBadges();
  Future<BadgeModel?> getBadgeById(String id);
  Future<void> unlockBadge(String badgeId);
  Future<bool> checkAndUnlockBadges(int currentPoints, int currentStreak);
}


class MockBadgeService implements BadgeService {
  final NotificationService _notificationService;

  MockBadgeService(this._notificationService);

  static const String _earnedBadgesKey = 'earned_badges_';

  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }


  static final List<BadgeModel> _allBadges = [

    BadgeModel(
      id: 'streak_3',
      name: 'Konsisten 3 Hari',
      description: 'Selesaikan challenge 3 hari berturut-turut',
      iconPath: 'assets/badges/streak_3.png',
      category: BadgeCategory.streak,
      requiredStreak: 3,
    ),
    BadgeModel(
      id: 'streak_7',
      name: 'Pekan Sempurna',
      description: 'Selesaikan challenge 7 hari berturut-turut',
      iconPath: 'assets/badges/streak_7.png',
      category: BadgeCategory.streak,
      requiredStreak: 7,
    ),
    BadgeModel(
      id: 'streak_30',
      name: 'Disiplin Sejati',
      description: 'Selesaikan challenge 30 hari berturut-turut!',
      iconPath: 'assets/badges/streak_30.png',
      category: BadgeCategory.streak,
      requiredStreak: 30,
    ),
    BadgeModel(
      id: 'streak_100',
      name: 'Legenda Menabung',
      description: 'Selesaikan challenge 100 hari berturut-turut! Luar biasa!',
      iconPath: 'assets/badges/streak_100.png',
      category: BadgeCategory.streak,
      requiredStreak: 100,
    ),


    BadgeModel(
      id: 'points_50',
      name: 'Pemula Hebat',
      description: 'Kumpulkan 50 poin challenge',
      iconPath: 'assets/badges/points_50.png',
      category: BadgeCategory.challenge,
      requiredPoints: 50,
    ),
    BadgeModel(
      id: 'points_100',
      name: 'Penabung Handal',
      description: 'Kumpulkan 100 poin challenge',
      iconPath: 'assets/badges/points_100.png',
      category: BadgeCategory.challenge,
      requiredPoints: 100,
    ),
    BadgeModel(
      id: 'points_250',
      name: 'Master Hemat',
      description: 'Kumpulkan 250 poin challenge',
      iconPath: 'assets/badges/points_250.png',
      category: BadgeCategory.challenge,
      requiredPoints: 250,
    ),
    BadgeModel(
      id: 'points_500',
      name: 'Raja Tabungan',
      description: 'Kumpulkan 500 poin challenge',
      iconPath: 'assets/badges/points_500.png',
      category: BadgeCategory.challenge,
      requiredPoints: 500,
    ),
    BadgeModel(
      id: 'points_1000',
      name: 'Dewa Penabung',
      description: 'Kumpulkan 1000 poin challenge - Achievement tertinggi!',
      iconPath: 'assets/badges/points_1000.png',
      category: BadgeCategory.challenge,
      requiredPoints: 1000,
    ),


    BadgeModel(
      id: 'first_challenge',
      name: 'Langkah Pertama',
      description: 'Selesaikan challenge pertamamu',
      iconPath: 'assets/badges/first_challenge.png',
      category: BadgeCategory.challenge,
    ),
    BadgeModel(
      id: 'zero_expense_master',
      name: 'Master Zero Expense',
      description: 'Selesaikan Zero Expense Day challenge',
      iconPath: 'assets/badges/zero_expense.png',
      category: BadgeCategory.challenge,
      requiredChallengeId: 'zero-expense',
    ),
    BadgeModel(
      id: 'meal_prepper',
      name: 'Chef Hemat',
      description: 'Selesaikan Meal Prep Week challenge',
      iconPath: 'assets/badges/meal_prep.png',
      category: BadgeCategory.challenge,
      requiredChallengeId: 'meal-prep',
    ),
    BadgeModel(
      id: 'no_shopping',
      name: 'Pantang Belanja',
      description: 'Selesaikan No Online Shopping Week',
      iconPath: 'assets/badges/no_shopping.png',
      category: BadgeCategory.challenge,
      requiredChallengeId: 'no-online-shopping',
    ),
    BadgeModel(
      id: 'save_500k',
      name: 'Jumbo Saver',
      description: 'Berhasil tabung 500K dalam sebulan',
      iconPath: 'assets/badges/save_500k.png',
      category: BadgeCategory.saving,
      requiredChallengeId: 'save-500k-month',
    ),


    BadgeModel(
      id: 'early_bird',
      name: 'Early Adopter',
      description: 'Pengguna awal fitur Challenge Menabung',
      iconPath: 'assets/badges/early_bird.png',
      category: BadgeCategory.special,
    ),
  ];

  Future<List<String>> _getEarnedBadgeIds() async {
    final prefs = await _getPrefs();
    final userId = await _getCurrentUserId();
    final key = '$_earnedBadgesKey$userId';
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((e) => e as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveEarnedBadgeIds(List<String> badgeIds) async {
    final prefs = await _getPrefs();
    final userId = await _getCurrentUserId();
    final key = '$_earnedBadgesKey$userId';
    final jsonString = jsonEncode(badgeIds);
    await prefs.setString(key, jsonString);
  }

  @override
  Future<List<BadgeModel>> getAllBadges() async {
    final earnedIds = await _getEarnedBadgeIds();

    return _allBadges.map((badge) {
      final isEarned = earnedIds.contains(badge.id);
      return badge.copyWith(
        isEarned: isEarned,
        earnedDate: isEarned
            ? DateTime.now()
            : null, // TODO: Store actual earned date
      );
    }).toList();
  }

  @override
  Future<List<BadgeModel>> getEarnedBadges() async {
    final allBadges = await getAllBadges();
    return allBadges.where((b) => b.isEarned).toList();
  }

  @override
  Future<List<BadgeModel>> getAvailableBadges() async {
    final allBadges = await getAllBadges();
    return allBadges.where((b) => !b.isEarned).toList();
  }

  @override
  Future<BadgeModel?> getBadgeById(String id) async {
    final allBadges = await getAllBadges();
    try {
      return allBadges.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> unlockBadge(String badgeId) async {
    final earnedIds = await _getEarnedBadgeIds();

    if (!earnedIds.contains(badgeId)) {
      earnedIds.add(badgeId);
      await _saveEarnedBadgeIds(earnedIds);


      final badge = await getBadgeById(badgeId);
      if (badge != null) {
        await _notificationService.addNotification(
          NotificationModel(
            id: 'badge_$badgeId\_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Badge Baru Terbuka! 🏆',
            message:
                'Selamat! Kamu baru saja mendapatkan badge "${badge.name}".',
            timestamp: DateTime.now(),
            type: NotificationType.badge,
            actionData: badgeId,
          ),
        );
      }
    }
  }

  @override
  Future<bool> checkAndUnlockBadges(
    int currentPoints,
    int currentStreak,
  ) async {
    final availableBadges = await getAvailableBadges();
    bool unlocked = false;

    for (final badge in availableBadges) {
      bool shouldUnlock = false;


      if (badge.requiredPoints > 0 && currentPoints >= badge.requiredPoints) {
        shouldUnlock = true;
      }


      if (badge.requiredStreak != null &&
          currentStreak >= badge.requiredStreak!) {
        shouldUnlock = true;
      }

      if (shouldUnlock) {
        await unlockBadge(badge.id);
        unlocked = true;
      }
    }

    return unlocked;
  }


  Future<void> unlockChallengeBadge(String challengeTemplateId) async {
    final badge = _allBadges.firstWhere(
      (b) => b.requiredChallengeId == challengeTemplateId,
      orElse: () => _allBadges.first, // Dummy
    );

    if (badge.requiredChallengeId == challengeTemplateId) {
      await unlockBadge(badge.id);
    }
  }


  Future<void> unlockFirstChallengeBadge() async {
    await unlockBadge('first_challenge');
  }


  Future<void> unlockEarlyBirdBadge() async {
    await unlockBadge('early_bird');
  }
}
