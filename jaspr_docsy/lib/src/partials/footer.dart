import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

final class Footer extends StatelessComponent {
  final Component left;
  final Component center;
  final Component right;

  const Footer({
    super.key,
    required this.left,
    required this.center,
    required this.right,
  });

  @override
  Component build(BuildContext context) {
    return footer(classes: 'td-footer row d-print-none', [
      div(classes: 'container-fluid', [
        div(classes: 'row mx-md-2', [
          div(classes: 'td-footer__left col-6 col-sm-4 order-sm-1', [left]),
          div(classes: 'td-footer__right col-6 col-sm-4 order-sm-3', [right]),
          div(classes: 'td-footer__center col-6 col-sm-4 order-sm-2', [center]),
        ]),
      ]),
    ]);
  }
}

final class FooterLinks extends StatelessComponent {
  final List<Component> children;

  const FooterLinks({super.key, required this.children});

  @override
  Component build(BuildContext context) {
    return ul(classes: 'td-footer__links-list', children);
  }
}

final class FooterLink extends StatelessComponent {
  final String title;
  final String href;
  final Component child;

  const FooterLink({
    super.key,
    required this.title,
    required this.href,
    required this.child,
  });

  @override
  Component build(BuildContext context) {
    return li(
      classes: 'td-footer__links-item',
      attributes: {'title': title},
      [
        a(
          target: Target.blank,
          href: href,
          attributes: {'rel': 'noopener'},
          [child],
        ),
      ],
    );
  }
}
