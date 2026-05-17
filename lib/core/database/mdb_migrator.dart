import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'native_mdb_reader.dart';

class MdbMigrator {
  static const _logPrefix = '[MDB Import]';
  static const _maxLoggedRowErrors = 10;

  final Database _db;
  final String mdbPath;

  MdbMigrator({required Database db, required this.mdbPath}) : _db = db;

  /// Chemin vers mdb-export selon la plateforme
  String get _mdbExport {
    if (Platform.isWindows) {
      final candidates = [
        // 1. Dossier de l'exécutable
        p.join(p.dirname(Platform.resolvedExecutable), 'mdb-export.exe'),
        // 2. Racine du projet (développement)
        p.join(Directory.current.path, 'mdb-export.exe'),
        // 3. Dossier bin (standard)
        p.join(Directory.current.path, 'bin', 'mdb-export.exe'),
        // 4. Dossier spécifique au projet hotel
        p.join(Directory.current.path, 'installer', 'mdb-export.exe'),
      ];

      for (final path in candidates) {
        if (File(path).existsSync()) {
          _log('Found mdb-export at: $path');
          return path;
        }
      }
      
      _log('mdb-export.exe not found in expected locations.');
      _log('Checked paths: ${candidates.join(', ')}');
      return 'mdb-export'; // Fallback to PATH
    }
    return 'mdb-export';
  }

  Future<void> checkRequirements() async {
    _log('Checking requirements for "$mdbPath".');

    if (!File(mdbPath).existsSync()) {
      _log('MDB file missing at "$mdbPath".');
      throw Exception('Fichier MDB introuvable: $mdbPath');
    }

    if (NativeMdbReader.isSupported) {
      _log('Using Windows native reader.');
      await NativeMdbReader.checkRequirements(mdbPath);
      _log('Windows native reader is available.');
      return;
    }

    try {
      _log('Using mdb-export fallback.');
      final result = await Process.run(_mdbExport, ['--version'], runInShell: Platform.isWindows);
      if (result.exitCode != 0) {
        throw Exception('mdb-export binaire trouvé mais a retourné une erreur: ${result.stderr}');
      }
      _log('mdb-export requirements check passed.');
    } catch (e) {
      final checkedPaths = [
        p.join(p.dirname(Platform.resolvedExecutable), 'mdb-export.exe'),
        p.join(Directory.current.path, 'mdb-export.exe'),
        p.join(Directory.current.path, 'bin', 'mdb-export.exe'),
        p.join(Directory.current.path, 'installer', 'mdb-export.exe'),
      ].map((path) => ' - $path').join('\n');

      throw Exception(
        'mdb-export est introuvable. Veuillez installer mdbtools ou placer mdb-export.exe dans le dossier installer/.\n'
        'Chemins vérifiés :\n$checkedPaths'
      );
    }
  }

  Future<void> migrate({void Function(String table)? onProgress}) async {
    await checkRequirements();
    _log('Starting MDB migration.');

    // ─── Nettoyage des données existantes ───
    _log('Clearing existing data to prevent duplicates.');
    _db.execute('BEGIN');
    try {
      _db.execute('DELETE FROM building_info');
      _db.execute('DELETE FROM room_info');
      _db.execute('DELETE FROM guest_info');
      _db.execute('DELETE FROM card_info');
      _db.execute('DELETE FROM operator_info');
      _db.execute('DELETE FROM record_open');
      _db.execute("DELETE FROM migration_status WHERE key = 'mdb_migrated'");
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      _log('Failed to clear existing tables: $e');
      throw Exception('Impossible de vider la base de données actuelle avant l\'importation.');
    }

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
    _log('MDB migration completed successfully.');
  }

  Future<void> _migrateTable(_MdbTable table) async {
    final rows = await _readRows(table.name);
    if (rows.isEmpty) {
      _log('Table ${table.name}: no rows found.');
      return;
    }

    _log('Table ${table.name}: ${rows.length} rows loaded from source.');
    final stmt = _db.prepare(table.sql);
    _db.execute('BEGIN');
    var successCount = 0;
    var skippedCount = 0;
    try {
      for (var index = 0; index < rows.length; index++) {
        final cols = rows[index];
        try {
          final mappedData = table.mapper(cols);
          stmt.execute(mappedData);
          successCount++;
        } catch (e, st) {
          skippedCount++;
          if (skippedCount <= _maxLoggedRowErrors) {
            _log(
              'Table ${table.name}: row ${index + 1} skipped. '
              'error=$e data=${_truncate(cols.toString(), 400)}',
            );
            _log(_truncate(st.toString(), 800));
          }
        }
      }
      _db.execute('COMMIT');
      _log(
        'Table ${table.name}: committed $successCount rows, skipped $skippedCount.',
      );
      if (skippedCount > _maxLoggedRowErrors) {
        _log(
          'Table ${table.name}: ${skippedCount - _maxLoggedRowErrors} additional row errors were suppressed.',
        );
      }
    } catch (e, st) {
      _db.execute('ROLLBACK');
      _log('Table ${table.name}: rollback due to error $e');
      _log(_truncate(st.toString(), 1200));
      rethrow;
    } finally {
      stmt.dispose();
    }
  }

  Future<List<List<String?>>> _readRows(String table) async {
    if (NativeMdbReader.isSupported) {
      _log('Reading table $table via Windows native reader.');
      final rows = await NativeMdbReader.readTable(mdbPath, table);
      _log('Table $table: native reader returned ${rows.length} rows.');
      return rows;
    }

    final csv = await _export(table);
    if (csv.isEmpty) {
      _log('Table $table: empty CSV payload from mdb-export.');
      return const [];
    }

    final lines = csv.split('\n');
    if (lines.length < 2) {
      return const [];
    }

    final rows = <List<String?>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }
      rows.add(_parseCsv(line));
    }
    _log('Table $table: parsed ${rows.length} rows from CSV export.');
    return rows;
  }

  Future<String> _export(String table) async {
    try {
      _log('Exporting table $table using $_mdbExport.');
      final result = await Process.run(
        _mdbExport,
        [mdbPath, table],
        runInShell: Platform.isWindows,
      );
      if (result.exitCode != 0) {
        final errorMsg =
            'Export failed for $table with exit code ${result.exitCode}\n'
            'Stdout: ${_truncate('${result.stdout}', 600)}\n'
            'Stderr: ${_truncate('${result.stderr}', 600)}';
        _log(errorMsg);
        throw Exception(errorMsg);
      }
      final stdout = result.stdout as String;
      _log('Export success for $table, payload length: ${stdout.length}.');
      return stdout.trim();
    } catch (e) {
      _log('Exception during export of $table: $e');
      return '';
    }
  }

  /// Parse CSV Access (gère guillemets doubles échappés)
  List<String?> _parseCsv(String line) {
    final result = <String?>[];
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
        result.add(_normalize(current.toString()));
        current.clear();
      } else {
        current.write(ch);
      }
    }
    result.add(_normalize(current.toString()));
    return result;
  }

  String? _normalize(String value) {
    final normalized = value.replaceAll('\u0000', '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  int? _i(String? s) {
    if (s == null || s.isEmpty) return null;
    return int.tryParse(s.replaceAll('"', '').trim());
  }

  double? _d(String? s) {
    if (s == null || s.isEmpty) return null;
    return double.tryParse(s.replaceAll('"', '').trim());
  }

  void _log(String message) {
    debugPrint('$_logPrefix $message');
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }
}

class _MdbTable {
  final String name;
  final String sql;
  final List<Object?> Function(List<String?>) mapper;

  const _MdbTable({
    required this.name,
    required this.sql,
    required this.mapper,
  });
}
