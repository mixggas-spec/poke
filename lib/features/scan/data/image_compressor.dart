import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageCompressor {
  const ImageCompressor._();

  static const maxLongestSide = 1024;
  static const initialQuality = 85;
  static const maxBytes = 1024 * 1024;

  static Future<Uint8List> compressForUpload(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode captured image.');
    }

    img.Image processed = decoded;
    final longestSide = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;

    if (longestSide > maxLongestSide) {
      processed = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxLongestSide)
          : img.copyResize(decoded, height: maxLongestSide);
    }

    var quality = initialQuality;
    Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(processed, quality: quality),
    );

    while (encoded.length > maxBytes && quality > 40) {
      quality -= 10;
      encoded = Uint8List.fromList(
        img.encodeJpg(processed, quality: quality),
      );
    }

    return encoded;
  }
}
