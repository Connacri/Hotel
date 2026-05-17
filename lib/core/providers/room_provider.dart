import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../database/native_mdb_reader.dart';
import '../database/local_database.dart';

class RoomProvider extends ChangeNotifier {
  final RoomRepository _repo;

  RoomProvider(this._repo);

  List<RoomModel> _rooms = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'all';
  String _searchQuery = '';

  Future<String?> get _mdbPath async => (await LocalDatabase.getInstance()).mdbPath;

  List<RoomModel> get rooms => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;

  Map<String, int> get stats => _repo.getStats();

  List<RoomModel> get _filtered {
    var list = _rooms;
    if (_statusFilter != 'all') {
      list = list.where((r) => r.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
        r.roomNo.toLowerCase().contains(q) ||
        (r.sType?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return list;
  }

  Map<int, List<RoomModel>> get byFloor {
    final map = <int, List<RoomModel>>{};
    for (final r in _filtered) {
      map.putIfAbsent(r.flrNo, () => []).add(r);
    }
    return map;
  }

  void setFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _rooms = _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkIn(int roomId) async {
    try {
      _repo.updateStatus(roomId, 'Guest');
      final room = _rooms.firstWhere((r) => r.id == roomId);
      final path = await _mdbPath;
      if (path != null) {
        await NativeMdbReader.execute(path, "UPDATE RoomInfo SET Status='Guest' WHERE RomID=${room.romId}");
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkOut(int roomId) async {
    try {
      _repo.updateStatus(roomId, 'Vacant');
      _repo.updateCardCount(roomId, 0);
      final room = _rooms.firstWhere((r) => r.id == roomId);
      final path = await _mdbPath;
      if (path != null) {
        await NativeMdbReader.execute(path, "UPDATE RoomInfo SET Status='Vacant', CardCount=0 WHERE RomID=${room.romId}");
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRoom(RoomModel room) async {
    try {
      _repo.update(room);
      final path = await _mdbPath;
      if (path != null) {
        await NativeMdbReader.execute(path, """
          UPDATE RoomInfo SET 
            Status='${room.status}', 
            Price=${room.price}, 
            CardCount=${room.cardCount}, 
            SType='${room.sType}', 
            BeiZhu='${room.beiZhu}', 
            FirstCkOut='${room.firstCkOut}'
          WHERE RomID=${room.romId}
        """);
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addRoom(RoomModel room) async {
    try {
      _repo.insert(room);
      final path = await _mdbPath;
      if (path != null) {
        await NativeMdbReader.execute(path, """
          INSERT INTO RoomInfo 
          (BldNo,FlrNo,RomID,RoomNo,SType,Status,Price,Dai,CardCount,MaxCards,BeiZhu)
          VALUES (${room.bldNo}, ${room.flrNo}, ${room.romId}, '${room.roomNo}', 
                  '${room.sType}', '${room.status}', ${room.price}, ${room.dai}, 
                  ${room.cardCount}, ${room.maxCards}, '${room.beiZhu}')
        """);
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRoom(int id) async {
    try {
      final room = _rooms.firstWhere((r) => r.id == id);
      _repo.delete(id);
      final path = await _mdbPath;
      if (path != null) {
        await NativeMdbReader.execute(path, "DELETE FROM RoomInfo WHERE RomID=${room.romId}");
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
