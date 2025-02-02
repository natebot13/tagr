import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoFileViewer extends StatefulWidget {
  final String path;
  final bool preview;
  const VideoFileViewer({super.key, required this.path, this.preview = false});
  @override
  State<VideoFileViewer> createState() => VideoFileViewerState();
}

class VideoFileViewerState extends State<VideoFileViewer> {
  final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.path));
    player.setVolume(0);
    player.setPlaylistMode(PlaylistMode.loop);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      wakelock: !widget.preview,
      fit: widget.preview ? BoxFit.cover : BoxFit.contain,
      controller: controller,
      controls: widget.preview ? NoVideoControls : AdaptiveVideoControls,
    );
  }
}
