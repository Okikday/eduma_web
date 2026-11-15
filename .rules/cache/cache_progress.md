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
- Implemented source-derived routes for sign-in, four-step web sign-up (name,
  account, optional profile photo, referral & terms),
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

## Completed: Main/Home, Space Detail, Calendar, Library, Notifications, Profile & Streak
- Completed `.rules/` lock-down (`rules.md` modularity/LOC cap, `routing.md`, `design_tokens.md`, `source_parity.md`).
- Completed codebase cleanup & bug fixes:
  - Added `publish_to: none` in `pubspec.yaml`, removed broken `main.css` link in `web/index.html`, removed unused `packages/eduma_icons/`, `web/images/`, and `main_navigation_preferences.dart`.
  - Updated `tool/subset_icon_fonts.py` to scan all `lib/**/*.dart` and re-generated `.woff2` icon font subsets (`FlutterIconsax.woff2` 42 glyphs / 6,612 B, `hugeicons-solid.woff2` 8 glyphs / 2,004 B, `hugeicons-stroke.woff2` 17 glyphs / 5,452 B).
  - Extracted shared CSS `@font-face` + design tokens into `web/styles/tokens.css`, replaced hand-drawn SVG `authIcon()` glyphs in `auth_frame.dart` with `IconsaxIcon`, and switched `auth.css` & `web/styles/main-home/*.css` to CSS custom properties.
  - Fixed `verify_email.dart` manual 6-digit OTP fallback after expired `?token=`, extracted `AuthLinkLogic` for `forgot_password.dart` pasted reset-URL parsing (+ 4 unit tests), fixed empty-name greeting `'Friend'` fallback, fixed `/calendarTab` & `/libraryTab` routes, un-gated the desktop Refresh button, preserved focus on `<details>` filter reset, and scoped the desktop pinned-card hiding rule to when `recentCanvases` is present.
  - Modularized `sign_up.dart` (`sign_up_bars.dart` & `sign_up_steps.dart`) and `main_home.dart` across focused widgets under `lib/features/main/presentation/widgets/`.
  - Added Hive `kickin_box` persistence (`eduma_pref_space_card_style`, `eduma_pref_space_sort`) via `MainPreferenceCodec` & `MainPreferences` and upgraded `SpaceGridCard` & `RecentCanvasCard` to match Flutter parity.
- **Completed Create Space, Join Space & Pin/Unpin Spaces slice**:
  - Generalized `EdumaAuthApi.requestAuthenticated(...)` with `postAuthenticated`, `patchAuthenticated`, and `deleteAuthenticated`, plus shared `extractResponseList` / `extractResponseMap` in `lib/core/data/json_envelope.dart`.
  - Added `MainSpacePreview`, `MainSpaceJoinResult`, `MainSpace.copyWith`, `MainPinLimitException`, `SpaceInviteLink`, `/join/:code` & `?join=` deep links, optimistic Pin/Unpin toggles with rollback, and accessible native `<dialog>` modals (`WebDialogHelper`).
- **Completed Space Detail (`/spaceDetail?id=...` & `/spaces/:id`)**:
  - Added `lib/features/space/` (`space_detail_models.dart`, `space_detail_api.dart`, `space_detail_actions.dart`, `space_detail_page.dart`, `space_detail_hero.dart`, `space_detail_pages_tab.dart`, `space_detail_members_tab.dart`, `space_detail_dialogs.dart`, and `web/styles/space-detail.css` + 3 unit tests).
  - Supports edit space title/description, invite link/code copy & renew, Pages tab with search/type/archived filters, create/archive/delete pages, Flutter canvas/notes handoff links, and Members tab with online indicators and admin/remove controls.
