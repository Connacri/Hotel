import 'package:sqlite3/sqlite3.dart';
import '../models/models.dart';

class GuestRepository {
  static const String tableName = 'guest_info';

  final Database _db;
  GuestRepository(this._db);

  List<GuestModel> getAll() {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName ORDER BY id DESC',
      );
      return rows.map(GuestModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch guests: $e');
    }
  }

  List<GuestModel> getByRoom(String bldRoomNo) {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE bld_room_no=? ORDER BY come_time DESC',
        [bldRoomNo],
      );
      return rows.map(GuestModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch guests for room $bldRoomNo: $e');
    }
  }

  List<GuestModel> search(String query) {
    try {
      final q = '%$query%';
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE name LIKE ? OR card_id LIKE ? OR bld_room_no LIKE ?',
        [q, q, q],
      );
      return rows.map(GuestModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to search guests: $e');
    }
  }

  int insert(GuestModel guest) {
    try {
      final m = guest.toMap();
      _db.execute('''
        INSERT INTO $tableName
        (bld_room_no,name,sex,c_type,c_no,come_time,go_time,card_id,flag,bei_zhu,price,ya_jin)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
      ''', [
        m['bld_room_no'], m['name'], m['sex'], m['c_type'], m['c_no'],
        m['come_time'], m['go_time'], m['card_id'], m['flag'],
        m['bei_zhu'], m['price'], m['ya_jin'],
      ]);
      return _db.lastInsertRowId;
    } catch (e) {
      throw Exception('Failed to insert guest: $e');
    }
  }

  void updateCheckout(int id, String goTime) {
    try {
      _db.execute('UPDATE $tableName SET go_time=? WHERE id=?', [goTime, id]);
    } catch (e) {
      throw Exception('Failed to update guest checkout: $e');
    }
  }

  void delete(int id) {
    try {
      _db.execute('DELETE FROM $tableName WHERE id=?', [id]);
    } catch (e) {
      throw Exception('Failed to delete guest: $e');
    }
  }
}
