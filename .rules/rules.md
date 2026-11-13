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
└── <feature>.css
```

- Keep each migrated feature self-contained. Put a component in a shared
  location only after at least two features use it and it has no feature
  knowledge.
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
  and deep links for every public route.
- Keep CSS responsive and scoped by feature classes. Prefer the existing
  design system over adding a framework; avoid fixed-width layouts that break
  at mobile sizes.
- Static assets belong under `web/`. The current deployment expects Jaspr at
  `/`; use an explicit base URL so direct route reloads resolve CSS and JS
  assets correctly.
- The static host must rewrite public Jaspr routes to `index.html` for direct
  visits/reloads. Exclude the Flutter workspace path from that rewrite.

## 5. Naming and Documentation

- Dart files use `snake_case`; types use `PascalCase`; private members use `_`.
- Use `Page` for Jaspr page components, `Actions` for feature workflows,
  `Api`/`Store` for data adapters, and `Model` only for intentional domain or
  presentation types.
- Keep comments for non-obvious platform or product constraints; do not
  narrate straightforward code.
- Record endpoint assumptions and deployment requirements in the README or a
  focused hand-off note when they affect integration with the Flutter app.

## 6. Validation

- After changing Dart code, run `dart analyze` and `jaspr build`; run focused
  tests when tests cover the changed behavior.
- After changing `pubspec.yaml`, resolve dependencies before analysis/build.
- Do not run Flutter builds or Flutter code generation for this Jaspr project.
- Report browser-only or same-origin behavior that could not be verified in
  the current local/deployment environment.
