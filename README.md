# Eduma web

Jaspr frontend for Eduma. The current migration includes account access and
the initial authenticated Main/Home slice, with unmigrated workflows handed
off to the existing Flutter workspace.

Project conventions and the Flutter-to-Jaspr mapping are documented in
[`.rules/rules.md`](.rules/rules.md).

## Run locally

```sh
jaspr serve
```

The development server is available at `http://localhost:8080`.

## Configure and build

The browser app calls the existing Eduma API. The default API URL is the
production endpoint; override it at build time when needed:

```sh
jaspr build \
  --dart-define=EDUMA_API_BASE_URL=https://your-api.example/api/v1 \
  --dart-define=EDUMA_GOOGLE_WEB_CLIENT_ID=your-google-web-client-id
```

`EDUMA_GOOGLE_WEB_CLIENT_ID` is the public OAuth client ID used by Google's
rendered web sign-in button. Google sign-in is unavailable when it is omitted.

## Flutter workspace handoff

The existing Flutter app and this Jaspr app must use the same origin for their
Hive browser storage to be shared. Serve Jaspr at `/` and move/proxy the
existing Flutter workspace to a separate path such as `/workspace/` on that
same origin. The Jaspr app must not replace the Flutter workspace at the URL
used for the handoff. Set `EDUMA_FLUTTER_APP_URL` to that same-origin path when
building:

```sh
jaspr build \
  --dart-define=EDUMA_API_BASE_URL=https://your-api.example/api/v1 \
  --dart-define=EDUMA_FLUTTER_APP_URL=https://your-domain.example/workspace/
```

The API must allow the deployed Jaspr origin through CORS and permit credentialed
requests. Configure the static host to rewrite the Jaspr routes (for example
`/sign-in`, `/verify-email`, and `/reset-password`) to `index.html`, while
excluding `/workspace/` from that rewrite. Local development uses a different
origin from the Flutter app, so the account page reports that handoff as
unavailable locally.

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
