import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../core/data/mdb_repository.dart';


class MdbCrudProvider extends ChangeNotifier {
  MdbRepository? _repo;

  List<String>              tables        = [];
  String?                   selectedTable;
  List<Map<String, String>> columns       = [];
  List<Map<String, String>> rows          = [];
  bool                      loading       = false;
  String?                   error;
  String?                   get mdbPath   => _repo?.mdbPath;

  String? get pkColumn => columns.isNotEmpty ? columns.first['name'] : null;

  // ── Sélection du fichier via file picker ────────────────────
  Future<void> pickAndLoad() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mdb', 'accdb'],
      dialogTitle: 'Sélectionner le fichier .mdb',
    );
    if (result == null || result.files.single.path == null) return;

    _repo = MdbRepository(result.files.single.path!);
    tables = []; selectedTable = null; columns = []; rows = [];
    await loadTables();
  }

  Future<void> loadTables() async {
    if (_repo == null) return;
    _setLoading(true);
    try {
      tables = await compute((_) => _repo!.getTables(), null);
      error = null;
    } catch (e) { error = e.toString(); }
    _setLoading(false);
  }

  Future<void> selectTable(String table) async {
    if (_repo == null) return;
    selectedTable = table;
    _setLoading(true);
    try {
      columns = await compute((_) => _repo!.getColumns(table), null);
      await _refresh();
      error = null;
    } catch (e) { error = e.toString(); }
    _setLoading(false);
  }

  Future<void> _refresh() async {
    if (_repo == null || selectedTable == null) return;
    rows = await compute((_) => _repo!.selectAll(selectedTable!), null);
  }

  Future<void> insert(Map<String, String> data) async {
    _setLoading(true);
    try { _repo!.insert(selectedTable!, data); await _refresh(); error = null; }
    catch (e) { error = e.toString(); }
    _setLoading(false);
  }

  Future<void> update(String pkVal, Map<String, String> data) async {
    _setLoading(true);
    try { _repo!.update(selectedTable!, pkColumn!, pkVal, data); await _refresh(); error = null; }
    catch (e) { error = e.toString(); }
    _setLoading(false);
  }

  Future<void> delete(String pkVal) async {
    _setLoading(true);
    try { _repo!.delete(selectedTable!, pkColumn!, pkVal); await _refresh(); error = null; }
    catch (e) { error = e.toString(); }
    _setLoading(false);
  }

  void _setLoading(bool v) { loading = v; notifyListeners(); }
}