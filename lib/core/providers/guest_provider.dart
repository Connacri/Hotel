import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../database/native_mdb_reader.dart';
import '../database/local_database.dart';

class GuestProvider extends ChangeNotifier {
  final GuestRepository _repo;

  GuestProvider(this._repo);

  List<GuestModel> _guests = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  Future<String?> get _mdbPath async => (await LocalDatabase.getInstance()).mdbPath;

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

  List<GuestModel> getGuestsForRoom(String bldRoomNo) {
    return _guests.where((g) => g.bldRoomNo == bldRoomNo).toList();
  }

  Future<void> addGuest(GuestModel guest) async {
    try {
      final id = _repo.insert(guest);
      final path = await _mdbPath;
      if (path != null) {
        // Dans GuestInfo MDB, l'ID est souvent mappé sur un champ spécifique (ici r[12] dans le migrateur)
        // Pour l'insertion, on laisse Access générer ou on passe les colonnes mappées
        await NativeMdbReader.execute(path, """
          INSERT INTO GuestInfo 
          (BldRoomNo,Name,Sex,CType,CNo,ComeTime,GoTime,CardID,Flag,BeiZhu,Price,YaJin)
          VALUES ('${guest.bldRoomNo}', '${guest.name}', '${guest.sex}', '${guest.cType}', 
                  '${guest.cNo}', '${guest.comeTime}', '${guest.goTime}', '${guest.cardId}', 
                  '${guest.flag}', '${guest.beiZhu}', ${guest.price}, ${guest.yaJin})
        """);
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkOut(int guestId, String goTime) async {
    try {
      _repo.updateCheckout(guestId, goTime);
      final guest = _guests.firstWhere((g) => g.id == guestId);
      final path = await _mdbPath;
      if (path != null) {
        await NativeMdbReader.execute(path, "UPDATE GuestInfo SET GoTime='$goTime' WHERE BldRoomNo='${guest.bldRoomNo}' AND Name='${guest.name}'");
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteGuest(int id) async {
    try {
      final guest = _guests.firstWhere((g) => g.id == id);
      _repo.delete(id);
      final path = await _mdbPath;
      if (path != null) {
        await NativeMdbReader.execute(path, "DELETE FROM GuestInfo WHERE BldRoomNo='${guest.bldRoomNo}' AND Name='${guest.name}'");
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
