import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

final class Navbar extends StatelessComponent {
  final bool cover;
  final Component brand;
  final Component? search;
  final List<Component> items;

  const Navbar({
    this.cover = false,
    this.search,
    required this.brand,
    required this.items,
  });

  @override
  Component build(BuildContext context) {
    return nav(
      classes: 'td-navbar js-navbar-scroll${cover ? ' td-navbar-cover' : ''}',
      attributes: {'data-bs-theme': 'dark'},
      [
        div(classes: 'container-fluid flex-column flex-md-row', [
          brand,
          div(classes: 'td-navbar-nav-scroll ms-md-auto', id: 'main_navbar', [
            ul(classes: 'navbar-nav', items),
          ]),
          if (search case final search?)
            div(classes: 'd-none d-lg-block', [search]),
        ]),
      ],
    );
  }
}

final class NavbarBrand extends StatelessComponent {
  final String href;
  final Component logo;
  final Component title;

  const NavbarBrand({
    super.key,
    required this.href,
    required this.title,
    this.logo = const Component.empty(),
  });

  @override
  Component build(BuildContext context) {
    return a(classes: 'navbar-brand', href: href, [
      span(classes: 'navbar-brand__logo navbar-logo', [logo]),
      span(classes: 'navbar-brand__name', [title]),
    ]);
  }
}

final class NavbarLink extends StatelessComponent {
  final String href;
  final bool active;
  final List<Component> children;

  const NavbarLink({
    super.key,
    required this.href,
    this.active = false,
    required this.children,
  });

  @override
  Component build(BuildContext context) {
    return li(classes: 'nav-item', [
      a(classes: 'nav-link${active ? ' active' : ''}', href: href, children),
    ]);
  }
}
