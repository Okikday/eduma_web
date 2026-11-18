/// The entrypoint for the **client** app.
///
/// This file is compiled to javascript and executed on the client when loading the page.
library;

// Client-specific Jaspr import.
import 'package:jaspr/client.dart';
// Imports the [App] component.
import 'app.dart';
import 'core/presentation/flutter_host.dart';
import 'core/presentation/theme_controller.dart';
import 'features/auth/logic/auth_actions.dart';

void main() {
  EdumaThemeController.applySavedTheme();
  // Attaches the [App] component to the <body> of the page.
  runApp(App());
  // Boot the shared Flutter app (Canvas / Notes / AI chat) in idle time once
  // signed in, so opening those views later is instant.
  AuthActions.restoreSession().then((session) {
    if (session != null) FlutterHost.scheduleWarmUp();
  }).ignore();
}
