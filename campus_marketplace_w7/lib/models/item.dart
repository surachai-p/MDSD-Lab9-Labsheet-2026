import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String? sellerId; // null = มาจาก Fake Store API
  final String? docId; // id เอกสารใน Firestore (null ถ้ามาจาก API)

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
    this.docId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final title = json['title'] as String;
    final price = (json['price'] as num).toDouble();
    final description = json['description'] as String;
    final category = json['category'] as String;
    final imageUrl = json['image'] as String; // key 'image' ไม่ตรงกับชื่อ field imageUrl

    return Item(
      id: id,
      title: title,
      price: price,
      description: description,
      category: category,
      imageUrl: imageUrl,
    );
  }

  // แปลงเป็น Map เพื่อเขียนลง Firestore (ไม่เก็บ id เพราะ Firestore สร้าง doc.id ให้เอง)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }

  // สร้าง Item จากเอกสาร Firestore
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      // Firestore doc.id เป็น String แต่ Item.id เป็น int จึงแปลงด้วย hashCode
      // (ติดลบไม่ได้ จึง & 0x7fffffff) เพื่อให้ Favorites/Cart เดิมใช้งานต่อได้
      id: doc.id.hashCode & 0x7fffffff,
      docId: doc.id,
      title: data['title'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sellerId: data['sellerId'] as String?,
    );
  }
}