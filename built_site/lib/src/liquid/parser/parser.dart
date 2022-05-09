import '../ast/node.dart';
import 'lexer.dart';
import 'token.dart';

class Parser {
  final Lexer lexer;

  List<String> _endCurrentBlock = [];
  late Token _lastToken;
  Token? _lookahead;

  Parser(this.lexer);

  Token _acceptAny() {
    if (_lookahead != null) {
      _lastToken = _lookahead!;
      _lookahead = null;
      return _lastToken;
    }
    return _lastToken = lexer.nextToken();
  }

  bool _check(TokenType type) {
    if (_lookahead != null) {
      return _lookahead!.type == type;
    }

    final next = _lookahead = lexer.nextToken();
    return next.type == type;
  }

  bool _checkAny(Iterable<TokenType> types) {
    return types.any(_check);
  }

  bool _match(TokenType type) {
    final matches = _check(type);
    if (matches) _acceptAny();

    return matches;
  }

  Token _expect(TokenType type) {
    if (!_check(type)) {
      _error('Expected $type');
    }

    return _acceptAny();
  }

  bool _checkIdentifier([String? lexeme]) {
    if (lexeme == null) {
      return _check(TokenType.identifier);
    } else {
      return _check(TokenType.identifier) && _lookahead!.lexeme == lexeme;
    }
  }

  IdentifierToken _expectIdentifier([String? lexeme]) {
    if (!_checkIdentifier(lexeme)) {
      _error('Expected ${lexeme ?? 'identifier'}');
    } else {
      return _acceptAny() as IdentifierToken;
    }
  }

  Never _error(String message) {
    throw ParseException(message, _lookahead ?? _lastToken);
  }

  Block parseBlock() {
    final parts = <TemplateComponent>[];
    while (!lexer.isAtEnd) {
      parts.add(_parseComponent());
    }

    return Block(parts);
  }

  /// Parses children until we see a tag that's included in [end].
  ///
  /// After the children have been parsed, the parser will have read the
  /// identifier of the ending tag. If set, [onDone] is invoked. Otherwise,
  /// we only expect a closing `%}` for the end tag.
  Block _parseBlockAsChild(List<String> end,
      {void Function(String tagName)? onDone}) {
    final savedEnd = _endCurrentBlock;
    _endCurrentBlock = end;

    final parts = <TemplateComponent>[];
    while (true) {
      try {
        parts.add(_parseComponent());
      } on _FinishedSubBlock catch (e) {
        if (onDone == null) {
          // End the closing tag.
          _expect(TokenType.endTag);
        } else {
          onDone(e.tagName);
        }
        break;
      }

      if (lexer.isAtEnd) {
        _error('Expected $end');
      }
    }

    _endCurrentBlock = savedEnd;
    return Block(parts);
  }

  TemplateComponent _parseComponent() {
    if (_check(TokenType.text)) {
      return _parseText();
    } else if (_check(TokenType.startObject)) {
      return _parseObject();
    } else if (_check(TokenType.startTag)) {
      return _parseTag();
    }

    _error('Expected text, an object or a tag.');
  }

  Text _parseText() {
    return Text(_expect(TokenType.text) as TextToken);
  }

  ObjectTag _parseObject() {
    _expect(TokenType.startObject);
    final expr = _parseExpression();
    _expect(TokenType.endObject);

    return ObjectTag(expr);
  }

  TemplateComponent _parseTag() {
    _match(TokenType.startTag);
    final type = _expect(TokenType.identifier) as IdentifierToken;

    if (_endCurrentBlock.contains(type.lexeme)) {
      throw _FinishedSubBlock(type.lexeme);
    }

    switch (type.lexeme) {
      case 'assign':
        return _parseAssignPart();
      case 'break':
        _expect(TokenType.endTag);
        return Break();
      case 'capture':
        return _parseCapturePart();
      case 'comment':
        return _parseCommentPart();
      case 'continue':
        _expect(TokenType.endTag);
        return Continue();
      case 'if':
        return _parseIfPart();
      case 'include':
        return _parseIncludePart();
      case 'block':
        return _parseIncludeBlockPart();
      case 'for':
        return _parseForPart();
      default:
        _error('Unknown tag');
    }
  }

  Assign _parseAssignPart() {
    final variableName = _expect(TokenType.identifier) as IdentifierToken;
    _expect(TokenType.assign);
    final value = _parseExpression();
    _expect(TokenType.endTag);

    return Assign(variableName, value);
  }

  Capture _parseCapturePart() {
    final variableName = _expect(TokenType.identifier) as IdentifierToken;
    _expect(TokenType.endTag);
    final child = _parseBlockAsChild(['endcapture']);

    return Capture(variableName.lexeme, child);
  }

  Comment _parseCommentPart() {
    _expect(TokenType.endTag);
    return Comment(_parseBlockAsChild(['endcomment']));
  }

