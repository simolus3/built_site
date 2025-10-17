import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

@client
final class MobileSidebarToggle extends StatefulComponent {
  final String target;

  const MobileSidebarToggle({super.key, this.target = '#td-section-nav'});

  @override
  State<StatefulComponent> createState() => _SidebarToggleState();
}

final class _SidebarToggleState extends State<MobileSidebarToggle> {
  var _expanded = false;
  web.Element? _target;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _target = web.document.querySelector(component.target);
      if (_target == null) {
        print('Sidebar toggle: Could not find ${component.target}!');
      }
    }
  }

  void _toggle() {
    if (_expanded) {
      _target?.classList.remove('show');
      setState(() => _expanded = false);
    } else {
      _target?.classList.add('show');
      setState(() => _expanded = true);
    }
  }

  @override
  Component build(BuildContext context) {
    return button(
      onClick: _toggle,
      classes: 'btn btn-link td-sidebar__toggle',
      type: ButtonType.button,
      attributes: {
        'aria-expanded': '$_expanded',
        'aria-label': 'Toggle section navigation',
      },
      [],
    );
  }
}
