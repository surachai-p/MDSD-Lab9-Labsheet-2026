import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const MyDraftsPage({
    super.key,
    required this.draftRepository,
  });

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _refreshDrafts();
  }

  void _refreshDrafts() {
    setState(() {
      _draftsFuture = widget.draftRepository.getAllDrafts();
    });
  }

  Future<void> _deleteDraft(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบร่างประกาศนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await widget.draftRepository.deleteDraft(id);
    _refreshDrafts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบร่างประกาศแล้ว')),
      );
    }
  }

  Future<void> _publishDraft(ListingDraftRow draft) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์ขายสินค้า')),
      );
      return;
    }

    // 1. แสดง Dialog ถามราคาสินค้า
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('กำหนดราคาสำหรับ "${draft.title}"'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'ราคาสินค้า (บาท)',
              prefixText: '฿ ',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'กรุณากรอกราคา';
              }
              final price = double.tryParse(val.trim());
              if (price == null || price <= 0) {
                return 'กรุณากรอกราคาที่มากกว่า 0';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('ยืนยันและโพสต์'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final price = double.parse(priceController.text.trim());

    // แสดง Loading Dialog ระหว่างดำเนินการ
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('กำลังอัปโหลดรูปและโพสต์ขาย...'),
          ],
        ),
      ),
    );

    try {
      // ใช้ placeholder URL โดยตรง (ไม่ใช้ Firebase Storage)
      const String imageUrl = 'https://picsum.photos/200';

      // 3. เขียนเอกสารลง Cloud Firestore
      final newItem = Item(
        id: '',
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: user.uid,
      );

      await ItemRepositoryFirestore().postItem(newItem);

      // 4. ลบร่างออกจาก Local Database (Drift)
      await widget.draftRepository.deleteDraft(draft.id);

      if (mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
        _refreshDrafts(); // รีเฟรชหน้าร่างประกาศ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โพสต์ขาย "${draft.title}" สำเร็จแล้ว!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโพสต์: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDrafts,
          ),
        ],
      ),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
            );
          }

          final drafts = snapshot.data ?? [];

          if (drafts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drafts_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีร่างประกาศที่บันทึกไว้',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshDrafts();
              await _draftsFuture;
            },
            child: ListView.builder(
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: draft.imagePath.isNotEmpty &&
                              File(draft.imagePath).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(draft.imagePath),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey),
                            ),
                      title: Text(
                        draft.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('หมวดหมู่: ${draft.category}'),
                          if (draft.description.isNotEmpty)
                            Text(
                              draft.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'แก้ไขล่าสุด: ${draft.updatedAt.toString().substring(0, 16)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ปุ่มโพสต์ขายจริง
                          ElevatedButton.icon(
                            icon: const Icon(Icons.cloud_upload, size: 16),
                            label: const Text('โพสต์ขายจริง'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _publishDraft(draft),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteDraft(draft.id),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
