import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

final class TabPane extends StatelessComponent {
  final List<TabEntry> entries;

  const TabPane({super.key, required this.entries});

  @override
  Component build(BuildContext context) {
    return fragment([
      InternalTabHeaders(
        items: {for (final entry in entries) entry.value: entry.label},
      ),
      div(classes: 'tab-content', [
        for (final (i, entry) in entries.indexed)
          div(
            classes: 'tab-pane tab-body fade${i == 0 ? ' active show' : ''}',
            attributes: {'data-tab': entry.value},
            [entry.child],
          ),
      ]),
    ]);
  }
}

final class TabEntry {
  final String value;
  final String label;
  final Component child;

  const TabEntry({
    required this.label,
    required this.value,
    required this.child,
  });
}

@client
final class InternalTabHeaders extends StatefulComponent {
  final Map<String, String> items;

  InternalTabHeaders({super.key, required this.items});

  @override
  State<StatefulComponent> createState() => _InternalTabHeadersState();
}

final class _InternalTabHeadersState extends State<InternalTabHeaders> {
  String? value;

  @override
  void initState() {
    super.initState();
  }

  @override
  Component build(BuildContext context) {
    return ul(
      classes: 'nav nav-tabs',
      attributes: {'role': 'tablist'},
      [
        for (final (i, MapEntry(:key, :value))
            in component.items.entries.indexed)
          li(
            classes: 'nav-item',
            attributes: {'role': 'presentation'},
            [
              button(
                classes: 'nav-link${_isActive(i, key) ? ' active' : ''}',
                attributes: {'role': 'tab'},
                [text(value)],
                events: {
                  'click': (e) {
                    setState(() {
                      this.value = key;
                    });

                    final btn = e.currentTarget as web.Element;
                    final ul = btn.parentElement!.parentElement!;
                    final tabs = ul.nextElementSibling!;

                    final children = tabs.children.length;
                    for (var i = 0; i < children; i++) {
                      final tab = tabs.children.item(i)!;
                      final tabValue = tab.getAttribute('data-tab')!;
                      if (tabValue == key) {
                        tab.classList
                          ..add('active')
                          ..add('show');
                      } else {
                        tab.classList
                          ..remove('active')
                          ..remove('show');
                      }
                    }
                  },
                },
              ),
            ],
          ),
      ],
    );
  }

  bool _isActive(int index, String key) {
    return (value == null && index == 0) || value == key;
  }
}
