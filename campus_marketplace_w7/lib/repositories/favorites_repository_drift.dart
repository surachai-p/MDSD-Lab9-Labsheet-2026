import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;
  FavoritesRepositoryDrift(this._db);

  @override
  Future<void> addFavorite(
      int itemId, String title, double price, String imageUrl) async {
    final rowId = await _db.into(_db.favoriteItems).insert(
          FavoriteItemsCompanion.insert(
            itemId: itemId,
            title: title,
            price: price,
            imageUrl: imageUrl,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    debugPrint('FAV add: itemId=$itemId rowId=$rowId');
  }

  @override
  Future<List<FavoriteItem>> getAllFavorites() async {
    final rows = await (_db.select(_db.favoriteItems)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .get();
    debugPrint('FAV read: ${rows.length} rows');
    return rows;
  }

  @override
  Future<void> removeFavorite(int itemId) async {
    await (_db.delete(_db.favoriteItems)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
    debugPrint('FAV remove: itemId=$itemId');
  }
}