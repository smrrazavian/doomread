import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doomread/ui/share/widgets/finish_poster.dart';
import 'package:flutter/rendering.dart';

/// The poster's image size: a 9:16 story, 1080×1920.
const posterPixels = Size(1080, 1920);

/// Draws [boundary], which holds a [FinishPoster], at [posterPixels] however
/// big it is on screen: it draws from its own layer, so a preview scaled to
/// fit the phone still gives the full-size image.
Future<ui.Image> posterImage(RenderRepaintBoundary boundary) =>
    boundary.toImage(pixelRatio: posterPixels.width / boundary.size.width);

/// The same, as a PNG.
Future<Uint8List> posterPng(RenderRepaintBoundary boundary) async {
  final image = await posterImage(boundary);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
