/// Image decode-size hints, sized to how large each image actually renders
/// on screen — decoding a full-resolution upload (up to 2560px, see
/// `MediaService`) for a small card thumbnail wastes decode time and memory
/// for no visible gain. Passed through `AppImage`/`appImageProvider`
/// (`core/widgets/app_image.dart`) as `memCacheWidth`/`maxWidth`+`maxHeight`
/// either way, whether the underlying image is a remote URL or a local file.
class AppImageCache {
  AppImageCache._();

  /// Full-width 16:9/16:10 cover and media cards (travel book covers,
  /// experience previews, in lists and edit screens). Sized for a ~2x-dpr
  /// phone at full screen width — still ~5.7x fewer pixels than a 2560px
  /// upload, with no visible softening on typical devices.
  static const int coverWidth = 1080;

  /// Profile avatar shown at a large size (profile screen, edit profile;
  /// `CircleAvatar` radius 48 = 96dp diameter, sized for 3x dpr).
  static const int largeAvatar = 300;

  /// Small inline avatar (author byline on a travel book card;
  /// `CircleAvatar` radius 10 = 20dp diameter, sized for 3x dpr).
  static const int smallAvatar = 80;
}
