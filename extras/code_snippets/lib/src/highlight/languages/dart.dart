import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_span/source_span.dart';

import '../highlighter.dart';
import '../regions.dart';

class DartHighlighter extends Highlighter {
  final CompilationUnit compilationUnit;

  DartHighlighter(SourceFile file, this.compilationUnit) : super(file);

  @override
  void highlight() {
    compilationUnit.visitChildren(_HighlightingVisitor(this));

    // Add comment ranges
    Token? token = compilationUnit.beginToken;
    while (token != null) {
      Token? commentToken = token.precedingComments;
      while (commentToken != null) {
        report(HighlightRegion(RegionType.comment,
            file.span(commentToken.offset, commentToken.end)));
        commentToken = commentToken.next;
      }
      if (token.type == TokenType.EOF) {
        // Only exit the loop *after* processing the EOF token as it may
        // have preceeding comments.
        break;
      }
      token = token.next;
    }
  }
}

class _HighlightingVisitor extends RecursiveAstVisitor<void> {
  final DartHighlighter highlighter;

  _HighlightingVisitor(this.highlighter);

  void _leaf(SyntacticEntity? entity, RegionType type) {
    if (entity != null) {
      highlighter.report(HighlightRegion(
          type, highlighter.file.span(entity.offset, entity.end)));
    }
  }

  void _keyword(SyntacticEntity? entity) {
    _leaf(entity, RegionType.keyword);
  }

  void _punctuation(SyntacticEntity? entity) {
    _leaf(entity, RegionType.punctuation);
  }

  void _symbol(SyntacticEntity? entity) {
    _leaf(entity, RegionType.symbol);
  }

  void _visitChildrenWithTitle(AstNode node, AstNode? title,
      [RegionType titleType = RegionType.title]) {
    for (final child in node.childNodes) {
      if (child == title) {
        _leaf(child, titleType);
      } else {
        child.accept(this);
      }
    }
  }

  void _reportMergedLeaf(Iterable<SyntacticEntity?> entities, RegionType type) {
    final present = entities.whereType<SyntacticEntity>();
    if (present.isEmpty) {
      return; // no range to highlight
    }

    int? first;
    int? last;

    for (final entity in present) {
      first = first == null ? entity.offset : min(entity.offset, first);
      last = last == null ? entity.end : max(entity.end, last);
    }

    highlighter
        .report(HighlightRegion(type, highlighter.file.span(first!, last)));
  }

  void _functionBody(FunctionBody body) {
    _reportMergedLeaf([body.keyword, body.star], RegionType.keyword);
    body.visitChildren(this);
  }

