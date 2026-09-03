import 'package:image_picker/image_picker.dart';

/// Wraps [ImagePicker] for the four capture/pick entry points the app
/// needs. Returns the raw [XFile] — compression and thumbnail generation
/// happen in [MediaProcessor], kept separate so each step is independently
/// testable.
class MediaService {
  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const Duration maxVideoDuration = Duration(seconds: 60);

  Future<XFile?> pickImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2560,
      maxHeight: 2560,
    );
  }

  Future<XFile?> captureImage() {
    return _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2560,
      maxHeight: 2560,
    );
  }

  Future<XFile?> pickVideo() {
    return _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxVideoDuration,
    );
  }

  Future<XFile?> captureVideo() {
    return _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxVideoDuration,
    );
  }
}
