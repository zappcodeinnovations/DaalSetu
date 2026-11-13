import 'package:image_picker/image_picker.dart';

/// A seller can add up to 10 images to one offer.
const int maxOfferImages = 10;

/// Picks up to [room] images from the gallery with multi-select.
/// (image_picker needs a limit of at least 2 for multi-select.)
Future<List<String>> pickOfferImages({int room = maxOfferImages}) async {
  if (room <= 0) return const [];
  final picker = ImagePicker();
  if (room == 1) {
    final one = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    return one == null ? const [] : [one.path];
  }
  final picked = await picker.pickMultiImage(limit: room, imageQuality: 88);
  return picked.take(room).map((file) => file.path).toList();
}
