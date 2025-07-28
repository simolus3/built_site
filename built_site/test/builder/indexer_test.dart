import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:built_site/src/builders/indexer.dart';
import 'package:test/test.dart';

void main() {
  test('finds sections', () {
    return testBuilder(
      Indexer(),
      <String, String>{
        'a|pages/foo/not/deeply/nested/index.page_meta': '',
        'a|pages/index.page_meta': '',
        'a|pages/foo/index.page_meta': '',
        'a|pages/bar/index.page_meta': '',
      },
      isInput: (_) => true,
      generateFor: {r'a|$package$'},
      outputs: <String, String>{
        'a|lib/site_index.json': json.encode(
          {
            'sections': [
              {
                'home': 'a|pages/index.page_meta',
                'parent': null,
              },
              {
                'home': 'a|pages/foo/index.page_meta',
                'parent': 'a|pages/index.page_meta',
              },
              {
                'home': 'a|pages/foo/not/deeply/nested/index.page_meta',
                'parent': 'a|pages/foo/index.page_meta',
              },
              {
                'home': 'a|pages/bar/index.page_meta',
                'parent': 'a|pages/index.page_meta',
              },
            ],
            'pages': [
              'a|pages/foo/not/deeply/nested/index.page_meta',
              'a|pages/index.page_meta',
              'a|pages/foo/index.page_meta',
              'a|pages/bar/index.page_meta',
            ],
          },
        )
      },
    );
  });
}
