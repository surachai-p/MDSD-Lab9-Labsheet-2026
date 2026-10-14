import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('items');

  @override
  Future<List<Item>> getItems() async {
    final snap = await _col.get();
    return snap.docs.map((d) => Item.fromFirestore(d)).toList();
  }

  // เขียนเอกสารใหม่ลง Collection items
  // ถ้าเน็ตไม่มี Firestore จะรอในคิวไม่ throw จึงใส่ timeout ให้ขึ้น Error
  Future<void> postItem(Item item) async {
    try {
      await _col
          .add(item.toFirestore())
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw Exception('ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาลองใหม่อีกครั้ง');
    }
  }

  Stream<List<Item>> watchMyListings(String sellerId) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Item.fromFirestore(d)).toList());
  }
}