- **Completed Shared Shell Navigation & Remaining Web Routes**:
  - Parameterized `mainHomeDesktopRail` & `mainHomeMobileNavigation` with `MainNavTab` + shared `appTabShell` (`lib/features/main/presentation/widgets/app_tab_shell.dart`, `web/styles/app-shell.css`).
  - **Calendar (`/calendarTab`, `/calendar`)**: interactive 42-cell Sunday-first month grid with inline desktop session preview chips, day agenda using pastel accent-bar `ScheduleEventCard` styling, upcoming list, search filter, repeat frequency, Create Event native `<dialog>` (`POST /events`), Delete Event (`DELETE /events/{id}`), + 4 unit tests.
  - **Library (`/libraryTab`, `/library`)**: debounced catalog search (`GET /library/documents`), category filters, recently opened strip (`GET /library/recents`, `POST /library/recents/{id}`), FNV-1a category-tinted portrait `LibraryBookStage` book cards & direct PDF reader launch, Load More pagination, + 2 unit tests.
  - **Notifications (`/notifications`)**: `all|unread|invites|schedule` filter pills, unread badge count, Mark Read/Unread, Mark All Read, Delete, inline Accept/Decline for space invites, `24px` white cards with squircle icons, + 1 unit test.
  - **Profile & Settings (`/profile`)**: user card, pill `ProfileStatsRow` (`GET /users/me/stats`), Edit Profile dialog (`PATCH /users/me` + live `/users/check-username`), Password & Security reset dialog, Home Grid/List & Sort persistence, Sign Out, + 4 unit tests.
  - **Study Streak (`/streak`)** & **See All Routes (`/pinnedSpacesSeeAll`, `/recentSpacesSeeAll`, `/recentCanvasesSeeAll`)**: `StreakHeroCard` with circular SVG progress ring, `StreakWeekStrip` flame dots, and activity calendar (`GET /streaks/me` + `/users/me/analytics` fallback) + 1 unit test, and dedicated See All pages reusing Home cards.
- **Flutter 1:1 UI Parity & Separation-of-Concerns Pass**:
  - Updated `web/styles/tokens.css` with `PureThemeExtension` tokens (`--eduma-card-border`, `--eduma-divider`, `--eduma-card-shadow`, `--eduma-card-shadow-raised`, `--eduma-space-circle-2`, `--eduma-pinned-gradient`) and semantic aliases; added shared cover fallback (`lib/core/presentation/eduma_cover_fallback.dart`), pure date/time formatters (`lib/core/utils/date_formatters.dart`), and shared primitives in `web/styles/app-shell.css` so no feature references another feature's CSS prefix (`eduma-calendar__*`, `eduma-profile__*`).
  - Rebuilt Home `SpaceTile`, 3-sheet fanned `SpaceGridCard`, carousel `PinnedSpaceCard`, and desktop `>= 880px` `SpaceHighlightsSliver` (`PinnedBand`), plus `SpaceDetailHero` & `SpacePageCard` against the `../eduma` Flutter widgets.
  - Exact icon, badge, and context-menu pass: switched Home chevrons (`Iconsax.arrow_right_3_copy` at `14px` / `11px` on `"See all"`), linear Iconsax icons (`people_copy`, `close_circle_copy`, `danger_copy`, `lock_copy`, `add_circle_copy`, `notification_status_copy`), and HugeIcons (`notification01` solid/stroke, `fire` solid/stroke, `clock01`, `flag03`, `pinOff`, `settings02`) via `main_home_icons.dart`; removed non-source inline pin buttons & role badges from `SpaceTile` / `SpaceGridCard` in favor of frosted right-click `MainHomeSpaceContextMenuDialog`; added `+N` member overflow circles, `PersonalSpaceBadge`, `StreakChip`, full-bleed mobile `PinnedBand`, desktop section order (`search -> highlights -> spaces`), and gold `.verified` styling in `space-detail.css`.
  - Rebuilt subset icon fonts via `tool/subset_icon_fonts.py` (`FlutterIconsax.woff2` 41 glyphs / 6,332 B, `hugeicons-solid.woff2` 10 glyphs / 2,332 B, `hugeicons-stroke.woff2` 22 glyphs / 6,648 B).
