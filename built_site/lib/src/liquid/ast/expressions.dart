import '../parser/token.dart';
import 'node.dart';

abstract class Expression extends AstNode {
  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg);
}

abstract class ExpressionVisitor<Arg, Ret> {
  Ret visitContains(Contains node, Arg arg);
  Ret visitBooleanCombination(BooleanCombination node, Arg arg);
  Ret visitCompare(Compare node, Arg arg);
  Ret visitFilterApplication(FilterApplication node, Arg arg);
  Ret visitRange(Range node, Arg arg);
  Ret visitStringLiteral(StringLiteral node, Arg arg);
  Ret visitNumberLiteral(NumberLiteral node, Arg arg);
  Ret visitVariableGet(VariableGet node, Arg arg);
  Ret visitUnaryMinus(UnaryMinus node, Arg arg);
}

class BooleanCombination extends Expression {
  final Expression left;
  final IdentifierToken operator;
  final Expression right;

  BooleanCombination(this.left, this.operator, this.right);

  bool get isAnd => operator.lexeme == 'and';
  bool get isOr => operator.lexeme == 'or';

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitBooleanCombination(this, arg);
  }
}

class Compare extends Expression {
  final Expression left;
  final Token comparator;
  final Expression right;

  Compare(this.left, this.comparator, this.right);

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitCompare(this, arg);
  }
}

class Contains extends Expression {
  final Expression left;
  final Expression right;

  Contains(this.left, this.right);

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitContains(this, arg);
  }
}

class FilterApplication extends Expression {
  final Expression target;
  final Token pipe;
  final IdentifierToken functionName;
  final List<Expression> arguments;

  FilterApplication(this.target, this.pipe, this.functionName, this.arguments);

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitFilterApplication(this, arg);
  }
}

/// Creates an iterable of numbers from [lower] to [higher] (both inclusive).
class Range extends Expression {
  final Expression lower;
  final Expression higher;

  Range(this.lower, this.higher);

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitRange(this, arg);
  }
}

class StringLiteral extends Expression {
  final StringLiteralToken token;

  StringLiteral(this.token);

  String get value => token.value;

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitStringLiteral(this, arg);
  }
}

class NumberLiteral extends Expression {
  final NumberLiteralToken token;

  NumberLiteral(this.token);

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitNumberLiteral(this, arg);
  }
}

class UnaryMinus extends Expression {
  final Expression inner;

  UnaryMinus(this.inner);

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitUnaryMinus(this, arg);
  }
}

class VariableGet extends Expression {
  final List<IdentifierToken> parts;

  VariableGet(this.parts);

  @override
  Ret accept<Arg, Ret>(ExpressionVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitVariableGet(this, arg);
  }
}
