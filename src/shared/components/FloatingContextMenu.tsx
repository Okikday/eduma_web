import React, { useEffect, useRef, useState } from 'react';

export interface ContextMenuItem {
  id: string;
  label: string;
  icon?: React.ReactNode;
  danger?: boolean;
  onSelect: () => void;
}

interface FloatingContextMenuProps {
  trigger: (props: { onClick: () => void; isOpen: boolean }) => React.ReactNode;
  items: readonly ContextMenuItem[];
  align?: 'left' | 'right';
}

export function FloatingContextMenu({
  trigger,
  items,
  align = 'right',
}: FloatingContextMenuProps) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!open) return;
    const onPointerDown = (e: MouseEvent) => {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false);
    };
    window.addEventListener('mousedown', onPointerDown);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('mousedown', onPointerDown);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [open]);

  return (
    <div ref={rootRef} className="relative inline-block">
      {trigger({ onClick: () => setOpen((p) => !p), isOpen: open })}
      {open ? (
        <div
          role="menu"
          className={`absolute top-full z-40 mt-2 min-w-[196px] overflow-hidden rounded-[16px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] p-1.5 shadow-xl ${
            align === 'right' ? 'right-0' : 'left-0'
          }`}
        >
          {items.map((item) => (
            <button
              key={item.id}
              type="button"
              role="menuitem"
              onClick={() => {
                setOpen(false);
                item.onSelect();
              }}
              className={`flex w-full cursor-pointer items-center gap-2.5 rounded-[11px] px-3 py-2 text-left text-[13.5px] font-semibold transition ${
                item.danger
                  ? 'text-[var(--eduma-error)] hover:bg-[var(--eduma-error)]/10'
                  : 'text-[var(--eduma-text-primary)] hover:bg-[var(--eduma-card)]'
              }`}
            >
              {item.icon ? <span className="shrink-0">{item.icon}</span> : null}
              <span className="truncate">{item.label}</span>
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