- **SPA Client-Side Routing, In-Memory Session Cache & Cross-Page 1:1 Flutter Parity**:
  - Replaced full-page `<a href>` / `web.window.location.assign(...)` navigation on internal routes with `edumaLink(...)` & `edumaNavigate(...)` (`lib/core/presentation/eduma_link.dart`) backed by `jaspr_router`'s `Router.maybeOf(context)` so navigating across tabs and pages is instant without full browser reloads.
  - Added in-memory `_currentSession` caching and `_restoringSession` in-flight request coalescing + transparent 401 refresh retry in `EdumaAuthApi` (`lib/features/auth/data/auth_api.dart`), seeded `_session` from `AuthActions.currentSession` / `MainActions.currentSession` / `SpaceDetailActions.currentSession` across all pages, and replaced `"Restoring your Eduma session…"` blocking copy in `mainHomeLoadingSessionState()` with a quiet spinner.
  - Updated Streak (`StreakHeroCard`, unified `StreakStatsRow` card with 3 divided stats, and 7-day `StreakWeekStrip` with `moon_copy` / `medal_star_copy`), Notifications (all 11 Flutter `NotificationType` icons/accents/badges, `16px` `#card` squircles, unread dot, `"Accept & Join Space"` button), Profile (`VerifiedBadge`, `edit_2_copy`, pill `ProfileStatsRow` without inner icons in `'Notebooks' / 'Time studied' / 'Spaces'` order), Calendar (`calendar_add_copy` CTA, `cancel01` clear, `14px` month arrows), Library (`LibraryRecentsStrip` card strip, `edgeLayersOf` stacked book paper edges, `.lock` icon badge, `cancel01` clear), and Space Detail (`AppSegmentedControl` pill tabs, owner/admin/member role chip tones).
  - Rebuilt subset icon fonts (`FlutterIconsax.woff2` 52 glyphs / 8,708 B, `hugeicons-solid.woff2` 10 glyphs / 2,332 B, `hugeicons-stroke.woff2` 22 glyphs / 6,648 B).
- **Current Session Fixes (Blur/Barrier Parity, Dialog Top-Layer, Clean Loading & In-Memory Cache)**:
  - **Exact `../eduma` Glass & Barrier Parity**: Added `--eduma-barrier-bg: rgb(0 0 0 / 16%)`, `--eduma-barrier-blur: blur(3px)` (`AppBarrier.sigma = 3.0`), `--eduma-glass-dialog-bg: rgb(239 238 244 / 80%)`, `--eduma-glass-dialog-blur: blur(12px)` (`AppGlassSurface.sigma = 12.0`), `--eduma-glass-dialog-border`, `--eduma-glass-dialog-shadow`, and `--eduma-glass-sheet-blur: blur(4px)` in `web/styles/tokens.css`; updated `modals.css`, `spaces.css` (`blur(20px)` on `.main-home__context-menu-card`), `space-detail.css`, `app-shell.css` (`blur(14px)` on `.eduma-desktop-header` & `.eduma-pure-appbar`), and `calendar.css`.
  - **Desktop `<dialog>` Close Fix**: Updated `WebDialogHelper.syncOpen` (`lib/features/main/presentation/widgets/web_dialog_helper.dart`) to call `showModal(); close();` when `dialog.open == false` while `dialog.matches(':modal') == true`, preventing the page behind from staying inert.
  - **Clean Loading State**: Added `.eduma-page-loading` in `web/styles/app-shell.css` and updated `SpaceDetailPage` and `StreakPage` to render only a centered spinner while loading uncached screens instead of a displaced `adaptivePageScaffold` app bar.
  - **Session-Scoped Tab & Detail Caching**: Added `EdumaMemoryCache` (`lib/core/data/eduma_memory_cache.dart`, cleared in `EdumaAuthApi.signOut()`) and wired immediate hydration + background refresh into `MainHomePage`, `SpaceDetailPage`, `CalendarPage`, `CalendarAgendaPanel`, `LibraryPage`, `NotificationsPage`, `StreakPage`, and `ProfilePage`.
  - **Calendar Tag Fix, Edit Event & Space Picker**: Removed the `'Space session'` fallback pill from `calendar_day_agenda.dart`; added `CalendarApi.updateEvent` (`PATCH /events/{id}`), `editingEvent` mode on `CalendarCreateDialog`, an **Edit** button on `calendarEventDetailModal`, and an optional **Space** selector (`spaceId`) populated from `EdumaMemoryCache.instance.home?.spaces` / `MainActions.loadSpaces(page: 1)`.
  - **Profile Real Sub-Flows & Dark Mode**: Added `EdumaThemeController` (`lib/core/presentation/theme_controller.dart`) + `[data-theme="dark"]` & `system` tokens in `web/styles/tokens.css` matching `PureDarkThemeExtension` (`#131313` bg, `#1f1f22` surface, `#28282d` card); added `ProfileAboutYouDialog` (`PATCH /users/me`), `ProfileDeleteAccountDialog` (`DELETE /users/me`), and `ProfileApi.signOutAllDevices()` (`POST /auth/logout-all`) replacing those `onShowNotice(...)` stubs.
  - **Library In-App Document Reader**: Added `libraryDocumentReaderModal` (`lib/features/library/presentation/widgets/library_reader_dialog.dart` + `.eduma-library-reader` in `web/styles/library.css`) so clicking a document opens an in-app PDF/document viewer modal with an "Open tab" link instead of forcing an immediate external tab jump.
