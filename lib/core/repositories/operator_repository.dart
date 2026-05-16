import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import '../models/models.dart';

class OperatorRepository {
  static const String tableName = 'operator_info';

  final Database _db;
  OperatorRepository(this._db);

  List<OperatorModel> getAll() {
    try {
      final rows = _db.select('SELECT * FROM $tableName ORDER BY gong_hao');
      return rows.map(OperatorModel.fromRow).toList();
    } catch (e) {
      throw Exception('Failed to fetch operators: $e');
    }
  }

  OperatorModel? getByLogin(String gongHao) {
    try {
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE gong_hao=? LIMIT 1',
        [gongHao],
      );
      return rows.isEmpty ? null : OperatorModel.fromRow(rows.first);
    } catch (e) {
      throw Exception('Failed to fetch operator by login: $e');
    }
  }

  /// Hashage SHA-256 du mot de passe
  String _hashPassword(String password) {
    if (password.isEmpty) return '';
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Authentification — retourne l'opérateur si credentials valides
  OperatorModel? authenticate(String gongHao, String miMa) {
    try {
      final hashed = _hashPassword(miMa);
      final rows = _db.select(
        'SELECT * FROM $tableName WHERE gong_hao=? AND mi_ma=? LIMIT 1',
        [gongHao, hashed],
      );
      return rows.isEmpty ? null : OperatorModel.fromRow(rows.first);
    } catch (e) {
      return null;
    }
  }

  void insert(OperatorModel op) {
    try {
      // On hashe le mot de passe avant insertion
      final hashed = _hashPassword(op.miMa);
      _db.execute('''
        INSERT OR REPLACE INTO $tableName (gong_hao,name,mi_ma,quan_xian,bei_zhu)
        VALUES (?,?,?,?,?)
      ''', [op.gongHao, op.name, hashed, op.quanXian, op.beiZhu]);
    } catch (e) {
      throw Exception('Failed to insert operator: $e');
    }
  }

  void updatePassword(String gongHao, String newMiMa) {
    try {
      final hashed = _hashPassword(newMiMa);
      _db.execute(
        'UPDATE $tableName SET mi_ma=? WHERE gong_hao=?',
        [hashed, gongHao],
      );
    } catch (e) {
      throw Exception('Failed to update operator password: $e');
    }
  }

  void delete(String gongHao) {
    try {
      _db.execute('DELETE FROM $tableName WHERE gong_hao=?', [gongHao]);
    } catch (e) {
      throw Exception('Failed to delete operator: $e');
    }
  }
}
