import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  final _vaultController = StreamController<VaultUpdate>();
  Stream<VaultUpdate> get vault => _vaultController.stream;

  Future<void> loadVault(Directory root) async {
    final vaultFile = File('${root.path}/$vaultFilename');
    final vault = Vault();

    try {
      final bytes = await vaultFile.readAsBytes();
      vault.mergeFromBuffer(bytes);
    } on PathNotFoundException {
      logger.i('Creating a new vault');
      await refreshFiles(root, vault);
    }
    _saveAndEmitVault(root, vault);
  }

  /// Given a path and current vault, scan the directory for new files that
  /// don't already exist in the vault.
  Future<void> refreshFiles(Directory root, Vault vault) async {
    final fileMap = Map.fromEntries(
      vault.files.map((vaultFile) => MapEntry(vaultFile.path, vaultFile)),
    );

    await for (final file in _listFiles(root)) {
      if (fileMap.containsKey(file.path)) continue;
      vault.files.add(_buildVaultFile(root, file));
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
      if (path.basename(entity.path).startsWith('.')) continue;
      if (entity is Directory) {
        yield* _listFiles(entity);
      } else if (entity is File) {
        yield entity;
      }
    }
  }

  VaultFile _buildVaultFile(Directory root, File file) {
    final relativePath = path.relative(file.path, from: root.path);
    return VaultFile(path: relativePath.replaceAll(r'\', '/'));
  }

  Future<void> _saveAndEmitVault(Directory root, Vault vault) async {
    // TODO: remove once done with debugging
    {
      const encoder = JsonEncoder.withIndent('  ');
      await File(
        path.join(root.path, '$vaultFilename.json'),
      ).writeAsString(
        encoder.convert(vault.toProto3Json() as Map<String, dynamic>),
      );
    }
    await File(path.join(root.path, vaultFilename))
        .writeAsBytes(vault.writeToBuffer());

    // Emit
    _vaultController.add(VaultUpdate(root, vault..freeze()));
  }
}
