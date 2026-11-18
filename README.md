# Eduma web

Jaspr frontend for Eduma. Simple web surfaces are implemented in Jaspr; the
canvas, Notes, and new AI-chat experiences use the Flutter web application.

Project conventions and the Flutter-to-Jaspr mapping are documented in
[`.rules/rules.md`](.rules/rules.md).

## Run locally

```sh
sh tool/jaspr_with_google.sh serve
```

The development server is available at `http://localhost:8080`.

Canvas, Notes and the new AI chat come from the Flutter source app. Build it
into `web/flutter/` (git-ignored) so the dev server serves it, then restart
`jaspr serve` once so it picks up the directory:

```sh
sh tool/build_flutter_embed.sh
```

The app boots once in a hidden iframe shortly after sign-in and is reused for
every embedded view (`lib/core/presentation/flutter_host.dart`), so opening
a page doesn't reload it. The two apps talk over same-origin `postMessage`
(`WebEmbedBridge` in the source's `lib/app/routes/core/web_embed/`).

## Configure and build

The browser app calls the existing Eduma API. The default API URL is the
production endpoint; override it at build time when needed. The Google web
client ID is read from the local `.env` copied from the Flutter source:

```sh
cp ../eduma/.env .env
sh tool/jaspr_with_google.sh build \
  --dart-define=EDUMA_API_BASE_URL=https://your-api.example/api/v1
```

The helper passes only `WEB_CLIENT_ID` to the browser build as
`EDUMA_GOOGLE_WEB_CLIENT_ID`; other `.env` values are not exposed to the
client. `.env` is ignored by Git. Add each deployed web origin to the OAuth
client's authorized JavaScript origins.

The sign-in consent links open the local `/legalDocument` route. Terms are
loaded from the public `/legal/terms` API endpoint and fall back to the bundled
source policy; the Privacy Policy uses its bundled source copy.

## Embedded Flutter views

Build the Jaspr app and the sibling Flutter source workspace into one static
site:

```sh
sh tool/build_with_flutter.sh \
  --dart-define=EDUMA_API_BASE_URL=https://your-api.example/api/v1
```

Stop any running `jaspr serve` process in this workspace before this production
build; Jaspr shares a build daemon between `serve` and `build`, and rejects
switching its options while that daemon is active.

The script expects FVM and the Flutter checkout at `../eduma`. Override that
location with `EDUMA_FLUTTER_SOURCE_DIR` when building elsewhere. The pinned
Flutter web output is placed at `build/jaspr/flutter/`; deploy that directory
alongside the Jaspr output. Configure the static host to rewrite Jaspr routes
to `/index.html` and serve the Flutter files under `/flutter/` as static
assets. Keeping both apps on the same origin gives them a shared browser
storage scope; the Flutter app may still require its own sign-in if the
session formats differ.

Routes not yet embedded can still hand off to the deployed Flutter app at
`https://app.eduma.com.ng`; set `EDUMA_FLUTTER_APP_URL` only when it is hosted
at a different base URL. The API must allow the deployed web origin through
CORS and permit credentialed requests.

## Main icons

The local `iconsax_flutter` and `hugeicons_pro` packages under `packages/` are
Jaspr ports of the source icon packages. Their complete glyph definitions and
font files are retained there; the browser assets are WOFF2 subsets containing
only glyphs referenced by the Main page. After changing Main icon references,
regenerate the browser subsets with:

```sh
python3 -m pip install fonttools brotli
python3 tool/subset_icon_fonts.py
```

Iconsax was cloned from
[PersianFlutter/iconsax_flutter](https://github.com/PersianFlutter/iconsax_flutter)
at version 1.0.1 (BSD 3-Clause). HugeIcons Pro 0.0.3 was adapted from the
published package source available in the local Pub cache (MIT). Both license
texts are retained in the package directories and `web/assets/licenses/`.

## Output

The static build is written to `build/jaspr/`.
