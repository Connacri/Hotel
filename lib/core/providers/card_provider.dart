import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

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
    try {
      _repo.updateStatus(id, 'Erased Card Successfully');
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCard(int id) async {
    try {
      _repo.delete(id);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
