import '../mdb_ffi.dart';


class MdbRepository {
  String mdbPath;
  final MdbFfi _ffi = MdbFfi.instance;

  MdbRepository(this.mdbPath);

  List<String>              getTables()              => _ffi.getTables(mdbPath);
  List<Map<String, String>> getColumns(String t)     => _ffi.getColumns(mdbPath, t);
  List<Map<String, String>> selectAll(String t)      => _ffi.selectAll(mdbPath, t);
  void insert(String t, Map<String, String> d)       => _ffi.insertRow(mdbPath, t, d);
  void update(String t, String pk, String pv, Map<String, String> d) => _ffi.updateRow(mdbPath, t, pk, pv, d);
  void delete(String t, String pk, String pv)        => _ffi.deleteRow(mdbPath, t, pk, pv);
}