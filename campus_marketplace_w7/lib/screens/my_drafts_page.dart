import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _draftsFuture = widget.repository.getAllDrafts();
  }

  void _reload() {
    setState(() {
      _draftsFuture = widget.repository.getAllDrafts();
    });
  }

  Future<void> _deleteDraft(int id, String title) async {
    try {
      await widget.repository.deleteDraft(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบร่าง "$title" แล้ว')),
        );
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _publishDraft(ListingDraftRow draft) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์ขายสินค้า'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // 1. แสดง Dialog ถามราคาสินค้าก่อนเสมอ และตรวจสอบค่าตัวเลข > 0
    final confirmedPrice = await showDialog<double>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('ระบุราคาสำหรับ "${draft.title}"'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('กรุณากรอกราคาขายสินค้า (บาท):'),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ราคา (บาท)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  hintText: 'เช่น 150.00',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกราคา';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'ราคาต้องเป็นตัวเลขที่มากกว่า 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final price = double.parse(priceController.text.trim());
                Navigator.pop(dialogCtx, price);
              }
            },
            child: const Text('ยืนยันโพสต์'),
          ),
        ],
      ),
    );

    if (confirmedPrice == null) return; // กดยกเลิก

    if (!mounted) return;

    // 2. แสดง Progress Indicator ระหว่างอัปโหลด (หัวข้อ 9.7)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingCtx) => const Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'กำลังอัปโหลดรูปภาพและโพสต์ขาย...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 3. อัปโหลดรูปจาก draft.imagePath ขึ้น Storage ผ่าน StorageService
      String downloadUrl = '';
      final imageFile = File(draft.imagePath);
      if (imageFile.existsSync()) {
        final storageService = StorageService();
        downloadUrl = await storageService.uploadListingImage(imageFile, user.uid);
      } else {
        downloadUrl = 'https://picsum.photos/400/400';
      }

      // 4. สร้าง Item จากข้อมูลร่าง + ราคาที่กรอก + sellerId
      final item = Item(
        id: DateTime.now().millisecondsSinceEpoch,
        title: draft.title,
        price: confirmedPrice,
        description: draft.description,
        category: draft.category,
        imageUrl: downloadUrl,
        sellerId: user.uid,
      );

      // 5. เขียนเอกสารลง Firestore
      final firestoreRepo = ItemRepositoryFirestore();
      await firestoreRepo.postItem(item);

      // 6. ลบร่างออกจาก Local Database หลังโพสต์สำเร็จ
      await widget.repository.deleteDraft(draft.id);

      if (mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
        _reload(); // รีเฟรชหน้าร่างประกาศ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โพสต์ขาย "${draft.title}" บน Campus Marketplace สำเร็จ! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโพสต์: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
      ),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          // สถานะที่ 1: กำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // สถานะที่ 2: เกิดข้อผิดพลาด
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final drafts = snapshot.data ?? [];

          // สถานะที่ 3: ยังไม่มีร่าง
          if (drafts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีร่างประกาศ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'กลับไปถ่ายรูปสินค้าและให้ AI ช่วยแนะนำดูสิ 📸',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // สถานะที่ 4: มีข้อมูล
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final hasImage = draft.imagePath.isNotEmpty && File(draft.imagePath).existsSync();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(draft.imagePath),
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.edit_note),
                          ),
                    title: Text(
                      draft.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('หมวดหมู่: ${draft.category}'),
                        Text(
                          'แก้ไขล่าสุด: ${_formatDate(draft.updatedAt)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                              label: const Text('โพสต์ขายจริง'),
                              onPressed: () => _publishDraft(draft),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'ลบร่างนี้',
                              onPressed: () => _deleteDraft(draft.id, draft.title),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
