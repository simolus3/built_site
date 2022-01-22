import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:highlight/highlight_core.dart' hide highlight;

List<Node> highlightParsed(String code, CompilationUnit unit) {
  final visitor = _HighlightingVisitor()
    ..visitCompilationUnit(unit)
    .._addCommentRanges(unit);

  final nodes = <Node>[];
  var currentOffset = 0;

  void report(List<_HighlightRegion> regions) {
    regions.sort((r1, r2) => r1.offset.compareTo(r2.offset));

    for (final region in regions) {
      if (region.offset > currentOffset) {
        // Add node for code between regions
        nodes.add(Node(value: code.substring(currentOffset, region.offset)));
      }

      final value = code.substring(region.offset, region.endOffset);
      nodes.add(Node(className: region.className, value: value));
      currentOffset = region.endOffset;
    }
  }

  report(visitor._currentNodes);
  if (currentOffset < code.length) {
    nodes.add(Node(value: code.substring(currentOffset)));
  }
  return nodes;
}

class _HighlightRegion {
  final int offset;
  final int length;

  final String className;

  _HighlightRegion(this.offset, this.length, this.className);

  int get endOffset => offset + length;
}

class _HighlightingVisitor extends RecursiveAstVisitor<void> {
  final List<_HighlightRegion> _currentNodes = [];

  _HighlightingVisitor();

  void _reportLeaf(SyntacticEntity? entity, String className) {
    if (entity == null) return;

    _currentNodes
        .add(_HighlightRegion(entity.offset, entity.length, className));
  }

  void _reportMergedLeaf(
      Iterable<SyntacticEntity?> entities, String className) {
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

    _currentNodes.add(_HighlightRegion(first!, last! - first, className));
  }

  void _builtinLeaf(SyntacticEntity? entity) {
    _reportLeaf(entity, 'built_in');
  }

  void _keywordLeaf(SyntacticEntity? entity) {
    _reportLeaf(entity, 'keyword');
  }

  void _functionNameLeaf(SyntacticEntity? entity) {
    _reportLeaf(entity, 'function');
  }

  void _punctuation(Token? token) {
    _reportLeaf(token, 'punctuation');
  }

  void _stringLeaf(SyntacticEntity? entity) {
    _reportLeaf(entity, 'string');
  }

  void _symbolLeaf(SyntacticEntity? entity) {
    _reportLeaf(entity, 'symbol');
  }

  void _typeNameLeaf(SyntacticEntity? entity) {
    _reportLeaf(entity, 'type');
  }

