import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import 'regions.dart';

abstract class Highlighter {
  final SourceFile file;
  final List<HighlightRegion> foundRegions = [];

  Highlighter(this.file);

  void highlight();

  void report(HighlightRegion region) {
    foundRegions.add(region);
  }
}
