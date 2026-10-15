class Item {
  final dynamic id; 
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String? sellerId; // ฟิลด์ใหม่รองรับ Firestore (nullable เพราะ API ไม่มี)

  Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
  });

  // สำหรับดึงข้อมูลจาก Fake Store API (ของเดิม)
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      title: json['title'],
      price: json['price'].toDouble(),
      description: json['description'],
      category: json['category'],
      imageUrl: json['image'],
      sellerId: null,
    );
  }

  // เตรียมข้อมูลเป็น Map เพื่อส่งขึ้นไปบันทึกลง Firestore
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

  // แปลงข้อมูลที่ดึงกลับมาจาก Firestore ให้กลายเป็นออบเจกต์ Item
  factory Item.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Item(
      id: documentId, // ใช้ documentId ที่ได้จาก Firestore เป็น ID ของสินค้า
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      sellerId: data['sellerId'],
    );
  }
}