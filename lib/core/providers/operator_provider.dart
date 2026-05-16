import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

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
    try {
      _repo.insert(op);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePassword(String gongHao, String newPass) async {
    try {
      _repo.updatePassword(gongHao, newPass);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteOperator(String gongHao) async {
    try {
      _repo.delete(gongHao);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Authentifie un utilisateur (utile pour le futur écran de login)
  Future<OperatorModel?> login(String gongHao, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final op = _repo.authenticate(gongHao, password);
      if (op == null) _error = 'Identifiants invalides';
      return op;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
