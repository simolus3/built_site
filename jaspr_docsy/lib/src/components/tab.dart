import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../../components/internal/tabs.dart';

final class DocsyTabs extends CustomComponent {
  DocsyTabs() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node is ElementNode && node.tag == 'Tabs') {
      var tabs =
          node.children?.whereType<ElementNode>().where(
            (n) => n.tag == 'TabItem',
          ) ??
          [];
      if (tabs.isEmpty) {
        print("[WARNING] Tabs component requires at least one TabItem child.");
      }

      return TabPane(
        entries: [
          for (var tab in tabs)
            TabEntry(
              label: tab.attributes['label'] ?? '',
              value: tab.attributes['value'] ?? '',
              child: builder.build(tab.children),
            ),
        ],
      );
    }
    return null;
  }
}
