///
//  Generated code. Do not modify.
//  source: tagr.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use valueTypeDescriptor instead')
const ValueType$json = const {
  '1': 'ValueType',
  '2': const [
    const {'1': 'bool', '2': 0},
    const {'1': 'string', '2': 1},
    const {'1': 'int', '2': 2},
    const {'1': 'float', '2': 3},
    const {'1': 'list', '2': 4},
  ],
};

/// Descriptor for `ValueType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List valueTypeDescriptor = $convert.base64Decode('CglWYWx1ZVR5cGUSCAoEYm9vbBAAEgoKBnN0cmluZxABEgcKA2ludBACEgkKBWZsb2F0EAMSCAoEbGlzdBAE');
@$core.Deprecated('Use vaultDescriptor instead')
const Vault$json = const {
  '1': 'Vault',
  '2': const [
    const {'1': 'files', '3': 1, '4': 3, '5': 11, '6': '.VaultFile', '10': 'files'},
    const {'1': 'tagTypes', '3': 2, '4': 3, '5': 11, '6': '.Vault.TagTypesEntry', '10': 'tagTypes'},
  ],
  '3': const [Vault_TagTypesEntry$json],
};

@$core.Deprecated('Use vaultDescriptor instead')
const Vault_TagTypesEntry$json = const {
  '1': 'TagTypesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.VaultTagType', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `Vault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vaultDescriptor = $convert.base64Decode('CgVWYXVsdBIgCgVmaWxlcxgBIAMoCzIKLlZhdWx0RmlsZVIFZmlsZXMSMAoIdGFnVHlwZXMYAiADKAsyFC5WYXVsdC5UYWdUeXBlc0VudHJ5Ugh0YWdUeXBlcxpKCg1UYWdUeXBlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EiMKBXZhbHVlGAIgASgLMg0uVmF1bHRUYWdUeXBlUgV2YWx1ZToCOAE=');
@$core.Deprecated('Use vaultFileDescriptor instead')
const VaultFile$json = const {
  '1': 'VaultFile',
  '2': const [
    const {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    const {'1': 'tags', '3': 2, '4': 3, '5': 11, '6': '.VaultTagValue', '10': 'tags'},
  ],
};

/// Descriptor for `VaultFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vaultFileDescriptor = $convert.base64Decode('CglWYXVsdEZpbGUSEgoEcGF0aBgBIAEoCVIEcGF0aBIiCgR0YWdzGAIgAygLMg4uVmF1bHRUYWdWYWx1ZVIEdGFncw==');
@$core.Deprecated('Use vaultTagTypeDescriptor instead')
const VaultTagType$json = const {
  '1': 'VaultTagType',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'category', '3': 2, '4': 1, '5': 9, '10': 'category'},
    const {'1': 'type', '3': 3, '4': 1, '5': 14, '6': '.ValueType', '10': 'type'},
  ],
};

/// Descriptor for `VaultTagType`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vaultTagTypeDescriptor = $convert.base64Decode('CgxWYXVsdFRhZ1R5cGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIaCghjYXRlZ29yeRgCIAEoCVIIY2F0ZWdvcnkSHgoEdHlwZRgDIAEoDjIKLlZhbHVlVHlwZVIEdHlwZQ==');
@$core.Deprecated('Use vaultTagValueDescriptor instead')
const VaultTagValue$json = const {
  '1': 'VaultTagValue',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.Value', '10': 'value'},
  ],
};

/// Descriptor for `VaultTagValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vaultTagValueDescriptor = $convert.base64Decode('Cg1WYXVsdFRhZ1ZhbHVlEhIKBG5hbWUYASABKAlSBG5hbWUSHAoFdmFsdWUYAiABKAsyBi5WYWx1ZVIFdmFsdWU=');
@$core.Deprecated('Use valueDescriptor instead')
const Value$json = const {
  '1': 'Value',
  '2': const [
    const {'1': 'boolValue', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'boolValue'},
    const {'1': 'stringValue', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'stringValue'},
    const {'1': 'intValue', '3': 3, '4': 1, '5': 5, '9': 0, '10': 'intValue'},
    const {'1': 'floatValue', '3': 4, '4': 1, '5': 2, '9': 0, '10': 'floatValue'},
    const {'1': 'listValue', '3': 5, '4': 1, '5': 11, '6': '.ListValue', '9': 0, '10': 'listValue'},
  ],
  '8': const [
    const {'1': 'value'},
  ],
};

/// Descriptor for `Value`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueDescriptor = $convert.base64Decode('CgVWYWx1ZRIeCglib29sVmFsdWUYASABKAhIAFIJYm9vbFZhbHVlEiIKC3N0cmluZ1ZhbHVlGAIgASgJSABSC3N0cmluZ1ZhbHVlEhwKCGludFZhbHVlGAMgASgFSABSCGludFZhbHVlEiAKCmZsb2F0VmFsdWUYBCABKAJIAFIKZmxvYXRWYWx1ZRIqCglsaXN0VmFsdWUYBSABKAsyCi5MaXN0VmFsdWVIAFIJbGlzdFZhbHVlQgcKBXZhbHVl');
@$core.Deprecated('Use listValueDescriptor instead')
const ListValue$json = const {
  '1': 'ListValue',
  '2': const [
    const {'1': 'values', '3': 1, '4': 3, '5': 11, '6': '.Value', '10': 'values'},
  ],
};

/// Descriptor for `ListValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listValueDescriptor = $convert.base64Decode('CglMaXN0VmFsdWUSHgoGdmFsdWVzGAEgAygLMgYuVmFsdWVSBnZhbHVlcw==');
