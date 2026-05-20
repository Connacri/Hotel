import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ── Typedefs ────────────────────────────────────────────────────────────────
typedef _GetTablesN  = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _GetTablesD  = int   Function(Pointer<Utf8>, Pointer<Utf8>, int);

typedef _GetColumnsN = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _GetColumnsD = int   Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef _SelectAllN  = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _SelectAllD  = int   Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef _InsertN = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _InsertD = int   Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef _UpdateN = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _UpdateD = int   Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef _DeleteN = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _DeleteD = int   Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);

// ── Singleton ────────────────────────────────────────────────────────────────
class MdbFfi {
  MdbFfi._();
  static final MdbFfi instance = MdbFfi._();

  static const int _bufSize = 1 << 20; // 1 MB

  late final _GetTablesD  _getTables;
  late final _GetColumnsD _getColumns;
  late final _SelectAllD  _selectAll;
  late final _InsertD     _insert;
  late final _UpdateD     _update;
  late final _DeleteD     _delete;

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final lib = DynamicLibrary.open('$exeDir\\mdb_bridge.dll');
    _getTables  = lib.lookupFunction<_GetTablesN,  _GetTablesD>('get_tables');
    _getColumns = lib.lookupFunction<_GetColumnsN, _GetColumnsD>('get_columns');
    _selectAll  = lib.lookupFunction<_SelectAllN,  _SelectAllD>('select_all');
    _insert     = lib.lookupFunction<_InsertN,     _InsertD>('insert_row');
    _update     = lib.lookupFunction<_UpdateN,     _UpdateD>('update_row');
    _delete     = lib.lookupFunction<_DeleteN,     _DeleteD>('delete_row');
    _initialized = true;
  }

  String _withBuf(int Function(Pointer<Utf8>, int) fn) {
    final buf = calloc<Uint8>(_bufSize).cast<Utf8>();
    try { fn(buf, _bufSize); return buf.toDartString(); }
    finally { calloc.free(buf); }
  }

  List<String> getTables(String mdbPath) {
    final p = mdbPath.toNativeUtf8();
    final r = _withBuf((b, s) => _getTables(p, b, s));
    calloc.free(p);
    if (r.startsWith('ERROR') || r.isEmpty) return [];
    return r.split('\n');
  }

  List<Map<String, String>> getColumns(String mdbPath, String table) {
    final p = mdbPath.toNativeUtf8();
    final t = table.toNativeUtf8();
    final r = _withBuf((b, s) => _getColumns(p, t, b, s));
    calloc.free(p); calloc.free(t);
    if (r.startsWith('ERROR') || r.isEmpty) return [];
    return r.split(',').map((e) {
      final parts = e.split('|');
      return {'name': parts[0], 'type': parts.length > 1 ? parts[1] : ''};
    }).toList();
  }

  List<Map<String, String>> selectAll(String mdbPath, String table) {
    final p = mdbPath.toNativeUtf8();
    final t = table.toNativeUtf8();
    final r = _withBuf((b, s) => _selectAll(p, t, b, s));
    calloc.free(p); calloc.free(t);
    if (r == '[]' || r.isEmpty) return [];
    try {
      return (jsonDecode(r) as List)
          .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
          .toList();
    } catch (_) { return []; }
  }

  void insertRow(String mdbPath, String table, Map<String, String> data) {
    final p  = mdbPath.toNativeUtf8();
    final t  = table.toNativeUtf8();
    final cv = data.entries.map((e) => '${e.key}|${e.value}').join(',').toNativeUtf8();
    final r  = _withBuf((b, s) => _insert(p, t, cv, b, s));
    calloc.free(p); calloc.free(t); calloc.free(cv);
    if (!r.startsWith('OK')) throw Exception(r);
  }

  void updateRow(String mdbPath, String table, String pkCol, String pkVal, Map<String, String> data) {
    final p  = mdbPath.toNativeUtf8();
    final t  = table.toNativeUtf8();
    final pk = pkCol.toNativeUtf8();
    final pv = pkVal.toNativeUtf8();
    final cv = data.entries.map((e) => '${e.key}|${e.value}').join(',').toNativeUtf8();
    final r  = _withBuf((b, s) => _update(p, t, pk, pv, cv, b, s));
    for (final x in [p, t, pk, pv, cv]) calloc.free(x);
    if (!r.startsWith('OK')) throw Exception(r);
  }

  void deleteRow(String mdbPath, String table, String pkCol, String pkVal) {
    final p  = mdbPath.toNativeUtf8();
    final t  = table.toNativeUtf8();
    final pk = pkCol.toNativeUtf8();
    final pv = pkVal.toNativeUtf8();
    final r  = _withBuf((b, s) => _delete(p, t, pk, pv, b, s));
    for (final x in [p, t, pk, pv]) calloc.free(x);
    if (!r.startsWith('OK')) throw Exception(r);
  }
}