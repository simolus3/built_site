import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

final class SearchBar extends StatelessComponent {
  final Map<String, EventCallback> events;

  const SearchBar({super.key, this.events = const {}});

  @override
  Component build(BuildContext context) {
    return div(classes: 'td-search', events: events, [
      div(classes: 'td-search__icon', []),
      input(
        classes: 'td-search__input form-control td-search-input',
        type: InputType.search,
        attributes: {'placeholder': 'Search this site…', 'autocomplete': 'off'},
      ),
    ]);
  }
}
