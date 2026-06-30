import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/challenge_model.dart';
import 'package:otax/tabunganku/models/challenge_template_model.dart';
import 'package:otax/tabunganku/models/badge_model.dart';
import 'package:otax/tabunganku/services/challenge_service.dart';
import 'package:otax/tabunganku/services/badge_service.dart';
import 'package:otax/tabunganku/providers/notification_provider.dart';



final challengeServiceProvider = Provider<ChallengeService>((ref) {
  return MockChallengeService();
});

final badgeServiceProvider = Provider<BadgeService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return MockBadgeService(notificationService);
});




final challengesProvider = FutureProvider.autoDispose<List<ChallengeModel>>((
  ref,
) async {
  final service = ref.watch(challengeServiceProvider);
  return service.getChallenges();
});


final activeChallengesProvider =
    FutureProvider.autoDispose<List<ChallengeModel>>((ref) async {
      final service = ref.watch(challengeServiceProvider);
      return service.getActiveChallenges();
    });


final completedChallengesProvider =
    FutureProvider.autoDispose<List<ChallengeModel>>((ref) async {
      final service = ref.watch(challengeServiceProvider);
      return service.getCompletedChallenges();
    });


final activeChallengesStreamProvider =
    StreamProvider.autoDispose<List<ChallengeModel>>((ref) {
      final service = ref.watch(challengeServiceProvider);
      return service.watchActiveChallenges();
    });


final challengeProvider = FutureProvider.autoDispose
    .family<ChallengeModel, String>((ref, id) async {
      final service = ref.watch(challengeServiceProvider);
      return service.getChallenge(id);
    });




final challengeTemplatesProvider = Provider<List<ChallengeTemplateModel>>((
  ref,
) {
  final service = ref.watch(challengeServiceProvider);
  return service.getAllTemplates();
});


final templatesByTypeProvider =
    Provider.family<List<ChallengeTemplateModel>, ChallengeType>((ref, type) {
      final allTemplates = ref.watch(challengeTemplatesProvider);
      return allTemplates.where((t) => t.type == type).toList();
    });


final templatesByDifficultyProvider =
    Provider.family<List<ChallengeTemplateModel>, ChallengeDifficulty>((
      ref,
      difficulty,
    ) {
      final allTemplates = ref.watch(challengeTemplatesProvider);
      return allTemplates.where((t) => t.difficulty == difficulty).toList();
    });


final templateProvider = Provider.family<ChallengeTemplateModel?, String>((
  ref,
  id,
) {
  final service = ref.watch(challengeServiceProvider);
  return service.getTemplateById(id);
});




final currentStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.watch(challengeServiceProvider);
  return service.getCurrentStreak();
});


final totalPointsProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.watch(challengeServiceProvider);
  return service.getTotalPoints();
});




final allBadgesProvider = FutureProvider.autoDispose<List<BadgeModel>>((
  ref,
) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getAllBadges();
});


final earnedBadgesProvider = FutureProvider.autoDispose<List<BadgeModel>>((
  ref,
) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getEarnedBadges();
});


final availableBadgesProvider = FutureProvider.autoDispose<List<BadgeModel>>((
  ref,
) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getAvailableBadges();
});


final badgesByCategoryProvider = Provider.autoDispose
    .family<List<BadgeModel>, BadgeCategory>((ref, category) {
      final badgesAsync = ref.watch(allBadgesProvider);
      return badgesAsync.maybeWhen(
        data: (badges) => badges.where((b) => b.category == category).toList(),
        orElse: () => <BadgeModel>[],
      );
    });


final badgeProvider = FutureProvider.autoDispose.family<BadgeModel?, String>((
  ref,
  id,
) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getBadgeById(id);
});




final challengeStatsProvider = Provider.autoDispose((ref) {
  final challengesAsync = ref.watch(challengesProvider);

  return challengesAsync.maybeWhen(
    data: (challenges) {
      final total = challenges.length;
      final completed = challenges
          .where((c) => c.status == ChallengeStatus.completed)
          .length;
      final active = challenges
          .where((c) => c.status == ChallengeStatus.active)
          .length;
      final failed = challenges
          .where((c) => c.status == ChallengeStatus.failed)
          .length;
      final completionRate = total > 0
          ? (completed / total * 100).toStringAsFixed(1)
          : '0.0';

      return {
        'total': total,
        'completed': completed,
        'active': active,
        'failed': failed,
        'completionRate': completionRate,
      };
    },
    orElse: () => {
      'total': 0,
      'completed': 0,
      'active': 0,
      'failed': 0,
      'completionRate': '0.0',
    },
  );
});


final badgeStatsProvider = Provider.autoDispose((ref) {
  final badgesAsync = ref.watch(allBadgesProvider);

  return badgesAsync.maybeWhen(
    data: (badges) {
      final total = badges.length;
      final earned = badges.where((b) => b.isEarned).length;
      final percentage = total > 0
          ? (earned / total * 100).toStringAsFixed(1)
          : '0.0';

      return {
        'total': total,
        'earned': earned,
        'remaining': total - earned,
        'percentage': percentage,
      };
    },
    orElse: () => {
      'total': 0,
      'earned': 0,
      'remaining': 0,
      'percentage': '0.0',
    },
  );
});
