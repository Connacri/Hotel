import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class NativeMdbReader {
  NativeMdbReader._();

  static const MethodChannel _channel =
      MethodChannel('hotel/native_mdb_reader');

  static const String _powerShellScript = r'''
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Decode-Utf8Base64([string]$value) {
  if ([string]::IsNullOrEmpty($value)) {
    return $null
  }

  return [System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String($value)
  )
}

$path = Decode-Utf8Base64 $env:HOTEL_MDB_PATH_B64
$table = Decode-Utf8Base64 $env:HOTEL_MDB_TABLE_B64
$mode = $env:HOTEL_MDB_MODE

$connectionStrings = @(
  "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=$path;Uid=Admin;Pwd=;ReadOnly=1;",
  "Driver={Microsoft Access Driver (*.mdb)};Dbq=$path;Uid=Admin;Pwd=;ReadOnly=1;"
)

$lastErrorText = $null

foreach ($connectionString in $connectionStrings) {
  $connection = $null
  try {
    $connection = New-Object System.Data.Odbc.OdbcConnection($connectionString)
    $connection.Open()

    if ($mode -eq 'check') {
      @{ ok = $true } | ConvertTo-Json -Compress
      exit 0
    }

    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT * FROM [$table]"
    $reader = $command.ExecuteReader()
    $rows = New-Object System.Collections.Generic.List[object]

    while ($reader.Read()) {
      $row = New-Object object[] $reader.FieldCount
      for ($i = 0; $i -lt $reader.FieldCount; $i++) {
        if ($reader.IsDBNull($i)) {
          $row[$i] = $null
        } else {
          $row[$i] = [string]$reader.GetValue($i)
        }
      }
      [void]$rows.Add($row)
    }

    $reader.Close()
    @{ rows = @($rows) } | ConvertTo-Json -Compress -Depth 5
    exit 0
  } catch {
    $lastErrorText = $_.Exception.ToString()
  } finally {
    if ($connection -ne $null) {
      $connection.Dispose()
    }
  }
}

if ($lastErrorText) {
  [Console]::Error.WriteLine($lastErrorText)
} else {
  [Console]::Error.WriteLine(
    'Unable to open MDB through native Windows providers.'
  )
}

exit 1
''';

  static bool get isSupported => Platform.isWindows;

  static Future<void> checkRequirements(String mdbPath) async {
    if (!isSupported) {
      throw UnsupportedError(
        'La lecture native de fichiers MDB est uniquement disponible sous Windows.',
      );
    }

    try {
      await _channel.invokeMethod<void>('checkAccessSupport', {
        'path': mdbPath,
      });
    } on PlatformException catch (nativeError) {
      await _runPowerShell(mode: 'check', mdbPath: mdbPath, nativeError: nativeError);
    }
  }

  static Future<List<List<String?>>> readTable(
    String mdbPath,
    String table,
  ) async {
    if (!isSupported) {
      throw UnsupportedError(
        'La lecture native de fichiers MDB est uniquement disponible sous Windows.',
      );
    }

    List<Object?>? rows;
    try {
      rows = await _channel.invokeMethod<List<Object?>>(
        'readTable',
        {
          'path': mdbPath,
          'table': table,
        },
      );
    } on PlatformException catch (nativeError) {
      return _runPowerShell(
        mode: 'read',
        mdbPath: mdbPath,
        table: table,
        nativeError: nativeError,
      );
    }

    if (rows == null) {
      return const [];
    }

    return rows
        .map(
          (row) => (row as List<Object?>)
              .map((value) => value as String?)
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  static Future<List<List<String?>>> _runPowerShell({
    required String mode,
    required String mdbPath,
    String? table,
    PlatformException? nativeError,
  }) async {
    final result = await Process.run(
      _powerShellPath,
      [
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        _powerShellScript,
      ],
      environment: {
        'HOTEL_MDB_MODE': mode,
        'HOTEL_MDB_PATH_B64': base64Encode(utf8.encode(mdbPath)),
        'HOTEL_MDB_TABLE_B64': base64Encode(utf8.encode(table ?? '')),
      },
      runInShell: false,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      final buffer = StringBuffer(
        'Impossible de lire le fichier MDB via les fournisseurs natifs Windows.',
      );

      final stderr = (result.stderr as String).trim();
      if (stderr.isNotEmpty) {
        buffer.write('\n$stderr');
      }

      if (nativeError != null && nativeError.message?.isNotEmpty == true) {
        buffer.write('\n\nErreur ODBC x64:\n${nativeError.message}');
      }

      throw Exception(buffer.toString());
    }

    if (mode == 'check') {
      return const [];
    }

    final stdout = (result.stdout as String).trim();
    if (stdout.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(stdout);
    final payload = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final rows = payload['rows'];
    if (rows is! List) {
      return const [];
    }

    return rows
        .map<List<String?>>((row) {
          if (row is! List) {
            return const <String?>[];
          }
          return row.map((value) => value as String?).toList(growable: false);
        })
        .toList(growable: false);
  }

  static String get _powerShellPath {
    final windowsDir = Platform.environment['WINDIR'] ?? r'C:\Windows';
    final wow64Path =
        '$windowsDir\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe';
    if (File(wow64Path).existsSync()) {
      return wow64Path;
    }
    return 'powershell.exe';
  }
}
