import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:highlight/languages/all.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as path;
import 'package:quiver/collection.dart';
import 'package:tagr/src/constants.dart';
import 'package:tagr/src/extensions.dart';

final logger = Logger();

enum FileType {
  unknown,
  image,
  svg,
  text,
  markdown,
  code,
  pdf,
  video,
  audio,
}

// cSpell:disable
final _supportedFileExtensions = <String, FileType>{
  '.pdf': FileType.pdf,
  '.avif': FileType.image,
  '.bmp': FileType.image,
  '.gif': FileType.image,
  '.heic': FileType.image,
  '.jpeg': FileType.image,
  '.jpg': FileType.image,
  '.pjpeg': FileType.image,
  '.png': FileType.image,
  '.svg': FileType.svg,
  '.tiff': FileType.image,
  '.webp': FileType.image,
  '.csv': FileType.text,
  '.tsv': FileType.text,
  '.txt': FileType.text,
  '.md': FileType.markdown,
  '.dart': FileType.code,
  '.css': FileType.code,
  '.html': FileType.code,
  '.js': FileType.code,
  '.asm': FileType.code,
  '.c': FileType.code,
  '.h': FileType.code,
  '.cpp': FileType.code,
  '.cxx': FileType.code,
  '.hpp': FileType.code,
  '.hxx': FileType.code,
  '.java': FileType.code,
  '.py': FileType.code,
  '.sh': FileType.code,
  '.3gpp': FileType.video,
  '.3gpp2': FileType.video,
  '.3gpp-tt': FileType.video,
  '.mp4': FileType.video,
  '.mov': FileType.video,
  '.webm': FileType.video,
};
// cSpell:enable

const catalogJson = 'assets/icons/$iconPack/catalog.json';
const blankSvg = 'assets/icons/$iconPack/blank.svg.vec';

final languageExtensionMap = buildLanguageExtensionMap();

Multimap<String, String> buildLanguageExtensionMap() {
  final result = Multimap<String, String>();
  for (final MapEntry(key: name, value: language) in allLanguages.entries) {
    for (final alias in language.aliases ?? <String>[]) {
      result.add('.$alias', name);
    }
  }
  return result;
}

class SvgIcon {
  static final Future<Set<String>> icons = _buildIconList();

  static Future<Set<String>> _buildIconList() async {
    final data = await rootBundle.loadString(catalogJson);
    // Series of casting since I know the data is a list of strings
    final catalog = json.decode(data) as List<dynamic>;
    return <String>{...catalog};
  }
}

Future<String> pickSvgVecAsset(String? id) async {
  if (id == null) return blankSvg;
  var ext = path.extension(id).replaceFirst('.', '');
  final iconSet = await SvgIcon.icons;
  if (ext.isEmpty || !iconSet.contains(ext)) return blankSvg;
  return 'assets/icons/$iconPack/$ext.svg.vec';
}

String? getMimeType(Directory root, String? id) {
  if (id == null) return null;
  final filePath = path.join(root.path, id);
  return mime.lookupMimeType(filePath);
}

FileType getFileType(String? id) {
  if (id == null) return FileType.unknown;
  return _supportedFileExtensions[path.extension(id)] ?? FileType.unknown;
}

String getLanguage(String id) {
  final ext = path.extension(id);
  return languageExtensionMap[ext].firstOrNull ?? 'dart';
}

enum SizeUnit {
  b,
  kb,
  mb,
  gb,
  tb;

  static final _base2Units = {
    b: 1,
    kb: pow(2, 10) as int,
    mb: pow(2, 20) as int,
    gb: pow(2, 30) as int,
    tb: pow(2, 40) as int,
  };

  static final _base10Units = {
    b: 1,
    kb: pow(10, 3) as int,
    mb: pow(10, 6) as int,
    gb: pow(10, 9) as int,
    tb: pow(10, 12) as int,
  };

  int getScale([int base = 2]) {
    return switch (base) {
      2 => _base2Units[this]!,
      10 => _base10Units[this]!,
      _ => throw ArgumentError("Only base 2 or 10"),
    };
  }
}

extension SizeUnitParsing on String {
  static final unitsNameMap = SizeUnit.values.asNameMap();

  /// Parses the string such as "10.3kb" into the number of bytes
  /// Returns null if the string isn't a parsable byte size
  int? tryParseAsByteSize({int base = 2}) {
    if (base != 2 || base != 10) throw ArgumentError("Only base 2 or 10");
    var unit = unitsNameMap[last(2).toLowerCase()];
    unit ??= unitsNameMap['b']!;

    final valueString = toLowerCase().replaceFirst(RegExp(unit.name), '');
    final value = double.tryParse(valueString);
    if (value == null) return null;
    final scale = switch (base) {
      2 => unit.getScale(),
      10 => unit.getScale(),
      _ => throw ArgumentError()
    };
    return (value * scale).ceil();
  }
}
