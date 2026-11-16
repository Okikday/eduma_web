# Eduma web

Jaspr frontend for Eduma. The current migration includes account access and
the initial authenticated Main/Home slice, with unmigrated workflows handed
off to the existing Flutter workspace.

Project conventions and the Flutter-to-Jaspr mapping are documented in
[`.rules/rules.md`](.rules/rules.md).

## Run locally

```sh
sh tool/jaspr_with_google.sh serve
```

The development server is available at `http://localhost:8080`.

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

## Flutter workspace handoff

Routes that are not migrated yet link to the existing Flutter app at
`https://app.eduma.com.ng` and use its real named-route paths and query
parameters. This is the default; set `EDUMA_FLUTTER_APP_URL` only when the
Flutter app is deployed at a different base URL:

```sh
sh tool/jaspr_with_google.sh build \
  --dart-define=EDUMA_API_BASE_URL=https://your-api.example/api/v1 \
  --dart-define=EDUMA_FLUTTER_APP_URL=https://your-flutter-app.example/
```

Browser storage is origin-scoped. When Jaspr and Flutter are on different
origins, signing in to Jaspr does not transfer its saved session to Flutter;
the Flutter app may ask the user to sign in there as well. The API must allow
the deployed Jaspr origin through CORS and permit credentialed requests.
Configure the static host to rewrite Jaspr routes (for example `/sign-in`,
`/verify-email`, and `/reset-password`) to `index.html`.

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
