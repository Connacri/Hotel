import 'package:sqlite3/sqlite3.dart';
import '../models/models.dart';

class CardRepository {
  static const String tableName = 'card_info';

  final Database _db;
  CardRepository(this._db);

  List<CardModel> getAll() {
    try {
      final rows = _db.select('SELECT * FROM $tableName ORDER BY id DESC');
      return rows.map(CardModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch cards: $e');
    }
  }

  List<CardModel> getByHolder(String holder) {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE holder=?',
        [holder],
      );
      return rows.map(CardModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch cards for holder $holder: $e');
    }
  }

  Map<String, int> getStats() {
    try {
      final total = _db.select('SELECT COUNT(*) as c FROM $tableName').first['c'] as int;
      final erased = _db.select("SELECT COUNT(*) as c FROM $tableName WHERE status LIKE '%Erased%'").first['c'] as int;
      final active = total - erased;
      return {'total': total, 'active': active, 'erased': erased};
    } catch (e) {
      return {'total': 0, 'active': 0, 'erased': 0};
    }
  }

  int insert(CardModel card) {
    try {
      _db.execute('''
        INSERT INTO $tableName (card_data,holder,gong_hao,bei_zhu,status)
        VALUES (?,?,?,?,?)
      ''', [card.cardData, card.holder, card.gongHao, card.beiZhu, card.status]);
      return _db.lastInsertRowId;
    } catch (e) {
      throw Exception('Failed to insert card: $e');
    }
  }

  void updateStatus(int id, String status) {
    try {
      _db.execute('UPDATE $tableName SET status=? WHERE id=?', [status, id]);
    } catch (e) {
      throw Exception('Failed to update card status: $e');
    }
  }

  void delete(int id) {
    try {
      _db.execute('DELETE FROM $tableName WHERE id=?', [id]);
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }
}
