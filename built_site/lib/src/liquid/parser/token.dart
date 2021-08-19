import 'package:source_span/source_span.dart';

enum TokenType {
  startObject,
  endObject,
  startTag,
  endTag,
  dot,
  dotDot,
  identifier,
  colon,
  comma,
  number,
  minus,
  text,
  string,
  pipe,
  assign,
  equals,
  notEqual,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  leftParen,
  rightParen,
  eof,
}

class Token {
  final FileSpan? span;
  final TokenType type;

  Token(this.span, this.type);

  static Token eof = Token(null, TokenType.eof);

  String get lexeme => span!.text;
}

class StringLiteralToken extends Token {
  final String value;

  StringLiteralToken(FileSpan span, this.value) : super(span, TokenType.string);
}

class NumberLiteralToken extends Token {
  final num value;

  NumberLiteralToken(FileSpan span, this.value) : super(span, TokenType.number);
}

class IdentifierToken extends Token {
  IdentifierToken(FileSpan span) : super(span, TokenType.identifier);
}
