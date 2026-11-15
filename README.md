# Eduma Web (React + TypeScript + Tailwind CSS)

Web client for **Eduma**, ported directly from the Flutter source of truth at `../eduma` into a modular React 19, TypeScript, Tailwind CSS v4, and Vite 6 application.

> Note: The earlier Jaspr prototype is preserved untouched in [`jaspr/`](./jaspr/).

## Stack

- **UI & Routing**: React 19, React Router DOM v7 (`BrowserRouter`), Tailwind CSS v4 (`@tailwindcss/vite`)
- **Language & Build**: TypeScript 5.8 (`strict`), Vite 6
- **Testing**: Vitest 3 (`test/edumaLogic.test.ts`)
- **Icons & Fonts**: Bundled `Raleway` variable font, Google Fonts (`ABeeZee`, `Agbalumo`, `Bellota`, `Cal Sans`, `Plus Jakarta Sans`), and vector icon webfonts (`FlutterIconsax`, `HugeIconsStroke`, `HugeIconsSolid`) sourced from the Flutter glyph tables

## Getting Started

```bash
npm install
npm run dev
```

The dev server starts at `http://localhost:5173`.

### Scripts

| Command | Description |
| --- | --- |
| `npm run dev` | Start Vite development server on port 5173 |
| `npm run typecheck` | Run strict TypeScript check (`tsc --noEmit`) |
| `npm test` | Run Vitest unit suite (`vitest run`) |
| `npm run build` | Typecheck project references and build production bundle to `dist/` |
| `npm run preview` | Preview production `dist/` build locally |

## Environment Configuration

Configure optional `VITE_*` variables in `.env.local` (all have safe defaults in [`src/core/config/appConfig.ts`](./src/core/config/appConfig.ts)):

- `VITE_API_BASE_URL` — Backend API base URL (default: `https://api.eduma.ai/api`)
- `VITE_FLUTTER_APP_URL` — Optional hosted Flutter web workspace URL for interactive canvas handoff (`/spacePageCanvas`)
- `VITE_GOOGLE_WEB_CLIENT_ID` — Google Identity Services Web Client ID (can also be provided via `public/google-sign-in.js`)

## Project Structure

```text
eduma_web/
├── index.html                  # Pre-paint theme/font/blur bootstrap + font preloads
├── public/
│   ├── assets/
│   │   ├── fonts/              # Raleway TTFs + Iconsax & HugeIcons webfonts
│   │   ├── images/             # Brand patterns (book_sparkle_bg.webp, dust_pattern.webp)
│   │   ├── legal/              # Privacy, Terms, and Refund markdown documents
│   │   └── logo/               # Brand mark
│   ├── favicon.ico
│   └── google-sign-in.js
├── src/
│   ├── core/
│   │   ├── api/                # Refresh-coalesced fetch client & envelope extractors
│   │   ├── cache/              # Session-scoped in-memory cache
│   │   ├── config/             # Environment config, origin normalization, canvas handoff
│   │   ├── icons/              # Exact codepoint maps & EdumaIcon component
│   │   ├── storage/            # LocalStorage persistence & session reset
│   │   ├── theme/              # System/Light/Dark mode, font selector, reduce-blur context
│   │   └── utils/              # FNV-1a accent/book-edge hashing, date/month/timeline utils
│   ├── shared/
│   │   └── components/         # AppModalDialog, AppOtpField, buttons, segmented controls, etc.
│   ├── features/
│   │   ├── auth/               # Sign in, 4-step sign up, forgot/reset password, verify email
│   │   ├── main/               # Adaptive MainShell (desktop 84px rail + mobile floating nav)
│   │   ├── spaces/             # Home spaces, fanned grid cards, space detail, page viewer
│   │   ├── calendar/           # Month grid, overlapping timeline, day agenda, event dialogs
│   │   ├── library/            # Catalog search, categories, stacked book cards, PDF reader
│   │   ├── notifications/      # Filterable notification center & invite accept/decline
│   │   ├── streaks/            # Circular streak ring, stats, and 7-day strip
│   │   ├── assistant/          # AI Study Assistant history viewer
│   │   └── profile/            # Appearance, billing, AI memory, security & account settings
│   ├── styles/index.css        # Design tokens, dark mode variables, font-face & dialog styling
│   ├── App.tsx                 # Route definitions & auth guards
│   └── main.tsx                # React entrypoint
├── test/                       # Unit tests for core business & UI-math logic
└── jaspr/                      # Archived Jaspr web implementation
```

## Production Hosting Notes

- Configure your static host or reverse proxy with an SPA fallback rewrite so deep links (`/sign-in`, `/join/:code`, `/spaces/:id`, `/verify-email`, `/reset-password`, etc.) serve `index.html`.
- Keep CORS configured on the backend API to allow your web origin with credentials and Authorization headers.
- Interactive canvas editing hands off to `VITE_FLUTTER_APP_URL` when configured, preserving the Flutter canvas engine without duplicating it in React.
