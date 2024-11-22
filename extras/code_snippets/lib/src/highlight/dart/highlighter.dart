import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import '../highlighter.dart';
import '../regions.dart';
import 'dart_index.dart';
import 'dartdoc.dart';

class _PendingUriResolve {
  final Element element;
  final HighlightRegion region;

  _PendingUriResolve(this.element, this.region);
}

class DartHighlighter extends Highlighter {
  final CompilationUnit compilationUnit;
  final BuildStep buildStep;

  final List<_PendingUriResolve> _pendingResolves = [];

  final Map<String, Uri> overridenDartdocUrls;

  DartHighlighter(super.file, this.buildStep, this.compilationUnit,
      this.overridenDartdocUrls);

  @override
  Future<void> highlight() async {
    _pendingResolves.clear();
    compilationUnit.visitChildren(_HighlightingVisitor(this));
    await _resolveReferences();

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

  Future<void> _resolveReferences() async {
    final index = await DartIndex.of(buildStep);

    for (final reference in _pendingResolves) {
      final import =
          await index.findImportForElement(reference.element, buildStep);

      if (import != null) {
        reference.region.documentationUri =
            _dartDocUri(import, reference.element);
      } else {
        final element = reference.element;
        final id = ElementIdentifier.fromElement(element);

        if (id != null) {
          reference.region.documentationUri =
              id.definedSource.replace(port: id.offsetInSource);
        }
      }
    }

    _pendingResolves.clear();
  }

  Uri _dartDocUri(AssetId import, Element element) {
    final libraryName = import.path;
    final base = overridenDartdocUrls[import.package] ??
        defaultDocumentationUri(import.package);

    return documentationForElement(element, libraryName, base);
  }
}

class _HighlightingVisitor extends RecursiveAstVisitor<void> {
  static final RegExp _startsWithUppercase = RegExp('^[A-Z]');

  final DartHighlighter highlighter;

  _HighlightingVisitor(this.highlighter);

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
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    visitAssert(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _keyword(node.awaitKeyword);
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

    _leaf(node.name, RegionType.classTitle);
    super.visitClassDeclaration(node);
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
      if (child != node.returnType) {
        child.accept(this);
      }
    }
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    final name = node.constructorName;
    name.type.accept(this);
    final nameLeaf = _leaf(name.name, RegionType.invokedFunctionTitle);
    final reference = node.constructorName.staticElement;
    if (reference != null && nameLeaf != null) {
      highlighter._pendingResolves.add(_PendingUriResolve(reference, nameLeaf));
    }
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
    _leaf(node.name,
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
    _keyword(node.enumKeyword);
    _leaf(node.name, RegionType.title);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _keyword(node.exportKeyword);
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

    _leaf(node.name, RegionType.classTitle);
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    _keyword(node.onKeyword);
    super.visitExtensionOnClause(node);
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
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.type?.accept(this);
    _leaf(node.name, RegionType.variable);
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
    _keyword(node.importKeyword);
    _keyword(node.deferredKeyword);
    _keyword(node.asKeyword);

    final stringRegion = _leaf(node.uri, RegionType.string);
    final importedLibrary = node.element?.importedLibrary;

    if (importedLibrary != null && stringRegion != null) {
      highlighter._pendingResolves
          .add(_PendingUriResolve(importedLibrary, stringRegion));
    }

    node.metadata.accept(this);
    node.combinators.accept(this);
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
    _keyword(node.libraryKeyword);
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

    _leaf(node.name, RegionType.functionTitle);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _punctuation(node.operator);
    final calledFunction = node.methodName.staticElement;
    final isConstructor = calledFunction != null
        ? calledFunction is ConstructorElement
        : node.realTarget == null &&
            _startsWithUppercase.hasMatch(node.methodName.name);

    final name = _leaf(
        node.methodName,
        isConstructor
            ? RegionType.classTitle
            : RegionType.invokedFunctionTitle);
    if (name != null && calledFunction != null) {
      highlighter._pendingResolves
          .add(_PendingUriResolve(calledFunction, name));
    }

    for (final child in node.childNodes) {
      if (child != node.methodName) child.accept(this);
    }
  }

  @override
  void visitNamedType(NamedType node) {
    final name = node.name2.lexeme;
    final probablyBuiltIn = !_startsWithUppercase.hasMatch(name);
    final nameLeaf = _leaf(
        node.name2, probablyBuiltIn ? RegionType.builtIn : RegionType.type);

    final resolved = node.element;
    if (resolved != null && nameLeaf != null) {
      highlighter._pendingResolves.add(_PendingUriResolve(resolved, nameLeaf));
    }

    for (final child in node.childNodes) {
      child.accept(this);
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
    final target = node.staticElement;
    HighlightRegion? region;

    if (node.parent is Annotation) {
      region = _leaf(node, RegionType.meta);
    } else {
      if (target is VariableElement || target is PropertyAccessorElement) {
        region = _leaf(node, RegionType.variable);
      } else if (target is FunctionTypedElement) {
        region = _leaf(node, RegionType.functionTitle);
      } else if (target is ClassElement) {
        region = _leaf(node, RegionType.classTitle);
      } else if (node.parent is MethodDeclaration ||
          node.parent is FunctionDeclaration) {
        region = _leaf(node, RegionType.functionTitle);
      }
      // Unknown reference, attempt to guess from name
      else if (!_startsWithUppercase.hasMatch(node.name)) {
        region = _leaf(node, RegionType.variable);
      } else {
        region = _leaf(node, RegionType.type);
      }
    }

    if (region != null && target != null) {
      highlighter._pendingResolves.add(_PendingUriResolve(target, region));
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _leaf(node, RegionType.string);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _leaf(node.superKeyword, RegionType.keyword);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _leaf(node.superKeyword, RegionType.keyword);
    super.visitSuperExpression(node);
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
  void visitVariableDeclaration(VariableDeclaration node) {
    _leaf(node.name, RegionType.variable);
    _punctuation(node.equals);
    node.initializer?.accept(this);
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

  void _functionBody(FunctionBody body) {
    _reportMergedLeaf([body.keyword, body.star], RegionType.keyword);
    body.visitChildren(this);
  }

  void _keyword(SyntacticEntity? entity) {
    _leaf(entity, RegionType.keyword);
  }

  HighlightRegion? _leaf(SyntacticEntity? entity, RegionType type) {
    HighlightRegion? region;
    if (entity != null) {
      region = HighlightRegion(
          type, highlighter.file.span(entity.offset, entity.end));
      highlighter.report(region);
    }

    return region;
  }

  void _punctuation(SyntacticEntity? entity) {
    _leaf(entity, RegionType.punctuation);
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

  void _symbol(SyntacticEntity? entity) {
    _leaf(entity, RegionType.symbol);
  }
}

extension on AstNode {
  Iterable<AstNode> get childNodes => childEntities.whereType();
}
