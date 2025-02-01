import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:code_highlight_view/code_highlight_view.dart';
import 'package:code_highlight_view/themes/darcula.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tagr/src/helpers.dart';
import 'package:tagr/src/widgets/conditional_parent_widget.dart';

class TextFileViewer extends StatelessWidget {
  final FileType fileType;
  final String path;
  final bool preview;

  const TextFileViewer({
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
            FileType.text => ConditionalParentWidget(
                condition: !preview,
                parentBuilder: (child) => SingleChildScrollView(child: child),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(text),
                ),
              ),
            FileType.code => ConditionalParentWidget(
                condition: !preview,
                // parentBuilderElse: (child) => FittedBox(child: child, ),
                parentBuilder: (child) => SingleChildScrollView(child: child),
                child: CodeHighlightView(
                  isSelectable: !preview,
                  text,
                  padding: const EdgeInsets.all(8),
                  theme: darculaTheme,
                  textStyle: const TextStyle(),
                  language: getLanguage(path),
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
