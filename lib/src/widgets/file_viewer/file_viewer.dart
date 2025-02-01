import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/helpers.dart';
import 'package:tagr/src/widgets/file_viewer/file_icon_viewer.dart';
import 'package:tagr/src/widgets/file_viewer/image_file_viewer.dart';
import 'package:tagr/src/widgets/file_viewer/pdf_file_viewer.dart';
import 'package:tagr/src/widgets/file_viewer/text_file_viewer.dart';
import 'package:tagr/src/widgets/file_viewer/video_file_viewer.dart';

class FileViewer extends StatelessWidget {
  final VaultOpen vaultOpen;
  final String? id;
  final int? resize;
  final BoxFit fit;
  final bool preview;
  const FileViewer({
    super.key,
    required this.vaultOpen,
    this.id,
    this.resize,
    this.fit = BoxFit.contain,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    final fullPath = path.join(vaultOpen.root.path, id);
    return Hero(
      tag: id ?? 'none',
      child: Builder(builder: (context) {
        final fileType = getFileType(id);
        if (vaultOpen.isMissing(id)) {
          return FileIconViewer(id: id, resize: resize, missing: true);
        }

        return switch (fileType) {
          FileType.image => ImageFileViewer.fromPath(
              fullPath,
              resize: resize,
              fit: fit,
            ),
          FileType.markdown || FileType.text || FileType.code => TextFileViewer(
              fileType: fileType,
              path: fullPath,
              preview: preview,
            ),
          FileType.pdf => PdfFileViewer(
              key: ValueKey(id),
              fullPath,
              preview: preview,
            ),
          FileType.video => VideoFileViewer(
              key: ValueKey(id),
              path: fullPath,
              preview: preview,
            ),
          _ => FileIconViewer(id: id, resize: resize),
        };
      }),
    );
  }
}
