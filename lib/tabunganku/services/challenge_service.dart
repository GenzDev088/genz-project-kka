import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/challenge_model.dart';
import 'package:otax/tabunganku/models/challenge_template_model.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/services/challenge_templates.dart';


abstract class ChallengeService {
  Future<List<ChallengeModel>> getChallenges();
  Future<List<ChallengeModel>> getActiveChallenges();
  Future<List<ChallengeModel>> getCompletedChallenges();
  Future<ChallengeModel> getChallenge(String id);
  Future<ChallengeModel> createChallenge(
    ChallengeTemplateModel template, {
    double? customTargetAmount,
    int? customDuration,
    bool isGroupChallenge = false,
    String? groupId,
  });
  Future<ChallengeModel> createCustomChallenge(ChallengeModel challenge);
  Future<void> updateChallenge(ChallengeModel challenge);
  Future<void> deleteChallenge(String id);
  Future<void> abandonChallenge(String id);
  Future<void> updateChallengeProgress(String challengeId, double progress);
  Future<void> checkAndUpdateChallengeFromTransaction(
    TransactionModel transaction,
  );
  Future<int> getCurrentStreak();
  Future<int> getTotalPoints();
  Stream<List<ChallengeModel>> watchActiveChallenges();
  List<ChallengeTemplateModel> getAllTemplates();
  ChallengeTemplateModel? getTemplateById(String id);
}


