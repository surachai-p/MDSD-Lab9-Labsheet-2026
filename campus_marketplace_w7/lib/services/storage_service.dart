import 'dart:io';
import 'dart:convert'; // 1. อย่าลืม import ตัวนี้เพิ่มเข้ามาเพื่อใช้แปลง Base64

class StorageService {
  // ไม่ต้องใช้ FirebaseStorage แล้ว (ลบตัวแปร _storage ออกได้เลย)

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    try {
      // 1. อ่านไฟล์รูปภาพให้กลายเป็นข้อมูลไบต์ (Bytes)
      final bytes = await imageFile.readAsBytes();
      
      // 2. แปลงข้อมูลไบต์เป็นข้อความรหัส Base64
      final base64String = base64Encode(bytes);
      
      // 3. คืนค่ากลับไปเป็นสตริงตามรูปแบบ (Data URI) แบบเดียวกับของเพื่อนเป๊ะๆ
      return 'data:image/jpeg;base64,$base64String';
      
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }
}