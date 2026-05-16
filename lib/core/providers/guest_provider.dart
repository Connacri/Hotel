import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

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
    try {
      _repo.insert(guest);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkOut(int guestId, String goTime) async {
    try {
      _repo.updateCheckout(guestId, goTime);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteGuest(int id) async {
    try {
      _repo.delete(id);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
