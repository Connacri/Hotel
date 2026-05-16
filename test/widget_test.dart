import 'package:flutter_test/flutter_test.dart';
import 'package:hotel/main.dart';
import 'package:hotel/core/providers/providers.dart';
import 'package:hotel/core/repositories/repositories.dart';
import 'package:provider/provider.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database db;

  setUp(() {
    // Initialisation d'une base de données en mémoire pour les tests
    db = sqlite3.openInMemory();
    _createTables(db);
  });

  tearDown(() {
    db.dispose();
  });

  testWidgets('App smoke test - verify navigation rail items', (WidgetTester tester) async {
    final roomRepo = RoomRepository(db);
    final guestRepo = GuestRepository(db);
    final cardRepo = CardRepository(db);
    final opRepo = OperatorRepository(db);
    final recRepo = RecordOpenRepository(db);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RoomProvider(roomRepo)),
          ChangeNotifierProvider(create: (_) => GuestProvider(guestRepo)),
          ChangeNotifierProvider(create: (_) => CardProvider(cardRepo)),
          ChangeNotifierProvider(create: (_) => OperatorProvider(opRepo)),
          ChangeNotifierProvider(create: (_) => RecordProvider(recRepo)),
        ],
        child: const CardLockApp(),
      ),
    );

    // Vérifie que le titre principal est présent
    expect(find.text('Plan des chambres'), findsOneWidget);

    // Vérifie la présence des éléments du NavigationRail (sidebar)
    expect(find.text('Chambres'), findsOneWidget);
    expect(find.text('Clients'), findsOneWidget);
    expect(find.text('Cartes'), findsOneWidget);
  });
}

void _createTables(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS room_info (
      id                INTEGER PRIMARY KEY AUTOINCREMENT,
      bld_no            INTEGER NOT NULL DEFAULT 1,
      flr_no            INTEGER NOT NULL DEFAULT 1,
      rom_id            INTEGER NOT NULL DEFAULT 0,
      room_no           TEXT    NOT NULL,
      s_type            TEXT,
      status            TEXT    DEFAULT 'Vacant',
      price             REAL    DEFAULT 0,
      dai               INTEGER DEFAULT 0,
      card_count        INTEGER DEFAULT 0,
      max_cards         INTEGER DEFAULT 10,
      bei_zhu           TEXT,
      first_ck_out      TEXT
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS guest_info (
      id          INTEGER PRIMARY KEY,
      bld_room_no TEXT    NOT NULL,
      name        TEXT,
      sex         TEXT,
      c_type      TEXT,
      c_no        TEXT,
      come_time   TEXT,
      go_time     TEXT,
      card_id     TEXT,
      flag        TEXT,
      bei_zhu     TEXT,
      price       REAL    DEFAULT 0,
      ya_jin      REAL    DEFAULT 0
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS card_info (
      id        INTEGER PRIMARY KEY,
      card_data TEXT,
      holder    TEXT,
      gong_hao  TEXT,
      bei_zhu   TEXT,
      status    TEXT
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS operator_info (
      gong_hao  TEXT PRIMARY KEY,
      name      TEXT NOT NULL,
      mi_ma     TEXT NOT NULL DEFAULT '',
      quan_xian TEXT,
      bei_zhu   TEXT
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS record_open (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      order_flag INTEGER DEFAULT 0,
      rec_data   TEXT,
      open_time  TEXT
    );
  ''');
}
