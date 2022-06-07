import 'package:file/local.dart';
import 'package:git/git.dart';
import 'package:simons_pub_uploader/upload.dart';
import 'package:tools/sass_package.dart';

const _version = '1.5.1';
const _fs = LocalFileSystem();

Future<void> main() async {
  final directory = _fs.systemTempDirectory.childDirectory('pico');

  await runGit(
    [
      'clone',
      'https://github.com/picocss/pico.git',
      '--depth=1',
      '--branch=v$_version',
      'pico',
    ],
    processWorkingDir: _fs.systemTempDirectory.path,
  );

  final package =
      SassOnlyPackage(directory, 'picocss', _version, license: 'LICENSE.md');
  await uploadPackages([package]);
}
