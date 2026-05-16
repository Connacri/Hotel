import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import 'core/database/local_database.dart';
import 'core/repositories/repositories.dart';
import 'core/providers/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/app_shell.dart';
import 'features/migration_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation SQLite
  final localDb = await LocalDatabase.getInstance();

  // 2. Détection MDB pour migration potentielle
  final mdbPath = _findMdb();
  final needsMigration = !localDb.isMigrated && mdbPath != null;

  // 3. Repositories
  final db         = localDb.db;
  final roomRepo   = RoomRepository(db);
  final guestRepo  = GuestRepository(db);
  final cardRepo   = CardRepository(db);
  final opRepo     = OperatorRepository(db);
  final recordRepo = RecordOpenRepository(db);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoomProvider(roomRepo)..load()),
        ChangeNotifierProvider(create: (_) => GuestProvider(guestRepo)..load()),
        ChangeNotifierProvider(create: (_) => CardProvider(cardRepo)..load()),
        ChangeNotifierProvider(create: (_) => OperatorProvider(opRepo)..load()),
        ChangeNotifierProvider(create: (_) => RecordProvider(recordRepo)..load()),
      ],
      child: CardLockApp(
        localDb: localDb,
        mdbPath: needsMigration ? mdbPath : null,
      ),
    ),
  );
}

/// Cherche CardLock.mdb dans les emplacements standards Windows
String? _findMdb() {
  if (!Platform.isWindows) return null;
  final candidates = [
    p.join(Directory.current.path, 'CardLock.mdb'),
    p.join(Directory.current.path, 'data', 'CardLock.mdb'),
    p.join(
      Platform.environment['APPDATA'] ?? '',
      'CardLock',
      'CardLock.mdb',
    ),
    r'C:\CardLock\CardLock.mdb',
    r'C:\Program Files\CardLock\CardLock.mdb',
    r'C:\Program Files (x86)\CardLock\CardLock.mdb',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

class CardLockApp extends StatelessWidget {
  final LocalDatabase localDb;
  final String? mdbPath;

  const CardLockApp({
    super.key,
    required this.localDb,
    this.mdbPath,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardLock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: mdbPath != null
          ? MigrationScreen(localDb: localDb, mdbPath: mdbPath!)
          : const AppShell(),
    );
  }
}
