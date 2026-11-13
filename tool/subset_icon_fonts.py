from pathlib import Path
import re
import sys

try:
    from fontTools import subset
except ImportError as error:
    raise SystemExit(
        "Install the icon-font tooling with: "
        "python3 -m pip install fonttools brotli"
    ) from error


ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / "lib/features/main/presentation/pages/main_home.dart"
ICON_SOURCE = ROOT / "packages/iconsax_flutter/lib/iconsax_flutter.dart"
ICON_FONT = ROOT / "packages/iconsax_flutter/fonts/FlutterIconsax.ttf"
HUGE_SOURCE = ROOT / "packages/hugeicons_pro/lib/src"
HUGE_FONTS = ROOT / "packages/hugeicons_pro/fonts"
OUTPUT = ROOT / "web/assets/fonts/icons"


def referenced_codepoints(class_name: str, definitions: Path) -> set[int]:
    page_source = PAGE.read_text(encoding="utf-8")
    names = set(re.findall(rf"\b{class_name}\.(\w+)\b", page_source))
    if not names:
        raise ValueError(f"No {class_name} glyphs referenced in {PAGE}")

    definitions_text = definitions.read_text(encoding="utf-8")
    codepoints = set()
    for name in sorted(names):
        pattern = re.compile(
            rf"\bstatic\s+const\s+(?:IconData\s+)?{re.escape(name)}"
            rf"\s*=\s*IconData\(\s*(0x[0-9a-fA-F]+)"
        )
        match = pattern.search(definitions_text)
        if match is None:
            raise ValueError(f"Could not resolve {class_name}.{name} in {definitions}")
        codepoints.add(int(match.group(1), 16))
    return codepoints


def subset_font(source: Path, destination: Path, codepoints: set[int]) -> None:
    options = subset.Options()
    options.flavor = "woff2"
    font = subset.load_font(str(source), options)
    available = {
        codepoint
        for table in font["cmap"].tables
        for codepoint in table.cmap
    }
    missing = codepoints - available
    if missing:
        raise ValueError(
            f"{source} is missing glyph codepoints: "
            + ", ".join(f"U+{value:04X}" for value in sorted(missing))
        )

    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=codepoints)
    subsetter.subset(font)
    destination.parent.mkdir(parents=True, exist_ok=True)
    subset.save_font(font, str(destination), options)
    print(
        f"{destination.relative_to(ROOT)}: "
        f"{len(codepoints)} glyphs, {destination.stat().st_size:,} bytes"
    )


def main() -> None:
    subset_font(
        ICON_FONT,
        OUTPUT / "FlutterIconsax.woff2",
        referenced_codepoints("Iconsax", ICON_SOURCE),
    )
    subset_font(
        HUGE_FONTS / "hugeicons-solid.ttf",
        OUTPUT / "hugeicons-solid.woff2",
        referenced_codepoints(
            "HugeIconsSolid", HUGE_SOURCE / "hugeicons_solid.dart"
        ),
    )
    subset_font(
        HUGE_FONTS / "hugeicons-stroke.ttf",
        OUTPUT / "hugeicons-stroke.woff2",
        referenced_codepoints(
            "HugeIconsStroke", HUGE_SOURCE / "hugeicons_stroke.dart"
        ),
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1) from error
