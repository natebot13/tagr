///
//  Generated code. Do not modify.
//  source: tagr.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Vault extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Vault', createEmptyInstance: create)
    ..pc<VaultFile>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'files', $pb.PbFieldType.PM, subBuilder: VaultFile.create)
    ..m<$core.int, TagType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tagTypes', entryClassName: 'Vault.TagTypesEntry', keyFieldType: $pb.PbFieldType.O3, valueFieldType: $pb.PbFieldType.OM, valueCreator: TagType.create)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastTagId', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  Vault._() : super();
  factory Vault({
    $core.Iterable<VaultFile>? files,
    $core.Map<$core.int, TagType>? tagTypes,
    $core.int? lastTagId,
  }) {
    final _result = create();
    if (files != null) {
      _result.files.addAll(files);
    }
    if (tagTypes != null) {
      _result.tagTypes.addAll(tagTypes);
    }
    if (lastTagId != null) {
      _result.lastTagId = lastTagId;
    }
    return _result;
  }
  factory Vault.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Vault.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Vault clone() => Vault()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Vault copyWith(void Function(Vault) updates) => super.copyWith((message) => updates(message as Vault)) as Vault; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Vault create() => Vault._();
  Vault createEmptyInstance() => create();
  static $pb.PbList<Vault> createRepeated() => $pb.PbList<Vault>();
  @$core.pragma('dart2js:noInline')
  static Vault getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Vault>(create);
  static Vault? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<VaultFile> get files => $_getList(0);

  @$pb.TagNumber(2)
  $core.Map<$core.int, TagType> get tagTypes => $_getMap(1);

  @$pb.TagNumber(3)
  $core.int get lastTagId => $_getIZ(2);
  @$pb.TagNumber(3)
  set lastTagId($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLastTagId() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastTagId() => clearField(3);
}

class VaultFile extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'VaultFile', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'path')
    ..aOM<MapValue>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tags', subBuilder: MapValue.create)
    ..hasRequiredFields = false
  ;

  VaultFile._() : super();
  factory VaultFile({
    $core.String? path,
    MapValue? tags,
  }) {
    final _result = create();
    if (path != null) {
      _result.path = path;
    }
    if (tags != null) {
      _result.tags = tags;
    }
    return _result;
  }
  factory VaultFile.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VaultFile.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VaultFile clone() => VaultFile()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VaultFile copyWith(void Function(VaultFile) updates) => super.copyWith((message) => updates(message as VaultFile)) as VaultFile; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static VaultFile create() => VaultFile._();
  VaultFile createEmptyInstance() => create();
  static $pb.PbList<VaultFile> createRepeated() => $pb.PbList<VaultFile>();
  @$core.pragma('dart2js:noInline')
  static VaultFile getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VaultFile>(create);
  static VaultFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  @$pb.TagNumber(2)
  MapValue get tags => $_getN(1);
  @$pb.TagNumber(2)
  set tags(MapValue v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTags() => $_has(1);
  @$pb.TagNumber(2)
  void clearTags() => clearField(2);
  @$pb.TagNumber(2)
  MapValue ensureTags() => $_ensure(1);
}

