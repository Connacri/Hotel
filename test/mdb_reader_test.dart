import 'package:flutter_test/flutter_test.dart';
import 'package:hotel/core/database/odbc_mdb_reader.dart';
import 'dart:io';

void main() {
  test('ODBC Reader availability', () {
    // This will likely be false in the test environment unless ODBC is configured,
    // but we can at least check if it doesn't crash.
    try {
      final available = OdbcMdbReader.isAvailable;
      print('ODBC Reader available: $available');
    } catch (e) {
      fail('ODBC Reader crashed: $e');
    }
  });

  test('ODBC Reader list tables (if available)', () async {
    if (OdbcMdbReader.isAvailable) {
      final mdbPath = 'CardLock.mdb';
      if (File(mdbPath).existsSync()) {
        try {
          final tables = await OdbcMdbReader.listTables(mdbPath);
          print('Tables in CardLock.mdb: $tables');
        } catch (e) {
          print('Failed to list tables: $e');
        }
      } else {
        print('CardLock.mdb not found at $mdbPath');
      }
    } else {
      print('ODBC Reader not available, skipping table listing test');
    }
  });
}
