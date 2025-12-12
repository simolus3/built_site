import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

export 'src/components/tab.dart';

export 'src/partials/footer.dart';
export 'src/partials/navbar.dart';
export 'src/partials/page.dart';
export 'src/partials/sidebar.dart';

enum PageType { page, section }

typedef BuildWithChildren = Component Function(List<Component> children);

abstract base class DocsyLayout extends PageLayoutBase {
  final BuildWithChildren wrapBody;

  final Component navbar;
  final Component footer;
  final Component sidebar;
  final Component toc;

  DocsyLayout({
    required this.navbar,
    required this.footer,
    required this.sidebar,
    required this.toc,
    this.wrapBody = Component.fragment,
  });

  PageType get type;

  Component buildContent(Page page, Component child);

  @override
  Component buildBody(Page page, Component child) {
    return wrapBody([
      header([navbar]),
      div(classes: 'container-fluid td-outer', [
        div(classes: 'td-main', [
          div(classes: 'row flex-xl-nowrap', [
            aside(classes: 'col-12 col-md-3 col-xl-2 td-sidebar d-print-none', [
              sidebar,
            ]),
            aside(
              classes: 'd-none d-xl-block col-xl-2 td-sidebar-toc d-print-none',
              [toc],
            ),
            main_(
              classes: 'col-12 col-md-9 col-xl-8 ps-md-5',
              attributes: {'role': 'main'},
              [buildContent(page, child)],
            ),
          ]),
          footer,
        ]),
      ]),
    ]);
  }

  @override
  Component buildLayout(Page page, Component child) {
    final lang = switch (page.data) {
      {'page': {'lang': String lang}} => lang,
      {'site': {'lang': String lang}} => lang,
      _ => null,
    };

    return Component.element(
      tag: 'html',
      attributes: {if (lang != null) 'lang': lang},
      children: [
        Component.element(
          tag: 'head',
          children: [
            HeadDocument(
              meta: {
                'charset': 'utf-8',
                'viewport':
                    'width=device-width, initial-scale=1, shrink-to-fit=no',
              },
            ),
            ...buildHead(page),
          ],
        ),
        Component.element(
          tag: 'body',
          classes: 'td-${type.name}',
          children: [buildBody(page, child)],
        ),
      ],
    );
  }
}
