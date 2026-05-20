import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Converts CameraImage (Android YUV_420_888) to ML Kit InputImage.
final class CameraImageConverter {
  const CameraImageConverter._();

  static InputImage? toInputImage(
    CameraImage image, {
    required CameraDescription camera,
    required int rotationDegrees,
  }) {
    // Only support Android YUV_420_888 in this MVP.
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Concatenate the planes into a single Uint8List.
    final bytes = _concatenatePlanes(image.planes);

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _rotationFromDegrees(rotationDegrees),
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  static Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
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