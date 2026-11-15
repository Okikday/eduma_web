import React from 'react';
import {
  HUGE_SOLID_GLYPHS,
  HUGE_STROKE_GLYPHS,
  ICONSAX_GLYPHS,
} from './iconGlyphs';

export type IconsaxName = keyof typeof ICONSAX_GLYPHS;
export type HugeStrokeName = keyof typeof HUGE_STROKE_GLYPHS;
export type HugeSolidName = keyof typeof HUGE_SOLID_GLYPHS;

export type EdumaIconRef =
  | { family: 'iconsax'; name: IconsaxName }
  | { family: 'huge-stroke'; name: HugeStrokeName }
  | { family: 'huge-solid'; name: HugeSolidName };

interface EdumaIconProps {
  family?: 'iconsax' | 'huge-stroke' | 'huge-solid';
  name: string;
  size?: number;
  className?: string;
  color?: string;
  label?: string;
  style?: React.CSSProperties;
}

const FONT_FAMILY_CSS: Record<'iconsax' | 'huge-stroke' | 'huge-solid', string> = {
  iconsax: '"FlutterIconsax"',
  'huge-stroke': '"HugeIconsStroke"',
  'huge-solid': '"HugeIconsSolid"',
};

function resolveCodePoint(
  family: 'iconsax' | 'huge-stroke' | 'huge-solid',
  name: string
): number | undefined {
  if (family === 'iconsax') {
    return (ICONSAX_GLYPHS as Record<string, number>)[name];
  }
  if (family === 'huge-solid') {
    return (HUGE_SOLID_GLYPHS as Record<string, number>)[name];
  }
  return (HUGE_STROKE_GLYPHS as Record<string, number>)[name];
}

export function EdumaIcon({
  family = 'huge-stroke',
  name,
  size = 20,
  className = '',
  color,
  label,
  style,
}: EdumaIconProps) {
  const codePoint = resolveCodePoint(family, name);
  const glyph = codePoint ? String.fromCodePoint(codePoint) : '•';

  return (
    <span
      className={`inline-flex shrink-0 select-none items-center justify-center leading-none ${className}`}
      style={{
        fontFamily: FONT_FAMILY_CSS[family],
        fontSize: `${size}px`,
        width: `${size}px`,
        height: `${size}px`,
        color,
        ...style,
      }}
      aria-label={label}
      aria-hidden={label ? undefined : true}
      role={label ? 'img' : undefined}
    >
      {glyph}
    </span>
  );
}
