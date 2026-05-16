import 'package:sqlite3/sqlite3.dart';
import '../models/models.dart';

class RoomRepository {
  static const String tableName = 'room_info';

  final Database _db;
  RoomRepository(this._db);

  List<RoomModel> getAll() {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName ORDER BY bld_no, flr_no, CAST(room_no AS INTEGER)',
      );
      return rows.map(RoomModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  List<RoomModel> getByFloor(int flrNo) {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE flr_no = ? ORDER BY CAST(room_no AS INTEGER)',
        [flrNo],
      );
      return rows.map(RoomModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch rooms for floor $flrNo: $e');
    }
  }

  List<RoomModel> getByStatus(String status) {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE status = ?',
        [status],
      );
      return rows.map(RoomModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch rooms with status $status: $e');
    }
  }

  RoomModel? getByRoomNo(String roomNo) {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE room_no = ? LIMIT 1',
        [roomNo],
      );
      return rows.isEmpty ? null : RoomModel.fromRow(rows.first);
    } catch (e) {
      throw Exception('Failed to fetch room by number $roomNo: $e');
    }
  }

  Map<String, int> getStats() {
    try {
      final total = _db.select('SELECT COUNT(*) as c FROM $tableName').first['c'] as int;
      final occupied = _db.select("SELECT COUNT(*) as c FROM $tableName WHERE status='Guest'").first['c'] as int;
      final vacant = _db.select("SELECT COUNT(*) as c FROM $tableName WHERE status='Vacant'").first['c'] as int;
      return {'total': total, 'occupied': occupied, 'vacant': vacant};
    } catch (e) {
      return {'total': 0, 'occupied': 0, 'vacant': 0};
    }
  }

  void updateStatus(int id, String status) {
    try {
      _db.execute('UPDATE $tableName SET status=? WHERE id=?', [status, id]);
    } catch (e) {
      throw Exception('Failed to update room status: $e');
    }
  }

  void updateCardCount(int id, int count) {
    try {
      _db.execute('UPDATE $tableName SET card_count=? WHERE id=?', [count, id]);
    } catch (e) {
      throw Exception('Failed to update room card count: $e');
    }
  }

  void insert(RoomModel room) {
    try {
      final m = room.toMap();
      _db.execute('''
        INSERT INTO $tableName
        (bld_no,flr_no,rom_id,room_no,s_type,status,price,dai,card_count,max_cards,bei_zhu)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
      ''', [
        m['bld_no'], m['flr_no'], m['rom_id'], m['room_no'],
        m['s_type'], m['status'], m['price'], m['dai'],
        m['card_count'], m['max_cards'], m['bei_zhu'],
      ]);
    } catch (e) {
      throw Exception('Failed to insert room: $e');
    }
  }

  void update(RoomModel room) {
    try {
      _db.execute('''
        UPDATE $tableName SET
          status=?, price=?, card_count=?, s_type=?, bei_zhu=?, first_ck_out=?
        WHERE id=?
      ''', [
        room.status, room.price, room.cardCount, room.sType,
        room.beiZhu, room.firstCkOut, room.id,
      ]);
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  void delete(int id) {
    try {
      _db.execute('DELETE FROM $tableName WHERE id=?', [id]);
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }
}
