import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final FirebaseFirestore _firestore;

  ItemRepositoryFirestore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Item>> getItems() async {
    try {
      final snapshot = await _firestore.collection('items').get();
      return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลสินค้าจาก Firestore ได้: $e');
    }
  }

  Future<void> postItem(Item item) async {
    try {
      await _firestore.collection('items').add(item.toFirestore());
    } catch (e) {
      throw Exception('ไม่สามารถลงประกาศสินค้าใน Firestore ได้: $e');
    }
  }

  Stream<List<Item>> watchMyListings(String sellerId) {
    return _firestore
        .collection('items')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList(),
        );
  }
}
