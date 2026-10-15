import 'dart:io';
import 'dart:async'; // เพิ่มบรรทัดนี้เข้ามาสำหรับจัดการเวลา Timeout
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/item.dart';
import '../repositories/listing_draft_repository.dart'; 
import '../repositories/item_repository_firestore.dart';
import '../services/storage_service.dart';

import 'sell_item_page.dart'; 

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const MyDraftsPage({super.key, required this.draftRepository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  Future<List<dynamic>> _loadDrafts() async {
    return await widget.draftRepository.getAllDrafts();
  }

  Future<double?> _askForPrice(BuildContext context) async {
    final priceController = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ตั้งราคาสินค้า'),
          content: TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'ราคา (บาท)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(priceController.text);
                if (parsed != null && parsed > 0) {
                  Navigator.pop(context, parsed);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกราคาให้ถูกต้อง (มากกว่า 0)')),
                  );
                }
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _postDraftToFirestore(dynamic draftRow) async {
    final price = await _askForPrice(context);
    if (price == null) return; 

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageFile = File(draftRow.imagePath);
      
      // เพิ่ม .timeout(...) ถ้าโหลดเกิน 5 วินาทีให้ถือว่า Error ทันที
      final downloadUrl = await StorageService()
          .uploadListingImage(imageFile, user.uid)
          .timeout(const Duration(seconds: 5));

      final newItem = Item(
        id: DateTime.now().millisecondsSinceEpoch.toString(), 
        title: draftRow.title,
        price: price,
        description: draftRow.description,
        category: draftRow.category,
        imageUrl: downloadUrl, 
        sellerId: user.uid,
      );

      // เพิ่ม .timeout(...) ตรงบันทึกข้อมูลเช่นกัน
      await ItemRepositoryFirestore()
          .postItem(newItem)
          .timeout(const Duration(seconds: 5));
          
      await widget.draftRepository.deleteDraft(draftRow.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โพสต์ขายสำเร็จ!')),
        );
        setState(() {}); 
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ปิดหน้าต่างโหลดที่หมุนค้าง
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการโพสต์: ขาดการเชื่อมต่อเครือข่าย ไม่สามารถเข้าถึง Cloud Firestore (Offline)',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการร่าง (My Drafts)'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadDrafts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีรายการร่าง'));
          }

          final drafts = snapshot.data!;
          
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: draft.imagePath.isNotEmpty
                      ? Image.file(
                          File(draft.imagePath),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 60),
                  title: Text(draft.title),
                  subtitle: Text(draft.category),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: const Text('โพสต์ขายจริง'),
                    onPressed: () => _postDraftToFirestore(draft),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SellItemPage(
                draftRepository: widget.draftRepository,
              ),
            ),
          );
          setState(() {}); 
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}