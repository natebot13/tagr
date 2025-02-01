import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfFileViewer extends StatelessWidget {
  final String path;
  final bool preview;
  const PdfFileViewer(
    this.path, {
    super.key,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.file(path, builder: (context, document) {
      if (preview) {
        return PdfPageView(document: document, pageNumber: 1);
      } else {
        return ListView.builder(
          itemCount: document?.pages.length ?? 0,
          itemBuilder: (context, index) {
            return PdfPageView(document: document, pageNumber: index + 1);
          },
        );
      }
    });
  }
}
