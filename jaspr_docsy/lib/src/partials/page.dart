import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

final class PageContent extends StatelessComponent {
  final Page page;
  final Component renderedMarkdown;

  const PageContent({
    super.key,
    required this.page,
    required this.renderedMarkdown,
  });

  @override
  Component build(BuildContext context) {
    return div(classes: 'td-content', [
      if (page.data.page['title'] case String title) h1([.text(title)]),
      if (page.data.page['description'] case String desc)
        div(classes: 'lead', [.text(desc)]),
      header(classes: 'article-meta', []),
      if (renderedMarkdown case Content content)
        // Content adds a <section> we need to remove for styles to work.
        content.child
      else
        renderedMarkdown,
    ]);
  }
}
