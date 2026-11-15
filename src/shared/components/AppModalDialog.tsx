import React, { useEffect, useId, useRef } from 'react';
import { EdumaIcon } from '../../core/icons/EdumaIcon';
import { DesktopWidths } from './formFactor';

interface AppModalDialogProps {
  open: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  maxWidth?: number;
  closedby?: 'any' | 'closerequest' | 'none';
  sheetOnMobile?: boolean;
}

/**
 * Native top-layer modal built on `<dialog>` + `showModal()`.
 * Implements `closedby="any"` light-dismiss plus bounding-box pointer fallback
 * for Safari/older engines where `HTMLDialogElement.prototype.closedBy` is absent.
 */
export function AppModalDialog({
  open,
  onClose,
  title,
  subtitle,
  children,
  footer,
  maxWidth = DesktopWidths.dialog,
  closedby = 'any',
  sheetOnMobile = true,
}: AppModalDialogProps) {
  const dialogRef = useRef<HTMLDialogElement | null>(null);
  const titleId = useId();
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (open && !dialog.open) {
      dialog.returnValue = '';
      dialog.showModal();
    } else if (!open && dialog.open) {
      dialog.close();
    }
  }, [open]);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    const handleClose = () => {
      // Clear returnValue so subsequent closes never inherit stale action state.
      dialog.returnValue = '';
      onCloseRef.current();
    };

    const handleCancel = (event: Event) => {
      if (closedby === 'none') {
        event.preventDefault();
      }
    };

    dialog.addEventListener('close', handleClose);
    dialog.addEventListener('cancel', handleCancel);

    // Light-dismiss fallback when `closedby` attribute is unsupported natively.
    const needsFallback =
      closedby === 'any' && !('closedBy' in HTMLDialogElement.prototype);
    let pressedOutside = false;

    const isOutside = (e: PointerEvent) => {
      const r = dialog.getBoundingClientRect();
      return (
        e.clientX < r.left ||
        e.clientX > r.right ||
        e.clientY < r.top ||
        e.clientY > r.bottom
      );
    };

    const handlePointerDown = (e: PointerEvent) => {
      pressedOutside = isOutside(e);
    };
    const handlePointerUp = (e: PointerEvent) => {
      if (pressedOutside && isOutside(e)) {
        dialog.close();
      }
      pressedOutside = false;
    };

    if (needsFallback) {
      dialog.addEventListener('pointerdown', handlePointerDown);
      dialog.addEventListener('pointerup', handlePointerUp);
    }

    return () => {
      dialog.removeEventListener('close', handleClose);
      dialog.removeEventListener('cancel', handleCancel);
      if (needsFallback) {
        dialog.removeEventListener('pointerdown', handlePointerDown);
        dialog.removeEventListener('pointerup', handlePointerUp);
      }
    };
  }, [closedby]);

  return (
    <dialog
      ref={dialogRef}
      aria-labelledby={titleId}
      {...({ closedby } as Record<string, string>)}
      className={`w-full overflow-hidden rounded-[24px] bg-[var(--eduma-surface)] text-[var(--eduma-text-primary)] shadow-2xl border border-[var(--eduma-border)] ${
        sheetOnMobile ? 'max-sm:mb-0 max-sm:rounded-b-none' : ''
      }`}
      style={{ maxWidth: `min(100vw - 24px, ${maxWidth}px)` }}
    >
      <div className="flex items-start justify-between gap-3 border-b border-[var(--eduma-border-subtle)] px-6 py-4">
        <div className="min-w-0">
          <h2 id={titleId} className="type-title-lg truncate text-[var(--eduma-text-primary)]">
            {title}
          </h2>
          {subtitle ? (
            <p className="type-body-sm mt-0.5 text-[var(--eduma-text-muted)]">
              {subtitle}
            </p>
          ) : null}
        </div>
        <button
          type="button"
          onClick={() => dialogRef.current?.close()}
          aria-label={`Close ${title}`}
          className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-bg)] text-[var(--eduma-text-secondary)] transition hover:bg-[var(--eduma-card)]"
        >
          <EdumaIcon family="huge-stroke" name="cancel01" size={16} />
        </button>
      </div>

      <div className="thin-scrollbar max-h-[75dvh] overflow-y-auto px-6 py-5">
        {children}
      </div>

      {footer ? (
        <div className="flex flex-wrap items-center justify-end gap-2.5 border-t border-[var(--eduma-border-subtle)] px-6 py-4">
          {footer}
        </div>
      ) : null}
    </dialog>
  );
}
