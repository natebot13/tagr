part of 'vault_cubit.dart';

@immutable
sealed class VaultState {}

final class VaultClosed extends VaultState {}

final class VaultLoading extends VaultState {}

final class VaultLoadFailure extends VaultState {
  final String message;
  VaultLoadFailure(this.message);
}

class TagTypeValuePair {
  final Set<String> fileIds;
  final TagType tagType;
  final TagValue? tagValue;
  TagTypeValuePair(this.fileIds, this.tagType, this.tagValue);
}

final class VaultOpen extends VaultState {
  final String? ephemeralIssue;
  final Directory root;
  final Vault vault;
  final Map<String, int> fileMap;
  VaultOpen(this.root, this.vault, {this.ephemeralIssue})
      : fileMap = vault.files
            .asMap()
            .map((index, file) => MapEntry(file.path, index));

  String fullPath(String id) {
    final i = fileMap[id]!;
    return path.join(root.path, vault.files[i].path);
  }

  ImageProvider defaultImage() {
    return const AssetImage('assets/images/unknown.png');
  }

  ImageProvider imageProvider(String? id) {
    if (id == null) return defaultImage();
    final filePath = fullPath(id);
    final mimeType = lookupMimeType(filePath);
    if (mimeType?.contains('image') ?? false) {
      return FileImage(File(filePath));
    }
    return defaultImage();
  }

  Map<int, TagTypeValuePair> tags(Set<String> ids) {
    final entries = ids.expand(
      (id) => vault.files[fileMap[id]!].tags.values.entries.map(
        (entry) => MapEntry(
          entry.key,
          TagTypeValuePair({id}, vault.tagTypes[entry.key]!, entry.value),
        ),
      ),
    );
    if (ids.length == 1) return Map.fromEntries(entries);

    // Join tags from multiple vault files, only keeping common tags
    final commonTags = entries.duplicates(
      (entry) => entry.key,
      (c) => c == ids.length,
    );
    final result = <int, TagTypeValuePair>{};
    for (final entry in commonTags) {
      result[entry.key] = _mergeValues(result[entry.key], entry.value);
    }
    return result;
  }

  /// Should only be called on two values with the same type. If they aren't the
  /// same type, the vault data must me inconsistent with the tag data, and an
  /// assertion error is thrown.
  TagTypeValuePair _mergeValues(TagTypeValuePair? a, TagTypeValuePair b) {
    if (a == null) return b;
    assert(a.tagType == b.tagType);

    // If the values are the same, return one of the values. If they aren't the
    // same, return null as the value, which indicates that the tag is present,
    // but the values differ, surfacing the opportunity to edit them all at once
    // and make them all the same.
    return TagTypeValuePair(
      a.fileIds.union(b.fileIds),
      b.tagType,
      a.tagValue == b.tagValue ? b.tagValue : null,
    );
  }
}
