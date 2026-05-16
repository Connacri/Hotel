import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

class MdbMigrator {
  final Database _db;
  final String mdbPath;

  MdbMigrator({required Database db, required this.mdbPath}) : _db = db;

  /// Chemin vers mdb-export selon la plateforme
  String get _mdbExport {
    if (Platform.isWindows) {
      // Chercher mdb-export.exe bundlé à côté de l'exécutable
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final bundled = p.join(exeDir, 'mdb-export.exe');
      if (File(bundled).existsSync()) return bundled;
      // Fallback : PATH système (msys2 installé)
      return 'mdb-export';
    }
    return 'mdb-export';
  }

  Future<void> migrate({void Function(String table)? onProgress}) async {
    final tables = [
      _MdbTable(
        name: 'BuildingInfo',
        sql: 'INSERT OR IGNORE INTO building_info (bld_no, bld_name) VALUES (?,?)',
        mapper: (r) => [_i(r[0]), r[1]],
      ),
      _MdbTable(
        name: 'RoomInfo',
        sql: '''INSERT OR IGNORE INTO room_info
          (bld_no,flr_no,rom_id,rom_id2,room_no,s_type,status,price,dai,
           card_count,max_cards,public_door,bei_zhu,first_ck_out,
           hour_rate_startup,hour_rate_price,reserv_ck_in)
          VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
        mapper: (r) => [
          _i(r[0]), _i(r[1]), _i(r[2]), _i(r[3]), r[4],
          r[5], r[6], _d(r[7]), _i(r[8]),
          _i(r[9]), _i(r[10]), _i(r[11]), r[12], r[13],
          _d(r[14]), _d(r[15]), r[16],
        ],
      ),
      _MdbTable(
        name: 'GuestInfo',
        sql: '''INSERT OR IGNORE INTO guest_info
          (id,bld_room_no,name,sex,c_type,c_no,come_time,go_time,
           card_id,flag,bei_zhu,price,ya_jin)
          VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)''',
        mapper: (r) => [
          _i(r[12]), r[0], r[1], r[2], r[3], r[4],
          r[5], r[6], r[7], r[8], r[9],
          _d(r[10]), _d(r[11]),
        ],
      ),
      _MdbTable(
        name: 'CardInfo',
        sql: '''INSERT OR IGNORE INTO card_info
          (id,card_data,holder,gong_hao,bei_zhu,status)
          VALUES (?,?,?,?,?,?)''',
        mapper: (r) => [_i(r[0]), r[1], r[2], r[3], r[4], r[5]],
      ),
      _MdbTable(
        name: 'OperatorInfo',
        sql: '''INSERT OR IGNORE INTO operator_info
          (gong_hao,name,mi_ma,quan_xian,bei_zhu)
          VALUES (?,?,?,?,?)''',
        mapper: (r) => [r[0], r[1], r[2], r[3], r[4]],
      ),
      _MdbTable(
        name: 'RecordOpen',
        sql: 'INSERT OR IGNORE INTO record_open (order_flag,rec_data,open_time) VALUES (?,?,?)',
        mapper: (r) => [_i(r[0]), r[1], r[2]],
      ),
    ];

    for (final table in tables) {
      onProgress?.call(table.name);
      await _migrateTable(table);
    }

    _db.execute(
      "INSERT OR REPLACE INTO migration_status (key,value) VALUES ('mdb_migrated','1')",
    );
  }

  Future<void> _migrateTable(_MdbTable table) async {
    final csv = await _export(table.name);
    if (csv.isEmpty) return;

    final lines = csv.split('\n');
    if (lines.length < 2) return;

    final stmt = _db.prepare(table.sql);
    _db.execute('BEGIN');
    try {
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final cols = _parseCsv(line);
          if (cols.isEmpty) continue;
          stmt.execute(table.mapper(cols));
        } catch (_) {
          // Ligne corrompue — on continue
        }
      }
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.dispose();
    }
  }

  Future<String> _export(String table) async {
    try {
      final result = await Process.run(
        _mdbExport,
        [mdbPath, table],
        runInShell: Platform.isWindows,
      );
      if (result.exitCode != 0) return '';
      return (result.stdout as String).trim();
    } catch (_) {
      return '';
    }
  }

  /// Parse CSV Access (gère guillemets doubles échappés)
  List<String> _parseCsv(String line) {
    final result = <String>[];
    var inQuote = false;
    final current = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuote && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuote = !inQuote;
        }
      } else if (ch == ',' && !inQuote) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  int? _i(String? s) {
    if (s == null || s.isEmpty) return null;
    return int.tryParse(s.replaceAll('"', '').trim());
  }

  double? _d(String? s) {
    if (s == null || s.isEmpty) return null;
    return double.tryParse(s.replaceAll('"', '').trim());
  }
}

class _MdbTable {
  final String name;
  final String sql;
  final List<Object?> Function(List<String>) mapper;

  const _MdbTable({
    required this.name,
    required this.sql,
    required this.mapper,
  });
}
