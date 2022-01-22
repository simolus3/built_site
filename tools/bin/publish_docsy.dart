import 'package:simons_pub_uploader/upload.dart';

Future<void> main() async {
  final package = await FileSystemPackage.load(
    directory: 'themes/docsy',
    listPackageFiles: (fs) async* {
      final dir = fs.directory('themes/docsy');

      yield* dir.childDirectory('i18n').list(recursive: true);
      yield* dir.childDirectory('lib').list(recursive: true);
      yield* dir.childDirectory('static').list(recursive: true);
      yield* dir.childDirectory('templates').list(recursive: true);

      yield dir.childFile('build.yaml');
      yield dir.childFile('NOTICE');
      yield dir.childFile('theme.yaml');
    },
  );

  await uploadPackages([package]);
}
