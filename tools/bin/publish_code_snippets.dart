import 'package:simons_pub_uploader/upload.dart';

Future<void> main() async {
  final package =
      await FileSystemPackage.load(directory: 'extras/code_snippets');

  await uploadPackages([package]);
}
