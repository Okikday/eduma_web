# Jaspr Project Rules

These rules govern `eduma_web`, the Jaspr/browser project. The Flutter source
project's `.rules/rules.md` is useful for product and domain conventions, but
its Flutter-specific implementation rules do not apply here. This document
records the Jaspr equivalents and takes precedence for this workspace.

## 1. Architecture

Organize code by vertical feature, not by generic file type:

```text
lib/
├── app.dart
└── features/
    └── <feature>/
        ├── data/                 # HTTP, persistence, API and session adapters
        ├── logic/                # validation and multi-step feature actions
        └── presentation/
            ├── pages/
            └── widgets/
web/
├── index.html
└── styles/
    └── <feature>/
        ├── base.css
        └── ...
```

- Keep each migrated feature self-contained. Put a component in a shared
  location only after at least two features use it and it has no feature
  knowledge.
- Keep presentation files modular and focused: target a soft cap of ~250–300
  lines per Dart component file. Extract distinct sections, cards, bars, forms,
  or dialogs into dedicated files under `presentation/widgets/`.
- `app.dart` owns application bootstrap and route registration; feature pages
  own their presentation. Do not put feature implementations in `app.dart`.
- Keep API, browser storage, and session details out of presentation
  components. Pages delegate operations to feature logic, which uses the
  feature's data adapters.
- Do not preserve starter/demo pages or generic `pages/` and `components/`
  dumping grounds once they are no longer part of the product.

## 2. Flutter-to-Jaspr Equivalents

| Flutter source convention | Jaspr/browser equivalent |
|---|---|
| `features/<feature>/ui`, `pods`, `logic`, `models` | Keep vertical feature slices; use `presentation`, `logic`, `data`, and add `models` only when domain types warrant them. |
| Riverpod pod owns async state and side effects | Use a feature logic/action class for workflows and a Jaspr `StatefulComponent` for local view state. Add a state package only when shared state actually requires it. |
| `go_router`, typed `Routes`, route overriders | `jaspr_router` `Router`/`Route`; keep route names in `app.dart`, pass small URL-safe inputs through route/query parameters. |
| Flutter widgets and shared Material components | Jaspr components and semantic HTML elements, with accessible labels, status/error semantics, keyboard support, and CSS. |
| `Theme.of(context)` and spacing/radius tokens | CSS custom properties, reusable classes, and responsive media queries in web stylesheets. Keep visual tokens centralized when multiple features need them. |
| `UserMessage`, `AppToast`, Flutter dialogs | Typed feature errors mapped to clear inline notices and status messages; use browser-native navigation and accessible confirmation UI. |
| `kickin_storage` / Flutter Hive integration | Browser-compatible Hive CE only where its persisted schema must interoperate with Flutter; keep key names and value shapes compatible and never clear unrelated app data. |
| Flutter platform channels / plugins | Browser APIs behind small adapters where appropriate; keep unsupported native-only behavior in the Flutter app or embed that real app surface. |
| Flutter widget tests and `@AppPreview` | Test pure Dart logic and Jaspr/browser interactions with the project's available test tooling; use browser rendering for visual and responsive checks. |

Do not introduce Riverpod, Flutter widgets, Material APIs, or Flutter-only
plugins into this project merely to mirror the source structure.

### Package-first browser ports

- Before recreating behavior or visual assets supplied by a Flutter package,
  inspect the source package and check for a browser-compatible equivalent.
- When a useful package is Flutter-bound, prefer a local Jaspr/browser port in
  `packages/` when feasible. Preserve the source API names, glyph mappings, and
  required licenses while adapting only the platform-specific boundary.
- Do not draw replacement icons or approximate package assets by hand when the
  source package already provides them. Use `IconsaxIcon` (`packages/iconsax_flutter`)
  or `HugeIcon` (`packages/hugeicons_pro`), never hand-drawn `<svg>` `<path>` icons.
- Icon fonts in `web/assets/fonts/` are subsetted with `python3 tool/subset_icon_fonts.py`,
  which scans all `lib/**/*.dart` files for `Iconsax.*`, `HugeIconsStroke.*`, and
  `HugeIconsSolid.*` references. Re-run `python3 tool/subset_icon_fonts.py`
  whenever icons are added or changed in any Dart file under `lib/`.

## 3. Browser and Network Boundaries

- Browser code must use browser-compatible packages. `kickin_network` is not a
  direct Jaspr client: the installed package depends on Flutter and uses
  `dart:io`/Flutter APIs. Use `package:http/browser_client.dart` or another
  browser-supported client for browser requests.
