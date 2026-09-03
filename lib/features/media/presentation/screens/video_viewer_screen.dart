import 'package:flutter/material.dart';

import '../widgets/travel_video_player.dart';

/// Full-screen video playback, pushed on top of whatever screen shows the
/// video's thumbnail (the travel book timeline, or the experience editor's
/// media preview).
class VideoViewerScreen extends StatelessWidget {
  const VideoViewerScreen({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: TravelVideoPlayer(videoUrl: videoUrl, autoPlay: true),
      ),
    );
  }
}
