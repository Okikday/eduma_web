# Source Parity, API Contracts & Hive Schema

Reference contract between `../eduma` (Flutter) and `eduma_web` (Jaspr).

## 1. Hive Storage Schema (`kickin_box`)

`eduma_web` shares the Hive CE box name `kickin_box` on the same origin as
Flutter web (`../eduma/lib/data/hive/hive_keys.dart`,
`../eduma/lib/app/pods/app_prefs/app_prefs.dart`). Never rename existing keys or
clear unrelated keys during sign-out (`Auth` vs `AppPrefs`).

### Auth & Session Keys (`hive_keys.dart`)

| Key | Value Shape | Notes |
|---|---|---|
| `accessToken` | `String?` | Optional on web when HttpOnly cookies handle auth |
| `refreshToken` | `String?` | Cleared/updated carefully; web primarily uses HttpOnly cookies + `credentials: true` |
| `profile` | JSON `Map` (`user` fields) | Cached signed-in `EdumaSession` fields (`id`, `name`, `email`, `username`, `profilePic`, `isVerified`, `role`, `createdAt`, `updatedAt`) |
| `userId` | `String` | User identifier |
| `userRole` | `String` | e.g. `'user'` / `'admin'` |
| `isUserSignedIn` | `bool` | Signed-in marker |
| `seenOnboardingScreens` | `bool` | Onboarding state |
| `auth_signed_in_here_v1` | `bool` | Web-specific hint confirming interactive Jaspr sign-in succeeded on this origin |

### Preference Keys (`app_prefs.dart`, survive sign-out)

| Key | Allowed String Values | Default on Web |
|---|---|---|
| `eduma_pref_space_card_style` | `'list'` \| `'grid'` (`SpaceCardStyle`) | `'list'` (if unset on web; Flutter web defaults `'list'`, native `'grid'`) |
| `eduma_pref_space_sort` | `'recent'` \| `'name'` \| `'created'` | `'recent'` |
| `eduma_pref_space_content_style` | `'list'` \| `'grid'` | `'list'` |
| `eduma_pref_space_asset_style` | `'list'` \| `'grid'` | `'grid'` |

## 2. Backend API Contracts (`../eduma/lib/network/src/`)

### Auth (`/auth` & `/referrals`)

- `POST /auth/login` (`{ email, password }`) -> session + user (`403 EMAIL_NOT_VERIFIED` triggers verification flow)
- `POST /auth/register` (`{ name, username, email, password, referralCode? }`) -> creates account (`403 EMAIL_NOT_VERIFIED` expected until OTP verified)
- `POST /auth/google` (`{ idToken | code }`) -> session + user
- `POST /auth/refresh` -> refreshes session cookie/token
- `POST /auth/logout` -> clears session on server + local auth keys
- `GET /auth/me` -> `{ user }` (`EdumaSession`)
- `POST /auth/forgot-password` (`{ email }`) -> sends reset code/link
- `POST /auth/reset-password` (`{ token, newPassword }`) -> completes password reset (`token` may come from pasted URL `?token=` or 6-digit code)
- `POST /auth/verify-email` (`{ code }` when signed in OR `{ token }` from email link)
- `POST /auth/verify-email/resend` / `POST /auth/verify-email/resend-by-email` (`{ email }`)
- `GET /referrals/{code}` -> `{ valid / referrer }` invite code lookup

### Spaces & Home (`/spaces`)

- `GET /spaces` -> list or `{ spaces | items }` (`MainSpacesPage`)
- `GET /spaces/pages/recent?limit=<n>` -> recent canvases & static pages (`MainCanvas`)
- `POST /spaces` -> create new space (`{ title, description?, isPublic? }`, returns `{ space }` or space object)
- `GET /spaces/invite/{code}` -> invite preview before joining
- `POST /spaces/join` -> `{ inviteCode }` joins a space
- `GET /spaces/{id}` -> space detail & metadata
- `PATCH /spaces/{id}` / `DELETE /spaces/{id}` -> update or delete space
- `POST /spaces/{id}/pin` / `DELETE /spaces/{id}/pin` -> pin/unpin space
- `POST /spaces/{id}/invite-code` -> generate space invite code
- `GET /spaces/{id}/pages` -> pages in space
- `POST /spaces/{id}/pages` / `GET /spaces/{id}/pages/{pageId}` / `PATCH` / `DELETE`
- `POST /spaces/{id}/pages/{pageId}/opened` -> mark canvas/page opened
- `GET /spaces/{id}/members` / `POST|DELETE .../members/{userId}` / `POST|DELETE .../admins/{userId}`

## 3. Feature Migration Checklist

| Feature | Status in `eduma_web` | Target Parity Notes |
|---|---|---|
| Sign In (`/sign-in`) | Migrated | Email/password, Google Identity Services, unverified email redirect |
| Sign Up (`/sign-up`) | Migrated (modularizing) | 3-step form, username validation, password strength, invite code check |
| Forgot / Reset Password | Migrated (fixing link token parse) | Sends OTP/link, extracts `?token=` from pasted links |
| Verify Email (`/verify-email`) | Migrated (fixing OTP fallback) | Auto link `?token=` verify + manual 6-digit OTP fallback + resend |
| Signed-in Home (`/`, `/main`) | Migrated (modularizing + fixing parity) | Rail, verification banner, search/filter/sort/view prefs, Recent Canvases, Pinned carousel, All Spaces list/grid |
| Create Space & Join Space modals | Next up after Home cleanup | Native `<dialog>` flows backed by `POST /spaces`, `GET /spaces/invite/{code}`, `POST /spaces/join` |
| Pin / Unpin Space & Space Actions | Planned | Optimistic pin toggle backed by `POST/DELETE /spaces/{id}/pin` |
| Space Detail (`/spaces/:id`) | Planned | Space header, pages list, members, invite link/code |
| Calendar / Library / Profile tabs | Planned (currently Flutter handoff) | Migrate natively as web features once Space flows land |

