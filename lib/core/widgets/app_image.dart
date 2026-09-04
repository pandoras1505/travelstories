import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders [path] whether it's a real network URL or a local file path.
/// Both are possible today: any cover/media uploaded through the local
/// storage bypass (Firebase Storage isn't activated — see HANDOFF.md
/// §4.3/§8) is a plain on-device file path, while a URL from a real
/// Storage upload would still be `https://`.
///
/// A local path only ever resolves on the device that wrote it — viewing
/// someone else's public book (or reinstalling the app) means the file
/// genuinely doesn't exist here, which is expected given that trade-off
/// (see OFFLINE_SYNC.md), not a bug to crash or dump a stack trace over.
/// Both branches fall back to [_ImageErrorPlaceholder] instead of Flutter's
/// default broken-image visual.
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
        errorWidget: (context, url, error) => const _ImageErrorPlaceholder(),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      cacheWidth: memCacheWidth,
      errorBuilder: (context, error, stackTrace) =>
          const _ImageErrorPlaceholder(),
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// [ImageProvider] equivalent of [AppImage], for widgets that need a
/// provider rather than a widget (e.g. `CircleAvatar.backgroundImage`).
/// There's no error-widget hook at this level — a missing local avatar
/// file just leaves the `CircleAvatar` showing its own `child` fallback
/// (already wired at every call site for the "no photo set" case), rather
/// than Flutter's broken-image visual.
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
