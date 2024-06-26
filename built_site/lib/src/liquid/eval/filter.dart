import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../markdown/markdown.dart' as md;
import 'utils.dart';

typedef Filter = FutureOr<Object?> Function(Object? input, List<Object?> args);

num _toNum(Object? object) {
  final obj = ArgumentError.checkNotNull(object);

  if (obj is num) return obj;
  if (obj is String) return num.parse(obj);

  return double.nan;
}

num abs(Object? input, List<Object?> args) {
  return _toNum(input).abs();
}

String append(Object? input, List<Object?> args) {
  return input.toString() + args.join();
}

num atLeast(Object? input, List<Object?> args) {
  return max(_toNum(input), _toNum(args.single));
}

num atMost(Object? input, List<Object?> args) {
  return min(_toNum(input), _toNum(args.single));
}

String capitalize(Object? input, List<Object?> args) {
  final asString = input.toString();
  if (asString.isEmpty) return asString;

  return asString.substring(0, 1).toUpperCase() + asString.substring(1);
}

int ceil(Object? input, List<Object?> args) {
  return _toNum(input).ceil();
}

Object? compact(Object? input, List<Object?> args) {
  return (input! as Iterable<Object?>).where((e) => e != null);
}

Object? concat(Object? input, List<Object?> args) {
  final start = (input! as List).cast<Object?>();

  return <Object?>[
    ...start,
    for (final arg in args)
      if (arg is Iterable) ...arg else arg
  ];
}

String date(Object? input, List<Object?> args) {
  final format = DateFormat(args.first.toString());
  return format.format(DateTime.parse(input! as String));
}

Object? $default(Object? input, List<Object?> args) {
  final defaultParm = args.first;
  if (input == null || input == false || (input is Iterable && input.isEmpty)) {
    return defaultParm;
  }
  return input;
}

Object? dividedBy(Object? input, List<Object?> args) {
  final numerator = _toNum(input);
  final divisor = _toNum(args.first);

  if (divisor is int) {
    return (numerator / divisor).round();
  } else {
    return numerator / divisor;
  }
}

Object? downcase(Object? input, List<Object?> args) {
  return input.toString().toLowerCase();
}

Object? endsWith(Object? input, List<Object?> args) {
  return input.toString().endsWith(args.first.toString());
}

Object? floor(Object? input, List<Object?> args) {
  return _toNum(input).floor();
}

Object? get(Object? input, List<Object?> args) {
  return lookup(input, args.map((e) => e.toString()));
}

Object? jsonDecode(Object? input, List<Object?> args) {
  return json.decode(input.toString());
}

Object? map(Object? input, List<Object?> args) {
  return (input! as Iterable<Object?>).map<Object?>((e) {
    if (e is! Map) return null;
    return e[args.single];
  });
}

Object? markdownify(Object? input, List<Object?> args) {
  final inline = args.any((element) => element == 'inline');
  final data = md.parse(input.toString(), inline: inline);
  return md.renderToHtml(data);
}

Object? minus(Object? input, List<Object?> args) {
  return _toNum(input) - _toNum(args[0]);
}

Object? modulo(Object? input, List<Object?> args) {
  return _toNum(input) % _toNum(args[0]);
}

Object? plus(Object? input, List<Object?> args) {
  return _toNum(input) + _toNum(args[0]);
}

Object? reverse(Object? input, List<Object?> args) {
  return (input! as List).reversed;
}

Object? round(Object? input, List<Object?> args) {
  return _toNum(input).round();
}

Object? sort(Object? input, List<Object?> args) {
  if (input is List) {
    final properties = args.map((e) => e.toString()).toList();

    Object? map(Object? input) {
      return lookup(input, properties);
    }

    return input
      ..sort((Object? a, Object? b) {
        return Comparable.compare(map(a)! as Comparable, map(b)! as Comparable);
      });
  }

  return input;
}

Object? startsWith(Object? input, List<Object?> args) {
  return input.toString().startsWith(args.first.toString());
}

Object? times(Object? input, List<Object?> args) {
  if (args.isEmpty) return input;

  final factor = _toNum(args.first);

  try {
    return _toNum(input) * factor;
  } on Object {
    if (input is String) return input * factor.floor();
  }

  return input;
}

Object? upcase(Object? input, List<Object?> args) {
  return input.toString().toUpperCase();
}

Object? urlDecode(Object? input, List<Object?> args) {
  return Uri.decodeFull(input.toString());
}

Object? urlEncode(Object? input, List<Object?> args) {
  return Uri.encodeFull(input.toString());
}

Object? Function(Object?, List<Object?>) _binaryMath(
    Object? Function(num a, num b) compute) {
  return (input, args) {
    return compute(_toNum(input), _toNum(args[0]));
  };
}

Map<String, Filter> filters = {
  'abs': abs,
  'append': append,
  'at_least': atLeast,
  'ast_most': atMost,
  'capitalize': capitalize,
  'ceil': ceil,
  'changeExtension': (input, args) {
    final without = p.url.withoutExtension(input.toString());
    return without + args.map((e) => e.toString()).join();
  },
  'compact': compact,
  'concat': concat,
  'date': date,
  'default': $default,
  'divided_by': dividedBy,
  'downcase': downcase,
  'floor': floor,
  'endsWith': endsWith,
  'length': (input, args) {
    if (input is String) {
      return input.length;
    } else if (input is List) {
      return input.length;
    }
    return null;
  },
  'get': get,
  'json_decode': jsonDecode,
  'lower': downcase,
  'map': map,
  'markdownify': markdownify,
  'minus': minus,
  'modulo': modulo,
  'plus': plus,
  'reverse': reverse,
  'round': round,
  'startsWith': startsWith,
  'sort': sort,
  'split': (input, args) {
    return input.toString().split(args[0].toString());
  },
  'times': times,
  'upcase': upcase,
  'url_decode': urlDecode,
  'url_encode': urlEncode,
  'lt': _binaryMath((a, b) => a < b),
  'lte': _binaryMath((a, b) => a = b),
  'gt': _binaryMath((a, b) => a > b),
  'gte': _binaryMath((a, b) => a >= b),
};
