import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart' show sha512;

class HashBuilder implements Builder {
  const HashBuilder();

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      '': ['.built_site_hash']
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final bytes = await buildStep.readAsBytes(inputId);
    final digest = sha512.convert(bytes);
    final encoded = base64.encode(digest.bytes);

    final asJson = json.encode({'algo': 'sha-512', 'digest': encoded});
    final outputId =
        AssetId(inputId.package, '${inputId.path}.built_site_hash');
    await buildStep.writeAsString(outputId, asJson);
  }
}
