import 'package:build/build.dart';
import 'package:messagepack/messagepack.dart';
import 'package:path/path.dart' show url;

import '../pages/generated_page.dart';

class CopyToWeb extends PostProcessBuilder {
  @override
  Iterable<String> get inputExtensions => const ['.generated_page'];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    final serializedPage = await buildStep.readInputAsBytes();
    final unpacker = Unpacker.fromList(serializedPage);
    final page = GeneratedPage.deserialize(unpacker);

    for (var path in page.paths) {
      final isIndex = url.extension(path).isEmpty;
      if (url.isAbsolute(path)) {
        // Turn /foo/bar/baz into foo/bar/baz because asset ids need to be
        // relative in the end
        path = url.joinAll(url.split(path).skip(1));
      }

      final pageUrl = url.join('web', path, isIndex ? 'index.html' : null);

      final outputId = AssetId(buildStep.inputId.package, pageUrl);
      await buildStep.writeAsString(outputId, page.content);
    }
  }
}
