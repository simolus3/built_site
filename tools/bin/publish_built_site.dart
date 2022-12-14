import 'package:simons_pub_uploader/upload.dart';

Future<void> main() async {
  final package = await FileSystemPackage.load(
    directory: 'built_site',
    listPackageFiles: (fs) async* {
      final dir = fs.directory('built_site');

      yield* dir.childDirectory('lib').list(recursive: true);
      yield* dir.childDirectory('templates').list(recursive: true);

      yield dir.childFile('build.yaml');
    },
  );

  await uploadPackages([package]);
}
