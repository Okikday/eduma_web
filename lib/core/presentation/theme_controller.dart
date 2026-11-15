import 'package:web/web.dart' as web;

/// Manages the active Eduma web color theme (`Light`, `Dark`, or `System`)
/// via `localStorage` and `data-theme` on `<html>`.
abstract final class EdumaThemeController {
  static const _storageKey = 'eduma_theme_mode';

  static String currentModeLabel() {
    try {
      final raw = web.window.localStorage.getItem(_storageKey)?.trim().toLowerCase();
      return switch (raw) {
        'dark' => 'Dark',
        'system' => 'System',
        _ => 'Light',
      };
    } catch (_) {
      return 'Light';
    }
  }

  static void applySavedTheme() => applyMode(currentModeLabel());

  static String cycleMode(String current) => switch (current) {
    'Light' => 'Dark',
    'Dark' => 'System',
    _ => 'Light',
  };

  static void applyMode(String mode) {
    final normalized = switch (mode.trim().toLowerCase()) {
      'dark' => 'dark',
      'system' => 'system',
      _ => 'light',
    };
    try {
      web.window.localStorage.setItem(_storageKey, normalized);
    } catch (_) {}
    final root = web.document.documentElement;
    if (root != null) {
      root.setAttribute('data-theme', normalized);
    }
  }
}
