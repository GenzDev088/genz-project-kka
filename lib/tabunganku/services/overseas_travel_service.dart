import 'dart:async';
import 'dart:convert';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/overseas_travel_model.dart';

abstract class OverseasTravelService {
  Future<List<OverseasTravelGoalModel>> getGoals();
  Future<void> addGoal(OverseasTravelGoalModel goal);
  Future<void> updateGoal(OverseasTravelGoalModel goal);
  Future<void> deleteGoal(String id);
  Stream<List<OverseasTravelGoalModel>> watchGoals();
}

class MockOverseasTravelService implements OverseasTravelService {
  static const String _storageKey = 'overseas_travel_goals_v1';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static final Map<String, List<OverseasTravelGoalModel>> _userGoals = {};
  static final StreamController<List<OverseasTravelGoalModel>>
  _streamController =
      StreamController<List<OverseasTravelGoalModel>>.broadcast();

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'default_user' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userGoals.containsKey(userId)) {
      return;
    }

    final raw = await _secureStorage.readSecureData('$_storageKey$userId');
    if (raw == null || raw.isEmpty) {
      _userGoals[userId] = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userGoals[userId] = decoded
            .whereType<Map>()
            .map(
              (item) => OverseasTravelGoalModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _userGoals[userId] = [];
      }
    } catch (_) {
      _userGoals[userId] = [];
    }
  }

  Future<void> _saveUserGoals(String userId) async {
    final list = _userGoals[userId] ?? const <OverseasTravelGoalModel>[];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await _secureStorage.writeSecureData('$_storageKey$userId', raw);
  }

  Future<void> _emitGoals(String userId) async {
    await _ensureUserLoaded(userId);
    final goals = _userGoals[userId] ?? const <OverseasTravelGoalModel>[];
    _streamController.add(List.unmodifiable(goals));
  }

  @override
  Future<List<OverseasTravelGoalModel>> getGoals() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    return List.unmodifiable(
      _userGoals[userId] ?? const <OverseasTravelGoalModel>[],
    );
  }

  @override
  Future<void> addGoal(OverseasTravelGoalModel goal) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userGoals[userId]!.add(goal);
    await _saveUserGoals(userId);
    await _emitGoals(userId);
  }

  @override
  Future<void> updateGoal(OverseasTravelGoalModel goal) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final goals = _userGoals[userId]!;
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
      await _saveUserGoals(userId);
      await _emitGoals(userId);
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userGoals[userId]!.removeWhere((g) => g.id == id);
    await _saveUserGoals(userId);
    await _emitGoals(userId);
  }

  @override
  Stream<List<OverseasTravelGoalModel>> watchGoals() {
    return Stream<List<OverseasTravelGoalModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        controller.add(
          List.unmodifiable(
            _userGoals[userId] ?? const <OverseasTravelGoalModel>[],
          ),
        );
      });
      final subscription = _streamController.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }
}
