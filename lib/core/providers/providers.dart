import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

// ─────────────────────────────────────────────
// RoomProvider
// ─────────────────────────────────────────────
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
    _repo.updateStatus(roomId, 'Guest');
    await load();
  }

  Future<void> checkOut(int roomId) async {
    _repo.updateStatus(roomId, 'Vacant');
    _repo.updateCardCount(roomId, 0);
    await load();
  }

  Future<void> updateRoom(RoomModel room) async {
    _repo.update(room);
    await load();
  }

  Future<void> addRoom(RoomModel room) async {
    _repo.insert(room);
    await load();
  }

  Future<void> deleteRoom(int id) async {
    _repo.delete(id);
    await load();
  }
}

// ─────────────────────────────────────────────
// GuestProvider
// ─────────────────────────────────────────────
class GuestProvider extends ChangeNotifier {
  final GuestRepository _repo;

  GuestProvider(this._repo);

  List<GuestModel> _guests = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<GuestModel> get guests => _searched;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<GuestModel> get _searched {
    if (_searchQuery.isEmpty) return _guests;
    final q = _searchQuery.toLowerCase();
    return _guests.where((g) =>
      g.name.toLowerCase().contains(q) ||
      g.bldRoomNo.toLowerCase().contains(q) ||
      (g.cardId?.toLowerCase().contains(q) ?? false)
    ).toList();
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
      _guests = _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<GuestModel> getByRoom(String bldRoomNo) =>
      _repo.getByRoom(bldRoomNo);

  Future<void> addGuest(GuestModel guest) async {
    _repo.insert(guest);
    await load();
  }

  Future<void> checkOut(int guestId, String goTime) async {
    _repo.updateCheckout(guestId, goTime);
    await load();
  }

  Future<void> deleteGuest(int id) async {
    _repo.delete(id);
    await load();
  }
}

// ─────────────────────────────────────────────
// CardProvider
// ─────────────────────────────────────────────
class CardProvider extends ChangeNotifier {
  final CardRepository _repo;

  CardProvider(this._repo);

  List<CardModel> _cards = [];
  bool _isLoading = false;
  String? _error;

  List<CardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get stats => _repo.getStats();

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _cards = _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> eraseCard(int id) async {
    _repo.updateStatus(id, 'Erased Card Successfully');
    await load();
  }

  Future<void> deleteCard(int id) async {
    _repo.delete(id);
    await load();
  }
}

// ─────────────────────────────────────────────
// OperatorProvider
// ─────────────────────────────────────────────
class OperatorProvider extends ChangeNotifier {
  final OperatorRepository _repo;

  OperatorProvider(this._repo);

  List<OperatorModel> _operators = [];
  bool _isLoading = false;
  String? _error;

  List<OperatorModel> get operators => _operators;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _operators = _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addOperator(OperatorModel op) async {
    _repo.insert(op);
    await load();
  }

  Future<void> updatePassword(String gongHao, String newPass) async {
    _repo.updatePassword(gongHao, newPass);
    await load();
  }

  Future<void> deleteOperator(String gongHao) async {
    _repo.delete(gongHao);
    await load();
  }
}

// ─────────────────────────────────────────────
// RecordProvider
// ─────────────────────────────────────────────
class RecordProvider extends ChangeNotifier {
  final RecordOpenRepository _repo;

  RecordProvider(this._repo);

  List<RecordOpenModel> _records = [];
  bool _isLoading = false;
  String? _error;
  bool _doorOnly = false;

  List<RecordOpenModel> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get doorOnly => _doorOnly;

  void toggleDoorOnly() {
    _doorOnly = !_doorOnly;
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _records = _doorOnly ? _repo.getDoorOpenings() : _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
