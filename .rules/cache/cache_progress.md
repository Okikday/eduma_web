# Cache Progress: Eduma Web Rewrite (React + Tailwind CSS)

## Project boundaries
- Active React + TypeScript + Tailwind CSS v4 (Vite) web app: `eduma_web` (`src/`, `public/`, `test/`).
- Archived Jaspr prototype: `eduma_web/jaspr/` (moved intact from the repository root; untouched for the React port).
- Source of truth: Flutter codebase at sibling directory `../eduma`. Every UI screen, spacing/typography scale, token, validation rule, API contract, and business helper is ported directly from `../eduma`, not copied from `jaspr/`.
- Preserve interactive Flutter canvas editing (`/spacePageCanvas` handoff link via `VITE_FLUTTER_APP_URL`) alongside native React static page viewing and metadata editing.
- Keep UI components modular per feature slice (`models/`, `logic/`, `data/`, `ui/`).
- Avoid triggering real account creation, password reset emails, or destructive mutations against production APIs during local checks.

## Completed: React 19 + TypeScript + Tailwind v4 Port (`../eduma` -> `eduma_web`)

### 1. Workspace Restructure & Build Tooling
- Moved previous Jaspr workspace files into `jaspr/`.
- Initialized React 19 + TypeScript + Tailwind CSS v4 (`@tailwindcss/vite`) + React Router DOM v7 + Vite 6 + Vitest 3 (`package.json`, `tsconfig.json`, `vite.config.ts`, `vitest.config.ts`, `index.html`, `src/styles/index.css`).
- Copied local fonts (`Raleway-Variable.ttf`, `Raleway-Italic-Variable.ttf`), subset icon `.woff2` fonts (`FlutterIconsax.woff2`, `hugeicons-solid.woff2`, `hugeicons-stroke.woff2`), full fallback `hugeicons-stroke.ttf` (with CSS `@font-face` `unicode-range` split so out-of-subset glyphs like `notification01`, `folderLibrary`, `view`, `pdf01`, `sortByDown01` render cleanly), brand assets (`logo.png`, `book_sparkle_bg.webp`, `dust_pattern.webp`, `favicon.ico`, `google-sign-in.js`), and legal markdown (`privacy_policy.md`, `terms_of_service.md`, `refund_policy.md`) into `public/`.

### 2. Core Infrastructure (`src/core/`)
- `src/core/config/appConfig.ts`: Environment config (`VITE_API_BASE_URL`, `VITE_FLUTTER_APP_URL`, `VITE_GOOGLE_WEB_CLIENT_ID`), `normalizeOrigin` / `resolveAssetUrl`, and Flutter canvas handoff URL builder.
- `src/core/storage/storageService.ts` & `src/core/cache/memoryCache.ts`: Typed `localStorage` session & preferences persistence (`AppStorage`, `HomePreferences`, `MainPrefsStorage`, `SessionReset.resetAll()`) plus in-memory tab/space caching (`MemoryCache`).
- `src/core/api/apiClient.ts`: Browser HTTP client with Bearer injection, request de-duplication/refresh-token 401 retry coalescing (`_refreshPromise`), `ApiError`, and JSON envelope extraction (`extractEnvelopeData`, `extractEnvelopeList`, `extractEnvelopeMap`).
- `src/core/theme/themeContext.tsx`: Light / dark / system appearance mode (`color-scheme` meta sync + cross-tab `storage` listener), reduce-blur toggle, and configurable Eduma font family selector (`Raleway`, `ABeeZee`, `Agbalumo`, `Bellota`, `Cal Sans`, `Plus Jakarta Sans`), paired with pre-paint blocking script in `index.html`.
- `src/core/icons/iconGlyphs.ts` & `EdumaIcon.tsx`: Exact glyph codepoints verified 100% against `FlutterIconsax.ttf` (275 glyphs), `hugeicons-stroke.ttf` (138 glyphs), and `hugeicons-solid.ttf` (20 glyphs).
- `src/core/utils/accentHash.ts` & `dateFormatters.ts`: FNV-1a deterministic accent color & 3-sheet space grid / library stacked-book edge calculations, greetings, Sunday-first 42-cell month grid builder, and timeline overlap column layout.

### 3. Shared UI Primitives (`src/shared/components/`)
- Accessible native `<dialog>` modal system (`AppModalDialog`) with `showModal()`, `closedby="any"` light-dismiss + pointer-drag-safe bounding-box fallback for Safari, scroll-contained backdrop, and clean `returnValue` reset.
- Single `<input inputMode="numeric" autoComplete="one-time-code" pattern="\d{6}">` OTP control (`AppOtpField`) with six-box visual overlay and format instructions placed above the input.
- `AppTextFormField`, `AppButton`, `AppCircleIconButton`, `AppSegmentedControl`, `AppToast`, `AdaptiveImage`, `EdumaCoverFallback`, `DesktopPageHeader`, `DesktopSplitScaffold`, `PureAppBar`, `AppEmptyState`, `BadgesAndAvatars`, `SeeAllScaffold`, `FloatingContextMenu`, and `formFactor.ts`.

