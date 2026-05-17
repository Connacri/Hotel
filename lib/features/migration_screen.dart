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
  static const _logPrefix = '[MDB Import]';

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
    _log('Auto migration started for "${widget.mdbPath}".');
    try {
      await migrator.migrate(onProgress: (table) {
        setState(() {
          _currentTable = 'Importation de $table...';
          _progress += 0.15; // Approximation
        });
        _log('Auto migration progress: $table.');
      });
      setState(() {
        _isDone = true;
        _progress = 1.0;
      });
      _log('Auto migration completed.');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e, st) {
      _log('Auto migration failed: $e');
      _log(st.toString());
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
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(
          _error!,
          style: TextStyle(color: Colors.red[900], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AppShell()),
            ),
            child: const Text('Ignorer'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _progress = 0;
              });
              _startMigration();
            },
            child: const Text('Réessayer'),
          ),
        ],
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

  void _log(String message) {
    debugPrint('$_logPrefix $message');
  }
}
