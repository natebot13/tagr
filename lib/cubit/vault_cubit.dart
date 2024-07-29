import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:protobuf/protobuf.dart';
import 'package:tagr/src/constants.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/generated/tagr.pbserver.dart';

import 'package:logger/logger.dart';

part 'vault_state.dart';

final logger = Logger();

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
      logger.i('Creating a new vault');
      await _refreshFiles(VaultOpen(root, vault), vault);
      _saveVault(root, vault);
    }
    emit(VaultOpen(root, vault..freeze()));
  }

  /// Modifies the vault in-place
  Future<bool> _refreshFiles(VaultOpen state, Vault vault) async {
    bool changed = false;
    await for (final file in listFiles(state.root)) {
      if (state.fileMap.containsKey(file.path)) continue;
      vault.files.add(_buildVaultFile(state.root, file));
      changed = true;
    }
    return changed;
  }

  void refreshFilesInVault() {
    _updateVault(_refreshFiles);
  }

  Future<void> _updateVault(
    FutureOr<bool> Function(VaultOpen, Vault) fn,
  ) async {
    await _withVaultOpen((state) async {
      final newVault = state.vault.deepCopy();
      if (await fn(state, newVault)) {
        emit(VaultOpen(state.root, newVault..freeze()));
        await _saveVault(state.root, newVault);
      } else {
        emit(VaultOpen(
          state.root,
          state.vault,
          ephemeralIssue: 'Action failed',
        ));
      }
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
        path.join(root.path, '$vaultFilename.json'),
      ).writeAsString(
        encoder.convert(vault.toProto3Json() as Map<String, dynamic>),
      );
    }
    await File(path.join(root.path, vaultFilename))
        .writeAsBytes(vault.writeToBuffer());
  }

  VaultFile _buildVaultFile(Directory root, File file) {
    final relativePath = path.relative(file.path, from: root.path);
    return VaultFile(path: relativePath.replaceAll(r'\', '/'));
  }

  VaultFile? _getVaultFile(String id, VaultOpen state, Vault vault) {
    final index = state.fileMap[id];
    if (index == null) {
      logger.e('fileMap missing id: $id');
      return null;
    }
    if (index >= vault.files.length) {
      logger.e('Out of bounds vault file index: $index');
      return null;
    }
    return vault.files[index];
  }

  /// Lists all files allowed in a vault, ignoring hidden files and folders.
  Stream<File> listFiles(Directory dir) async* {
    await for (final entity in dir.list()) {
      if (path.basename(entity.path).startsWith('.')) continue;
      if (entity is Directory) {
        yield* listFiles(entity);
      } else if (entity is File) {
        yield entity;
      }
    }
  }

  void updateTag(Set<String> fileIds, int tagTypeId, [TagValue? value]) {
    _updateVault((state, vault) {
      if (!vault.tagTypes.containsKey(tagTypeId)) {
        logger.e('TagTypes missing id: $tagTypeId');
        return false;
      }
      bool changed = false;
      for (final fileId in fileIds) {
        final vaultFile = _getVaultFile(fileId, state, vault);
        if (vaultFile == null) return false;
        value ??= vault.tagTypes[tagTypeId]!.defaultValue;
        if (!vaultFile.hasTags()) vaultFile.tags = MapValue();
        if (vaultFile.tags.values[tagTypeId] != value) {
          vaultFile.tags.values[tagTypeId] = value!;
          changed = true;
        }
      }
      return changed;
    });
  }

  void removeTag({required Set<String> from, required int tagId}) {
    _updateVault((state, vault) {
      bool changed = false;
      for (final fileId in from) {
        final vaultFile = _getVaultFile(fileId, state, vault);
        if (vaultFile == null) return false;
        if (!vaultFile.hasTags()) return false;
        if (vaultFile.tags.values.remove(tagId) != null) {
          if (vaultFile.tags.values.isEmpty) vaultFile.clearTags();
          changed = true;
        }
      }
      return changed;
    });
  }

  void createTag() {
    _updateVault((state, vault) {
      final tagId = vault.lastTagId++;
      vault.tagTypes[tagId] = TagType(
        id: tagId,
        name: 'tag_$tagId',
        defaultValue: TagValue(boolValue: true),
        isFlag: true,
        category: 'tags',
      );
      return true;
    });
  }

  /// Pass a new instance of a TagType to merge with the current tag type. Don't
  /// reuse the passed update object as it gets updated in place.
  void updateTagType(int tagId, TagType update) {
    _updateVault((state, vault) {
      final tagType = vault.tagTypes[tagId];
      if (tagType == null) return false;

      final updated = tagType.deepCopy()..mergeFromMessage(update);
      if (tagType == updated) return false;

      tagType.mergeFromMessage(update);
      return true;
    });
  }
}
