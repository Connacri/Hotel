import 'dart:io';

import 'package:flutter/services.dart';

class NativeMdbReader {
  NativeMdbReader._();

  static const MethodChannel _channel =
      MethodChannel('hotel/native_mdb_reader');

  static bool get isSupported => Platform.isWindows;

  static Future<void> checkRequirements(String mdbPath) async {
    if (!isSupported) {
      throw UnsupportedError(
        'La lecture native de fichiers MDB est uniquement disponible sous Windows.',
      );
    }

    await _channel.invokeMethod<void>('checkAccessSupport', {
      'path': mdbPath,
    });
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

    final rows = await _channel.invokeMethod<List<Object?>>(
      'readTable',
      {
        'path': mdbPath,
        'table': table,
      },
    );

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
}
