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
  final TagType tagType;

  /// The value will be set if all selected files have the same value, otherwise null
  final TagValue? tagValue;

  /// Partial will be true if only some of the selected files have this tagType
  final bool partial;

  TagTypeValuePair({
    required this.tagType,
    this.tagValue,
    this.partial = false,
  });

  TagTypeValuePair withPartial() => TagTypeValuePair(
        tagType: tagType,
        partial: true,
      );
}

final class VaultOpen extends VaultState {
  final String? ephemeralIssue;
  final Directory root;
  final Vault vault;
  final Map<String, int> fileMap;
  final Map<String, int> tagMap;
  VaultOpen(this.root, this.vault, {this.ephemeralIssue})
      // This may be slow for many files. Need to think if this is necessary
      : fileMap = vault.files
            .asMap()
            .map((index, file) => MapEntry(file.path, index)),
        tagMap = vault.tagTypes
            .map((id, type) => MapEntry(type.name.toLowerCase(), id));

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
          TagTypeValuePair(
            tagType: vault.tagTypes[entry.key]!,
            tagValue: entry.value,
          ),
        ),
      ),
    );
    if (ids.length == 1) return Map.fromEntries(entries);

    // Find the tags that exist in all of the selected files
    final commonTags = entries.duplicates(
      (entry) => entry.key,
      (c) => c == ids.length,
    );
    // Find the tags that exist on only some of the selected files
    final uncommonTags = entries.duplicates(
      (entry) => entry.key,
      (c) => c < ids.length,
    );
    final result = <int, TagTypeValuePair>{};
    for (final entry in commonTags) {
      result[entry.key] = _mergeValues(result[entry.key], entry.value);
    }
    for (final entry in uncommonTags) {
      result[entry.key] ??= entry.value.withPartial();
    }
    return result;
  }

  /// Should only be called on two values with the same type. If they aren't the
  /// same type, the vault data must me inconsistent with the tag data, and an
  /// assertion error is thrown.
  TagTypeValuePair _mergeValues(TagTypeValuePair? a, TagTypeValuePair b) {
    if (a == null) return b;
    assert(a.tagType == b.tagType, 'Inconsistent tagType and file tag value');

    // If the values are the same, return one of the values. If they aren't the
    // same, return null as the value, which indicates that the tag is present,
    // but the values differ, surfacing the opportunity to edit them all at once
    // and make them all the same.
    return TagTypeValuePair(
      tagType: b.tagType,
      tagValue: a.tagValue == b.tagValue ? b.tagValue : null,
    );
  }
}
