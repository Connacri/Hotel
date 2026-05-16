import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class RoomProvider extends ChangeNotifier {
  final RoomRepository _repo;

  RoomProvider(this._repo);

  List<RoomModel> _rooms = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'all';
  String _searchQuery = '';

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
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRoom(RoomModel room) async {
    try {
      _repo.update(room);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addRoom(RoomModel room) async {
    try {
      _repo.insert(room);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRoom(int id) async {
    try {
      _repo.delete(id);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
