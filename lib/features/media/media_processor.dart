import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

import '../../core/errors/app_exception.dart';

typedef ProcessedImage = ({Uint8List bytes, String extension});
typedef ProcessedVideo = ({
  Uint8List bytes,
  String extension,
  Uint8List? thumbnailBytes,
});

/// Turns a raw picked/captured file into something ready to upload:
/// compresses images, and generates a thumbnail for videos (video itself
/// is uploaded as captured — see the master prompt discussion on why
/// client-side video compression was deliberately skipped for this MVP).
class MediaProcessor {
  static const int maxImageBytes = 15 * 1024 * 1024;
  static const int maxVideoBytes = 200 * 1024 * 1024;

  Future<ProcessedImage> processImage(XFile file) async {
    final Uint8List original;
    try {
      original = await file.readAsBytes();
    } catch (e) {
      throw MediaException('Failed to read image file.', cause: e);
    }

    if (original.lengthInBytes > maxImageBytes) {
      throw const MediaException(
        'Image exceeds the 15 MB limit.',
        code: 'image-too-large',
      );
    }

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        minWidth: 1920,
        minHeight: 1920,
        quality: 82,
        format: CompressFormat.jpeg,
      );
      return (bytes: compressed, extension: 'jpg');
    } catch (e) {
      throw MediaException('Failed to compress image.', cause: e);
    }
  }

  Future<ProcessedVideo> processVideo(XFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      throw MediaException('Failed to read video file.', cause: e);
    }

    if (bytes.lengthInBytes > maxVideoBytes) {
      throw const MediaException(
        'Video exceeds the 200 MB limit.',
        code: 'video-too-large',
      );
    }

    Uint8List? thumbnail;
    try {
      thumbnail = await vt.VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 512,
        quality: 70,
      );
    } catch (_) {
      // A missing thumbnail isn't fatal — the video itself still uploads
      // and the UI falls back to a generic video icon.
      thumbnail = null;
    }

    final extension = file.name.contains('.')
        ? file.name.split('.').last
        : 'mp4';
    return (bytes: bytes, extension: extension, thumbnailBytes: thumbnail);
  }
}
