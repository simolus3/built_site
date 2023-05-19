import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:simons_pub_uploader/upload.dart';
import 'package:tar/tar.dart';

class SassOnlyPackage extends Package {
  final Directory directory;

  final String readme;
  final String license;
  final String scssFolder;

  SassOnlyPackage(
    this.directory,
    String name,
    String version, {
    this.readme = 'README.md',
    this.license = 'LICENSE',
    this.scssFolder = 'scss',
  }) : super(
          name,
          version,
          {
            'name': name,
            'version': version,
            'environment': {'sdk': '>=2.12.0 <4.0.0'},
          },
        );

  @override
  Stream<TarEntry> get entries async* {
    yield _file(directory.childFile(readme));
    yield _file(directory.childFile(license));

    final scss = directory.childDirectory(scssFolder);
    await for (final file in scss.list(recursive: true)) {
      if (file is File) {
        final relativeToScss = p.relative(file.path, from: scss.path);
        yield _file(file, path: p.join('lib', relativeToScss));
      }
    }
  }

  TarEntry _file(File file, {String? path}) {
    path ??= p.relative(file.path, from: directory.path);

    return TarEntry(
      TarHeader(name: path, mode: 420),
      file.openRead(),
    );
  }
}
