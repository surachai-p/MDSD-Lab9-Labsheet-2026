import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String? sellerId; // null = สินค้าจาก API ภายนอก

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
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

  // แปลงเป็น Map เพื่อเขียนลง Firestore (key ตรงกับชื่อ field)
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }

  // สร้าง Item จากเอกสารใน Firestore
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      // ถ้าไม่มี id ตัวเลขในเอกสาร ใช้ hashCode ของ doc.id แทน
      id: (data['id'] as num?)?.toInt() ?? doc.id.hashCode,
      title: data['title'] as String,
      price: (data['price'] as num).toDouble(),
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sellerId: data['sellerId'] as String?,
    );
  }
}