import 'package:messagepack/messagepack.dart';

class GeneratedPage {
  final List<String> paths;
  final int primaryPathIndex;

  final String content;

  GeneratedPage(this.paths, this.primaryPathIndex, this.content);

  String get primaryPath => paths[primaryPathIndex];

  void serialize(Packer packer) {
    packer.packListLength(paths.length);
    paths.forEach(packer.packString);

    packer.packInt(primaryPathIndex);
    packer.packString(content);
  }

  static GeneratedPage deserialize(Unpacker unpacker) {
    final pathsLength = unpacker.unpackListLength();
    final paths = List.generate(pathsLength, (_) => unpacker.unpackString()!);

    return GeneratedPage(
      paths,
      unpacker.unpackInt()!,
      unpacker.unpackString()!,
    );
  }
}
