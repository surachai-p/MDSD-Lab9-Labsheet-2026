import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('items');

  @override
  Future<List<Item>> getItems() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
  }

  Future<void> postItem(Item item) async {
    await _collection.add(item.toFirestore());
  }

  Stream<List<Item>> watchMyListings(String sellerId) {
    return _collection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList());
  }
}

