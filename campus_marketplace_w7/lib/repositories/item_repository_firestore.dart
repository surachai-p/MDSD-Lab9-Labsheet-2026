import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. อ่านข้อมูลทั้งหมดจาก Firestore (ใช้งานผ่าน Interface เดิม)
  @override
  Future<List<Item>> getItems() async {
    final snapshot = await _firestore.collection('items').get();
    return snapshot.docs.map((doc) {
      // หมายเหตุ: fromFirestore จะถูกสร้างในขั้นตอนที่ 6.2
      return Item.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // 2. เขียนเอกสารใหม่ลง Collection
  Future<void> postItem(Item item) async {
    // หมายเหตุ: toFirestore จะถูกสร้างในขั้นตอนที่ 6.2
    await _firestore.collection('items').doc(item.id).set(item.toFirestore());
  }

  // 3. ดึงข้อมูลแบบ Real-time เฉพาะรายการที่ตัวเองเป็นคนลงขาย
  Stream<List<Item>> watchMyListings(String sellerId) {
    return _firestore
        .collection('items')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}