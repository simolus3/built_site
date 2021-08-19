import 'dart:math';
import 'dart:typed_data';

import 'package:charcode/charcode.dart';
import 'package:source_span/source_span.dart';

import 'token.dart';

class Lexer {
  final SourceFile input;
  final Uint32List chars;

  int _position;
  late int _startPositionOfToken;
  bool _isInObjectOrTag = false;

  Lexer(this.input, this.chars, [this._position = 0]);

  FileSpan get _tokenSpan => input.span(_startPositionOfToken, _position);

  bool get isAtEnd => _position == chars.length;

  int _get() => chars[_position];
  int _getAndAdvance() => chars[_position++];

  bool _check(int char) => !isAtEnd && _get() == char;

  bool _checkAny(Iterable<int> chars) => !isAtEnd && chars.contains(_get());

  Never _invalidToken([String message = 'Invalid token']) {
    throw TokenizationException._(_tokenSpan, message);
  }

  Token nextToken() {
    if (isAtEnd) return Token.eof;

    _startPositionOfToken = _position;
    var char = _getAndAdvance();

    if (_isInObjectOrTag) {
      // Skip whitespace
      while (char == $space) {
        _startPositionOfToken = _position;
        char = _getAndAdvance();
      }

      switch (char) {
        case $percent:
          if (_getAndAdvance() == $close_brace) {
            // %}, closes a tag
            _isInObjectOrTag = false;
            return Token(_tokenSpan, TokenType.endTag);
          }
          _invalidToken();
        case $close_brace:
          if (_getAndAdvance() == $close_brace) {
            // }}, closes an object
            _isInObjectOrTag = false;
            return Token(_tokenSpan, TokenType.endObject);
          }
          _invalidToken();
        case $single_quote:
        case $double_quote:
          return _string(char);
        case $dot:
          if (_check($dot)) {
            _position++;
            return Token(_tokenSpan, TokenType.dotDot);
          } else if (_checkAny(digits)) {
            return _number(_getAndAdvance());
          } else {
            return Token(_tokenSpan, TokenType.dot);
          }
        case $pipe:
          return Token(_tokenSpan, TokenType.pipe);
        case $exclamation:
          if (_check($equal)) {
            _position++;
            return Token(_tokenSpan, TokenType.notEqual);
          }
          _invalidToken('Expected !=, but only got !');
        case $equal:
          if (_check($equal)) {
            _position++;
            return Token(_tokenSpan, TokenType.equals);
          }
          return Token(_tokenSpan, TokenType.assign);
        case $colon:
          return Token(_tokenSpan, TokenType.colon);
        case $comma:
          return Token(_tokenSpan, TokenType.comma);
        case $open_paren:
          return Token(_tokenSpan, TokenType.leftParen);
        case $close_paren:
          return Token(_tokenSpan, TokenType.rightParen);
        case $0:
        case $1:
        case $2:
        case $3:
        case $4:
        case $5:
        case $6:
        case $7:
        case $8:
        case $9:
          return _number(char);
        case $minus:
          return Token(_tokenSpan, TokenType.minus);
      }

      // Not a special token. Does it start an identifier?
      if (char >= $a && char <= $z || char >= $A && char <= $Z) {
        return _identifier(char);
      }

      _invalidToken();
    } else {
      if (char == $open_brace) {
        final next = _getAndAdvance();
        if (next == $open_brace) {
          // {{, starts an object
          _isInObjectOrTag = true;
          return Token(_tokenSpan, TokenType.startObject);
        } else if (next == $percent) {
          // {%, starts a tag
          _isInObjectOrTag = true;
          return Token(_tokenSpan, TokenType.startTag);
        }
      }
      return _text();
    }
  }

  Token _string(int endChar) {
    var sawEscape = false;
    final content = StringBuffer();

    while (!isAtEnd) {
      final nextChar = _getAndAdvance();
      if (nextChar == $backslash) {
        sawEscape = true;
      } else if (!sawEscape) {
        if (nextChar == endChar && !sawEscape) {
          return StringLiteralToken(_tokenSpan, content.toString());
        }

        content.writeCharCode(nextChar);
      }
      sawEscape = false;
    }

    _invalidToken('Unterminated string literal');
  }

  Token _number(int firstChar) {
    int digit(int charCode) {
      assert(charCode >= $0 && charCode <= $9);
      return charCode - $0;
    }

    int? charsAfterDot = firstChar == $dot ? 0 : null;
    // If we already had a dot, start at 0. Otherwise, start with the first
    // digit.
    num number = charsAfterDot != null ? 0 : digit(firstChar);

    while (true) {
      if (_checkAny(digits)) {
        final code = _getAndAdvance();

        if (charsAfterDot != null) {
          number += code / pow(10, ++charsAfterDot);
        } else {
          number = number * 10 + digit(code);
        }
      } else if (charsAfterDot == null && _check($dot)) {
        _position++;
        charsAfterDot = 0;
      } else {
        break;
      }
    }

    return NumberLiteralToken(_tokenSpan, number);
  }

  Token _identifier(int startChar) {
    while (!isAtEnd && _continuesIdentifier(_get())) {
      _position++;
    }

    return IdentifierToken(_tokenSpan);
  }

  Token _text() {
    while (!isAtEnd && _get() != $open_brace) {
      _position++;
    }

    return Token(_tokenSpan, TokenType.text);
  }

  bool _startsIdentifier(int char) {
    return char >= $a && char <= $z ||
        char >= $A && char <= $Z ||
        char == $underscore ||
        char == $dollar;
  }

  bool _continuesIdentifier(int char) {
    return _startsIdentifier(char) || char >= $0 && char <= $9;
  }

  static const digits = [$0, $1, $2, $3, $4, $5, $6, $7, $8, $9];
}

class TokenizationException implements Exception {
  final FileSpan span;
  final String message;

  TokenizationException._(this.span, this.message);

  @override
  String toString() {
    return span.message(message);
  }
}
