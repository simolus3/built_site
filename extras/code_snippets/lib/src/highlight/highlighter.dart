import 'dart:async';

import 'package:source_span/source_span.dart';

import 'regions.dart';

abstract class Highlighter {
  final SourceFile file;
  final List<HighlightRegion> foundRegions = [];

  Highlighter(this.file);

  FutureOr<void> highlight();

  void report(HighlightRegion region) {
    foundRegions.add(region);
  }
}

class NullHighlighter extends Highlighter {
  NullHighlighter(SourceFile file) : super(file);

  @override
  void highlight() {}
}