- Keep endpoint paths, payload mapping, response decoding, credentials, and
  session persistence in the feature's data layer. The UI must not construct
  HTTP requests.
- Browser requests must handle CORS, credential policy, timeouts, malformed
  responses, and non-2xx responses explicitly. Never silently turn a failed
  request into a successful-looking result.
- Never put server secrets in a browser build. Public API base URLs may be
  configured with compile-time defines.
- Keep auth/reset tokens out of logs and remove sensitive one-time tokens from
  the address bar after reading them.
- Treat same-origin storage sharing as a deployment requirement, not an
  assumption: the Jaspr and Flutter apps must run on the same origin and use
  compatible Hive CE storage. Do not replace or recursively load the Flutter
  app's route when handing off.

## 4. UI, Routing, and Styling

- Use semantic DOM elements and preserve accessible names, form labels,
  visible focus, keyboard operation, and `role="alert"`/`role="status"` for
  feedback.
- Keep state local to a page unless another route or feature genuinely needs
  it. After asynchronous work, check that the component is still mounted
  before calling `setState`.
- Keep loading, success, empty, and error states explicit. Do not use
  placeholder pages for features that have not been migrated; link to or embed
  the real Flutter surface instead.
- Keep route query parameters small and non-sensitive. Support direct reloads
  and deep links for every public route. Never invent Flutter handoff paths;
  use the exact verified routes in `.rules/routing.md`.
- Keep visual design tokens (palette, surfaces, Raleway typography scale,
  radii, shadows) and `@font-face` declarations centralized in `web/styles/tokens.css`
  per `.rules/design_tokens.md`, linked before feature stylesheets in
  `web/index.html`. Do not duplicate `@font-face` blocks or scatter unverified
  brand colors across feature stylesheets.
- Keep CSS responsive and scoped by feature classes. A small feature may use
  one stylesheet; split larger feature styles into focused files under
  `web/styles/<feature>/` and load them in cascade order from `index.html`.
  Prefer the existing design system over adding a framework; avoid fixed-width
  layouts that break at mobile sizes.
- See companion specs for exact project contracts:
  - `.rules/routing.md` (Jaspr routes + Flutter handoff routes)
  - `.rules/design_tokens.md` (palette, theme tokens, typography, radii)
  - `.rules/source_parity.md` (API endpoints, Hive schema, feature checklist)
- Static assets belong under `web/`. The current deployment expects Jaspr at
  `/`; use an explicit base URL so direct route reloads resolve CSS and JS
  assets correctly.
- The static host must rewrite public Jaspr routes to `index.html` for direct
  visits/reloads. Exclude the Flutter workspace path from that rewrite.

## 5. End-to-End Task Completion

- Treat a request as an expected outcome, not a request for the smallest
  plausible code edit. Inspect the source implementation and all relevant
  routes, shared wrappers, states, and platform-specific variants before
  deciding what the complete change requires.
- For Flutter-to-Jaspr work, translate the full user-visible behavior and
  responsive layouts, including source desktop/tablet frames and assets where
  they apply. A phone-sized page alone is not a completed migration when the
  source also has desktop behavior.
- Verify the actual outcome at relevant viewport sizes and interaction states,
  not just that code compiles. Run the project checks, inspect rendered routes,
  and fix issues that those checks reveal before reporting completion.
- For work spanning multiple sessions, keep `.rules/cache/cache_progress.md`
  current with completed scope, concrete validation results, known gaps, and
  the next source-backed slice. Do not describe pending or unverified work as
  complete.

## 6. Naming and Documentation

- Dart files use `snake_case`; types use `PascalCase`; private members use `_`.
- Use `Page` for Jaspr page components, `Actions` for feature workflows,
  `Api`/`Store` for data adapters, and `Model` only for intentional domain or
  presentation types.
- Use enums for finite internal value sets instead of stringly typed values;
  prefer Dart dot shorthands when the type is clear from context.
- Keep comments for non-obvious platform or product constraints; do not
  narrate straightforward code.
- Record endpoint assumptions and deployment requirements in the README or a
  focused hand-off note when they affect integration with the Flutter app.

## 7. Validation

- After changing Dart code, run `dart analyze` and `jaspr build`; run focused
  tests when tests cover the changed behavior.
- After changing `pubspec.yaml`, resolve dependencies before analysis/build.
- Do not run Flutter builds or Flutter code generation for this Jaspr project.
- Report browser-only or same-origin behavior that could not be verified in
  the current local/deployment environment.
