import '../parser/token.dart';
import 'node.dart';

abstract class ComponentVisitor<Arg, Ret> {
  Ret visitAssign(Assign node, Arg arg);
  Ret visitBlock(Block node, Arg arg);
  Ret visitBreak(Break node, Arg arg);
  Ret visitCapture(Capture node, Arg arg);
  Ret visitComment(Comment node, Arg arg);
  Ret visitContinue(Continue node, Arg arg);
  Ret visitFor(For node, Arg arg);
  Ret visitIf(If node, Arg arg);
  Ret visitInclude(Include node, Arg arg);
  Ret visitIncludeBlock(IncludeBlock node, Arg arg);
  Ret visitObject(ObjectTag node, Arg arg);
  Ret visitText(Text node, Arg arg);
}

abstract class TemplateComponent extends AstNode {
  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg);
}

class Assign extends TemplateComponent {
  final IdentifierToken variable;
  final Expression expression;

  Assign(this.variable, this.expression);

  String get variableName => variable.lexeme;

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitAssign(this, arg);
  }
}

class Block extends TemplateComponent {
  final List<TemplateComponent> children;

  Block(this.children);

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitBlock(this, arg);
  }
}

class Break extends TemplateComponent {
  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitBreak(this, arg);
  }
}

class Capture extends TemplateComponent {
  final String variable;
  final TemplateComponent content;

  Capture(this.variable, this.content);

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitCapture(this, arg);
  }
}

class Comment extends TemplateComponent {
  final Block content;

  Comment(this.content);

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitComment(this, arg);
  }
}

class Continue extends TemplateComponent {
  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitContinue(this, arg);
  }
}

class For extends TemplateComponent {
  final IdentifierToken variable;
  final Expression iterable;
  final Block body;
  final Block? elseBlock;

  final Expression? limit;
  final Expression? offset;
  final bool reverse;

  For(this.variable, this.iterable, this.body,
      {this.elseBlock, this.limit, this.offset, this.reverse = false});

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitFor(this, arg);
  }
}

class If extends TemplateComponent {
  final Expression condition;
  final Block body;
  final TemplateComponent? elseComponent;

  If(this.condition, this.body, [this.elseComponent]);

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitIf(this, arg);
  }
}

class Include extends TemplateComponent {
  final String reference;
  final Map<String, Expression> arguments;

  Include(this.reference, this.arguments);

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitInclude(this, arg);
  }
}

class IncludeBlock extends TemplateComponent {
  final String reference;
  final Map<String, Expression> arguments;
  final TemplateComponent body;

  IncludeBlock(this.reference, this.arguments, this.body);

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitIncludeBlock(this, arg);
  }
}

class ObjectTag extends TemplateComponent {
  final Expression expression;

  ObjectTag(this.expression);

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitObject(this, arg);
  }
}

/// Simple text node that will just emit raw text.
class Text extends TemplateComponent {
  final Token token;

  Text(this.token)
      : assert(token.type == TokenType.text, 'Invalid type for text token');

  @override
  Ret accept<Arg, Ret>(ComponentVisitor<Arg, Ret> visitor, Arg arg) {
    return visitor.visitText(this, arg);
  }

  @override
  String toString() {
    return 'Text: ${token.lexeme}';
  }
}
