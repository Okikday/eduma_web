# Cache Progress: Eduma Web Extraction

## Project boundaries
- Jaspr workspace: `eduma_web`; Flutter source: sibling project `../eduma`.
- Keep this as an incremental extraction, not a redesign. Use the source UI,
  wording, spacing, colors, and behavior as the reference for each migrated
  feature.
- Preserve Flutter surfaces that are better left in Flutter (notably canvas)
  and hand off to or embed the real workspace rather than creating a substitute.
- Follow `.rules/rules.md` in this workspace for Jaspr architecture and browser
  boundaries; use `../eduma/.rules/rules.md` for source/product conventions
  where applicable.

## Completed: account access
- Implemented source-derived routes for sign-in, three-step web sign-up,
  email verification, password recovery/reset, and `/account` workspace
  handoff.
- Ported source validation for usernames/password strength and referral-code
  lookup; added API-backed username checks, referral handling, and registration.
- Added API/session adapters using the browser-compatible `http` client,
  consent-gated Google sign-in, verification-code resend/lock states, and
  token scrubbing from the address bar.
- Recreated shared Eduma auth controls, Raleway typography, colors, and
  responsive styles. Keep comparing each route against the Flutter source;
  do not replace it with generic auth-card patterns.
- Added semantic labels, autocomplete/input hints, dynamic status/error
  announcements, accessible sign-up progress, and focus on validation/step
  changes.
- The OTP keeps Eduma's six-box visual, backed by one real input with
  `one-time-code` autocomplete for paste and browser OTP support.
- Added the source `AuthDesktopFrame` behavior: centered 480px form column,
  source-matched 520–680px/40%-width pane, and branded panel from 1024px upward.
  The desktop panel uses Eduma's actual logo and book-sparkle asset, with the
  source gradient, heading, and three feature rows.
- Sign-up is capped at the source desktop flow height (720px plus its 16px
  vertical insets) and centered from tablet widths upward; phone layout remains
  full-width and scrollable.

## In progress: Main/Home initial slice
- Added `/main` with session restoration, the source greeting/profile treatment,
  email verification notice, pinned spaces, debounced space search, paging,
  loading/error/empty states, and navigation handoff for Flutter-only routes.
- Added a browser `/spaces` adapter with explicit response parsing and a
  standalone space mapper covered by unit tests.
- Added the recent-canvas endpoint and source route/query mapping for both
  dynamic canvases and static notes. Recent-history failures are reported
  independently so they do not block spaces from loading.
- Added space role, member preview, personal/verified state, and activity/date
  parsing. The Show filters and sort orders now use the source's membership,
  personal-space-first, and stable-order rules.
- Replaced the initial native selects with a source-like Show/Sort/View
  disclosure and list/grid switch. Persisting the view preference and ordering
  by recently opened on this device remain to be ported.
- Cloned Iconsax Flutter 1.0.1 and adapted the published HugeIcons Pro 0.0.3
  source into local Jaspr packages. Glyphs render through the packages'
  original named constants and fonts, not hand-drawn SVG replacements.
- Kept complete package font files in `packages/`; `tool/subset_icon_fonts.py`
  generates app WOFF2 assets only for Main's referenced glyphs (12 Iconsax,
  3 HugeIcons Solid, 5 HugeIcons Stroke). Package licenses are retained.
- Main is not a complete migration yet. Pinned pages and their visibility
  preference, online presence, AI-create jobs, create/join actions, page
  content-search hits, and the Calendar/Library surfaces still need
  source-backed implementation or handoff.
- Successful sign-in now enters `/main`; `/` and `/account` also render Main
  rather than the removed account-handoff placeholder. When the separate
  Flutter workspace URL is not configured, Flutter-only destinations render
  as non-interactive content instead of routing back into `/account`/Main.
- Added the source bottom tab bar and floating Home actions menu. The Create
  and Join entries currently hand off to `/main` rather than opening the
  source's create/join sheets; this is a known behavior gap. Calendar and
  Library are still Flutter handoffs and do not yet render inside a shared
  Jaspr shell.
- The source combines Profile and Settings in one `/profile` screen with tabs.
  When that feature is ported, expose Settings in the shared navigation and move
  the mobile navigation-layout preference into its Settings tab. Until then,
  the existing layout switch in the mobile drawer is interim, not the final
  Settings integration.

## Browser and network boundaries
- `kickin_network` 0.0.36 is not a direct Jaspr dependency: it remains a
  Flutter package. Use `package:http/browser_client.dart` or another
  browser-supported client here.
- Google sign-in requires the public `EDUMA_GOOGLE_WEB_CLIENT_ID` build define.
  Do not put private OAuth/server credentials in the browser build.
