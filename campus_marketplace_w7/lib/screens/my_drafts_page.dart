import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const MyDraftsPage({super.key, required this.draftRepository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    setState(() {
      _draftsFuture = widget.draftRepository.getAllDrafts();
    });
  }

  Future<void> _deleteDraft(int id) async {
    try {
      await widget.draftRepository.deleteDraft(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบร่างประกาศแล้ว')),
        );
      }
      _loadDrafts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
        );
      }
    }
  }

  Future<void> _publishDraft(ListingDraftRow draft) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทำการโพสต์ขาย')),
      );
      return;
    }

    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final price = await showDialog<double>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('ระบุราคาสินค้า'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สินค้า: ${draft.title}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ราคา (บาท)',
                  prefixText: '฿ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'กรุณาระบุราคาสินค้า';
                  }
                  final parsed = double.tryParse(val.trim());
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
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final val = double.parse(priceController.text.trim());
                Navigator.of(dialogCtx).pop(val);
              }
            },
            child: const Text('ยืนยันและโพสต์'),
          ),
        ],
      ),
    );

    if (price == null || !mounted) return;

    // แสดง Loading Dialog ระหว่างดำเนินการ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังโพสต์สินค้าขึ้น Firestore...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final imageFile = File(draft.imagePath);

      // หมายเหตุ: Firebase Storage ต้องใช้ Blaze plan
      // ใช้ imagePath ท้องถิ่นเป็น placeholder แทน (สำหรับ Lab 9)
      final String imageUrl = imageFile.existsSync()
          ? 'file://${draft.imagePath}'
          : '';

      // สร้าง Item พร้อม sellerId แล้วบันทึกลง Firestore
      final item = Item(
        id: '',
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: user.uid,
      );

      await ItemRepositoryFirestore().postItem(item);

      // 3. ลบร่างออกจาก Local Database หลังโพสต์สำเร็จ
      await widget.draftRepository.deleteDraft(draft.id);

      // ปิด Loading Dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // รีเฟรชรายการร่างบนหน้าจอ
      _loadDrafts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('โพสต์ขายสินค้าสำเร็จแล้ว!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // ปิด Loading Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโพสต์: $e'),
            backgroundColor: Colors.red,
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
            tooltip: 'รีเฟรช',
            onPressed: _loadDrafts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadDrafts(),
        child: FutureBuilder<List<ListingDraftRow>>(
          future: _draftsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                ),
              );
            }

            final drafts = snapshot.data ?? [];
            if (drafts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'ยังไม่มีร่างประกาศที่บันทึกไว้',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                final imageFile = File(draft.imagePath);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: imageFile.existsSync()
                                    ? Image.file(imageFile, fit: BoxFit.cover)
                                    : const Icon(
                                        Icons.image_not_supported_outlined),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    draft.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'หมวดหมู่: ${draft.category}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    draft.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'ลบร่างประกาศ',
                              onPressed: () => _deleteDraft(draft.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'บันทึกเมื่อ: ${draft.updatedAt.toLocal().toString().split('.')[0]}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            FilledButton.icon(
                              icon: const Icon(Icons.cloud_upload_outlined,
                                  size: 18),
                              label: const Text('โพสต์ขายจริง'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _publishDraft(draft),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
