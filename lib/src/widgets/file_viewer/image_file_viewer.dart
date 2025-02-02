// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class ImageFileViewer extends StatelessWidget {
  final ImageProvider provider;
  final BoxFit fit;
  ImageFileViewer({
    required ImageProvider provider,
    super.key,
    this.fit = BoxFit.contain,
    int? resize,
  }) : provider = resize != null
            ? ResizeImage.resizeIfNeeded(resize, null, provider)
            : provider;

  @override
  Widget build(BuildContext context) {
    return FadeInImage(
      placeholder: MemoryImage(kTransparentImage),
      fadeInDuration: const Duration(milliseconds: 100),
      image: provider,
      fit: fit,
    );
  }

  factory ImageFileViewer.fromPath(
    String path, {
    int? resize,
    BoxFit fit = BoxFit.contain,
  }) {
    ImageProvider provider = FileImage(File(path));
    if (resize != null) {
      provider = ResizeImage.resizeIfNeeded(resize, null, provider);
    }
    return ImageFileViewer(provider: provider, fit: fit);
  }
}
