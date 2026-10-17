import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    _draftsFuture = widget.repository.getAllDrafts();
  }

  Future<void> _deleteDraft(int id, String title) async {
    await widget.repository.deleteDraft(id);
    setState(() {
      _loadDrafts();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ลบร่างประกาศ "$title" แล้ว')));
  }

  Future<double?> _promptForPrice() async {
    return showDialog<double>(
      context: context,
      builder: (_) => const _PricePromptDialog(),
    );
  }

  Future<void> _postDraft(ListingDraftRow draft) async {
    final price = await _promptForPrice();
    if (price == null || !mounted) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final sellerId = FirebaseAuth.instance.currentUser!.uid;
      const imageUrl = 'https://placehold.co/400x400.png?text=No+Image';
      final item = Item(
        id: '',
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: sellerId,
      );

      await ItemRepositoryFirestore().postItem(item);
      await widget.repository.deleteDraft(draft.id);

      if (!mounted) return;
      setState(() {
        _loadDrafts();
        _isPosting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('โพสต์ขายจริงสำเร็จ')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โพสต์ขายจริงไม่สำเร็จ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
      body: Stack(
        children: [
          FutureBuilder<List<ListingDraftRow>>(
            future: _draftsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
              }

              final drafts = snapshot.data ?? [];

              if (drafts.isEmpty) {
                return const Center(
                  child: Text(
                    'ยังไม่มีร่างประกาศที่บันทึกไว้',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  final draft = drafts[index];
                  final imageFile = File(draft.imagePath);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: imageFile.existsSync()
                          ? Image.file(
                              imageFile,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image, size: 50),
                      title: Text(
                        draft.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'หมวดหมู่: ${draft.category}\nแก้ไขล่าสุด: ${draft.updatedAt.toLocal().toString().substring(0, 16)}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _deleteDraft(draft.id, draft.title),
                          ),
                          IconButton(
                            icon: const Icon(Icons.upload, color: Colors.blue),
                            tooltip: 'โพสต์ขายจริง',
                            onPressed: _isPosting
                                ? null
                                : () => _postDraft(draft),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isPosting)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Text(
                            'กำลังอัปโหลดและโพสต์...',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PricePromptDialog extends StatefulWidget {
  const _PricePromptDialog();

  @override
  State<_PricePromptDialog> createState() => _PricePromptDialogState();
}

class _PricePromptDialogState extends State<_PricePromptDialog> {
  final _priceController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || !price.isFinite || price <= 0) {
      setState(() {
        _validationError = 'กรุณากรอกราคาเป็นตัวเลขที่มากกว่า 0';
      });
      return;
    }
    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ระบุราคาสินค้า'),
      content: TextField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'ราคา',
          suffixText: 'บาท',
          errorText: _validationError,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }
}
