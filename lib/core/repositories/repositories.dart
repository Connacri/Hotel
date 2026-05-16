import 'package:sqlite3/sqlite3.dart';
import '../models/room_model.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────
// RoomRepository
// ─────────────────────────────────────────────
class RoomRepository {
  final Database _db;
  RoomRepository(this._db);

  List<RoomModel> getAll() {
    final rows = _db.select(
      'SELECT * FROM room_info ORDER BY bld_no, flr_no, CAST(room_no AS INTEGER)',
    );
    return rows.map(RoomModel.fromRow).toList();
  }

  List<RoomModel> getByFloor(int flrNo) {
    final rows = _db.select(
      'SELECT * FROM room_info WHERE flr_no = ? ORDER BY CAST(room_no AS INTEGER)',
      [flrNo],
    );
    return rows.map(RoomModel.fromRow).toList();
  }

  List<RoomModel> getByStatus(String status) {
    final rows = _db.select(
      'SELECT * FROM room_info WHERE status = ?',
      [status],
    );
    return rows.map(RoomModel.fromRow).toList();
  }

  RoomModel? getByRoomNo(String roomNo) {
    final rows = _db.select(
      'SELECT * FROM room_info WHERE room_no = ? LIMIT 1',
      [roomNo],
    );
    return rows.isEmpty ? null : RoomModel.fromRow(rows.first);
  }

  Map<String, int> getStats() {
    final total = _db.select('SELECT COUNT(*) as c FROM room_info').first['c'] as int;
    final occupied = _db.select("SELECT COUNT(*) as c FROM room_info WHERE status='Guest'").first['c'] as int;
    final vacant = _db.select("SELECT COUNT(*) as c FROM room_info WHERE status='Vacant'").first['c'] as int;
    return {'total': total, 'occupied': occupied, 'vacant': vacant};
  }

  void updateStatus(int id, String status) {
    _db.execute('UPDATE room_info SET status=? WHERE id=?', [status, id]);
  }

  void updateCardCount(int id, int count) {
    _db.execute('UPDATE room_info SET card_count=? WHERE id=?', [count, id]);
  }

  void insert(RoomModel room) {
    final m = room.toMap();
    _db.execute('''
      INSERT INTO room_info
      (bld_no,flr_no,rom_id,room_no,s_type,status,price,dai,card_count,max_cards,bei_zhu)
      VALUES (?,?,?,?,?,?,?,?,?,?,?)
    ''', [
      m['bld_no'], m['flr_no'], m['rom_id'], m['room_no'],
      m['s_type'], m['status'], m['price'], m['dai'],
      m['card_count'], m['max_cards'], m['bei_zhu'],
    ]);
  }

  void update(RoomModel room) {
    _db.execute('''
      UPDATE room_info SET
        status=?, price=?, card_count=?, s_type=?, bei_zhu=?, first_ck_out=?
      WHERE id=?
    ''', [
      room.status, room.price, room.cardCount, room.sType,
      room.beiZhu, room.firstCkOut, room.id,
    ]);
  }

  void delete(int id) {
    _db.execute('DELETE FROM room_info WHERE id=?', [id]);
  }
}

// ─────────────────────────────────────────────
// GuestRepository
// ─────────────────────────────────────────────
class GuestRepository {
  final Database _db;
  GuestRepository(this._db);

  List<GuestModel> getAll() {
    final rows = _db.select(
      'SELECT * FROM guest_info ORDER BY id DESC',
    );
    return rows.map(GuestModel.fromRow).toList();
  }

  List<GuestModel> getByRoom(String bldRoomNo) {
    final rows = _db.select(
      'SELECT * FROM guest_info WHERE bld_room_no=? ORDER BY come_time DESC',
      [bldRoomNo],
    );
    return rows.map(GuestModel.fromRow).toList();
  }

  List<GuestModel> search(String query) {
    final q = '%$query%';
    final rows = _db.select(
      'SELECT * FROM guest_info WHERE name LIKE ? OR card_id LIKE ? OR bld_room_no LIKE ?',
      [q, q, q],
    );
    return rows.map(GuestModel.fromRow).toList();
  }

  int insert(GuestModel guest) {
    final m = guest.toMap();
    _db.execute('''
      INSERT INTO guest_info
      (bld_room_no,name,sex,c_type,c_no,come_time,go_time,card_id,flag,bei_zhu,price,ya_jin)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
    ''', [
      m['bld_room_no'], m['name'], m['sex'], m['c_type'], m['c_no'],
      m['come_time'], m['go_time'], m['card_id'], m['flag'],
      m['bei_zhu'], m['price'], m['ya_jin'],
    ]);
    return _db.lastInsertRowId;
  }

