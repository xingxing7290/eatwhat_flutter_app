import 'dart:io';

import 'package:image/image.dart' as img;

const sourcePath = 'assets/branding/app_icon_source.png';

const launcherSizes = <String, int>{
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

void main() {
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing icon source: $sourcePath');
    exitCode = 1;
    return;
  }

  final source = img.decodePng(sourceFile.readAsBytesSync());
  if (source == null) {
    stderr.writeln('Cannot decode icon source: $sourcePath');
    exitCode = 1;
    return;
  }

  for (final entry in launcherSizes.entries) {
    final icon = img.copyResize(
      source,
      width: entry.value,
      height: entry.value,
      interpolation: img.Interpolation.cubic,
    );
    final output =
        File('android/app/src/main/res/${entry.key}/ic_launcher.png');
    output.createSync(recursive: true);
    output.writeAsBytesSync(img.encodePng(icon, level: 6));
  }

  final splash = img.copyResize(
    source,
    width: 240,
    height: 240,
    interpolation: img.Interpolation.cubic,
  );
  final splashOutput =
      File('android/app/src/main/res/drawable-nodpi/launch_image.png');
  splashOutput.createSync(recursive: true);
  splashOutput.writeAsBytesSync(img.encodePng(splash, level: 6));
}
