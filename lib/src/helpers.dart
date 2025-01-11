import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as path;
import 'package:tagr/src/constants.dart';
import 'package:tagr/src/vault_widget/preview_widget.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:vector_graphics/vector_graphics.dart';

enum FileType {
  unknown,
  image,
  text,
  code,
  pdf,
}

// cSpell:disable
final _supportedMimeTypes = <String, FileType>{
  'application/pdf': FileType.pdf,
  'image/avif': FileType.image,
  'image/avif-sequence': FileType.image,
  'image/bmp': FileType.image,
  'image/cgm': FileType.image,
  'image/g3fax': FileType.image,
  'image/gif': FileType.image,
  'image/heic': FileType.image,
  'image/ief': FileType.image,
  'image/jpeg': FileType.image,
  'image/pjpeg': FileType.image,
  'image/png': FileType.image,
  'image/prs.btif': FileType.image,
  'image/svg+xml': FileType.image,
  'image/tiff': FileType.image,
  'image/vnd.adobe.photoshop': FileType.image,
  'image/vnd.djvu': FileType.image,
  'image/vnd.dwg': FileType.image,
  'image/vnd.dxf': FileType.image,
  'image/vnd.fastbidsheet': FileType.image,
  'image/vnd.fpx': FileType.image,
  'image/vnd.fst': FileType.image,
  'image/vnd.fujixerox.edmics-mmr': FileType.image,
  'image/vnd.fujixerox.edmics-rlc': FileType.image,
  'image/vnd.ms-modi': FileType.image,
  'image/vnd.net-fpx': FileType.image,
  'image/vnd.wap.wbmp': FileType.image,
  'image/vnd.xiff': FileType.image,
  'image/webp': FileType.image,
  'image/x-adobe-dng': FileType.image,
  'image/x-canon-cr2': FileType.image,
  'image/x-canon-crw': FileType.image,
  'image/x-cmu-raster': FileType.image,
  'image/x-cmx': FileType.image,
  'image/x-epson-erf': FileType.image,
  'image/x-freehand': FileType.image,
  'image/x-fuji-raf': FileType.image,
  'image/x-icns': FileType.image,
  'image/x-icon': FileType.image,
  'image/x-kodak-dcr': FileType.image,
  'image/x-kodak-k25': FileType.image,
  'image/x-kodak-kdc': FileType.image,
  'image/x-minolta-mrw': FileType.image,
  'image/x-nikon-nef': FileType.image,
  'image/x-olympus-orf': FileType.image,
  'image/x-panasonic-raw': FileType.image,
  'image/x-pcx': FileType.image,
  'image/x-pentax-pef': FileType.image,
  'image/x-pict': FileType.image,
  'image/x-portable-anymap': FileType.image,
  'image/x-portable-bitmap': FileType.image,
  'image/x-portable-graymap': FileType.image,
  'image/x-portable-pixmap': FileType.image,
  'image/x-rgb': FileType.image,
  'image/x-sigma-x3f': FileType.image,
  'image/x-sony-arw': FileType.image,
  'image/x-sony-sr2': FileType.image,
  'image/x-sony-srf': FileType.image,
  'image/x-xbitmap': FileType.image,
  'image/x-xpixmap': FileType.image,
  'image/x-xwindowdump': FileType.image,
  'text/calendar': FileType.text,
  'text/css': FileType.code,
  'text/csv': FileType.text,
  'text/html': FileType.code,
  'text/javascript': FileType.code,
  'text/markdown': FileType.text,
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
  'text/x-setext': FileType.text,
  'text/x-uuencode': FileType.text,
  'text/x-vcalendar': FileType.text,
  'text/x-vcard': FileType.text,
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

FileType getFileType(Directory root, String? id) {
  if (id == null) return FileType.unknown;
  final filePath = path.join(root.path, id);
  final mimeType = mime.lookupMimeType(filePath);
  if (mimeType == null) return FileType.unknown;
  return _supportedMimeTypes[mimeType] ?? FileType.unknown;
}

Widget previewWidget(
  Directory root,
  String? id, {
  int? resize,
  BoxFit fit = BoxFit.contain,
}) {
  final fileType = getFileType(root, id);
  return switch (fileType) {
    FileType.image => PreviewImage.fromPath(
        root,
        id!,
        resize: resize,
        fit: fit,
      ),
    _ => FutureBuilder(
        future: pickSvgVecAsset(id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Image.memory(kTransparentImage);
          return SvgPicture(
            AssetBytesLoader(snapshot.data!),
            width: resize?.toDouble(),
          );
        }),
  };
}
