import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:tagr/src/constants.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

final logger = Logger();

class VaultUpdate {
  Directory root;
  Vault vault;
  VaultUpdate(this.root, this.vault);
}

class VaultSaveException implements Exception {
  final String message;
  VaultSaveException(this.message);
}

class VaultRepository {
  final _vaultController = StreamController<VaultUpdate>.broadcast();
  Stream<VaultUpdate> get vault => _vaultController.stream;

  File _vaultDatabaseFile(Directory root) {
    return File(path.join(root.path, vaultFoldername, vaultFilename));
  }

  Future<void> _migrate(Directory root) async {
    final v1database = File(path.join(root.path, '.tagr'));
    if (!await v1database.exists()) return;
    if (await _vaultDatabaseFile(root).exists()) {
      logger.e(
          'A database already exists in the new location. Manual action is required.');
      return;
    }
    final backup = File(path.join(v1database.parent.path, 'backup.tagr'));
    await v1database.rename(backup.path);

    try {
      await _vaultDatabaseFile(root).create(recursive: true, exclusive: true);
    } on PathExistsException {
      logger.e('Huh? this should not have happened...');
    } on FileSystemException {
      logger.e('Failed to create new vault.');
    }
    await backup.rename(_vaultDatabaseFile(root).path);
  }

  Future<void> loadVault(Directory root) async {
    final vault = Vault();

    // Migrate breaking change
    await _migrate(root);

    try {
      final bytes = await _vaultDatabaseFile(root).readAsBytes();
      vault.mergeFromBuffer(bytes);
    } on PathNotFoundException {
      logger.i('Creating a new vault');
    }
    await refreshFiles(root, vault);
    _saveAndEmitVault(root, vault);
  }

  /// Given a path and current vault, scan the directory for new files that
  /// don't already exist in the vault.
  Future<void> refreshFiles(Directory root, Vault vault) async {
    final fileMap = <String, VaultFile>{};
    for (final file in vault.files) {
      if (!fileMap.containsKey(file.path)) {
        fileMap[file.path] = file;
        continue;
      }

      // Temp de-dup
      final vaultFile = fileMap[file.path]!;

      final a = vaultFile.hasTags() ? vaultFile.tags.values.length : 0;
      final b = file.hasTags() ? file.tags.values.length : 0;

      if (b > a) {
        fileMap[file.path] = file;
      }
    }

    vault.files.clear();

    await for (final file in _listFiles(root)) {
      final normalizedFilePath = _normalizeFilePath(root, file);
      vault.files.add(
        fileMap.containsKey(normalizedFilePath)
            ? fileMap[normalizedFilePath]!
            : VaultFile(path: normalizedFilePath),
      );
      fileMap.remove(normalizedFilePath);
    }

    // Deal with vault files not found on disk
    for (final file in fileMap.values) {
      if (file.hasTags() && file.tags.values.isNotEmpty) {
        vault.files.add(file..missing = true);
      }
    }
  }

  Future<void> saveVault(Directory root, Vault vault) async {
    try {
      _saveAndEmitVault(root, vault);
    } catch (e) {
      throw VaultSaveException('Failed to save vault. $e');
    }
  }

  /// Lists all files allowed in a vault, ignoring hidden files and folders.
  Stream<File> _listFiles(Directory dir) async* {
    await for (final entity in dir.list()) {
      final filename = path.basename(entity.path);
      if (filename.startsWith('.')) continue;
      if (entity is Directory) {
        yield* _listFiles(entity);
      } else if (entity is File) {
        yield entity;
      }
    }
  }

  String _normalizeFilePath(Directory root, File file) {
    final relativePath = path.relative(file.path, from: root.path);
    return relativePath.replaceAll(r'\', '/');
  }

  Future<void> _saveAndEmitVault(Directory root, Vault vault) async {
    final vaultDatabase = _vaultDatabaseFile(root);
    await Directory(vaultDatabase.parent.path).create(recursive: true);
    if (kDebugMode) {
      const encoder = JsonEncoder.withIndent('  ');
      await File(
        path.join(vaultDatabase.parent.path, '$vaultFilename.json'),
      ).writeAsString(
        encoder.convert(vault.toProto3Json() as Map<String, dynamic>),
      );
    }
    (await vaultDatabase.create(recursive: true))
        .writeAsBytes(vault.writeToBuffer());

    // Emit
    _vaultController.add(VaultUpdate(root, vault..freeze()));
  }
}
