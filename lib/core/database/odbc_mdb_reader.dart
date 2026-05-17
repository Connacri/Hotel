import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class OdbcMdbReader {
  static const int SQL_SUCCESS           = 0;
  static const int SQL_SUCCESS_WITH_INFO = 1;
  static const int SQL_NO_DATA           = 100;
  static const int SQL_NULL_HANDLE       = 0;
  static const int SQL_HANDLE_ENV        = 1;
  static const int SQL_HANDLE_DBC        = 2;
  static const int SQL_HANDLE_STMT       = 3;
  static const int SQL_ATTR_ODBC_VERSION = 200;
  static const int SQL_OV_ODBC3         = 3;
  static const int SQL_NTS              = -3;
  static const int SQL_C_WCHAR          = -8;
  static const int SQL_WCHAR            = -8;
  static const int SQL_ATTR_ACCESS_MODE = 101;
  static const int SQL_MODE_READ_ONLY   = 1;

  // Chargement odbc32.dll
  static final _odbc = DynamicLibrary.open('odbc32.dll');

  // Bindings ODBC
  static final _sqlAllocHandle = _odbc.lookupFunction<
    Int16 Function(Int16 handleType, IntPtr inputHandle, Pointer<IntPtr> outputHandle),
    int  Function(int   handleType, int   inputHandle, Pointer<IntPtr> outputHandle)
  >('SQLAllocHandle');

  static final _sqlSetEnvAttr = _odbc.lookupFunction<
    Int16 Function(IntPtr envHandle, Int32 attribute, IntPtr value, Int32 stringLength),
    int  Function(int   envHandle, int   attribute, int   value, int   stringLength)
  >('SQLSetEnvAttr');

  static final _sqlDriverConnectW = _odbc.lookupFunction<
    Int16 Function(IntPtr hdbc, IntPtr hwnd, Pointer<Utf16> inConnStr, Int16 inLen,
                   Pointer<Utf16> outConnStr, Int16 outMax, Pointer<Int16> outLen, Int16 driverCompletion),
    int  Function(int   hdbc, int   hwnd, Pointer<Utf16> inConnStr, int   inLen,
                  Pointer<Utf16> outConnStr, int   outMax, Pointer<Int16> outLen, int   driverCompletion)
  >('SQLDriverConnectW');

  static final _sqlExecDirectW = _odbc.lookupFunction<
    Int16 Function(IntPtr stmtHandle, Pointer<Utf16> statementText, Int32 textLength),
    int  Function(int   stmtHandle, Pointer<Utf16> statementText, int   textLength)
  >('SQLExecDirectW');

  static final _sqlNumResultCols = _odbc.lookupFunction<
    Int16 Function(IntPtr stmtHandle, Pointer<Int16> columnCount),
    int  Function(int   stmtHandle, Pointer<Int16> columnCount)
  >('SQLNumResultCols');

  static final _sqlFetch = _odbc.lookupFunction<
    Int16 Function(IntPtr stmtHandle),
    int  Function(int   stmtHandle)
  >('SQLFetch');

  static final _sqlGetData = _odbc.lookupFunction<
    Int16 Function(IntPtr stmtHandle, Int16 colNum, Int16 targetType,
                   Pointer<Void> targetValue, IntPtr bufferLength, Pointer<IntPtr> strLenOrInd),
    int  Function(int   stmtHandle, int   colNum, int   targetType,
                  Pointer<Void> targetValue, int   bufferLength, Pointer<IntPtr> strLenOrInd)
  >('SQLGetData');

  static final _sqlFreeHandle = _odbc.lookupFunction<
    Int16 Function(Int16 handleType, IntPtr handle),
    int  Function(int   handleType, int   handle)
  >('SQLFreeHandle');

  static final _sqlDisconnect = _odbc.lookupFunction<
    Int16 Function(IntPtr hdbc),
    int  Function(int   hdbc)
  >('SQLDisconnect');

  static final _sqlCloseCursor = _odbc.lookupFunction<
    Int16 Function(IntPtr stmtHandle),
    int  Function(int   stmtHandle)
  >('SQLCloseCursor');

  // ─── API publique ─────────────────────────────────────────────

  static bool get isAvailable {
    try {
      if (!Platform.isWindows) return false;
      // Test allocation simple
      final envPtr = calloc<IntPtr>();
      try {
        final rc = _sqlAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, envPtr);
        if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO) {
          _sqlFreeHandle(SQL_HANDLE_ENV, envPtr.value);
          return true;
        }
      } finally {
        calloc.free(envPtr);
      }
    } catch (_) {}
    return false;
  }

  /// Lit toutes les lignes d'une table MDB.
  /// Retourne une liste de maps colonne→valeur.
  static Future<List<Map<String, String?>>> readTable(
    String mdbPath,
    String tableName,
  ) async {
    return _withConnection(mdbPath, (stmtHandle) {
      return _executeQuery(stmtHandle, 'SELECT * FROM [$tableName]');
    });
  }

  /// Exécute une requête SQL arbitraire.
  static Future<List<Map<String, String?>>> query(
    String mdbPath,
    String sql,
  ) async {
    return _withConnection(mdbPath, (stmtHandle) {
      return _executeQuery(stmtHandle, sql);
    });
  }

  /// Liste les tables disponibles dans le MDB.
  static Future<List<String>> listTables(String mdbPath) async {
    try {
      final rows = await query(
        mdbPath,
        "SELECT Name FROM MSysObjects WHERE Type=1 AND Flags=0 ORDER BY Name",
      );
      return rows.map((r) => r['Name'] ?? '').where((n) => n.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Exécute une commande SQL sans retour (INSERT, UPDATE, DELETE).
  static Future<void> execute(String mdbPath, String sql) async {
    return _withConnection(mdbPath, (stmtHandle) {
      final sqlPtr = sql.toNativeUtf16();
      try {
        final rc = _sqlExecDirectW(stmtHandle, sqlPtr, SQL_NTS);
        _check(rc, 'SQLExecDirect: $sql');
      } finally {
        calloc.free(sqlPtr);
      }
    });
  }

  // ─── Internals ────────────────────────────────────────────────

  static T _withConnection<T>(
    String mdbPath,
    T Function(int stmtHandle) work,
  ) {
    // 1. Allouer environnement
    final envPtr = calloc<IntPtr>();
    var rc = _sqlAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, envPtr);
    _check(rc, 'SQLAllocHandle ENV');
    final envHandle = envPtr.value;

    try {
      // 2. ODBC v3
      rc = _sqlSetEnvAttr(envHandle, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, 0);
      _check(rc, 'SQLSetEnvAttr ODBC_VERSION');

      // 3. Allouer connexion
      final dbcPtr = calloc<IntPtr>();
      rc = _sqlAllocHandle(SQL_HANDLE_DBC, envHandle, dbcPtr);
      _check(rc, 'SQLAllocHandle DBC');
      final dbcHandle = dbcPtr.value;

      try {
        // 4. Connexion — on essaie plusieurs connection strings
        final connected = _connect(dbcHandle, mdbPath);
        if (!connected) {
          throw Exception(
            'Impossible de se connecter à "$mdbPath".\n'
            'Vérifiez que Microsoft Access Database Engine est installé.',
          );
        }

        // 5. Allouer statement
        final stmtPtr = calloc<IntPtr>();
        rc = _sqlAllocHandle(SQL_HANDLE_STMT, dbcHandle, stmtPtr);
        _check(rc, 'SQLAllocHandle STMT');
        final stmtHandle = stmtPtr.value;

        try {
          return work(stmtHandle);
        } finally {
          _sqlCloseCursor(stmtHandle);
          _sqlFreeHandle(SQL_HANDLE_STMT, stmtHandle);
          calloc.free(stmtPtr);
        }
      } finally {
        _sqlDisconnect(dbcHandle);
        _sqlFreeHandle(SQL_HANDLE_DBC, dbcHandle);
        calloc.free(dbcPtr);
      }
    } finally {
      _sqlFreeHandle(SQL_HANDLE_ENV, envHandle);
      calloc.free(envPtr);
    }
  }

  static bool _connect(int dbcHandle, String mdbPath) {
    final candidates = [
      'Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=$mdbPath;Uid=Admin;Pwd=;',
      'Driver={Microsoft Access Driver (*.mdb)};Dbq=$mdbPath;Uid=Admin;Pwd=;',
      'Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=$mdbPath;Uid=Admin;Pwd=pradlock;',
      'Driver={Microsoft Access Driver (*.mdb)};Dbq=$mdbPath;Uid=Admin;Pwd=pradlock;',
      // Version localized / common fallbacks
      'Driver={Driver do Microsoft Access (*.mdb)};Dbq=$mdbPath;Uid=Admin;Pwd=;',
    ];

    final outBuf    = calloc<Uint16>(1024);
    final outLenPtr = calloc<Int16>();

    try {
      for (final connStr in candidates) {
        final inPtr = connStr.toNativeUtf16();
        try {
          final rc = _sqlDriverConnectW(
            dbcHandle, 0, inPtr, SQL_NTS,
            outBuf.cast<Utf16>(), 1024, outLenPtr, 0,
          );
          if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO) return true;
        } finally {
          calloc.free(inPtr);
        }
      }
      return false;
    } finally {
      calloc.free(outBuf);
      calloc.free(outLenPtr);
    }
  }

  static List<Map<String, String?>> _executeQuery(
    int stmtHandle,
    String sql,
  ) {
    // Exécuter la requête
    final sqlPtr = sql.toNativeUtf16();
    try {
      final rc = _sqlExecDirectW(stmtHandle, sqlPtr, SQL_NTS);
      _check(rc, 'SQLExecDirect: $sql');
    } finally {
      calloc.free(sqlPtr);
    }

    // Nombre de colonnes
    final colCountPtr = calloc<Int16>();
    _sqlNumResultCols(stmtHandle, colCountPtr);
    final colCount = colCountPtr.value;
    calloc.free(colCountPtr);

    // Récupérer noms de colonnes
    final colNames = _getColumnNames(stmtHandle, colCount);

    // Parcourir les lignes
    final rows = <Map<String, String?>>[];
    const bufSize   = 4096;
    final valueBuf  = calloc<Uint16>(bufSize);
    final indPtr    = calloc<IntPtr>();

    try {
      while (_sqlFetch(stmtHandle) == SQL_SUCCESS) {
        final row = <String, String?>{};
        for (var col = 1; col <= colCount; col++) {
          final rc2 = _sqlGetData(
            stmtHandle, col, SQL_C_WCHAR,
            valueBuf.cast<Void>(), bufSize * 2, indPtr,
          );
          if (rc2 == SQL_SUCCESS || rc2 == SQL_SUCCESS_WITH_INFO) {
            final ind = indPtr.value;
            if (ind == -1) { // SQL_NULL_DATA
              row[colNames[col - 1]] = null;
            } else {
              row[colNames[col - 1]] = valueBuf.cast<Utf16>().toDartString();
            }
          } else {
            row[colNames[col - 1]] = null;
          }
        }
        rows.add(row);
      }
    } finally {
      calloc.free(valueBuf);
      calloc.free(indPtr);
    }
    return rows;
  }

  static List<String> _getColumnNames(int stmtHandle, int colCount) {
    final describeCol = _odbc.lookupFunction<
      Int16 Function(IntPtr stmt, Int16 colNum, Pointer<Utf16> colName, Int16 bufLen,
                     Pointer<Int16> nameLen, Pointer<Int16> dataType, Pointer<Uint64> colSize,
                     Pointer<Int16> decDigits, Pointer<Int16> nullable),
      int  Function(int   stmt, int   colNum, Pointer<Utf16> colName, int   bufLen,
                    Pointer<Int16> nameLen, Pointer<Int16> dataType, Pointer<Uint64> colSize,
                    Pointer<Int16> decDigits, Pointer<Int16> nullable)
    >('SQLDescribeColW');

    final names    = <String>[];
    final nameBuf  = calloc<Uint16>(256);
    final nameLen  = calloc<Int16>();
    final dataType = calloc<Int16>();
    final colSize  = calloc<Uint64>();
    final decDig   = calloc<Int16>();
    final nullable = calloc<Int16>();

    try {
      for (var i = 1; i <= colCount; i++) {
        describeCol(
          stmtHandle, i,
          nameBuf.cast<Utf16>(), 256,
          nameLen, dataType, colSize, decDig, nullable,
        );
        names.add(nameBuf.cast<Utf16>().toDartString());
      }
    } finally {
      calloc.free(nameBuf);
      calloc.free(nameLen);
      calloc.free(dataType);
      calloc.free(colSize);
      calloc.free(decDig);
      calloc.free(nullable);
    }
    return names;
  }

  static void _check(int rc, String context) {
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
      throw Exception('ODBC error in $context (rc=$rc)');
    }
  }
}
