import 'dart:html';

import 'src/collapse.dart';

const _insertLinkIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" width="24" height="24" viewBox="0 0 24 24"><path d="M0 0h24v24H0z" fill="none"/><path d="M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z"/></svg>';

void built_site_main() {
  // Init components
  initCollapse();

  // Create fixed headers if we have a cover
  final promo = document.querySelector('.js-td-cover');
  final navbar = document.querySelector('.js-navbar-scroll');
  if (promo != null && navbar != null) {
    final promoOffset = promo.bottomPos;
    final threshold = navbar.offset.height.ceil();

    if ((promoOffset - window.scrollY) < threshold) {
      navbar.classes.add('navbar-bg-onscroll');
    }

    document.onScroll.listen((_) {
      final promoOffset = promo.bottomPos;

      if ((promoOffset - window.scrollY) < threshold) {
        navbar.classes.add('navbar-bg-onscroll');
      } else {
        navbar.classes
          ..remove('navbar-bg-onscroll')
          ..add('navbar-bg-onscoll--fade');
      }
    });
  }

  // Add anchor links that show on hover
  final articles = document.getElementsByTagName('main');
  if (articles.isNotEmpty) {
    final article = articles.first as Element;
    final headings = article.querySelectorAll('h1, h2, h3, h4, h5, h6');
    for (final heading in headings) {
      if (heading.id.isNotEmpty) {
        final a = AnchorElement()
          // set visibility: hidden instead of display:none to avoid layout change
          ..style.visibility = 'hidden'
          // hide this from screen readers
          ..attributes['aria-hidden'] = 'true'
          ..setInnerHtml(_insertLinkIcon,
              treeSanitizer: NodeTreeSanitizer.trusted)
          ..href = '#${heading.id}';
        heading.insertAdjacentElement('beforeend', a);
        heading.onMouseEnter.listen((_) {
          a.style.visibility = 'initial';
        });
        heading.onMouseLeave.listen((_) {
          a.style.visibility = 'hidden';
        });
      }
    }
  }
}

extension on Element {
  num get bottomPos {
    return offsetTop + offsetHeight;
  }
}
