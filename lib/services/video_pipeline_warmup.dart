import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';

class VideoPipelineWarmup {
  static bool _didWarm = false;

  static Future<void> warm() async {
    if (_didWarm) return;
    _didWarm = true;

    try {
      // 1) Initialize VideoCompress native side
      // (no heavy work, but triggers plugin channel init)
      await VideoCompress.getMediaInfo(''); // may throw, that's fine
    } catch (_) {}

    try {
      // 2) Thumbnail pipeline warmup
      // Create a tiny dummy file so plugin init paths run.
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/warmup.bin');
      if (!await f.exists()) {
        await f.writeAsBytes(List<int>.filled(16, 0));
      }

      // This will likely fail because it's not a real video, but it warms the method channel.
      await VideoThumbnail.thumbnailData(
        video: f.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 64,
        quality: 10,
        timeMs: 0,
      ).catchError((_) {});
    } catch (_) {}
  }
}