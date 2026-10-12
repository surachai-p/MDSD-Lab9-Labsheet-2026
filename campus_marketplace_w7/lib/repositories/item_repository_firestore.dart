import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  CollectionReference<Map<String, dynamic>> get _items =>
      FirebaseFirestore.instance.collection('items');

  // อ่านทุกเอกสารใน Collection items ครั้งเดียว
  @override
  Future<List<Item>> getItems() async {
    final snapshot = await _items.get();
    return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
  }

  // เขียนเอกสารใหม่ลง Collection items
  Future<void> postItem(Item item) async {
    await _items.add(item.toFirestore());
  }

  // ฟังเอกสารของผู้ขายคนนี้แบบ Real-time
  Stream<List<Item>> watchMyListings(String sellerId) {
    return _items
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList());
  }
}