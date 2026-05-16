import 'package:sqlite3/sqlite3.dart';
import '../models/models.dart';

class RecordOpenRepository {
  static const String tableName = 'record_open';

  final Database _db;
  RecordOpenRepository(this._db);

  List<RecordOpenModel> getAll({int limit = 200}) {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE rec_data != ? ORDER BY id DESC LIMIT ?',
        ['FFFFFFFFFFFFFFFF', limit],
      );
      return rows.map(RecordOpenModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch records: $e');
    }
  }

  List<RecordOpenModel> getDoorOpenings() {
    try {
      final rows = _db.select(
        "SELECT * FROM $tableName WHERE order_flag=0 AND rec_data != 'FFFFFFFFFFFFFFFF' ORDER BY id DESC",
      );
      return rows.map(RecordOpenModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch door openings: $e');
    }
  }

  void insert(RecordOpenModel record) {
    try {
      _db.execute(
        'INSERT INTO $tableName (order_flag,rec_data,open_time) VALUES (?,?,?)',
        [record.orderFlag, record.recData, record.openTime],
      );
    } catch (e) {
      throw Exception('Failed to insert record: $e');
    }
  }
}
