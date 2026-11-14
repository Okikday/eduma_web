import 'package:web/web.dart' as web;

abstract final class MainNavigationPreferences {
  static const _mobileLayoutKey = 'eduma_web_mobile_navigation';

  static bool get usesHamburgerNavigation => web.window.localStorage.getItem(_mobileLayoutKey) == 'hamburger';

  static void setHamburgerNavigation(bool enabled) {
    if (enabled) {
      web.window.localStorage.setItem(_mobileLayoutKey, 'hamburger');
    } else {
      web.window.localStorage.removeItem(_mobileLayoutKey);
    }
  }
}
