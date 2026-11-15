# Design Tokens Spec

Source of truth: `../eduma/lib/shared/theme/src/colors/` (`app_colors.dart`,
`pure_light_theme_extension.dart`, `pure_dark_theme_extension.dart`,
`pure_accents.dart`) and `app_text_theme.dart`.

All shared CSS custom properties and `@font-face` declarations live in
`web/styles/tokens.css`, loaded before feature stylesheets in `web/index.html`.

## 1. Core Brand & Neutral Palette (`app_colors.dart`)

| Source Symbol | Hex Value | Usage |
|---|---|---|
| `AppColors.primary` | `#4b24d2` | Light-mode primary brand indigo/purple (actions, focus, active tabs) |
| `AppColors.primaryDark` | `#5375f6` | Dark-mode primary accent blue-indigo |
| `AppColors.bgLight` | `#efeef4` | Light scaffold background (`PureLightThemeExtension.scaffoldBackground`) |
| `AppColors.bgDark` | `#131313` | Dark scaffold background (`PureDarkThemeExtension.scaffoldBackground`) |
| `AppColors.deepBlue` | `#14143e` | Dark secondary / brand deep indigo (`#14143E`) |
| `AppColors.surfaceLightCard` | `#e5e4ec` | Light default card fill (`PureLightThemeExtension.card`) |
| `AppColors.surfaceDark1F` | `#1f1f1f` | Dark surface 1 |
| `AppColors.surfaceDark35` | `#353535` | Dark surface elevated |
| `AppColors.surfaceDark3D` | `#3d3d3d` | Dark divider/surface |
| `AppColors.textGray72` | `#727272` | Gray muted ink |
| `AppColors.textGrayA5` | `#a5a5a5` | Gray medium ink |
| `AppColors.textGrayD1` | `#d1d1d1` | Light gray ink on dark surfaces |
| `AppColors.whatsapp` | `#25d366` | WhatsApp integration green |
| `AppColors.whatsappDark` | `#128c7e` | WhatsApp darker green |

## 2. Semantic Surface & Text Tokens

### Light Mode (`pure_light_theme_extension.dart`)

| Token | Value | CSS Custom Property (`tokens.css`) |
|---|---|---|
| `primary` | `#4b24d2` | `--eduma-primary` |
| `secondary` | `#4a4d57` | `--eduma-secondary` |
| `scaffoldBackground` | `#efeef4` | `--eduma-bg` |
| `surface` | `#ffffff` | `--eduma-surface` |
| `surfaceElevated` | `#ffffff` | `--eduma-surface-elevated` |
| `card` | `#e5e4ec` | `--eduma-card` |
| `textPrimary` | `#141522` | `--eduma-text` |
| `textSecondary` | `#454957` | `--eduma-text-secondary` |
| `textMuted` | `#666b7a` | `--eduma-text-muted` |
| `border` | `rgba(16, 24, 40, 0.094)` (`0x18101828`) | `--eduma-border` |
| `borderSubtle` | `rgba(16, 24, 40, 0.055)` (`0x0E101828`) | `--eduma-border-subtle` |
| `error` | `#e5484d` | `--eduma-error` |
| `success` | `#30a46c` | `--eduma-success` |
| `warning` | `#f5a524` (Amber) | `--eduma-warning` |
| `gold` | `#e2a90f` | `--eduma-gold` |

### Dark Mode (`pure_dark_theme_extension.dart`, reference for future dark toggle)

| Token | Value |
|---|---|
| `primary` | `#5375f6` |
| `secondary` | `#14143e` |
| `scaffoldBackground` | `#131313` |
| `surface` | `#1f1f22` |
| `surfaceElevated` | `#2b2b30` |
| `card` | `#28282d` |
| `textPrimary` | `#f7f8fa` |
| `textSecondary` | `#d5d7e0` |
| `textMuted` | `#9e9fa8` |
| `border` | `#3a3a40` |
| `borderSubtle` | `#2e2e34` |
| `error` | `#ff4d4f` |
| `success` | `#52c41a` |
| `gold` | `#f2c230` |

## 3. Side-by-Side Categorical Accents (`pure_accents.dart`)

Used for distinguishing items side-by-side (e.g., Space grid fan covers, study
tools) — **never** for primary actions or semantic validation states:

| Accent | Light Hex | Dark Hex | CSS Var (`tokens.css`) |
|---|---|---|---|
| `accentViolet` | `#7c3aed` | `#b4a0fb` | `--eduma-accent-violet` |
| `accentSky` | `#0284c7` | `#7dd3fc` | `--eduma-accent-sky` |
| `accentTeal` | `#0f9488` | `#5eead4` | `--eduma-accent-teal` |
| `accentAmber` | `#d97706` | `#fcd34d` | `--eduma-accent-amber` |
| `accentRose` | `#e11d48` | `#fda4af` | `--eduma-accent-rose` |
| `accentGreen` | `#16a34a` | `#86efac` | `--eduma-accent-green` |

## 4. Typography (`app_text_theme.dart`)

- Primary font family: `'Raleway'` loaded from `/assets/fonts/Raleway-Variable.ttf`
  (weights `400`–`800`).
- Minimum body weight is `500` (medium) across standard text roles (`bodyLarge`
  `17px / 500`, `bodyMedium` `15px / 500`, `bodySmall` `13px / 500`,
  `sectionTitle` `17px / 700`, `cardTitle` `15.5px / 600`, `cardSubtitle`
  `12.5px / 500`, `meta` `12px / 500`, `badge` `11px / 700`).

## 5. Radii, Spacing & Elevation Rules

- Radii: control pills / buttons `14px`–`999px`; inputs/notices `16px`;
  Space cards & panels `20px`–`24px` (`--eduma-radius-md: 16px`,
  `--eduma-radius-lg: 20px`, `--eduma-radius-xl: 24px`, `--eduma-radius-pill: 999px`).
- Shadows: subtle neutral shadows (`0 10px 26px rgba(16, 24, 40, 0.06)`,
  `0 20px 54px rgba(16, 24, 40, 0.08)`), never heavy drop-shadows on flat cards.
- Accessibility: pair color cues with icons/text/focus outlines; respect
  `prefers-reduced-motion: reduce`.