  @override
  void visitAnnotation(Annotation node) {
    _leaf(node.atSign, RegionType.meta);
    super.visitAnnotation(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _keyword(node.asOperator);
    super.visitAsExpression(node);
  }

  void visitAssert(Assertion node) {
    _keyword(node.assertKeyword);
    _punctuation(node.leftParenthesis);
    node.visitChildren(this);
    _punctuation(node.rightParenthesis);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    visitAssert(node);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    visitAssert(node);
    super.visitAssertStatement(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _keyword(node.awaitKeyword);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _functionBody(node);
  }

  @override
  void visitBlock(Block node) {
    _punctuation(node.leftBracket);
    super.visitBlock(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _leaf(node, RegionType.literal);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _keyword(node.breakKeyword);
    _symbol(node.label);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _keyword(node.catchKeyword);
    _keyword(node.onKeyword);
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _keyword(node.classKeyword);
    _keyword(node.abstractKeyword);
    _visitChildrenWithTitle(node, node.name, RegionType.classTitle);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _leaf(node.name, RegionType.classTitle);
    _keyword(node.abstractKeyword);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    _punctuation(node.question);
    node.thenExpression.accept(this);
    _punctuation(node.colon);
    node.elseExpression.accept(this);
  }

  @override
  void visitConfiguration(Configuration node) {
    _keyword(node.ifKeyword);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _keyword(node.externalKeyword);
    _leaf(node.name, RegionType.functionTitle);
    _leaf(node.returnType, RegionType.classTitle);

    for (final child in node.childNodes) {
      if (child != node.name && child != node.returnType) {
        child.accept(this);
      }
    }
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    final name = node.constructorName;
    name.type2.accept(this);
    _leaf(name.name, RegionType.invokedFunctionTitle);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _keyword(node.continueKeyword);
    _symbol(node.label);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.metadata.accept(this);
    _keyword(node.keyword);
    _leaf(node.identifier,
        node.isConst ? RegionType.constantVariable : RegionType.variable);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _keyword(node.requiredKeyword);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _keyword(node.doKeyword);
    _keyword(node.whileKeyword);
    super.visitDoStatement(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _leaf(node, RegionType.number);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _leaf(node.name, RegionType.constantVariable);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _visitChildrenWithTitle(node, node.name);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _keyword(node.keyword);
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _punctuation(node.functionDefinition);
    _functionBody(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _keyword(node.extendsKeyword);
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _keyword(node.extensionKeyword);
    _keyword(node.onKeyword);
    _visitChildrenWithTitle(node, node.name, RegionType.classTitle);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _keyword(node.abstractKeyword);
    _keyword(node.externalKeyword);
    _keyword(node.staticKeyword);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _keyword(node.requiredKeyword);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _keyword(node.inKeyword);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _keyword(node.inKeyword);
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    _keyword(node.awaitKeyword);
    _keyword(node.forKeyword);
    super.visitForElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _keyword(node.awaitKeyword);
    _keyword(node.forKeyword);
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _keyword(node.externalKeyword);
    _keyword(node.propertyKeyword);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _keyword(node.typedefKeyword);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _keyword(node.ifKeyword);
    _punctuation(node.leftParenthesis);
    _punctuation(node.rightParenthesis);
    _keyword(node.elseKeyword);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _keyword(node.ifKeyword);
    _punctuation(node.leftParenthesis);
    _punctuation(node.rightParenthesis);
    _keyword(node.elseKeyword);
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _keyword(node.implementsKeyword);
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _keyword(node.keyword);
    _keyword(node.deferredKeyword);
    _keyword(node.asKeyword);
    super.visitImportDirective(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _keyword(node.keyword);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _leaf(node, RegionType.number);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _punctuation(node.leftBracket);
    super.visitInterpolationExpression(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _leaf(node, RegionType.string);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _keyword(node.isOperator);
    super.visitIsExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _keyword(node.keyword);
    super.visitLibraryDirective(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _keyword(node.constKeyword);
    _punctuation(node.leftBracket);
    super.visitListLiteral(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _keyword(node.modifierKeyword);
    _keyword(node.propertyKeyword);
    _keyword(node.operatorKeyword);

    _visitChildrenWithTitle(node, node.name, RegionType.functionTitle);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _punctuation(node.operator);
    final calledFunction = node.methodName.staticElement;
    final isConstructor = calledFunction != null
        ? calledFunction is ConstructorElement
        : node.realTarget == null &&
            _startsWithUppercase.hasMatch(node.methodName.name);

    _leaf(
        node.methodName,
        isConstructor
            ? RegionType.classTitle
            : RegionType.invokedFunctionTitle);

    for (final child in node.childNodes) {
      if (child != node.methodName) child.accept(this);
    }
  }

  @override
  void visitNamedType(NamedType node) {
    final name = node.name.name;
    final probablyBuiltIn = !_startsWithUppercase.hasMatch(name);
    _leaf(node.name, probablyBuiltIn ? RegionType.builtIn : RegionType.type);

    for (final child in node.childNodes) {
      if (child != node.name) child.accept(this);
    }
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _keyword(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _punctuation(node.leftParenthesis);
    super.visitParenthesizedExpression(node);
    _punctuation(node.rightParenthesis);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _keyword(node.partKeyword);
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _keyword(node.partKeyword);
    _keyword(node.ofKeyword);
    super.visitPartOfDirective(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _keyword(node.returnKeyword);
    super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _keyword(node.constKeyword);
    _punctuation(node.leftBracket);
    super.visitSetOrMapLiteral(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _keyword(node.keyword);
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is Annotation) {
      _leaf(node, RegionType.meta);
    } else {
      final target = node.staticElement;

      if (target is VariableElement || target is PropertyAccessorElement) {
        _leaf(node, RegionType.variable);
      } else if (target is FunctionTypedElement) {
        _leaf(node, RegionType.functionTitle);
      } else if (target is ClassElement) {
        _leaf(node, RegionType.classTitle);
      } else if (node.parent is MethodDeclaration ||
          node.parent is FunctionDeclaration) {
        _leaf(node, RegionType.functionTitle);
      }
      // Unknown reference, attempt to guess from name
      else if (!_startsWithUppercase.hasMatch(node.name)) {
        _leaf(node, RegionType.variable);
      } else {
        _leaf(node, RegionType.type);
      }
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _leaf(node, RegionType.string);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _keyword(node.keyword);
    _punctuation(node.colon);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _keyword(node.keyword);
    _punctuation(node.colon);
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _keyword(node.switchKeyword);
    _punctuation(node.leftParenthesis);
    _punctuation(node.rightParenthesis);
    _punctuation(node.leftBracket);
    super.visitSwitchStatement(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _keyword(node.thisKeyword);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _keyword(node.throwKeyword);
    super.visitThrowExpression(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _keyword(node.tryKeyword);
    _keyword(node.finallyKeyword);
    super.visitTryStatement(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _keyword(node.lateKeyword);
    _keyword(node.keyword);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _keyword(node.whileKeyword);
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    _keyword(node.withKeyword);
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _keyword(node.yieldKeyword);
    _keyword(node.star);
    super.visitYieldStatement(node);
  }

  static final RegExp _startsWithUppercase = RegExp('^[A-Z]');
}

extension on AstNode {
  Iterable<AstNode> get childNodes => childEntities.whereType();
}