  If _parseIfPart() {
    final condition = _parseExpression();
    _expect(TokenType.endTag);

    TemplateComponent? elseComponent;
    final body = _parseBlockAsChild(
      ['endif', 'elseif', 'else'],
      onDone: (tagName) {
        if (tagName == 'endif') {
          _expect(TokenType.endTag);
        } else if (tagName == 'else') {
          _expect(TokenType.endTag);
          elseComponent = _parseBlockAsChild(['endif']);
        } else if (tagName == 'elseif') {
          elseComponent = _parseIfPart();
        }
      },
    );

    return If(condition, body, elseComponent);
  }

  Include _parseIncludePart() {
    final path = _expect(TokenType.string) as StringLiteralToken;
    final args = _parseArguments();
    _expect(TokenType.endTag);

    return Include(path.value, args);
  }

  IncludeBlock _parseIncludeBlockPart() {
    final path = _expect(TokenType.string) as StringLiteralToken;
    final args = _parseArguments();
    _expect(TokenType.endTag);

    final body = _parseBlockAsChild(['endblock']);
    return IncludeBlock(path.value, args, body);
  }

  Map<String, Expression> _parseArguments() {
    final args = <String, Expression>{};

    while (_match(TokenType.identifier)) {
      final id = _lastToken as IdentifierToken;
      _expect(TokenType.assign);
      args[id.lexeme] = _parseExpression();
    }

    return args;
  }

  For _parseForPart() {
    final variable = _expectIdentifier();
    _expectIdentifier('in');
    final iterable = _parseExpression();

    Expression? limit;
    Expression? offset;
    var hasReversed = false;

    Block? elseBlock;

    // Parse limit, offset, reversed
    while (_check(TokenType.identifier)) {
      final token = _acceptAny() as IdentifierToken;

      if (token.lexeme == 'limit') {
        _expect(TokenType.colon);
        limit = _parseExpression();
      } else if (token.lexeme == 'offset') {
        offset = _parseExpression();
      } else if (token.lexeme == 'reversed') {
        hasReversed = true;
      } else {
        _error('Expected limit, offset or reversed before here');
      }
    }
    _expect(TokenType.endTag);

    final body = _parseBlockAsChild(['endfor', 'else'], onDone: (tag) {
      _expect(TokenType.endTag);
      if (tag == 'else') {
        elseBlock = _parseBlockAsChild(['endfor']);
      }
    });

    return For(
      variable,
      iterable,
      body,
      elseBlock: elseBlock,
      limit: limit,
      offset: offset,
      reverse: hasReversed,
    );
  }

  // Precedences (from low to high):
  // - filter applications
  // - and/or (same precedence, right-associative)
  // - primary (strings, variables)
  Expression _parseExpression() => _parseFilter();

  Expression _parseFilter() {
    var expression = _parseLogic();

    while (_check(TokenType.pipe)) {
      final pipe = _acceptAny();
      final filterName = _expectIdentifier();
      final arguments = <Expression>[];

      if (_check(TokenType.colon)) {
        _acceptAny();

        do {
          arguments.add(_parseLogic());
        } while (_match(TokenType.comma));
      }

      expression = FilterApplication(expression, pipe, filterName, arguments)
        ..first = expression.first
        ..last = _lastToken;
    }

    return expression;
  }

  Expression _parseLogic() {
    var result = _parseRange();

    while (true) {
      if (_checkAny(const [TokenType.equals, TokenType.notEqual])) {
        result = Compare(result, _acceptAny(), _parseRange());
      } else if (_checkIdentifier('contains')) {
        _acceptAny();
        result = Contains(result, _parseRange());
      } else if (_checkIdentifier('and') || _checkIdentifier('or')) {
        final id = _acceptAny() as IdentifierToken;
        return BooleanCombination(result, id, _parseLogic());
      } else {
        break;
      }
    }

    return result;
  }

  Expression _parseRange() {
    if (_match(TokenType.leftParen)) {
      final first = _lastToken;
      // Parse range expression: (1..4)
      final low = _parseExpression();
      if (_match(TokenType.dotDot)) {
        final high = _parseExpression();
        _expect(TokenType.rightParen);

        return Range(low, high)
          ..first = first
          ..last = high.last;
      }

      // Parenthesized
      _expect(TokenType.rightParen);
      return low;
    }

    return _parsePrimary();
  }

  Expression _parsePrimary() {
    if (_check(TokenType.string)) {
      final string = _acceptAny() as StringLiteralToken;
      return StringLiteral(string)..setSpan(string, string);
    } else if (_check(TokenType.identifier)) {
      final parts = [_acceptAny() as IdentifierToken];

      while (_match(TokenType.dot)) {
        parts.add(_expectIdentifier());
      }

      return VariableGet(parts)..setSpan(parts.first, parts.last);
    } else if (_match(TokenType.number)) {
      final token = _lastToken as NumberLiteralToken;
      return NumberLiteral(token)..setSpan(token, token);
    } else if (_match(TokenType.minus)) {
      final minus = _lastToken;
      return UnaryMinus(_parseExpression())..setSpan(minus, _lastToken);
    }

    _error('Could not parse this expression');
  }
}

class ParseException implements Exception {
  final String message;
  final Token token;

  ParseException(this.message, this.token);

  @override
  String toString() {
    return token.span!.message(message);
  }
}

class _FinishedSubBlock implements Exception {
  final String tagName;

  const _FinishedSubBlock(this.tagName);
}
