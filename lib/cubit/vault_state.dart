part of 'vault_cubit.dart';

@immutable
sealed class VaultState {}

final class VaultClosed extends VaultState {}

final class VaultLoading extends VaultState {}

final class VaultLoadFailure extends VaultState {
  final String message;
  VaultLoadFailure(this.message);
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

  String fullPath(int i) {
    return join(root.path, vault.files[i].path);
  }

  ImageProvider defaultImage() {
    return const AssetImage('assets/images/unknown.png');
  }

  ImageProvider imageProvider(int i) {
    final filePath = fullPath(i);
    final mimeType = lookupMimeType(filePath);
    if (mimeType?.contains('image') ?? false) {
      return FileImage(File(filePath));
    }
    return defaultImage();
  }

  List<VaultTagValue> tags(Set<int> multi) {
    return multi.expand((i) => vault.files[i].tags).toList();
  }
}

extension ListValuePrinter on ListValue {
  String get asString =>
      '[${values.map((value) => value.asString).join(', ')}]';
}

extension ValuePrinter on Value {
  String get asString => switch (whichValue()) {
        Value_Value.boolValue => boolValue ? 'true' : 'false',
        Value_Value.stringValue => '"$stringValue"',
        Value_Value.intValue => '$intValue',
        Value_Value.floatValue => '$floatValue',
        Value_Value.listValue => listValue.asString,
        Value_Value.notSet => '',
      };
}

extension TagValuePrinter on VaultTagValue {
  String toYaml() => '$name: ${value.asString}';
}

extension TagListPrinter on List<VaultTagValue> {
  String toYaml() => map((tag) => tag.toYaml()).join('\n');
}
