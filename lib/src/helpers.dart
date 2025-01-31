import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as path;
import 'package:pdfrx/pdfrx.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:tagr/src/constants.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/vault_widget/preview_widget.dart';
import 'package:tagr/src/widgets/video.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:vector_graphics/vector_graphics.dart';

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
final _supportedMimeTypes = <String, FileType>{
  'application/pdf': FileType.pdf,
  'image/avif': FileType.image,
  'image/avif-sequence': FileType.image,
  'image/bmp': FileType.image,
  'image/gif': FileType.image,
  'image/heic': FileType.image,
  'image/jpeg': FileType.image,
  'image/pjpeg': FileType.image,
  'image/png': FileType.image,
  'image/svg+xml': FileType.svg,
  'image/tiff': FileType.image,
  'image/webp': FileType.image,
  'text/calendar': FileType.text,
  'text/css': FileType.code,
  'text/csv': FileType.text,
  'text/html': FileType.code,
  'text/javascript': FileType.code,
  'text/markdown': FileType.markdown,
  'text/mathml': FileType.text,
  'text/plain': FileType.text,
  'text/prs.lines.tag': FileType.text,
  'text/richtext': FileType.text,
  'text/sgml': FileType.text,
  'text/tab-separated-values': FileType.text,
  'text/troff': FileType.text,
  'text/uri-list': FileType.text,
  'text/vnd.curl': FileType.text,
  'text/vnd.curl.dcurl': FileType.text,
  'text/vnd.curl.mcurl': FileType.text,
  'text/vnd.curl.scurl': FileType.text,
  'text/vnd.fly': FileType.text,
  'text/vnd.fmi.flexstor': FileType.text,
  'text/vnd.graphviz': FileType.text,
  'text/vnd.in3d.3dml': FileType.text,
  'text/vnd.in3d.spot': FileType.text,
  'text/vnd.sun.j2me.app-descriptor': FileType.text,
  'text/vnd.wap.si': FileType.text,
  'text/vnd.wap.sl': FileType.text,
  'text/vnd.wap.wml': FileType.text,
  'text/vnd.wap.wmlscript': FileType.text,
  'text/x-asm': FileType.code,
  'text/x-c': FileType.code,
  'text/x-fortran': FileType.code,
  'text/x-java-source': FileType.code,
  'text/x-pascal': FileType.code,
  'text/x-python': FileType.code,
  'text/x-sh': FileType.code,
  'text/x-setext': FileType.text,
  'text/x-uuencode': FileType.text,
  'text/x-vcalendar': FileType.text,
  'text/x-vcard': FileType.text,
  'video/3gpp': FileType.video,
  'video/3gpp2': FileType.video,
  'video/3gpp-tt': FileType.video,
  'video/AV1': FileType.video,
  'video/BMPEG': FileType.video,
  'video/BT656': FileType.video,
  'video/CelB': FileType.video,
  'video/DV': FileType.video,
  'video/encaprtp': FileType.video,
  'video/evc': FileType.video,
  'video/example': FileType.video,
  'video/FFV1': FileType.video,
  'video/flexfec': FileType.video,
  'video/H261': FileType.video,
  'video/H263': FileType.video,
  'video/H263-1998': FileType.video,
  'video/H263-2000': FileType.video,
  'video/H264': FileType.video,
  'video/H264-RCDO': FileType.video,
  'video/H264-SVC': FileType.video,
  'video/H265': FileType.video,
  'video/H266': FileType.video,
  'video/JPEG': FileType.video,
  'video/jpeg2000': FileType.video,
  'video/jxsv': FileType.video,
  'video/matroska': FileType.video,
  'video/matroska-3d': FileType.video,
  'video/mj2': FileType.video,
  'video/MP1S': FileType.video,
  'video/MP2P': FileType.video,
  'video/MP2T': FileType.video,
  'video/mp4': FileType.video,
  'video/MP4V-ES': FileType.video,
  'video/MPV': FileType.video,
  'video/mpeg': FileType.video,
  'video/mpeg4-generic': FileType.video,
  'video/nv': FileType.video,
  'video/ogg': FileType.video,
  'video/parityfec': FileType.video,
  'video/pointer': FileType.video,
  'video/quicktime': FileType.video,
  'video/raptorfec': FileType.video,
  'video/raw': FileType.video,
  'video/VP8': FileType.video,
  'video/VP9': FileType.video,
  'video/webm': FileType.video,
};
// cSpell:enable

const catalogJson = 'assets/icons/$iconPack/catalog.json';
const blankSvg = 'assets/icons/$iconPack/blank.svg.vec';

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

FileType getFileType(String? mimeType) {
  if (mimeType == null) return FileType.unknown;
  return _supportedMimeTypes[mimeType] ?? FileType.unknown;
}

Widget previewWidget(
  VaultOpen vaultState,
  String? id, {
  int? resize,
  BoxFit fit = BoxFit.contain,
  bool preview = false,
}) {
  final fullPath = path.join(vaultState.root.path, id);
  return Hero(
    tag: id ?? 'none',
    child: Builder(builder: (context) {
      final mimeType = getMimeType(vaultState.root, id);
      final fileType = getFileType(mimeType);
      if (vaultState.isMissing(id)) {
        return FileIcon(id: id, resize: resize, missing: true);
      }

      return switch (fileType) {
        FileType.image => PreviewImage.fromPath(
            fullPath,
            resize: resize,
            fit: fit,
          ),
        FileType.markdown || FileType.text || FileType.code => TextFilePreview(
            fileType: fileType,
            path: fullPath,
            preview: preview,
          ),
        FileType.pdf => PdfViewer.file(
            path.join(vaultState.root.path, id),
          ),
        FileType.video =>
          MyScreen(key: ValueKey(id), path: fullPath, preview: preview),
        _ => FileIcon(id: id, resize: resize),
      };
    }),
  );
}

class TextFilePreview extends StatelessWidget {
  final FileType fileType;
  final String path;
  final bool preview;

  const TextFilePreview({
    super.key,
    required this.fileType,
    required this.path,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getText(),
        builder: (context, AsyncSnapshot<(String, bool)> snapshot) {
          final (text, truncated) = snapshot.data ?? ('Loading...', false);
          return switch (fileType) {
            FileType.markdown => Markdown(
                data: text + (truncated ? '...' : ''),
                selectable: !preview,
              ),
            FileType.text => SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(text),
                ),
              ),
            _ => throw ArgumentError.value(fileType),
          };
        });
  }

  Future<(String, bool)> getText() async {
    final file = File(path);
    if (preview) {
      const previewSize = 256;
      final openFile = await file.open();
      final size = await file.length();
      final truncated = size > previewSize;
      final text = await openFile
          .read(min(size, previewSize))
          .then((bytes) => (utf8.decoder.convert(bytes), truncated));
      await openFile.close();
      return text;
    } else {
      return (await file.readAsString(), false);
    }
  }
}

class FileIcon extends StatelessWidget {
  final String? id;
  final int? resize;
  final bool missing;
  const FileIcon({
    super.key,
    this.id,
    this.resize,
    this.missing = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: pickSvgVecAsset(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Image.memory(kTransparentImage);
        return Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture(
              AssetBytesLoader(snapshot.data!),
              width: resize?.toDouble(),
            ),
            if (missing)
              FittedBox(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationZ(pi / 8),
                  child: const Text(
                    "Missing",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
          ],
        );
      },
    );
  }
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
