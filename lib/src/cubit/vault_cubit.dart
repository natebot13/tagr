import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:protobuf/protobuf.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

import 'package:logger/logger.dart';
import 'package:tagr/src/repository/vault_repository.dart';

part 'vault_state.dart';

final logger = Logger();

class VaultCubit extends Cubit<VaultState> {
  final VaultRepository _repository;
  StreamSubscription<VaultUpdate>? subscription;
  VaultCubit(VaultRepository repository)
      : _repository = repository,
        super(VaultClosed()) {
    subscription = _repository.vault.listen((vaultUpdate) {
      emit(VaultOpen(vaultUpdate.root, vaultUpdate.vault));
    });
  }

  @override
  Future<void> close() {
    subscription?.cancel();
    return super.close();
  }

  Future<void> openVault(String path) async {
    emit(VaultLoading());
    await changeRoot(path);
  }

  Future<void> changeRoot(String path) async {
    // Copy for type promotion
    final _state = state;

    if (_state is VaultOpen && _state.root.path == path) return;

    if (!await FileSystemEntity.isDirectory(path)) {
      if (_state is VaultOpen) {
        emit(VaultOpen(
          _state.root,
          _state.vault,
          ephemeralIssue: 'Failed to open. $path is not a directory.',
        ));
      } else {
        emit(VaultLoadFailure('Failed to open. $path is not a directory.'));
      }
    }
    _repository.loadVault(Directory(path));
  }

  void refreshFilesInVault() {
    _updateVault((state, vault) {
      _repository.refreshFiles(state.root, vault);
      return true;
    });
  }

  Future<bool> _updateVault(
    FutureOr<bool> Function(VaultOpen, Vault) fn,
  ) async {
    final result = await _withVaultOpen((state) async {
      final newVault = state.vault.deepCopy();
      try {
        if (await fn(state, newVault)) {
          await _repository.saveVault(state.root, newVault);
          return true;
        }
      } on VaultSaveException catch (e) {
        emit(VaultOpen(
          state.root,
          state.vault,
          ephemeralIssue: e.message,
        ));
      }
      return false;
    });
    return result ?? false;
  }

  Future<T?> _withVaultOpen<T>(FutureOr<T> Function(VaultOpen state) fn) async {
    if (state is VaultOpen) {
      return await fn(state as VaultOpen);
    }
    return null;
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

  Future<void> updateTag(
    Set<String> fileIds,
    int tagTypeId, [
    TagValue? value,
  ]) {
    return _updateVault((state, vault) {
      if (!vault.tagTypes.containsKey(tagTypeId)) {
        logger.e('TagTypes missing id: $tagTypeId');
        return false;
      }
      return _updateTag(
        fileIds: fileIds,
        tagTypeId: tagTypeId,
        state: state,
        vault: vault,
        value: value,
      );
    });
  }

  bool _updateTag({
    required Set<String> fileIds,
    required int tagTypeId,
    required VaultOpen state,
    required Vault vault,
    TagValue? value,
  }) {
    bool changed = false;
    for (final fileId in fileIds) {
      var eachValue = value;
      final vaultFile = _getVaultFile(fileId, state, vault);
      if (vaultFile == null) return false;
      if (!vaultFile.hasTags()) vaultFile.tags = MapValue();
      final tagTypeDefaultValue = vault.tagTypes[tagTypeId]?.defaultValue;
      final tagValue = vaultFile.tags.values[tagTypeId];
      if (eachValue == null) {
        if (tagTypeDefaultValue?.whichValue() == tagValue?.whichValue()) {
          eachValue = tagValue ?? TagValue();
        } else {
          eachValue = TagValue();
        }
      }
      if (vaultFile.tags.values[tagTypeId] != eachValue) {
        vaultFile.tags.values[tagTypeId] = eachValue;
        changed = true;
      }
    }
    return changed;
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

  Future<bool> createTag({String? name, Set<String>? fileIds}) async {
    return await _updateVault((state, vault) {
      if (name != null && state.tagMap.containsKey(name.toLowerCase())) {
        logger.i('Tag [$name] already exists');
        return false;
      }
      final tagId = vault.lastTagId++;
      vault.tagTypes[tagId] = TagType(
        id: tagId,
        name: name ?? 'tag_$tagId',
        defaultValue: TagValue(boolValue: true),
        isFlag: true,
        category: 'tags',
      );
      if (fileIds != null) {
        _updateTag(
          fileIds: fileIds,
          tagTypeId: tagId,
          state: state,
          vault: vault,
        );
      }
      return true;
    });
  }

  /// The vault's tag type, located using [tagId], is merged with [update].
  ///
  /// Important note: We don't update all the vault files if a tag type changes.
  /// This means that files could have the wrong tag value type. When reading
  /// the tags of a file, check the tag type for the correct type and reassign
  /// the tag's value when convenient.
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