- Production handoff requires Jaspr at `/` and the Flutter workspace at a
  separate path on the same origin; configure `EDUMA_FLUTTER_APP_URL`, API CORS,
  credentialed requests, and static-host route rewrites as described in
  `README.md`.
- The existing production auth endpoints and Google OAuth have not been
  end-to-end tested with a real account. Avoid creating test accounts or
  triggering email delivery during local validation.

## Tooling
- Installed Dart static-analysis/unit-test skills under `.agents/skills/`.
- Installed `modern-web-guidance` under `.agents/skills/`; used its form,
  autofill, multi-step, and accessibility guidance for the auth slice.

## Validation state

- `dart analyze lib`: passed after the current Dart changes.
- `jaspr build`: passed after the desktop frame changes.
- Local browser checks: sign-in, sign-up step 1 and step transitions, invalid
  submission focus, forgot-password rendering, and verification-code rendering.
  No account creation or email resend was triggered.
- Raleway is now applied to `body` as well as `:root`, overriding the generated
  starter `main.css` Roboto rule. Browser font check confirmed Raleway loaded.
- Browser geometry checks at phone, tablet, 1024px-class, laptop, and wide
  desktop viewports confirmed no horizontal document overflow, the source
  breakpoint for the brand panel, a 480px content cap, and centered 752px
  desktop sign-up flow. Sign-in, sign-up, recovery, and verification routes
  were checked. Account creation, password reset, and email delivery were not
  triggered.
- Added the project-level completion rule requiring source/platform/layout
  variants to be traced, rendered behavior to be checked, and progress notes
  to distinguish verified scope from pending work.
- Earlier Main/icon checks: `dart analyze lib packages/iconsax_flutter/lib
  packages/hugeicons_pro/lib test` passed; the initial
  `main_api_test.dart` passed (4 tests); `jaspr build` passed before the most
  recent Main changes.
- An earlier `/main` browser check used an unauthenticated state and therefore
  did not verify the authenticated dashboard; the latest signed-in check is
  recorded below. The three subset-font URLs returned HTTP 200 (2.4 KB,
  1.1 KB, and 2.1 KB) at that earlier validation.
- Current follow-up validation: `dart analyze
  lib/features/main/presentation/pages/main_home.dart` passed, and the four
  `main_api_test.dart` tests passed. A production `jaspr build` could not run:
  an existing `jaspr serve` process in this workspace owns the build daemon
  with incompatible options. It was left running and was not interrupted.
## Latest Main verification
- `dart format` completed for the current model, query, UI, and test files.
- The focused `main_api_test.dart` passes (11 tests), including membership
  filters, name/date/access sorting, personal-space precedence, and stable
  ties. `dart analyze lib/features/auth/data/auth_api.dart lib/features/main
  test/features/main/data/main_api_test.dart` exits successfully with four
  `sort_children_last` infos at Jaspr's positional-children select/option
  calls; no errors or warnings.
- `git diff --check` passes.
- The active local `/main` page was checked with an existing signed-in browser
  session at phone/tablet/desktop viewport settings. The document had no
  horizontal overflow; native select controls remained 44px high; selecting
  Pinned filtered the visible list, and Reset filters restored defaults.
  No account or email action was triggered. Two browser console 404s were
  present without a resource URL in the available log, so their source is
  unresolved.
- The latest `jaspr build --no-managed-build-options` attempt was blocked
  because the active `jaspr serve` build daemon has incompatible options.
  That process was not stopped; the live server already rendered the current
  UI for browser checks.
- Split Home styles from the former `web/main-home.css` into focused
  `web/styles/main-home/` files (base, notices, search, highlights, spaces,
  navigation, responsive), and linked them in cascade order from `web/index.html`.
- Latest follow-up: targeted `dart analyze` exited successfully with five
  `sort_children_last` infos and no errors or warnings; the focused
  `main_api_test.dart` passes all 11 tests; `git diff --check` passes.
  The local server returned HTTP 200 for all seven Home stylesheets and the
  icon font. The current browser opens the unauthenticated sign-in prompt, so
  it does not verify the authenticated Home layout. The existing build-daemon
  conflict remains unresolved.

## Remaining work
- The full Flutter-to-Jaspr migration is not complete. Account access is
  implemented; Main/Home remains a partial slice. Continue with the remaining
  source Home widgets and interactions before migrating other routes.
- Before each slice, inspect its source pages, shared widgets, logic, and API
  contracts; preserve one-to-one UI/behavior, then verify routes and viewport
  behavior in the browser.
- Continue with the next source-backed feature. Keep README
  deployment/handoff requirements current.
