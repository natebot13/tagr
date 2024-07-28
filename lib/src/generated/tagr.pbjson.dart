///
//  Generated code. Do not modify.
//  source: tagr.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use vaultDescriptor instead')
const Vault$json = const {
  '1': 'Vault',
  '2': const [
    const {'1': 'files', '3': 1, '4': 3, '5': 11, '6': '.VaultFile', '10': 'files'},
    const {'1': 'tag_types', '3': 2, '4': 3, '5': 11, '6': '.Vault.TagTypesEntry', '10': 'tagTypes'},
    const {'1': 'last_tag_id', '3': 3, '4': 1, '5': 5, '10': 'lastTagId'},
  ],
  '3': const [Vault_TagTypesEntry$json],
};

@$core.Deprecated('Use vaultDescriptor instead')
const Vault_TagTypesEntry$json = const {
  '1': 'TagTypesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 5, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.TagType', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `Vault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vaultDescriptor = $convert.base64Decode('CgVWYXVsdBIgCgVmaWxlcxgBIAMoCzIKLlZhdWx0RmlsZVIFZmlsZXMSMQoJdGFnX3R5cGVzGAIgAygLMhQuVmF1bHQuVGFnVHlwZXNFbnRyeVIIdGFnVHlwZXMSHgoLbGFzdF90YWdfaWQYAyABKAVSCWxhc3RUYWdJZBpFCg1UYWdUeXBlc0VudHJ5EhAKA2tleRgBIAEoBVIDa2V5Eh4KBXZhbHVlGAIgASgLMgguVGFnVHlwZVIFdmFsdWU6AjgB');
@$core.Deprecated('Use vaultFileDescriptor instead')
const VaultFile$json = const {
  '1': 'VaultFile',
  '2': const [
    const {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    const {'1': 'tags', '3': 2, '4': 1, '5': 11, '6': '.MapValue', '10': 'tags'},
  ],
};

/// Descriptor for `VaultFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vaultFileDescriptor = $convert.base64Decode('CglWYXVsdEZpbGUSEgoEcGF0aBgBIAEoCVIEcGF0aBIdCgR0YWdzGAIgASgLMgkuTWFwVmFsdWVSBHRhZ3M=');
@$core.Deprecated('Use tagTypeDescriptor instead')
const TagType$json = const {
  '1': 'TagType',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'category', '3': 3, '4': 1, '5': 9, '10': 'category'},
    const {'1': 'default_value', '3': 4, '4': 1, '5': 11, '6': '.TagValue', '10': 'defaultValue'},
    const {'1': 'is_flag', '3': 5, '4': 1, '5': 8, '10': 'isFlag'},
  ],
};

/// Descriptor for `TagType`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagTypeDescriptor = $convert.base64Decode('CgdUYWdUeXBlEg4KAmlkGAEgASgFUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhoKCGNhdGVnb3J5GAMgASgJUghjYXRlZ29yeRIuCg1kZWZhdWx0X3ZhbHVlGAQgASgLMgkuVGFnVmFsdWVSDGRlZmF1bHRWYWx1ZRIXCgdpc19mbGFnGAUgASgIUgZpc0ZsYWc=');
@$core.Deprecated('Use tagValueDescriptor instead')
const TagValue$json = const {
  '1': 'TagValue',
  '2': const [
    const {'1': 'bool_value', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'boolValue'},
    const {'1': 'string_value', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'stringValue'},
    const {'1': 'int_value', '3': 3, '4': 1, '5': 5, '9': 0, '10': 'intValue'},
    const {'1': 'float_value', '3': 4, '4': 1, '5': 2, '9': 0, '10': 'floatValue'},
    const {'1': 'list_value', '3': 5, '4': 1, '5': 11, '6': '.ListValue', '9': 0, '10': 'listValue'},
    const {'1': 'map_value', '3': 6, '4': 1, '5': 11, '6': '.MapValue', '9': 0, '10': 'mapValue'},
  ],
  '8': const [
    const {'1': 'value'},
  ],
};

/// Descriptor for `TagValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagValueDescriptor = $convert.base64Decode('CghUYWdWYWx1ZRIfCgpib29sX3ZhbHVlGAEgASgISABSCWJvb2xWYWx1ZRIjCgxzdHJpbmdfdmFsdWUYAiABKAlIAFILc3RyaW5nVmFsdWUSHQoJaW50X3ZhbHVlGAMgASgFSABSCGludFZhbHVlEiEKC2Zsb2F0X3ZhbHVlGAQgASgCSABSCmZsb2F0VmFsdWUSKwoKbGlzdF92YWx1ZRgFIAEoCzIKLkxpc3RWYWx1ZUgAUglsaXN0VmFsdWUSKAoJbWFwX3ZhbHVlGAYgASgLMgkuTWFwVmFsdWVIAFIIbWFwVmFsdWVCBwoFdmFsdWU=');
@$core.Deprecated('Use listValueDescriptor instead')
const ListValue$json = const {
  '1': 'ListValue',
  '2': const [
    const {'1': 'values', '3': 1, '4': 3, '5': 11, '6': '.TagValue', '10': 'values'},
  ],
};

/// Descriptor for `ListValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listValueDescriptor = $convert.base64Decode('CglMaXN0VmFsdWUSIQoGdmFsdWVzGAEgAygLMgkuVGFnVmFsdWVSBnZhbHVlcw==');
@$core.Deprecated('Use mapValueDescriptor instead')
const MapValue$json = const {
  '1': 'MapValue',
  '2': const [
    const {'1': 'values', '3': 1, '4': 3, '5': 11, '6': '.MapValue.ValuesEntry', '10': 'values'},
  ],
  '3': const [MapValue_ValuesEntry$json],
};

@$core.Deprecated('Use mapValueDescriptor instead')
const MapValue_ValuesEntry$json = const {
  '1': 'ValuesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 5, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.TagValue', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `MapValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mapValueDescriptor = $convert.base64Decode('CghNYXBWYWx1ZRItCgZ2YWx1ZXMYASADKAsyFS5NYXBWYWx1ZS5WYWx1ZXNFbnRyeVIGdmFsdWVzGkQKC1ZhbHVlc0VudHJ5EhAKA2tleRgBIAEoBVIDa2V5Eh8KBXZhbHVlGAIgASgLMgkuVGFnVmFsdWVSBXZhbHVlOgI4AQ==');
