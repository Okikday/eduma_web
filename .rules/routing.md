# Routing & Flutter Handoff Spec

All Jaspr routes live in `lib/app.dart`. Flutter handoff paths come verbatim
from `../eduma/lib/app/routes/routes.dart` (`/${Routes.X.name}`), wired via
`EdumaAuthApi.flutterAppRoute(...)` / `_flutterPath(...)`.

## 1. Jaspr Routes (`eduma_web`)

| Path | Page Component | Purpose |
|---|---|---|
| `/` | `MainHomePage` (gated to `SignInPage` when unauthenticated) | Entry shell / signed-in Home |
| `/home` | `SignInPage` (redirects to `/main` when signed in) | Legacy/public entry alias |
| `/sign-in` | `SignInPage` | Email/password & Google sign-in |
| `/sign-up` | `SignUpPage` | 3-step account creation |
| `/forgot-password` | `ForgotPasswordPage` (`?token=`) | Password reset request & completion |
| `/reset-password` | `ForgotPasswordPage` (`?token=`) | Emailed reset link target |
| `/verify-email` | `VerifyEmailPage` (`?token=`) | 6-digit OTP & emailed link verification |
| `/account` | `VerifyEmailPage` (when unverified) / signed-in redirect to `/main` | Account verification guard |
| `/main` | `MainHomePage` (redirects to `/sign-in` if signed out) | Signed-in Home (Spaces & Recent Canvases) |

## 2. Verified Flutter Handoff Routes (`../eduma`)

Flutter `Routes` use `/${Routes.<member>.name}` with optional `?id=...` query
parameters (`routes.dart`, `main_routes.dart`, `feature_routes.dart`,
`see_all_routes.dart`). **Never invent truncated paths like `/calendar` or `/library`.**

| Feature / Surface | Verified Flutter Path | Query Params / Notes |
|---|---|---|
| Main shell (restored tab) | `/main` | Opening workspace root |
| Home tab | `/homeTab` | Explicit Home tab |
| Calendar tab | `/calendarTab` | **Must be `/calendarTab`, not `/calendar`** |
| Space tab | `/spaceTab` | Spaces tab |
| Library tab | `/libraryTab` | **Must be `/libraryTab`, not `/library`** |
| Space detail | `/spaceDetail?id=<spaceId>` | Individual space view |
| Dynamic Canvas page | `/spacePageCanvas?id=<pageId>&spaceId=<spaceId>` | Canvas editor; `spaceId` required when resolving from `MainCanvas` |
| Static / Notes page | `/spacePageStatic?id=<pageId>&spaceId=<spaceId>` | Structured notes page; `spaceId` required |
| Page details | `/pageDetails` | Expects extra in native; prefer opening `/spacePageCanvas` or `/spacePageStatic` when deep-linking |
| Profile / Settings | `/profile` | Account & app settings |
| Study Streak | `/streak` | Weekly streak & leaderboard |
| Notifications | `/notifications` | Notifications center |
| AI Assistant History | `/assistantHistory` | Past AI chats grouped by space |
| Notebook Search | `/notebookSearch` | Global search popup/view |
| Pinned Spaces (See All) | `/pinnedSpacesSeeAll` | Full pinned spaces list |
| Recent Spaces (See All) | `/recentSpacesSeeAll` | Full recent spaces list |
| Recent Canvases (See All) | `/recentCanvasesSeeAll` | Full recent canvases list |
| Legal Documents | `/legalDocument?id=<docId>` | e.g. Terms / Privacy (`LegalDocumentKind`) |
| Premium / Billing | `/premium` | Plan & billing |
| WhatsApp Integration | `/whatsapp` | Link WhatsApp bot |

## 3. Deep-Link & Query Rules

- Strip sensitive single-use `?token=` parameters from the browser address bar
  immediately after reading them (`AuthActions.scrubTokenFromAddressBar()`).
- When linking externally into Flutter workspace (`EDUMA_FLUTTER_APP_URL`),
  compose `/<flutterBase><path>` safely without double slashes and never loop back
  to `/sign-in` when already inside the Flutter shell.
- Pass only small URL-safe IDs (`id`, `spaceId`) in query strings. Support
  direct reloads and deep links on every public Jaspr route.

