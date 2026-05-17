import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/local_database.dart';
import '../database/mdb_migrator.dart';
import 'providers.dart';

class MigrationProvider extends ChangeNotifier {
  static const _logPrefix = '[MDB Import]';

  bool _isMigrating = false;
  String? _status;
  String? _error;

  bool get isMigrating => _isMigrating;
  String? get status => _status;
  String? get error => _error;

  Future<bool> importMdb(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mdb'],
        dialogTitle: 'Sélectionner le fichier CardLock.mdb',
      );

      if (result == null || result.files.single.path == null) return false;

      final path = result.files.single.path!;
      _log('Manual import selected file "$path".');
      
      _isMigrating = true;
      _status = "Initialisation de la migration...";
      _error = null;
      notifyListeners();

      final dbInstance = await LocalDatabase.getInstance();
      dbInstance.mdbPath = path; // Persister le nouveau chemin
      final migrator = MdbMigrator(db: dbInstance.db, mdbPath: path);

      await migrator.migrate(onProgress: (table) {
        _status = "Migration de la table : $table...";
        _log('Progress: migrating table $table.');
        notifyListeners();
      });

      _status = "Migration terminée avec succès !";
      _isMigrating = false;
      notifyListeners();

      // Rafraîchir tous les providers après la migration
      if (context.mounted) {
        context.read<RoomProvider>().load();
        context.read<GuestProvider>().load();
        context.read<CardProvider>().load();
        context.read<OperatorProvider>().load();
        context.read<RecordProvider>().load();
      }

      return true;
    } catch (e, st) {
      _log('Manual import failed: $e');
      _log(st.toString());
      _error = "Erreur lors de la migration : $e";
      _isMigrating = false;
      notifyListeners();
      return false;
    }
  }

  void _log(String message) {
    debugPrint('$_logPrefix $message');
  }
}
