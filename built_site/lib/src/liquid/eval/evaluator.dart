import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import '../../markdown/markdown.dart' show embeddRawHtml;
import '../ast/node.dart';
import '../liquid.dart';
import '../parser/token.dart';
import 'filter.dart';
import 'utils.dart' as utils;

// ignore_for_file: library_private_types_in_public_api

class TemplateEvaluator
    extends ComponentVisitor<_EvaluationContext, Future<void>> {
  final TemplateResolver resolver;
  final AssetReader reader;
  final bool isEmittingMarkdown;

  TemplateEvaluator(this.reader, this.resolver,
      {this.isEmittingMarkdown = false});

  Future<String> render(TemplateComponent node,
      {Map<String, Object?>? variables,
      Map<String, Filter>? additionalFilters,
      AssetId? sourceId}) async {
    final context = _EvaluationContext(
      <String, Object?>{
        'true': true,
        'false': false,
        'nil': null,
        ...?variables,
      },
      filters: {...filters, ...?additionalFilters},
    );
    await node.accept(this, context);
    return context.buffer.toString();
  }

  Future<Object?> _evaluate(Expression expr, _EvaluationContext arg) async {
    try {
      return await expr.accept(const _ExpressionEvaluator(), arg);
    } on Object catch (e) {
      if (e is! EvaluationException) {
        throw EvaluationException(e, expr);
      }
    }
    return null;
  }

  @override
  Future<void> visitAssign(Assign node, _EvaluationContext arg) async {
    final value = await _evaluate(node.expression, arg);
    arg.data[node.variableName] = value;
  }

  @override
  Future<void> visitBlock(Block node, _EvaluationContext arg) async {
    for (final child in node.children) {
      await child.accept(this, arg);
    }
  }

  @override
  Future<void> visitBreak(Break node, _EvaluationContext arg) {
    return Future.error(_ForLoopInterrupted(false));
  }

  @override
  Future<void> visitCapture(Capture node, _EvaluationContext arg) async {
    final buffer = StringBuffer();
    final childContext = arg.fork(buffer: buffer);

    await node.content.accept(this, childContext);
    arg.data[node.variable] = buffer.toString();
  }

  @override
  Future<void> visitComment(Comment node, _EvaluationContext arg) {
    return Future.value();
  }

  @override
  Future<void> visitContinue(Continue node, _EvaluationContext arg) {
    return Future.error(_ForLoopInterrupted(true));
  }

  @override
  Future<void> visitFor(For node, _EvaluationContext arg) async {
    final rawIterable = await _evaluate(node.iterable, arg);
    var iterable =
        rawIterable is Iterable ? rawIterable : const Iterable<Null>.empty();

    if (node.offset != null) {
      final offset =
          _ExpressionEvaluator._toInt(await _evaluate(node.offset!, arg));
      if (offset != null) {
        iterable = iterable.skip(offset);
      }
    }

    if (node.limit != null) {
      final limit =
          _ExpressionEvaluator._toInt(await _evaluate(node.limit!, arg));
      if (limit != null) {
        iterable = iterable.take(limit);
      }
    }

    if (node.reverse) {
      iterable = iterable.toList().reversed;
    }

    var hadIteration = false;
    for (final item in iterable) {
      hadIteration = true;
      final childCtx = arg.fork();
      childCtx.data[node.variable.lexeme] = item;

      try {
        await node.body.accept(this, childCtx);
      } on _ForLoopInterrupted catch (e) {
        if (e.shouldContinue) {
          continue;
        } else {
          break;
        }
      }
    }

    if (!hadIteration) {
      await node.elseBlock?.accept(this, arg);
    }
  }

  @override
  Future<void> visitIf(If node, _EvaluationContext arg) async {
    final condition =
        _ExpressionEvaluator._isTruthy(await _evaluate(node.condition, arg));
    if (condition) {
      await node.body.accept(this, arg);
    } else {
      await node.elseComponent?.accept(this, arg);
    }
  }

  @override
  Future<void> visitInclude(Include node, _EvaluationContext arg) async {
    final template = await resolver.getOrParse(reader, node.reference);

    await template.accept(
      this,
      arg.fork(args: <String, Object?>{
        'ordinal': arg.ordinal++,
        'args': {
          for (final entry in node.arguments.entries)
            entry.key: await _evaluate(entry.value, arg)
        },
      }),
    );
  }

  @override
  Future<void> visitIncludeBlock(
      IncludeBlock node, _EvaluationContext arg) async {
    final template = await resolver.getOrParse(reader, node.reference);

    final childBuffer = StringBuffer();
    await node.body.accept(this, arg.fork(buffer: childBuffer));

    final additionalVariables = <String, Object?>{
      'args': {
        for (final entry in node.arguments.entries)
          entry.key: await _evaluate(entry.value, arg)
      },
      'inner': childBuffer.toString(),
      'ordinal': arg.ordinal++,
    };

    final resultBuffer = isEmittingMarkdown ? StringBuffer() : arg.buffer;
    await template.accept(
        this, arg.fork(args: additionalVariables, buffer: resultBuffer));
    if (isEmittingMarkdown) {
      arg.buffer.writeln(escapeHtmlForMarkdown(resultBuffer.toString()));
    }
  }

  static String escapeHtmlForMarkdown(String html) {
    final lines = const LineSplitter().convert(html).length;
    return ('$embeddRawHtml ${lines + 1} \n $html');
  }

  @override
  Future<void> visitObject(ObjectTag node, _EvaluationContext arg) async {
    final result = await _evaluate(node.expression, arg);
    arg.buffer.write(result);
  }

  @override
  Future<void> visitText(Text node, _EvaluationContext arg) {
    arg.buffer.write(node.token.value);
    return Future.value();
  }
}

