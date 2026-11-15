# Hugeicons Flutter

Hugeicons Flutter is a free icon library featuring **4,687 icons** in two styles: **Solid** and **Stroke**. It is designed for Flutter projects and provides a wide range of icons for various use cases.

## Features

- **4,687 icons** for each style (Solid and Stroke).
- Easy integration with Flutter projects.
- Customizable and scalable icons.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  hugeicons_pro: ^0.0.2
```

Run `flutter pub get` to fetch the package.

## Usage

Import the library in your Dart file:

```dart
import 'package:hugeicons_pro/hugeicons.dart';
```

Use the icons in your Flutter widgets:

```dart
// Stroke style
Icon(HugeIconsStroke.home01)
Icon(HugeIconsStroke.search01)
Icon(HugeIconsStroke.notification01)

// Solid style
Icon(HugeIconsSolid.home01)
Icon(HugeIconsSolid.settings01)
Icon(HugeIconsSolid.camera01)
```

Customize size and color:

```dart
Icon(HugeIconsStroke.calendar01, size: 32, color: Colors.blue)
Icon(HugeIconsSolid.heartAdd, size: 48, color: Colors.red)
```

Use in buttons and other widgets:

```dart
IconButton(
  icon: Icon(HugeIconsStroke.shoppingCart01),
  onPressed: () {},
)
```

## Naming Conventions

### Icons starting with numbers

Icon names that start with a number are prefixed with `$` since Dart identifiers cannot begin with a digit. The original name is kept intact after the prefix.

```dart
// 3d-printer -> $3dPrinter
Icon(HugeIconsSolid.$3dPrinter)

// 4k -> $4k
Icon(HugeIconsStroke.$4k)

// 1st-bracket-circle -> $1stBracketCircle
Icon(HugeIconsSolid.$1stBracketCircle)
```

### Duplicate icon names

When two different SVG icons produce the same Dart name (e.g. `3d-printer` and `printer-3d` both become `printer3d`), the second occurrence is suffixed with an incrementing number.

```dart
Icon(HugeIconsSolid.printer3d)   // from printer-3d
Icon(HugeIconsSolid.printer3d2)  // from 3d-printer (duplicate, suffixed)
```

## License

This library is free to use. Check the repository for more details.
