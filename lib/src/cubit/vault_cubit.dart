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

  void updateTag(Set<String> fileIds, int tagTypeId, [TagValue? value]) {
    _updateVault((state, vault) {
      if (!vault.tagTypes.containsKey(tagTypeId)) {
        logger.e('TagTypes missing id: $tagTypeId');
        return false;
      }
      return _updateTag(
        fileIds: fileIds,
        tagTypeId: tagTypeId,
        state: state,
        vault: vault,
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
      final vaultFile = _getVaultFile(fileId, state, vault);
      if (vaultFile == null) return false;
      value ??= vault.tagTypes[tagTypeId]!.defaultValue;
      if (!vaultFile.hasTags()) vaultFile.tags = MapValue();
      if (vaultFile.tags.values[tagTypeId] != value) {
        vaultFile.tags.values[tagTypeId] = value;
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
