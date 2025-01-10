import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

ImageProvider defaultImage() {
  return const AssetImage('assets/images/unknown.png');
}

ImageProvider imageProvider(Directory root, String? id) {
  if (id == null) return defaultImage();
  final filePath = path.join(root.path, id);
  final mimeType = lookupMimeType(filePath);
  if (mimeType?.contains('image') ?? false) {
    return FileImage(File(filePath));
  }
  print('Unhandled mime type: $mimeType');
  return defaultImage();
}
