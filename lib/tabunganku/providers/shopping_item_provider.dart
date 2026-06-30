import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/shopping_item_model.dart';
import 'package:otax/tabunganku/services/shopping_item_service.dart';


final shoppingItemServiceProvider = Provider<ShoppingItemService>((ref) {
  return MockShoppingItemService();
});


final shoppingItemsStreamProvider =
    StreamProvider.autoDispose<List<ShoppingItem>>((ref) {
      final service = ref.watch(shoppingItemServiceProvider);
      return service.watchItems();
    });
