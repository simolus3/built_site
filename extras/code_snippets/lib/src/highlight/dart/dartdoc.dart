import 'package:analyzer/dart/element/element2.dart';
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
    Element2 element, String publicLibrary, Uri baseUri) {
  final reversePath = <String>[];

  void buildPathAsParent(Element2 element) {
    if (element is ClassElement2) {
      reversePath.add(element.name3!);
    } else if (element is ExtensionElement2) {
      // The name has to be non-null, otherwise it wouldn't be an exported
      // element.
      reversePath.add(element.name3!);
    }
  }

  void buildPath(Element2 element) {
    if (element is LibraryElement2) {
      reversePath.add('$publicLibrary-library.html');
    } else if (element is ClassElement2) {
      reversePath.add('${element.name3}-class.html');
    } else if (element is EnumElement2) {
      reversePath.add('${element.name3}.html');
    } else if (element is ExtensionElement2) {
      reversePath.add('${element.name3}.html');
    } else if (element is TypeAliasElement2) {
      reversePath.add('${element.name3}.html');
    } else if (element is ConstructorElement2) {
      var constructorName = element.enclosingElement2.name3!;
      if (element.name3 != 'new') {
        constructorName += '.${element.name3}';
      }

      reversePath.add('$constructorName.html');
      buildPathAsParent(element.enclosingElement2);
    } else if (element is MethodElement2) {
      var name = element.isOperator
          ? 'operator_${_operatorNames[element.name3]}'
          : element.name3;

      reversePath.add('$name.html');
      buildPathAsParent(element.enclosingElement2!);
    } else if (element is FieldElement2 ||
        element is PropertyAccessorElement2) {
      var name = '${element.name3}';

      final field = element is FieldElement2
          ? element
          : (element as PropertyAccessorElement2).variable3;

      if (field is FieldElement2) {
        if (field.isEnumConstant) {
          // Enum constants don't get their own dartdoc page, link to enum
          buildPathAsParent(field.enclosingElement2);
          return;
        }

        if (field.isConst) {
          name += '-constant';
        }
      }

      reversePath.add('$name.html');
      buildPathAsParent(element.enclosingElement2!);
    } else {
      final parent = element.enclosingElement2;
      if (parent != null) {
        buildPath(parent);
      }
    }
  }

  buildPath(element);
  reversePath.add(publicLibrary);

  return baseUri.resolve(url.joinAll(reversePath.reversed));
}
