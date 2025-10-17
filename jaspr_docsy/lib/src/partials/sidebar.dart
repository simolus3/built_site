import 'package:jaspr/server.dart';

import '../../components/internal/sidebar_toggle.dart';

final class Sidebar extends StatelessComponent {
  final Component? search;
  final List<Component> entries;

  const Sidebar({required this.entries, super.key, this.search});

  @override
  Component build(BuildContext context) {
    return div(id: 'td-sidebar-menu', classes: 'td-sidebar__inner', [
      div(id: 'content-mobile', [
        form(classes: 'td-sidebar__search d-flex align-items-center', [
          ?search,
          const MobileSidebarToggle(),
        ]),
      ]),
      div(id: 'content-desktop', []),
      nav(id: 'td-section-nav', classes: 'td-sidebar-nav collapse', [
        ul(classes: 'td-sidebar-nav__section pe-md-3 ul-0', [...entries]),
      ]),
    ]);
  }
}

final class SidebarEntry extends StatelessComponent {
  final String? href;
  final Component? title;
  final List<Component>? children;
  final int depth;
  final bool activePath;

  SidebarEntry({
    super.key,
    required this.href,
    required this.title,
    this.children,
    this.activePath = false,
    this.depth = 1,
  });

  @override
  Component build(BuildContext context) {
    final children = this.children ?? const [];
    final isPage = children.isEmpty;
    final title = this.title;
    final href = this.href;

    final titleClasses =
        'align-left ps-0 td-sidebar-link td-sidebar-link__${isPage ? 'page' : 'section'}${depth == 1 ? ' tree-root' : ''}${children.isEmpty && activePath ? ' active' : ''}';

    return li(
      classes:
          'td-sidebar-nav__section-title td-sidebar-nav__section '
          '${isPage ? ' without-child' : ' with-child'}',
      [
        if (title != null)
          if (href != null)
            a(classes: titleClasses, href: href, [
              span([title]),
            ])
          else
            div(classes: titleClasses, [
              span([title]),
            ]),

        if (children.isNotEmpty) ul(classes: 'ul-$depth', children),
      ],
    );
  }
}
