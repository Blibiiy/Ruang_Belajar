import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'dart:ui';

/// Android-only converter:
/// CameraImage (YUV_420_888) -> NV21 bytes -> ML Kit InputImage.
///
/// This avoids "Getting Image failed IllegalArgumentException" on many devices.
final class CameraImageConverter {
  const CameraImageConverter._();

  static InputImage? toInputImage(
    CameraImage image, {
    required CameraDescription camera,
    required int rotationDegrees,
  }) {
    // Expect YUV420 with 3 planes on Android
    if (image.format.group != ImageFormatGroup.yuv420) return null;
    if (image.planes.length != 3) return null;

    final nv21 = _yuv420ToNv21(image);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _rotationFromDegrees(rotationDegrees),
      format: InputImageFormat.nv21,
      // For NV21, bytesPerRow = width
      bytesPerRow: image.width,
    );

    return InputImage.fromBytes(bytes: nv21, metadata: metadata);
  }

  /// Converts YUV_420_888 CameraImage to NV21.
  /// NV21 layout: [YYYY....][VUVU....]
  static Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;

    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    // Output size for NV21 = width*height (Y) + (width*height/2) (VU)
    final out = Uint8List(width * height + (width * height ~/ 2));
    int outIndex = 0;

    // Copy Y plane
    // Handle rowStride/pixelStride
    for (int row = 0; row < height; row++) {
      final rowStart = row * yRowStride;
      for (int col = 0; col < width; col++) {
        out[outIndex++] = yBytes[rowStart + col * yPixelStride];
      }
    }

    // Interleave V and U (NV21 expects VU VU ...)
    final chromaHeight = height ~/ 2;
    final chromaWidth = width ~/ 2;

    for (int row = 0; row < chromaHeight; row++) {
      final rowStart = row * uvRowStride;
      for (int col = 0; col < chromaWidth; col++) {
        final uvIndex = rowStart + col * uvPixelStride;

        final v = vBytes[uvIndex];
        final u = uBytes[uvIndex];

        out[outIndex++] = v;
        out[outIndex++] = u;
      }
    }

    return out;
  }

  static InputImageRotation _rotationFromDegrees(int rotationDegrees) {
    switch (rotationDegrees) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
}