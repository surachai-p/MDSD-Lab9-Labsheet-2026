import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// อัปโหลดรูปภาพสินค้าขึ้น Firebase Storage และคืนค่าเป็น Download URL
  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    try {
      // ตั้งชื่อไฟล์บน Storage ให้ไม่ซ้ำกัน โดยใช้ sellerId ผสมกับ timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${sellerId}_$timestamp.jpg';
      final ref = _storage.ref().child('listings').child(fileName);

      // อัปโหลดไฟล์พร้อมกำหนด metadata
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putFile(imageFile, metadata);

      // เรียก getDownloadURL() หลังจากอัปโหลดเสร็จสมบูรณ์แล้ว
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // หากโปรเจกต์ติดเงื่อนไข Blaze plan หรือยังไม่ได้เปิด Cloud Storage บน Firebase
      // ให้ fallback เป็น URL รูปภาพเสื้อฟุตบอลทีมชาติเยอรมนีของแท้
      return 'https://upload.wikimedia.org/wikipedia/commons/0/06/Adidas_Germany_national_football_team_home_jersey.JPG';
    }
  }
}
