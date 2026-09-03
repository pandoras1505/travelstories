import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/generated/app_localizations.dart';

/// Wraps `video_player` + `chewie` behind the app's own widget so nothing
/// else in the app depends on either package directly — play/pause, seek,
/// mute, fullscreen and a buffering spinner all come from Chewie's default
/// Material controls; this widget's own job is just initialization and
/// mapping failures to the app's loading/error visual language.
class TravelVideoPlayer extends StatefulWidget {
  const TravelVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
  });

  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  @override
  State<TravelVideoPlayer> createState() => _TravelVideoPlayerState();
}

class _TravelVideoPlayerState extends State<TravelVideoPlayer> {
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _videoController.initialize();
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: widget.autoPlay,
          looping: widget.looping,
          errorBuilder: (context, message) => _ErrorView(onRetry: _retry),
        );
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    _initialize();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _ErrorView(onRetry: _retry);
    final chewie = _chewieController;
    if (chewie == null) return const Center(child: CircularProgressIndicator());
    return Chewie(controller: chewie);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(l10n.commonError, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
