import 'dart:async';
import 'dart:html';

const _show = 'show';
const _collapse = 'collapse';
const _collapsing = 'collapsing';
const _collapsed = 'collapsed';

const _duration = Duration(milliseconds: 300);

void initCollapse() {
  document.querySelectorAll('button.td-sidebar__toggle').forEach(_watch);
}

void _watch(Element button) {
  final target = document.querySelector(button.dataset['target']!)!;
  final useWidth = target.classes.contains('width');
  final dimension = useWidth ? 'width' : 'height';

  void show() {
    target.classes
      ..remove(_collapse)
      ..add(_collapsing);
    target.style.setProperty(dimension, '0');

    button.attributes['aria-expanded'] = 'true';

    final endDim = useWidth ? target.scrollWidth : target.scrollHeight;
    target.style.setProperty(dimension, '${endDim}px');

    Timer(_duration, () {
      target.classes
        ..remove(_collapsing)
        ..add(_collapse)
        ..add(_show);
      target.style.setProperty(dimension, '');
    });
  }

  void hide() {
    final boundingRect = target.getBoundingClientRect();
    final dimNow = useWidth ? boundingRect.width : boundingRect.height;
    target.style.setProperty(dimension, '${dimNow}px');

    target.classes
      ..add(_collapsing)
      ..remove(_collapse)
      ..remove(_show);

    button
      ..classes.add(_collapsed)
      ..attributes['aria-expanded'] = 'false';
    target.style.setProperty(dimension, '');

    Timer(_duration, () {
      target.classes
        ..remove(_collapsing)
        ..add(_collapse);
    });
  }

  void toggle() {
    if (target.classes.contains(_show)) {
      hide();
    } else {
      show();
    }
  }

  button.onClick.listen((e) {
    toggle();
  });
}
