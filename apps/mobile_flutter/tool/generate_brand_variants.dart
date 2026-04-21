import 'dart:io';

import 'package:image/image.dart' as img;

const String kSourcePath = 'assets/branding/logo_source.png';
const String kOutputDir = 'assets/branding/generated';

void main() {
  final sourceFile = File(kSourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing logo source at $kSourcePath');
    stderr.writeln('Place your logo there and run this script again.');
    exitCode = 1;
    return;
  }

  final bytes = sourceFile.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode PNG at $kSourcePath');
    exitCode = 1;
    return;
  }

  final outputDir = Directory(kOutputDir);
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  _writePng('${outputDir.path}/logo_primary.png', decoded);
  _writePng(
    '${outputDir.path}/logo_bg_light.png',
    _composeOnRoundedBackground(decoded, 768, 768, 0xFFF7F7F2),
  );
  _writePng(
    '${outputDir.path}/logo_bg_dark.png',
    _composeOnRoundedBackground(decoded, 768, 768, 0xFF101418),
  );
  _writePng(
    '${outputDir.path}/logo_bg_navy.png',
    _composeOnRoundedBackground(decoded, 768, 768, 0xFF0B1B3A),
  );

  stdout.writeln('Generated variants in $kOutputDir');
}

img.Image _composeOnRoundedBackground(
  img.Image source,
  int width,
  int height,
  int backgroundColor,
) {
  final canvas = img.Image(width: width, height: height);
  final color = img.ColorRgba8(
    (backgroundColor >> 16) & 0xFF,
    (backgroundColor >> 8) & 0xFF,
    backgroundColor & 0xFF,
    (backgroundColor >> 24) & 0xFF,
  );

  img.fill(canvas, color: color);

  final margin = (width * 0.06).round();
  final target = img.copyResize(
    source,
    width: width - (margin * 2),
    height: height - (margin * 2),
    interpolation: img.Interpolation.average,
  );

  img.compositeImage(canvas, target, dstX: margin, dstY: margin);
  return canvas;
}

void _writePng(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Wrote $path');
}
