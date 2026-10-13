import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final CollectionReference _itemsCollection =
      FirebaseFirestore.instance.collection('items');

  @override
  Future<List<Item>> getItems() async {
    try {
      final querySnapshot = await _itemsCollection.get();
      return querySnapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลสินค้าจาก Firestore ได้: $e');
    }
  }

  Future<void> postItem(Item item) async {
    try {
      await _itemsCollection.add(item.toFirestore());
    } catch (e) {
      throw Exception('ไม่สามารถบันทึกสินค้าลง Firestore ได้: $e');
    }
  }

  Stream<List<Item>> watchMyListings(String sellerId) {
    return _itemsCollection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList());
  }
}
