import 'package:simons_pub_uploader/upload.dart';

Future<void> main() async {
  final package = await FileSystemPackage.load(directory: 'jaspr_docsy');

  await uploadPackages([package]);
}
