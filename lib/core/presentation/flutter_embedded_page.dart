import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'eduma_link.dart';
import 'flutter_host.dart';

/// Screens of the Flutter app the Jaspr router renders itself; anything else
/// the embedded app navigates to falls back to Home.
const _jasprPaths = {
  '/main',
  '/home',
  '/spaceDetail',
  '/calendarTab',
  '/libraryTab',
  '/notifications',
  '/profile',
  '/streak',
  '/assistantHistory',
  '/pinnedSpacesSeeAll',
  '/recentSpacesSeeAll',
  '/recentCanvasesSeeAll',
  '/legalDocument',
};

/// Maps a location the embedded app moved to onto a Jaspr route.
String jasprLocationFor(String flutterLocation) {
  final uri = Uri.tryParse(flutterLocation);
  if (uri == null) return '/main';
  return _jasprPaths.contains(uri.path) ? uri.toString() : '/main';
}

/// A route showing an embedded Flutter screen (Canvas, Notes) through the
/// shared, already-running app ([FlutterHost]): no reload per open.
///
/// While the app boots the first time (only when it wasn't warmed up yet),
/// this shows a loading state underneath; the app's own back button closes
/// the view and returns to the previous screen.
class FlutterEmbeddedView extends StatefulComponent {
  const FlutterEmbeddedView({required this.title, required this.route, super.key});

  final String title;
  final String route;

  @override
  State<FlutterEmbeddedView> createState() => _FlutterEmbeddedViewState();
}

class _FlutterEmbeddedViewState extends State<FlutterEmbeddedView> {
  bool _ready = FlutterHost.isReady;
  int? _owner;

  @override
  void initState() {
    super.initState();
    _open();
    if (!_ready) {
      FlutterHost.whenReady(() {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  void didUpdateComponent(covariant FlutterEmbeddedView oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.route != component.route) _open();
  }

  void _open() {
    _owner = FlutterHost.open(
      component.route,
      onClose: () {
        if (mounted) edumaBack(context);
      },
      onNavigate: (location) {
        if (mounted) edumaNavigate(context, jasprLocationFor(location), replace: true);
      },
    );
  }

  @override
  void dispose() {
    FlutterHost.hide(_owner);
    super.dispose();
  }

  @override
  Component build(BuildContext context) => main_(
    classes: 'eduma-flutter-embedded',
    attributes: {'aria-label': component.title, 'aria-busy': '${!_ready}'},
    [
      if (!_ready)
        div(classes: 'eduma-flutter-embedded__loading', [
          span(classes: 'eduma-flutter-embedded__spinner', attributes: {'aria-hidden': 'true'}, []),
          span([.text('Opening ${component.title}…')]),
        ]),
    ],
  );
}

/// Opens a new AI chat (the source's assistant sheet) over the current
/// screen. Closing the sheet just hides it; moving to another screen from it
/// (e.g. AI chats) hands that navigation to the Jaspr router.
void openAiChatOverlay(BuildContext context, {VoidCallback? onClosed}) {
  FlutterHost.open(
    '/assistantNewChat',
    onClose: () {
      FlutterHost.hide();
      onClosed?.call();
    },
    onNavigate: (location) {
      FlutterHost.hide();
      edumaNavigate(context, jasprLocationFor(location));
    },
  );
}

/// Kept for callers of the previous API.
Component flutterEmbeddedPage({required String title, required String route}) =>
    FlutterEmbeddedView(title: title, route: route);