class MockChallengeService implements ChallengeService {
  static const String _storagePrefix = 'challenges_user_';
  static const String _streakKey = 'challenge_streak_';
  static const String _pointsKey = 'challenge_points_';
  static const String _lastCompletionKey = 'last_challenge_completion_';

  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<ChallengeModel>> _userChallenges = {};
  static final StreamController<List<ChallengeModel>> _streamController =
      StreamController<List<ChallengeModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userChallenges.containsKey(userId)) {
      return;
    }

    final prefs = await _getPrefs();
    final key = '$_storagePrefix$userId';
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      _userChallenges[userId] = [];
      return;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      _userChallenges[userId] = jsonList
          .map((json) => ChallengeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _userChallenges[userId] = [];
    }
  }

  Future<void> _saveUserChallenges(String userId) async {
    final prefs = await _getPrefs();
    final key = '$_storagePrefix$userId';
    final challenges = _userChallenges[userId] ?? [];
    final jsonString = jsonEncode(challenges.map((t) => t.toJson()).toList());
    await prefs.setString(key, jsonString);
  }

  Future<void> _emitChallenges(String userId) async {
    final activeChallenges = (_userChallenges[userId] ?? [])
        .where((c) => c.status == ChallengeStatus.active)
        .toList();
    _streamController.add(activeChallenges);
  }

  @override
  Future<List<ChallengeModel>> getChallenges() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    return List.from(_userChallenges[userId] ?? []);
  }

  @override
  Future<List<ChallengeModel>> getActiveChallenges() async {
    final challenges = await getChallenges();
    return challenges.where((c) => c.status == ChallengeStatus.active).toList();
  }

  @override
  Future<List<ChallengeModel>> getCompletedChallenges() async {
    final challenges = await getChallenges();
    return challenges
        .where((c) => c.status == ChallengeStatus.completed)
        .toList();
  }

  @override
  Future<ChallengeModel> getChallenge(String id) async {
    final challenges = await getChallenges();
    return challenges.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Challenge not found'),
    );
  }

  @override
  Future<ChallengeModel> createChallenge(
    ChallengeTemplateModel template, {
    double? customTargetAmount,
    int? customDuration,
    bool isGroupChallenge = false,
    String? groupId,
  }) async {
    final challenge = template.toChallenge(
      customTargetAmount: customTargetAmount,
      customDuration: customDuration,
      isGroupChallenge: isGroupChallenge,
      groupId: groupId,
    );

    return await createCustomChallenge(challenge);
  }

  @override
  Future<ChallengeModel> createCustomChallenge(ChallengeModel challenge) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);

    _userChallenges[userId]!.add(challenge);
    await _saveUserChallenges(userId);
    await _emitChallenges(userId);

    return challenge;
  }

  @override
  Future<void> updateChallenge(ChallengeModel challenge) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);

    final index = _userChallenges[userId]!.indexWhere(
      (c) => c.id == challenge.id,
    );
    if (index != -1) {
      _userChallenges[userId]![index] = challenge;
      await _saveUserChallenges(userId);
      await _emitChallenges(userId);
    }
  }

  @override
  Future<void> deleteChallenge(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);

    _userChallenges[userId]!.removeWhere((c) => c.id == id);
    await _saveUserChallenges(userId);
    await _emitChallenges(userId);
  }

  @override
  Future<void> abandonChallenge(String id) async {
    final challenge = await getChallenge(id);
    final abandoned = challenge.copyWith(status: ChallengeStatus.abandoned);
    await updateChallenge(abandoned);
  }

  @override
  Future<void> updateChallengeProgress(
    String challengeId,
    double progress,
  ) async {
    final challenge = await getChallenge(challengeId);


    ChallengeStatus newStatus = challenge.status;
    DateTime? completedDate;

    if (challenge.targetAmount != null && progress >= challenge.targetAmount!) {
      newStatus = ChallengeStatus.completed;
      completedDate = DateTime.now();


      await _updateStreakOnCompletion();
      await _addPoints(challenge.points);
    }


    if (DateTime.now().isAfter(challenge.endDate) &&
        newStatus != ChallengeStatus.completed) {
      newStatus = ChallengeStatus.failed;
    }

    final updated = challenge.copyWith(
      currentProgress: progress,
      status: newStatus,
      completedDate: completedDate,
    );

    await updateChallenge(updated);
  }

  @override
  Future<void> checkAndUpdateChallengeFromTransaction(
    TransactionModel transaction,
  ) async {
    final activeChallenges = await getActiveChallenges();
    debugPrint(
      'ChallengeService: Checking ${activeChallenges.length} active challenges for transaction: ${transaction.title} (${transaction.category})',
    );

    for (final challenge in activeChallenges) {
      final txCategory = transaction.category.toLowerCase().trim();
      final targetCategory = challenge.targetCategory?.toLowerCase().trim();

      switch (challenge.targetType) {
        case ChallengeTargetType.saveAmount:
          if (transaction.type == TransactionType.income) {
            debugPrint(
              'ChallengeService: Updating saveAmount challenge ${challenge.id}',
            );
            await updateChallengeProgress(
              challenge.id,
              challenge.currentProgress + transaction.amount,
            );
          }
          break;

        case ChallengeTargetType.limitExpense:
          if (transaction.type == TransactionType.expense) {
            final totalExpense = challenge.currentProgress + transaction.amount;
            debugPrint(
              'ChallengeService: Updating limitExpense challenge ${challenge.id}. Current total: $totalExpense',
            );
            if (challenge.targetAmount != null &&
                totalExpense > challenge.targetAmount!) {
              debugPrint(
                'ChallengeService: Challenge ${challenge.id} FAILED (limit exceeded)',
              );
              final failed = challenge.copyWith(status: ChallengeStatus.failed);
              await updateChallenge(failed);
            } else {
              await updateChallengeProgress(challenge.id, totalExpense);
            }
          }
          break;

        case ChallengeTargetType.zeroExpense:
          if (transaction.type == TransactionType.expense) {
            debugPrint(
              'ChallengeService: Challenge ${challenge.id} FAILED (zeroExpense violation)',
            );
            final failed = challenge.copyWith(status: ChallengeStatus.failed);
            await updateChallenge(failed);
          }
          break;

        case ChallengeTargetType.categoryLimit:
          if (transaction.type == TransactionType.expense &&
              txCategory == targetCategory) {
            final categoryExpense =
                challenge.currentProgress + transaction.amount;
            debugPrint(
              'ChallengeService: Updating categoryLimit challenge ${challenge.id}. New total: $categoryExpense',
            );
            if (challenge.targetAmount != null &&
                categoryExpense > challenge.targetAmount!) {
              debugPrint(
                'ChallengeService: Challenge ${challenge.id} FAILED (category limit exceeded)',
              );
              final failed = challenge.copyWith(status: ChallengeStatus.failed);
              await updateChallenge(failed);
            } else {
              await updateChallengeProgress(challenge.id, categoryExpense);
            }
          }
          break;

        case ChallengeTargetType.noTransactionType:
          if (txCategory == targetCategory) {
            debugPrint(
              'ChallengeService: Challenge ${challenge.id} FAILED (forbidden category used)',
            );
            final failed = challenge.copyWith(status: ChallengeStatus.failed);
            await updateChallenge(failed);
          }
          break;
        case ChallengeTargetType.custom:


          await updateChallengeProgress(
            challenge.id,
            challenge.currentProgress + 1,
          );
          break;
      }
    }
  }

  Future<void> _updateStreakOnCompletion() async {
    final prefs = await _getPrefs();
    final userId = await _getCurrentUserId();
    final streakKey = '$_streakKey$userId';
    final lastCompletionKey = '$_lastCompletionKey$userId';

    final currentStreak = prefs.getInt(streakKey) ?? 0;
    final lastCompletionStr = prefs.getString(lastCompletionKey);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastCompletionStr != null) {
      final lastCompletion = DateTime.parse(lastCompletionStr);
      final lastDate = DateTime(
        lastCompletion.year,
        lastCompletion.month,
        lastCompletion.day,
      );
      final daysDiff = today.difference(lastDate).inDays;

      if (daysDiff == 1) {

        await prefs.setInt(streakKey, currentStreak + 1);
      } else if (daysDiff > 1) {

        await prefs.setInt(streakKey, 1);
      }

    } else {

      await prefs.setInt(streakKey, 1);
    }

    await prefs.setString(lastCompletionKey, now.toIso8601String());
  }

  Future<void> _addPoints(int points) async {
    final prefs = await _getPrefs();
    final userId = await _getCurrentUserId();
    final pointsKey = '$_pointsKey$userId';

    final currentPoints = prefs.getInt(pointsKey) ?? 0;
    await prefs.setInt(pointsKey, currentPoints + points);
  }

  @override
  Future<int> getCurrentStreak() async {
    final prefs = await _getPrefs();
    final userId = await _getCurrentUserId();
    final streakKey = '$_streakKey$userId';
    return prefs.getInt(streakKey) ?? 0;
  }

  @override
  Future<int> getTotalPoints() async {
    final prefs = await _getPrefs();
    final userId = await _getCurrentUserId();
    final pointsKey = '$_pointsKey$userId';
    return prefs.getInt(pointsKey) ?? 0;
  }

  @override
  Stream<List<ChallengeModel>> watchActiveChallenges() {
    return _streamController.stream;
  }

  @override
  List<ChallengeTemplateModel> getAllTemplates() {
    return ChallengeTemplates.getAllTemplates();
  }

  @override
  ChallengeTemplateModel? getTemplateById(String id) {
    return ChallengeTemplates.getTemplateById(id);
  }
}