### 4. Feature Modules (`src/features/`)
- **Auth (`src/features/auth/`)**: Sign In (with email/password autofill hints + Google Identity Services consent flow), 4-step Sign Up (`Name`, `Account` with live username availability check & 4-segment password strength meter + suggestions, `Profile Photo`, `Referral & Terms`), Forgot & Reset Password (with pasted URL token extraction via `AuthLinkLogic`), Verify Email (6-digit OTP + resend timer + token link parsing), `EmailVerificationBanner`, and `AuthDesktopFrame`.
- **Main Shell & Spaces (`src/features/main/`, `src/features/spaces/`)**: Responsive `MainShell` (84px desktop navigation rail + optional 340px `CalendarAgendaPanel`; mobile floating pill `MainBottomNavBar` + gradient `SpecialActionButton`), `HomeTabView` with highlights carousel & 3-sheet fanned `SpaceGridCard` / `SpaceListTile` + sorting/filtering/search, `SeeAllSpacesViews` (`/pinnedSpacesSeeAll`, `/recentSpacesSeeAll`, `/recentCanvasesSeeAll`), `SpaceDetailView` (Pages, Assets, Events, Members tabs, invite link copy/renew, archived page toggle), and `SpacePageViewer` (static reader + Flutter Canvas handoff).
- **Calendar (`src/features/calendar/`)**: Month grid with session indicators, timeline layout for overlapping events, Day Agenda panel, Upcoming list, search filter, and `CreateEventDialog` (create/edit/delete events with space selector & repeat options).
- **Library (`src/features/library/`)**: Debounced catalog search, category chips, recently opened strip, portrait `LibraryBookCard` with FNV-1a tinted stacked-paper edges, Load More pagination, and in-app PDF/document viewer modal.
- **Notifications, Streaks, Assistant & Profile**:
  - `NotificationsView`: All / Unread / Invites / Schedule filters, mark read/unread, mark all read, delete, and inline space invite Accept/Decline.
  - `StreakView`: Circular progress ring hero, unified 3-stat row, and 7-day flame strip (`GET /streaks/me` + fallback analytics).
  - `AssistantHistoryView`: AI Study Assistant session history reader.
  - `ProfileView` & `AccountSubViews`: User card, stats row, appearance theme & font pickers, reduce-blur toggle, edit profile/bio, password reset, AI Memory preferences, Plan & Billing, WhatsApp link, Feedback, About & Legal document viewer (`/legalDocument`), and Sign Out / Log Out All Devices / Delete Account flows.

## Validation state
- **Static Typecheck (`npm run typecheck`)**: Passed (`tsc --noEmit`, exit code 0).
- **Unit Tests (`npm test`)**: Passed (`vitest run`, `test/edumaLogic.test.ts` — 13/13 tests passed across `AppConfig`, `AuthLinkLogic`, `ReferralLogic`, `Validator`, `SignUpLogic`, FNV-1a accent/book edge helpers, date/month/timeline layout, space sort/filter/page search, and `SessionReset`).
- **Production Build (`npm run build`)**: Passed (`tsc -b && vite build`, exit code 0 — built `dist/` bundle cleanly).
- **Static Asset & Font Glyph Audit**: Verified all local URLs in `src/` and `index.html` exist in `public/`. Detected that Jaspr's subset `hugeicons-stroke.woff2` omitted 20 glyphs used by React (`notification01`, `folderLibrary`, `view`, `pdf01`, etc.); resolved by adding `public/assets/fonts/icons/hugeicons-stroke.ttf` as a CSS `@font-face` `unicode-range` fallback alongside the subset `.woff2` and verifying all JSX icon names map to real TTF codepoints (`Static JSX icon mismatches: []`).
- **Browser QA (Chrome DevTools MCP)**: **Blocked in this environment** — `mcp_chrome_devtools_list_pages` failed to connect (`Could not find DevToolsActivePort for chrome at /Users/user/Library/Application Support/Google/Chrome/DevToolsActivePort` / `Unexpected server response: 403`). Live viewport rendering, dark mode visual check, and `<dialog>` interactive light-dismiss in Chrome still need visual inspection once `chrome://inspect/#remote-debugging` is connected.

## Legacy Reference (Jaspr)
- Legacy Jaspr notes & validation history live in `jaspr/` (archived alongside the Dart codebase). See git history prior to the React rewrite for the full Jaspr changelog.
