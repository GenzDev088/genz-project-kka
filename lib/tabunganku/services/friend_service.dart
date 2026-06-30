import 'package:otax/tabunganku/models/friend_model.dart';



abstract class FriendService {
  Future<List<FriendModel>> getFriends();
  Future<FriendModel> getFriend(String id);
  Future<FriendModel> addFriend(FriendModel friend);
  Future<void> updateFriend(FriendModel friend);
  Future<void> deleteFriend(String id);
  Stream<List<FriendModel>> watchFriends();
}


class MockFriendService implements FriendService {
  static final List<FriendModel> _mockFriends = [
    FriendModel(
      id: '1',
      name: 'Ahmad Wijaya',
      email: 'ahmad@example.com',
      balance: 2500000,
      addedDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    FriendModel(
      id: '2',
      name: 'Siti Nurhaliza',
      email: 'siti@example.com',
      balance: 1800000,
      addedDate: DateTime.now().subtract(const Duration(days: 20)),
    ),
    FriendModel(
      id: '3',
      name: 'Budi Santoso',
      email: 'budi@example.com',
      balance: 3200000,
      addedDate: DateTime.now().subtract(const Duration(days: 15)),
    ),
    FriendModel(
      id: '4',
      name: 'Dewi Lestari',
      email: 'dewi@example.com',
      balance: 2000000,
      addedDate: DateTime.now().subtract(const Duration(days: 10)),
    ),
    FriendModel(
      id: '5',
      name: 'Eka Putri',
      email: 'eka@example.com',
      balance: 2700000,
      addedDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<List<FriendModel>> getFriends() async {

    await Future.delayed(const Duration(seconds: 1));
    return _mockFriends;
  }

  @override
  Future<FriendModel> getFriend(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockFriends.firstWhere((f) => f.id == id);
  }

  @override
  Future<FriendModel> addFriend(FriendModel friend) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockFriends.add(friend);
    return friend;
  }

  @override
  Future<void> updateFriend(FriendModel friend) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockFriends.indexWhere((f) => f.id == friend.id);
    if (index != -1) {
      _mockFriends[index] = friend;
    }
  }

  @override
  Future<void> deleteFriend(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockFriends.removeWhere((f) => f.id == id);
  }

  @override
  Stream<List<FriendModel>> watchFriends() {

    return Stream.value(_mockFriends);
  }
}
