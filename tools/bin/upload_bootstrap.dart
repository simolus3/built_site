import 'package:file/local.dart';
import 'package:git/git.dart';
import 'package:simons_pub_uploader/upload.dart';
import 'package:tools/sass_package.dart';

const _version = '5.2.2';
const _fs = LocalFileSystem();

Future<void> main() async {
  final directory = _fs.systemTempDirectory.childDirectory('bootstrap');

  await runGit(
    [
      'clone',
      'https://github.com/twbs/bootstrap.git',
      '--depth=1',
      '--branch=v$_version',
      'bootstrap',
    ],
    processWorkingDir: _fs.systemTempDirectory.path,
  );

  final package = SassOnlyPackage(directory, 'bootstrap', _version);
  await uploadPackages([package]);
}
