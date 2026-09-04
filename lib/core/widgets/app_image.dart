import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Renders [path] whether it's a real network URL or a local file path.
/// Both are possible today: any cover/media uploaded through the local
/// storage bypass (Firebase Storage isn't activated — see HANDOFF.md
/// §4.3/§8) is a plain on-device file path, while a URL from a real
/// Storage upload would still be `https://`.
class AppImage extends StatelessWidget {
  const AppImage({super.key, required this.path, this.fit, this.memCacheWidth});

  final String path;
  final BoxFit? fit;

  /// Forwarded to [CachedNetworkImage.memCacheWidth] for a remote URL, or
  /// [Image.cacheWidth] for a local file — same intent either way: decode
  /// at roughly the size this is actually displayed at, not the source's
  /// full resolution. See `AppImageCache`.
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    if (_isRemote(path)) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        memCacheWidth: memCacheWidth,
      );
    }
    return Image.file(File(path), fit: fit, cacheWidth: memCacheWidth);
  }
}

/// [ImageProvider] equivalent of [AppImage], for widgets that need a
/// provider rather than a widget (e.g. `CircleAvatar.backgroundImage`).
ImageProvider appImageProvider(String path, {int? maxWidth, int? maxHeight}) {
  if (_isRemote(path)) {
    return CachedNetworkImageProvider(
      path,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
  final provider = FileImage(File(path));
  if (maxWidth == null && maxHeight == null) return provider;
  return ResizeImage(provider, width: maxWidth, height: maxHeight);
}

bool _isRemote(String path) =>
    path.startsWith('http://') || path.startsWith('https://');
