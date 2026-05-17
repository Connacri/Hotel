import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalDatabase {
  static LocalDatabase? _instance;
  late final Database _db;
  String? _mdbPath;

  LocalDatabase._();

  static Future<LocalDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = LocalDatabase._();
    await _instance!._init();
    return _instance!;
  }

  Future<void> _init() async {
    final path = await _resolvePath();
    _db = sqlite3.open(path);
    _db.execute('PRAGMA journal_mode=WAL;');
    _db.execute('PRAGMA foreign_keys=ON;');
    _db.execute('PRAGMA synchronous=NORMAL;');
    await _runMigrations();
  }

  Future<String> _resolvePath() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Directory.current.path;
      final dir = Directory(p.join(appData, 'CardLock'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return p.join(dir.path, 'cardlock.db');
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'cardlock.db');
  }

  Future<void> _runMigrations() async {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS building_info (
        bld_no   INTEGER PRIMARY KEY,
        bld_name TEXT    NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS room_info (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        bld_no            INTEGER NOT NULL DEFAULT 1,
        flr_no            INTEGER NOT NULL DEFAULT 1,
        rom_id            INTEGER NOT NULL DEFAULT 0,
        rom_id2           INTEGER DEFAULT 99,
        room_no           TEXT    NOT NULL,
        s_type            TEXT,
        status            TEXT    DEFAULT 'Vacant',
        price             REAL    DEFAULT 0,
        dai               INTEGER DEFAULT 0,
        card_count        INTEGER DEFAULT 0,
        max_cards         INTEGER DEFAULT 10,
        public_door       INTEGER DEFAULT 0,
        bei_zhu           TEXT,
        first_ck_out      TEXT,
        hour_rate_startup REAL    DEFAULT 0,
        hour_rate_price   REAL    DEFAULT 0,
        reserv_ck_in      TEXT
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS guest_info (
        id          INTEGER PRIMARY KEY,
        bld_room_no TEXT    NOT NULL,
        name        TEXT,
        sex         TEXT,
        c_type      TEXT,
        c_no        TEXT,
        come_time   TEXT,
        go_time     TEXT,
        card_id     TEXT,
        flag        TEXT,
        bei_zhu     TEXT,
        price       REAL    DEFAULT 0,
        ya_jin      REAL    DEFAULT 0
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS card_info (
        id        INTEGER PRIMARY KEY,
        card_data TEXT,
        holder    TEXT,
        gong_hao  TEXT,
        bei_zhu   TEXT,
        status    TEXT
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS operator_info (
        gong_hao  TEXT PRIMARY KEY,
        name      TEXT NOT NULL,
        mi_ma     TEXT NOT NULL DEFAULT '',
        quan_xian TEXT,
        bei_zhu   TEXT
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS record_open (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        order_flag INTEGER DEFAULT 0,
        rec_data   TEXT,
        open_time  TEXT
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS log_info (
        id        INTEGER PRIMARY KEY,
        operator  TEXT,
        log_time  TEXT,
        exit_time TEXT
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS migration_status (
        key   TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    // Index performance
    _db.execute('CREATE INDEX IF NOT EXISTS idx_room_status ON room_info(status);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_room_no ON room_info(room_no);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_guest_room ON guest_info(bld_room_no);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_card_holder ON card_info(holder);');
  }

  Database get db => _db;

  String? get mdbPath {
    if (_mdbPath != null) return _mdbPath;
    final rows = _db.select(
      "SELECT value FROM migration_status WHERE key = 'mdb_path'",
    );
    if (rows.isNotEmpty) {
      _mdbPath = rows.first['value'] as String?;
    }
    return _mdbPath;
  }

  set mdbPath(String? path) {
    _mdbPath = path;
    if (path != null) {
      _db.execute(
        "INSERT OR REPLACE INTO migration_status (key, value) VALUES ('mdb_path', ?)",
        [path],
      );
    }
  }

  bool get isMigrated {
    final rows = _db.select(
      "SELECT value FROM migration_status WHERE key = 'mdb_migrated'",
    );
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  void markMigrated() {
    _db.execute(
      "INSERT OR REPLACE INTO migration_status (key, value) VALUES ('mdb_migrated', '1')",
    );
  }

  void dispose() {
    _db.dispose();
    _instance = null;
  }
}
