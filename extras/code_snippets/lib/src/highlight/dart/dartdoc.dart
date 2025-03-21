import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart';

// https://github.com/dart-lang/dartdoc/blob/f39f5e2880d6513bf47ef7a749e0dd672de33c04/lib/src/comment_references/parser.dart#L10
const _operatorNames = {
  '[]': 'get',
  '[]=': 'put',
  '~': 'bitwise_negate',
  '==': 'equals',
  '-': 'minus',
  '+': 'plus',
  '*': 'multiply',
  '/': 'divide',
  '<': 'less',
  '>': 'greater',
  '>=': 'greater_equal',
  '<=': 'less_equal',
  '<<': 'shift_left',
  '>>': 'shift_right',
  '>>>': 'triple_shift',
  '^': 'bitwise_exclusive_or',
  'unary-': 'unary_minus',
  '|': 'bitwise_or',
  '&': 'bitwise_and',
  '~/': 'truncate_divide',
  '%': 'modulo'
};

Uri defaultDocumentationUri(String package, {String version = 'latest'}) {
  return Uri.parse('https://pub.dev/documentation/$package/latest/$version');
}

Uri documentationForElement(
    Element element, String publicLibrary, Uri baseUri) {
  final reversePath = <String>[];

  void buildPathAsParent(Element element) {
    if (element is ClassElement) {
      reversePath.add(element.name);
    } else if (element is ExtensionElement) {
      // The name has to be non-null, otherwise it wouldn't be an exported
      // element.
      reversePath.add(element.name!);
    }
  }

  void buildPath(Element element) {
    if (element is LibraryElement) {
      reversePath.add('$publicLibrary-library.html');
    } else if (element is ClassElement) {
      reversePath.add('${element.name}-class.html');
    } else if (element is EnumElement) {
      reversePath.add('${element.name}.html');
    } else if (element is ExtensionElement) {
      reversePath.add('${element.name}.html');
    } else if (element is TypeAliasElement) {
      reversePath.add('${element.name}.html');
    } else if (element is FunctionElement) {
      reversePath.add('${element.name}.html');
    } else if (element is ConstructorElement) {
      var constructorName = element.enclosingElement3.name;
      if (element.name.isNotEmpty) {
        constructorName += '.${element.name}';
      }

      reversePath.add('$constructorName.html');
      buildPathAsParent(element.enclosingElement3);
    } else if (element is MethodElement) {
      var name = element.isOperator
          ? 'operator_${_operatorNames[element.name]}'
          : element.name;

      reversePath.add('$name.html');
      buildPathAsParent(element.enclosingElement3);
    } else if (element is FieldElement || element is PropertyAccessorElement) {
      var name = '${element.name}';

      final field = element is FieldElement
          ? element
          : (element as PropertyAccessorElement).variable2;

      if (field is FieldElement) {
        if (field.isEnumConstant) {
          // Enum constants don't get their own dartdoc page, link to enum
          buildPathAsParent(field.enclosingElement3);
          return;
        }

        if (field.isConst) {
          name += '-constant';
        }
      }

      reversePath.add('$name.html');
      buildPathAsParent(element.enclosingElement3!);
    } else {
      final parent = element.enclosingElement3;
      if (parent != null) {
        buildPath(parent);
      }
    }
  }

  buildPath(element);
  reversePath.add(publicLibrary);

  return baseUri.resolve(url.joinAll(reversePath.reversed));
}
