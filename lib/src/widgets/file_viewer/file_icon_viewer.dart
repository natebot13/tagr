import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tagr/src/helpers.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:vector_graphics/vector_graphics.dart';

class FileIconViewer extends StatelessWidget {
  final String? id;
  final int? resize;
  final bool missing;
  const FileIconViewer({
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
