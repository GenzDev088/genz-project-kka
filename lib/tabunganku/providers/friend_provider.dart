import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/friend_model.dart';
import 'package:otax/tabunganku/services/friend_service.dart';


final friendServiceProvider = Provider<FriendService>((ref) {

  return MockFriendService();
});


final friendsProvider = FutureProvider<List<FriendModel>>((ref) async {
  final service = ref.watch(friendServiceProvider);
  return service.getFriends();
});


final friendsStreamProvider = StreamProvider<List<FriendModel>>((ref) {
  final service = ref.watch(friendServiceProvider);
  return service.watchFriends();
});


final friendProvider = FutureProvider.family<FriendModel, String>((
  ref,
  id,
) async {
  final service = ref.watch(friendServiceProvider);
  return service.getFriend(id);
});