  void _addCommentRanges(CompilationUnit unit) {
    Token? token = unit.beginToken;
    while (token != null) {
      Token? commentToken = token.precedingComments;
      while (commentToken != null) {
        _reportLeaf(commentToken, 'comment');
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

  void _visitChildrenWithTitle(AstNode node, AstNode? title) {
    for (final child in node.childNodes) {
      if (child == title) {
        _reportLeaf(child, 'title');
      } else {
        child.accept(this);
      }
    }
  }

  void _visitChildrenExcept(AstNode parent, AstNode? ignore) {
    for (final child in parent.childNodes) {
      if (child != ignore) {
        child.accept(this);
      }
    }
  }

  void _functionBody(FunctionBody body) {
    _reportMergedLeaf([body.keyword, body.star], 'keyword');
    body.visitChildren(this);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _keywordLeaf(node.asOperator);
    super.visitAsExpression(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _reportLeaf(node.atSign, 'meta');
    super.visitAnnotation(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _keywordLeaf(node.assertKeyword);
    _punctuation(node.leftParenthesis);
    super.visitAssertStatement(node);
    _punctuation(node.rightParenthesis);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _keywordLeaf(node.awaitKeyword);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBlock(Block node) {
    _punctuation(node.leftBracket);
    super.visitBlock(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _functionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _builtinLeaf(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _keywordLeaf(node.breakKeyword);
    _symbolLeaf(node.label);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _keywordLeaf(node.catchKeyword);
    _keywordLeaf(node.onKeyword);
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _keywordLeaf(node.classKeyword);
    _keywordLeaf(node.abstractKeyword);
    _visitChildrenWithTitle(node, node.name);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _functionNameLeaf(node.name);
    _typeNameLeaf(node.returnType);

    for (final child in node.childNodes) {
      if (child != node.name && child != node.returnType) {
        child.accept(this);
      }
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _functionNameLeaf(node.name);
    _visitChildrenExcept(node, node.name);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _keywordLeaf(node.continueKeyword);
    _symbolLeaf(node.label);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _keywordLeaf(node.requiredKeyword);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _keywordLeaf(node.doKeyword);
    _keywordLeaf(node.whileKeyword);
    super.visitDoStatement(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _reportLeaf(node, 'number');
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _keywordLeaf(node.keyword);
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _punctuation(node.functionDefinition);
    _functionBody(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _keywordLeaf(node.extendsKeyword);
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _keywordLeaf(node.extensionKeyword);
    _keywordLeaf(node.onKeyword);

    _visitChildrenWithTitle(node, node.name);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _keywordLeaf(node.abstractKeyword);
    _keywordLeaf(node.externalKeyword);
    _keywordLeaf(node.staticKeyword);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _keywordLeaf(node.requiredKeyword);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _keywordLeaf(node.inKeyword);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _keywordLeaf(node.inKeyword);
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    _keywordLeaf(node.awaitKeyword);
    _keywordLeaf(node.forKeyword);
    super.visitForElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _keywordLeaf(node.awaitKeyword);
    _keywordLeaf(node.forKeyword);
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _keywordLeaf(node.externalKeyword);
    _keywordLeaf(node.propertyKeyword);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _keywordLeaf(node.typedefKeyword);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _keywordLeaf(node.ifKeyword);
    _punctuation(node.leftParenthesis);
    _punctuation(node.rightParenthesis);
    _keywordLeaf(node.elseKeyword);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _keywordLeaf(node.ifKeyword);
    _punctuation(node.leftParenthesis);
    _punctuation(node.rightParenthesis);
    _keywordLeaf(node.elseKeyword);
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _keywordLeaf(node.implementsKeyword);
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _keywordLeaf(node.keyword);
    _keywordLeaf(node.deferredKeyword);
    _keywordLeaf(node.asKeyword);
    super.visitImportDirective(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _keywordLeaf(node.keyword);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _reportLeaf(node, 'number');
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _stringLeaf(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _keywordLeaf(node.isOperator);
    super.visitIsExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _keywordLeaf(node.keyword);
    super.visitLibraryDirective(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _keywordLeaf(node.constKeyword);
    _punctuation(node.leftBracket);
    super.visitListLiteral(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _keywordLeaf(node.modifierKeyword);
    _keywordLeaf(node.propertyKeyword);
    _keywordLeaf(node.operatorKeyword);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _punctuation(node.operator);
    final probablyConstructor = node.realTarget == null &&
        _startsWithUppercase.hasMatch(node.methodName.name);

    if (probablyConstructor) {
      _typeNameLeaf(node.methodName);
    } else {
      _functionNameLeaf(node.methodName);
    }
    _visitChildrenExcept(node, node.methodName);
  }

  @override
  void visitNamedType(NamedType node) {
    final name = node.name.name;
    final probablyBuiltIn = !_startsWithUppercase.hasMatch(name);
    _reportLeaf(node.name, probablyBuiltIn ? 'built_in' : 'type');

    _visitChildrenExcept(node, node.name);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _builtinLeaf(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _punctuation(node.leftParenthesis);
    super.visitParenthesizedExpression(node);
    _punctuation(node.rightParenthesis);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _keywordLeaf(node.partKeyword);
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _keywordLeaf(node.partKeyword);
    _keywordLeaf(node.ofKeyword);
    super.visitPartOfDirective(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _keywordLeaf(node.returnKeyword);
    super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _keywordLeaf(node.constKeyword);
    _punctuation(node.leftBracket);
    super.visitSetOrMapLiteral(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _keywordLeaf(node.keyword);
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is Annotation) {
      _reportLeaf(node, 'meta');
    } else if (node.parent is MethodDeclaration ||
        node.parent is FunctionDeclaration) {
      _functionNameLeaf(node);
    } else if (!_startsWithUppercase.hasMatch(node.name)) {
      _reportLeaf(node, 'variable');
    } else {
      _reportLeaf(node, 'type');
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _stringLeaf(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _keywordLeaf(node.keyword);
    _punctuation(node.colon);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _keywordLeaf(node.keyword);
    _punctuation(node.colon);
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _keywordLeaf(node.switchKeyword);
    _punctuation(node.leftParenthesis);
    _punctuation(node.rightParenthesis);
    _punctuation(node.leftBracket);
    super.visitSwitchStatement(node);
    _punctuation(node.rightBracket);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _keywordLeaf(node.thisKeyword);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _keywordLeaf(node.throwKeyword);
    super.visitThrowExpression(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _keywordLeaf(node.tryKeyword);
    _keywordLeaf(node.finallyKeyword);
    super.visitTryStatement(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _keywordLeaf(node.lateKeyword);
    _keywordLeaf(node.keyword);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _keywordLeaf(node.whileKeyword);
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    _keywordLeaf(node.withKeyword);
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _keywordLeaf(node.yieldKeyword);
    _keywordLeaf(node.star);
    super.visitYieldStatement(node);
  }

  static final RegExp _startsWithUppercase = RegExp('^[A-Z]');
}

extension on AstNode {
  Iterable<AstNode> get childNodes => childEntities.whereType();
}
