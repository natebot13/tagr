///
//  Generated code. Do not modify.
//  source: tagr.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ValueType extends $pb.ProtobufEnum {
  static const ValueType bool_ = ValueType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'bool');
  static const ValueType string = ValueType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'string');
  static const ValueType int_ = ValueType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'int');
  static const ValueType float = ValueType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'float');
  static const ValueType list = ValueType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'list');

  static const $core.List<ValueType> values = <ValueType> [
    bool_,
    string,
    int_,
    float,
    list,
  ];

  static final $core.Map<$core.int, ValueType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ValueType? valueOf($core.int value) => _byValue[value];

  const ValueType._($core.int v, $core.String n) : super(v, n);
}

