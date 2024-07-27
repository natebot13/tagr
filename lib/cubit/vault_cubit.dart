import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:tagr/src/constants.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

part 'vault_state.dart';

class VaultCubit extends Cubit<VaultState> {
  VaultCubit() : super(VaultClosed());

  void openVault(String path) async {
    emit(VaultLoading());
    if (!await FileSystemEntity.isDirectory(path)) {
      emit(VaultLoadFailure('Path is not a directory.'));
    }

    final root = Directory(path);

    final vaultFile = File('$path/$vaultFilename');
    final vault = Vault();
    if (await vaultFile.exists()) {
      final bytes = await vaultFile.readAsBytes();
      vault.mergeFromBuffer(bytes);
    } else {
      print('Creating a new vault');
      await _refreshFiles(VaultOpen(root, vault), vault);
      _saveVault(root, vault);
    }
    emit(VaultOpen(root, vault..freeze()));
  }

  /// Modifies the vault in-place
  Future<void> _refreshFiles(VaultOpen state, Vault vault) async {
    await for (final file in listFiles(state.root)) {
      if (state.fileMap.containsKey(file.path)) continue;
      vault.files.add(_buildVaultFile(state.root, file));
    }
  }

  void refreshFilesInVault() {
    _updateVault(_refreshFiles);
  }

  Future<void> _updateVault(
    FutureOr<void> Function(VaultOpen, Vault) fn,
  ) async {
    await _withVaultOpen((state) async {
      final newVault = state.vault.toBuilder() as Vault;
      await fn(state, newVault);
      emit(VaultOpen(state.root, newVault..freeze()));
      await _saveVault(state.root, newVault);
    });
  }

  Future<T?> _withVaultOpen<T>(FutureOr<T> Function(VaultOpen state) fn) async {
    if (state is VaultOpen) {
      return await fn(state as VaultOpen);
    }
    return null;
  }

  Future<void> _saveVault(Directory root, Vault vault) async {
    // TODO: remove once done with debugging
    {
      const encoder = JsonEncoder.withIndent('  ');
      await File(
        join(root.path, '$vaultFilename.json'),
      ).writeAsString(
        encoder.convert(vault.toProto3Json() as Map<String, dynamic>),
      );
    }
    await File(join(root.path, vaultFilename))
        .writeAsBytes(vault.writeToBuffer());
  }

  VaultFile _buildVaultFile(Directory root, File file) {
    final relativePath = relative(file.path, from: root.path);
    return VaultFile(path: relativePath);
  }

  /// Lists all files allowed in a vault, ignoring hidden files and folders.
  Stream<File> listFiles(Directory dir) async* {
    await for (final entity in dir.list()) {
      if (basename(entity.path).startsWith('.')) continue;
      if (entity is Directory) {
        yield* listFiles(entity);
      } else if (entity is File) {
        yield entity;
      }
    }
  }
}