  void updateCheckout(int id, String goTime) {
    _db.execute('UPDATE guest_info SET go_time=? WHERE id=?', [goTime, id]);
  }

  void delete(int id) {
    _db.execute('DELETE FROM guest_info WHERE id=?', [id]);
  }
}

// ─────────────────────────────────────────────
// CardRepository
// ─────────────────────────────────────────────
class CardRepository {
  final Database _db;
  CardRepository(this._db);

  List<CardModel> getAll() {
    final rows = _db.select('SELECT * FROM card_info ORDER BY id DESC');
    return rows.map(CardModel.fromRow).toList();
  }

  List<CardModel> getByHolder(String holder) {
    final rows = _db.select(
      'SELECT * FROM card_info WHERE holder=?',
      [holder],
    );
    return rows.map(CardModel.fromRow).toList();
  }

  Map<String, int> getStats() {
    final total = _db.select('SELECT COUNT(*) as c FROM card_info').first['c'] as int;
    final erased = _db.select("SELECT COUNT(*) as c FROM card_info WHERE status LIKE '%Erased%'").first['c'] as int;
    final active = total - erased;
    return {'total': total, 'active': active, 'erased': erased};
  }

  int insert(CardModel card) {
    _db.execute('''
      INSERT INTO card_info (card_data,holder,gong_hao,bei_zhu,status)
      VALUES (?,?,?,?,?)
    ''', [card.cardData, card.holder, card.gongHao, card.beiZhu, card.status]);
    return _db.lastInsertRowId;
  }

  void updateStatus(int id, String status) {
    _db.execute('UPDATE card_info SET status=? WHERE id=?', [status, id]);
  }

  void delete(int id) {
    _db.execute('DELETE FROM card_info WHERE id=?', [id]);
  }
}

// ─────────────────────────────────────────────
// OperatorRepository
// ─────────────────────────────────────────────
class OperatorRepository {
  final Database _db;
  OperatorRepository(this._db);

  List<OperatorModel> getAll() {
    final rows = _db.select('SELECT * FROM operator_info ORDER BY gong_hao');
    return rows.map(OperatorModel.fromRow).toList();
  }

  OperatorModel? getByLogin(String gongHao) {
    final rows = _db.select(
      'SELECT * FROM operator_info WHERE gong_hao=? LIMIT 1',
      [gongHao],
    );
    return rows.isEmpty ? null : OperatorModel.fromRow(rows.first);
  }

  /// Authentification — retourne l'opérateur si credentials valides
  OperatorModel? authenticate(String gongHao, String miMa) {
    final rows = _db.select(
      'SELECT * FROM operator_info WHERE gong_hao=? AND mi_ma=? LIMIT 1',
      [gongHao, miMa],
    );
    return rows.isEmpty ? null : OperatorModel.fromRow(rows.first);
  }

  void insert(OperatorModel op) {
    _db.execute('''
      INSERT OR REPLACE INTO operator_info (gong_hao,name,mi_ma,quan_xian,bei_zhu)
      VALUES (?,?,?,?,?)
    ''', [op.gongHao, op.name, op.miMa, op.quanXian, op.beiZhu]);
  }

  void updatePassword(String gongHao, String newMiMa) {
    _db.execute(
      'UPDATE operator_info SET mi_ma=? WHERE gong_hao=?',
      [newMiMa, gongHao],
    );
  }

  void delete(String gongHao) {
    _db.execute('DELETE FROM operator_info WHERE gong_hao=?', [gongHao]);
  }
}

// ─────────────────────────────────────────────
// RecordOpenRepository
// ─────────────────────────────────────────────
class RecordOpenRepository {
  final Database _db;
  RecordOpenRepository(this._db);

  List<RecordOpenModel> getAll({int limit = 200}) {
    final rows = _db.select(
      'SELECT * FROM record_open WHERE rec_data != ? ORDER BY id DESC LIMIT ?',
      ['FFFFFFFFFFFFFFFF', limit],
    );
    return rows.map(RecordOpenModel.fromRow).toList();
  }

  List<RecordOpenModel> getDoorOpenings() {
    final rows = _db.select(
      "SELECT * FROM record_open WHERE order_flag=0 AND rec_data != 'FFFFFFFFFFFFFFFF' ORDER BY id DESC",
    );
    return rows.map(RecordOpenModel.fromRow).toList();
  }

  void insert(RecordOpenModel record) {
    _db.execute(
      'INSERT INTO record_open (order_flag,rec_data,open_time) VALUES (?,?,?)',
      [record.orderFlag, record.recData, record.openTime],
    );
  }
}
