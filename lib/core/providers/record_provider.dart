import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

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