class _ExpressionEvaluator
    implements ExpressionVisitor<_EvaluationContext, Future<Object?>> {
  const _ExpressionEvaluator();

  static bool _isTruthy(Object? value) {
    return value != null && value != false;
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);

    return null;
  }

  Future<Object?> evaluate(
      Expression expression, _EvaluationContext ctx) async {
    try {
      return await expression.accept(this, ctx);
    } on Object catch (e) {
      if (e is! EvaluationException) {
        throw EvaluationException(e, expression);
      }
    }
    return null;
  }

  @override
  Future<Object> visitBooleanCombination(
      BooleanCombination node, _EvaluationContext arg) async {
    final first = _isTruthy(await evaluate(node.left, arg));
    if (node.isAnd) {
      return first && _isTruthy(await evaluate(node.right, arg));
    } else if (node.isOr) {
      return first || _isTruthy(await evaluate(node.right, arg));
    } else {
      throw AssertionError('Boolean combination must be and or or');
    }
  }

  @override
  Future<Object> visitContains(Contains node, _EvaluationContext arg) async {
    final left = await node.left.accept(this, arg);
    final right = await node.right.accept(this, arg);
    if (left is Iterable) {
      return left.contains(right);
    }

    return left.toString().contains(right.toString());
  }

  @override
  Future<Object> visitCompare(Compare node, _EvaluationContext arg) async {
    final left = await node.left.accept(this, arg);
    final right = await node.right.accept(this, arg);

    switch (node.comparator.type) {
      case TokenType.equals:
        return left == right;
      case TokenType.notEqual:
        return left != right;
      default:
        throw UnsupportedError('Unknown comparator ${node.comparator.type}');
    }
  }

  @override
  Future<Object?> visitFilterApplication(
      FilterApplication node, _EvaluationContext arg) async {
    final base = await node.target.accept(this, arg);
    final args =
        await Future.wait(node.arguments.map((e) => e.accept(this, arg)));

    final filterName = node.functionName.lexeme;
    final filter = arg.filters[filterName];
    if (filter == null) {
      throw ArgumentError('Filter $filterName was not found');
    }

    return filter(base, args);
  }

  @override
  Future<Object?> visitNumberLiteral(
      NumberLiteral node, _EvaluationContext arg) {
    return Future.value(node.token.value);
  }

  @override
  Future<Object> visitRange(Range node, _EvaluationContext arg) async {
    final low = _toInt(await node.lower.accept(this, arg));
    final high = _toInt(await node.higher.accept(this, arg));

    if (low == null || high == null || low > high) {
      return const Iterable<int>.empty();
    }

    return Iterable<int>.generate(high - low + 1, (index) => low + index);
  }

  @override
  Future<Object> visitStringLiteral(
      StringLiteral node, _EvaluationContext arg) {
    return Future.value(node.value);
  }

  @override
  Future<Object?> visitUnaryMinus(
      UnaryMinus node, _EvaluationContext arg) async {
    final inner = await evaluate(node.inner, arg);
    if (inner is num) {
      return -inner;
    } else {
      throw ArgumentError.value(
          node, 'value', 'Unary minus is not applicable to this value');
    }
  }

  @override
  Future<Object?> visitVariableGet(VariableGet node, _EvaluationContext arg) {
    return arg.lookup(node);
  }
}

class _EvaluationContext {
  int ordinal = 0;
  final Map<String, Filter> filters;
  final Map<String, Object?> data;
  final StringBuffer buffer;

  final _EvaluationContext? parent;

  _EvaluationContext(this.data,
      {this.parent, this.filters = const {}, StringBuffer? buffer})
      : buffer = buffer ?? StringBuffer();

  FutureOr<Object?> _lookupSingle(String key) {
    if (data.containsKey(key)) {
      final entry = data[key];
      if (entry is Object Function()) {
        return entry();
      }
      return entry;
    } else {
      return parent?._lookupSingle(key);
    }
  }

  Future<Object?> lookup(VariableGet variable) async {
    final first = await _lookupSingle(variable.parts.first.lexeme);
    return utils.lookup(first, variable.parts.skip(1).map((e) => e.lexeme));
  }

  _EvaluationContext fork({Map<String, Object?>? args, StringBuffer? buffer}) {
    return _EvaluationContext(
      args ?? <String, Object?>{}, // Note: Args must not be constant here
      parent: this,
      filters: filters,
      buffer: buffer ?? this.buffer,
    );
  }
}

class _ForLoopInterrupted implements Exception {
  final bool shouldContinue;

  _ForLoopInterrupted(this.shouldContinue);
}

class EvaluationException implements Exception {
  final Object cause;
  final AstNode node;

  EvaluationException(this.cause, this.node);

  @override
  String toString() {
    final span = node.span;
    if (span == null) return cause.toString();

    return 'Error evaluating ${span.file.url}:\n${span.message(cause.toString())}';
  }
}
