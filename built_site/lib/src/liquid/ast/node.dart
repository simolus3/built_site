import 'package:source_span/source_span.dart';

import '../parser/token.dart';
import 'components.dart';
import 'expressions.dart';

export 'components.dart';
export 'expressions.dart';

abstract class AstNode {
  /// The first and last token of this ast node, respectively.
  ///
  /// This can be used to build a source span of this node in error messages.
  Token? first, last;

  Ret accept<Arg, Ret>(AstVisitor<Arg, Ret> visitor, Arg arg);

  FileSpan? get span {
    final start = first?.span;
    final end = last?.span;

    if (start == null || end == null) return null;
    return start.expand(end);
  }

  void setSpan(Token first, Token last) {
    this.first = first;
    this.last = last;
  }
}

abstract class AstVisitor<Arg, Ret>
    implements ExpressionVisitor<Arg, Ret>, ComponentVisitor<Arg, Ret> {}
