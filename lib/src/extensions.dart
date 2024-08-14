import 'dart:io';

import 'package:tagr/src/generated/tagr.pb.dart';

extension CustomUpdation on Map<dynamic, int> {
  int increment(dynamic key) {
    return update(key, (value) => ++value, ifAbsent: () => 1);
  }
}

bool _moreThanOne(int c) => c > 1;

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> duplicates<K>(
    K Function(T) key, [
    bool Function(int) countCheck = _moreThanOne,
  ]) {
    final counts = <K, int>{};
    map(key).forEach(counts.increment);
    return where((v) => countCheck(counts[key(v)]!));
  }
}

isDesktop() {
  return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

isMobile() {
  return Platform.isAndroid || Platform.isIOS;
}

extension StringValue on TagValue {
  String asStringValue() {
    return switch (whichValue()) {
      TagValue_Value.boolValue => boolValue.toString(),
      TagValue_Value.stringValue => '"$stringValue"',
      TagValue_Value.intValue => intValue.toString(),
      TagValue_Value.floatValue => floatValue.toString(),

      // TODO: Do something cool with dot notation
      TagValue_Value.listValue => throw UnimplementedError(),
      TagValue_Value.mapValue => throw UnimplementedError(),
      TagValue_Value.notSet => throw UnimplementedError(),
    };
  }
}