class TagType extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TagType', createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id', $pb.PbFieldType.O3)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'category')
    ..aOM<TagValue>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultValue', subBuilder: TagValue.create)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isFlag')
    ..hasRequiredFields = false
  ;

  TagType._() : super();
  factory TagType({
    $core.int? id,
    $core.String? name,
    $core.String? category,
    TagValue? defaultValue,
    $core.bool? isFlag,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (category != null) {
      _result.category = category;
    }
    if (defaultValue != null) {
      _result.defaultValue = defaultValue;
    }
    if (isFlag != null) {
      _result.isFlag = isFlag;
    }
    return _result;
  }
  factory TagType.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TagType.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TagType clone() => TagType()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TagType copyWith(void Function(TagType) updates) => super.copyWith((message) => updates(message as TagType)) as TagType; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TagType create() => TagType._();
  TagType createEmptyInstance() => create();
  static $pb.PbList<TagType> createRepeated() => $pb.PbList<TagType>();
  @$core.pragma('dart2js:noInline')
  static TagType getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TagType>(create);
  static TagType? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get category => $_getSZ(2);
  @$pb.TagNumber(3)
  set category($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCategory() => $_has(2);
  @$pb.TagNumber(3)
  void clearCategory() => clearField(3);

  @$pb.TagNumber(4)
  TagValue get defaultValue => $_getN(3);
  @$pb.TagNumber(4)
  set defaultValue(TagValue v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasDefaultValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearDefaultValue() => clearField(4);
  @$pb.TagNumber(4)
  TagValue ensureDefaultValue() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get isFlag => $_getBF(4);
  @$pb.TagNumber(5)
  set isFlag($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsFlag() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsFlag() => clearField(5);
}

enum TagValue_Value {
  boolValue, 
  stringValue, 
  intValue, 
  floatValue, 
  listValue, 
  mapValue, 
  notSet
}

class TagValue extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, TagValue_Value> _TagValue_ValueByTag = {
    1 : TagValue_Value.boolValue,
    2 : TagValue_Value.stringValue,
    3 : TagValue_Value.intValue,
    4 : TagValue_Value.floatValue,
    5 : TagValue_Value.listValue,
    6 : TagValue_Value.mapValue,
    0 : TagValue_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TagValue', createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6])
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'boolValue')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'stringValue')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'intValue', $pb.PbFieldType.O3)
    ..a<$core.double>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'floatValue', $pb.PbFieldType.OF)
    ..aOM<ListValue>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'listValue', subBuilder: ListValue.create)
    ..aOM<MapValue>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mapValue', subBuilder: MapValue.create)
    ..hasRequiredFields = false
  ;

  TagValue._() : super();
  factory TagValue({
    $core.bool? boolValue,
    $core.String? stringValue,
    $core.int? intValue,
    $core.double? floatValue,
    ListValue? listValue,
    MapValue? mapValue,
  }) {
    final _result = create();
    if (boolValue != null) {
      _result.boolValue = boolValue;
    }
    if (stringValue != null) {
      _result.stringValue = stringValue;
    }
    if (intValue != null) {
      _result.intValue = intValue;
    }
    if (floatValue != null) {
      _result.floatValue = floatValue;
    }
    if (listValue != null) {
      _result.listValue = listValue;
    }
    if (mapValue != null) {
      _result.mapValue = mapValue;
    }
    return _result;
  }
  factory TagValue.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TagValue.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TagValue clone() => TagValue()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TagValue copyWith(void Function(TagValue) updates) => super.copyWith((message) => updates(message as TagValue)) as TagValue; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TagValue create() => TagValue._();
  TagValue createEmptyInstance() => create();
  static $pb.PbList<TagValue> createRepeated() => $pb.PbList<TagValue>();
  @$core.pragma('dart2js:noInline')
  static TagValue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TagValue>(create);
  static TagValue? _defaultInstance;

  TagValue_Value whichValue() => _TagValue_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.bool get boolValue => $_getBF(0);
  @$pb.TagNumber(1)
  set boolValue($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBoolValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoolValue() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get stringValue => $_getSZ(1);
  @$pb.TagNumber(2)
  set stringValue($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStringValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearStringValue() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get intValue => $_getIZ(2);
  @$pb.TagNumber(3)
  set intValue($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIntValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearIntValue() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get floatValue => $_getN(3);
  @$pb.TagNumber(4)
  set floatValue($core.double v) { $_setFloat(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFloatValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearFloatValue() => clearField(4);

  @$pb.TagNumber(5)
  ListValue get listValue => $_getN(4);
  @$pb.TagNumber(5)
  set listValue(ListValue v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasListValue() => $_has(4);
  @$pb.TagNumber(5)
  void clearListValue() => clearField(5);
  @$pb.TagNumber(5)
  ListValue ensureListValue() => $_ensure(4);

  @$pb.TagNumber(6)
  MapValue get mapValue => $_getN(5);
  @$pb.TagNumber(6)
  set mapValue(MapValue v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasMapValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearMapValue() => clearField(6);
  @$pb.TagNumber(6)
  MapValue ensureMapValue() => $_ensure(5);
}

class ListValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ListValue', createEmptyInstance: create)
    ..pc<TagValue>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'values', $pb.PbFieldType.PM, subBuilder: TagValue.create)
    ..hasRequiredFields = false
  ;

  ListValue._() : super();
  factory ListValue({
    $core.Iterable<TagValue>? values,
  }) {
    final _result = create();
    if (values != null) {
      _result.values.addAll(values);
    }
    return _result;
  }
  factory ListValue.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ListValue.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ListValue clone() => ListValue()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ListValue copyWith(void Function(ListValue) updates) => super.copyWith((message) => updates(message as ListValue)) as ListValue; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ListValue create() => ListValue._();
  ListValue createEmptyInstance() => create();
  static $pb.PbList<ListValue> createRepeated() => $pb.PbList<ListValue>();
  @$core.pragma('dart2js:noInline')
  static ListValue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListValue>(create);
  static ListValue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<TagValue> get values => $_getList(0);
}

class MapValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MapValue', createEmptyInstance: create)
    ..m<$core.int, TagValue>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'values', entryClassName: 'MapValue.ValuesEntry', keyFieldType: $pb.PbFieldType.O3, valueFieldType: $pb.PbFieldType.OM, valueCreator: TagValue.create)
    ..hasRequiredFields = false
  ;

  MapValue._() : super();
  factory MapValue({
    $core.Map<$core.int, TagValue>? values,
  }) {
    final _result = create();
    if (values != null) {
      _result.values.addAll(values);
    }
    return _result;
  }
  factory MapValue.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MapValue.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MapValue clone() => MapValue()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MapValue copyWith(void Function(MapValue) updates) => super.copyWith((message) => updates(message as MapValue)) as MapValue; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MapValue create() => MapValue._();
  MapValue createEmptyInstance() => create();
  static $pb.PbList<MapValue> createRepeated() => $pb.PbList<MapValue>();
  @$core.pragma('dart2js:noInline')
  static MapValue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MapValue>(create);
  static MapValue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, TagValue> get values => $_getMap(0);
}

