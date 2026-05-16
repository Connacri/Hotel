import 'package:flutter/material.dart';
import '../core/database/local_database.dart';
import '../core/database/mdb_migrator.dart';
import 'app_shell.dart';

class MigrationScreen extends StatefulWidget {
  final LocalDatabase localDb;
  final String mdbPath;

  const MigrationScreen({
    super.key,
    required this.localDb,
    required this.mdbPath,
  });

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  String _currentTable = 'Initialisation...';
  double _progress = 0;
  bool _isDone = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startMigration();
  }

  Future<void> _startMigration() async {
    final migrator = MdbMigrator(db: widget.localDb.db, mdbPath: widget.mdbPath);
    try {
      await migrator.migrate(onProgress: (table) {
        setState(() {
          _currentTable = 'Importation de $table...';
          _progress += 0.15; // Approximation
        });
      });
      setState(() {
        _isDone = true;
        _progress = 1.0;
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storage_rounded, size: 48, color: Color(0xFF1565C0)),
              const SizedBox(height: 24),
              const Text(
                'Migration des données',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Importation depuis CardLock.mdb',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AppShell()),
                  ),
                  child: const Text('Ignorer et continuer'),
                ),
              ] else ...[
                LinearProgressIndicator(
                  value: _isDone ? 1.0 : _progress,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  _isDone ? 'Migration terminée !' : _currentTable,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
