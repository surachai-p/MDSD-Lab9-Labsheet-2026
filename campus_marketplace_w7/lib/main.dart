import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// นำเข้าส่วนของ Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// นำเข้า Model, Database และ Repositories
import 'models/cart_model.dart';
import 'database/app_database.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/item_repository_firestore.dart'; // เพิ่ม Firestore Repo
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = AppDatabase();

  runApp(
    ChangeNotifierProvider<CartModel>(
      create: (context) => CartModel(),
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthGate(
        // เปลี่ยนจากใส่แค่ API เป็นใส่ List ที่มีทั้ง API และ Firestore
        itemRepositories: [
          ItemRepositoryApi(),
          ItemRepositoryFirestore(),
        ],
        favoritesRepository: FavoritesRepositoryDrift(db),
        draftRepository: ListingDraftRepositoryDrift(db),
      ),
    );
  }
}