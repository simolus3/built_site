import 'dart:convert';

import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'directive.dart';

const _equality = ListEquality();

class Excerpt {
  final String name;
  final List<ContinousRegion> regions;

  Excerpt(this.name, this.regions);

  @override
  int get hashCode => Object.hash(name, _equality.hash(regions));

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Excerpt &&
            other.name == name &&
            _equality.equals(other.regions, regions);
  }

  @override
  String toString() {
    final lines = regions
        .map((r) => '[${r.startLine}, ${r.endLineExclusive})')
        .join(', ');

    return 'Region $name covering lines $lines';
  }
}

@sealed
class ContinousRegion {
  final int startLine;
  final int endLineExclusive;

  ContinousRegion(this.startLine, this.endLineExclusive);

  @override
  int get hashCode => Object.hash(startLine, endLineExclusive);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ContinousRegion &&
            other.startLine == startLine &&
            other.endLineExclusive == endLineExclusive;
  }
}

class _PendingRegion {
  final String excerpt;
  final int startLine;

  _PendingRegion(this.excerpt, this.startLine);
}

class Excerpter {
  static const _fullFileKey = '(full)';
  static const _defaultRegionKey = '';

  final String uri;
  final String content;
  final List<String> _lines; // content as list of lines

  // Index of next line to process.
  int _lineIdx;
  int get _lineNum => _lineIdx + 1;
  String get _line => _lines[_lineIdx];

  bool containsDirectives = false;

  int get numExcerpts => excerpts.length;

  Excerpter(this.uri, this.content)
      : _lines = const LineSplitter().convert(content),
        _lineIdx = 0;

  final Map<String, Excerpt> excerpts = {};
  final List<_PendingRegion> _openExcerpts = [];

  void weave() {
    // Collect the full file in case we need it.
    _excerptStart(_fullFileKey);

    for (_lineIdx = 0; _lineIdx < _lines.length; _lineIdx++) {
      _processLine();
    }

    // End all regions at the end
    _openExcerpts.forEach(_closePending);
  }

  void _processLine() {
    final directive = Directive.tryParse(_line);

    if (directive != null) {
      directive.issues.forEach(_warn);

      switch (directive.kind) {
        case Kind.startRegion:
          containsDirectives = true;
          _startRegion(directive);
          break;
        case Kind.endRegion:
          containsDirectives = true;
          _endRegion(directive);
          break;
        default:
          throw Exception('Unimplemented directive: $_line');
      }

      // Interrupt pending regions, they should not contain this line with
      // a directive.
      final pending = _openExcerpts.toList();
      for (final open in pending) {
        if (open.startLine <= _lineIdx) {
          _closePending(open);
          _openExcerpts.remove(open);
          _openExcerpts.add(_PendingRegion(open.excerpt, _lineIdx + 1));
        }
      }
    }
  }

  void _startRegion(Directive directive) {
    final regionAlreadyStarted = <String>[];
    final regionNames = directive.args;

    log.finer('_startRegion(regionNames = $regionNames)');

    if (regionNames.isEmpty) regionNames.add(_defaultRegionKey);
    for (final name in regionNames) {
      final isNew = _excerptStart(name);
      if (!isNew) {
        regionAlreadyStarted.add(_quoteName(name));
      }
    }

    _warnRegions(
      regionAlreadyStarted,
      (regions) => 'repeated start for $regions',
    );
  }

  void _endRegion(Directive directive) {
    final regionsWithoutStart = <String>[];
    final regionNames = directive.args;
    log.finer('_endRegion(regionNames = $regionNames)');

    if (regionNames.isEmpty) {
      regionNames.add('');
      // _warn('${directive.lexeme} has no explicit arguments; assuming ""');
    }

    outer:
    for (final name in regionNames) {
      for (final open in _openExcerpts) {
        if (open.excerpt == name) {
          _closePending(open);
          _openExcerpts.remove(open);
          continue outer;
        }
      }

      // No matching region found, otherwise we would have returned.
      regionsWithoutStart.add(_quoteName(name));
    }

    _warnRegions(
      regionsWithoutStart,
      (regions) => '$regions end without a prior start',
    );
  }

  void _warnRegions(
    List<String> _regions,
    String Function(String) msg,
  ) {
    if (_regions.isEmpty) return;
    final regions = _regions.join(', ');
    final s = regions.isEmpty
        ? ''
        : _regions.length > 1
            ? 's ($regions)'
            : ' $regions';
    _warn(msg('region$s'));
  }

  void _closePending(_PendingRegion pending) {
    final excerpt = excerpts[pending.excerpt];
    if (excerpt == null) return;

    if (pending.startLine == _lineIdx) {
      _warnRegions(
        [pending.excerpt],
        (regions) => 'empty $regions',
      );
    }

    excerpt.regions.add(ContinousRegion(pending.startLine, _lineIdx));
  }

  /// Registers [name] as an open excerpt.
  ///
  /// If [name] is a new excerpt, then its value in
  /// [excerpts] is set to the empty list.
  ///
  /// Returns false iff name was already open
  bool _excerptStart(String name) {
    excerpts.putIfAbsent(name, () => Excerpt(name, []));

    if (_openExcerpts.any((e) => e.excerpt == name)) {
      return false; // Already open!
    }

    _openExcerpts.add(_PendingRegion(name, _lineIdx + 1));
    return true;
  }

  void _warn(String msg) => log.warning('$msg at $uri:$_lineNum');

  /// Quote a region name if it isn't already quoted.
  String _quoteName(String name) => name.startsWith("'") ? name : '"$name"';
}
