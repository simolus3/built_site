import 'dart:async';

FutureOr<Object?> lookup(FutureOr<Object?> base, Iterable<String> properties) {
  return properties.fold(base, (result, newElement) {
    Object? nextElementSync(Object? resolved) {
      if (resolved is Map) {
        return resolved[newElement];
      } else {
        return null;
      }
    }

    return result is Future
        ? result.then(nextElementSync)
        : nextElementSync(result);
  });
}