- **Icon Font Loading, Cross-Feature Parity & Visual Verification Pass**:
  - **Icons & Logos**: Added `.woff2` `<link rel="preload" ... crossorigin>` for `FlutterIconsax.woff2`, `hugeicons-stroke.woff2`, and `hugeicons-solid.woff2` in `web/index.html`, switched icon `@font-face` rules in `web/styles/tokens.css` from `font-display: block` to `font-display: swap` (fixing FOIT where icons such as the Home streak flame stayed invisible on initial load), fixed the rail logo asset path in `lib/features/main/presentation/widgets/main_home_navigation.dart` (`assets/logo/logo.png`), and removed the duplicate inner active box rule `.main-home__rail-item.is-active .eduma-icon` in `web/styles/main-home/responsive.css`.
  - **Shared UI Primitives & Overflow**: Defined `.eduma-circle-icon-btn`, `.main-home__see-all-btn`, flex `min-width: 0` on `.eduma-search-box` / `.main-home__center-wrap` / `.main-home__body` / `.eduma-library__section` (`web/styles/app-shell.css`, `web/styles/main-home/base.css`, `web/styles/library.css`), fixing unstyled icon/link buttons on Calendar/Library and eliminating mobile Library horizontal overflow (`scrollWidth == 390`).
  - **Space Detail, Library, Notifications & Streak**: Fixed Space Detail hero backdrop in `space_detail_hero.dart` / `web/styles/space-detail.css` to render a deep indigo gradient with a soft top-right translucent watermark instead of an oversized solid logo block; switched Library fallback book covers (`library_document_card.dart`) to centered crisp 3D `assets/logo/logo.png` artwork, `EdumaIcons.folderAdd`, `EdumaIcons.sort`, and `EdumaIcons.chevronRight`; aligned `NotificationFilterTab` to `[All, Unread, Invites, Schedule]`; and widened Streak's desktop `--wide` column to `1120px`.
  - **Chrome Verification**: Verified rendered screenshots across `/main`, `/calendarTab`, `/libraryTab`, `/notifications`, `/streak`, `/spaceDetail`, `/profile`, `/pinnedSpacesSeeAll`, and `/recentCanvasesSeeAll` (`1440x900` and/or `390x844`) with all 4 webfonts loaded and zero `console.log` errors.
- **Remaining Parity & Stubbed-Feature Queue (still open)**:
  1. **Calendar (`lib/features/calendar/`)**: Add resource picker (`resourceId`, `resourceType`) and `SpaceMemberStack` avatars on space-linked `ScheduleEventCard`s.
  2. **Profile & Settings (`lib/features/profile/`)**: Replace the remaining `onShowNotice(...)` stubs in `profile_settings_groups.dart` (`Plan & Billing`, theme/font/default-page-style dialogs beyond light/dark toggle, `WhatsApp`, `AI chat history`, `What Eduma remembers`, `Voice & Transcription`, `Beta features`, `About Eduma`, `Help & Support`, `Terms & Privacy`, avatar upload).
  3. **Space Pages, Practice, Comments & AI (`lib/features/space/`, `lib/features/ai/`)**: Replace external `mainHomeFlutterPath` handoffs (`/spacePageStatic`, `/spacePageCanvas`, `/assistantHistory`) with native Jaspr routes/views.
- **Current Validation**:
  - `dart analyze`: exited 0 (`No issues found!`).
  - `dart test`: exited 0 (all 42 unit tests passed).
  - `jaspr build`: exited 0.

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
- Interactive canvas editing (`/spacePageCanvas`, `/spacePageStatic`) and AI chat history (`/assistantHistory`) stay as Flutter workspace handoff links per architectural boundaries; all core signed-in web tabs and auth flows are now implemented in Jaspr.
- Before shipping, stop the local `jaspr serve` process to run a full production `jaspr build` and inspect live authenticated flows across viewports in Chrome. Keep README deployment/handoff requirements current.
