import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useFormFactor } from './formFactor';

interface DesktopPopupFrameProps {
  children: React.ReactNode;
  maxWidth?: number;
  backTo?: string;
}

/**
 * Ports `AdaptivePage` (`../eduma/lib/shared/components/desktop/adaptive_page.dart`):
 * On wide desktop viewports, presents secondary flows (Notifications, AI Chats,
 * Streak, Premium, WhatsApp, See-all views) inside a centered floating surface
 * card (max 940px tall) over a softly dimmed backdrop. On compact/medium sizes,
 * renders full screen.
 */
export function DesktopPopupFrame({
  children,
  maxWidth = 640,
  backTo = '/main',
}: DesktopPopupFrameProps) {
  const navigate = useNavigate();
  const { isExpanded } = useFormFactor();

  useEffect(() => {
    if (!isExpanded) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (window.history.length > 1) {
          navigate(-1);
        } else {
          navigate(backTo, { replace: true });
        }
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isExpanded, navigate, backTo]);

  if (!isExpanded) {
    return <div className="min-h-screen bg-[var(--eduma-bg)]">{children}</div>;
  }

  return (
    <div
      className="fixed inset-0 z-40 flex items-center justify-center bg-black/28 p-8 backdrop-blur-[6px]"
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          if (window.history.length > 1) {
            navigate(-1);
          } else {
            navigate(backTo, { replace: true });
          }
        }
      }}
    >
      <div
        className="flex w-full flex-col overflow-hidden rounded-[24px] border border-[var(--eduma-border)] bg-[var(--eduma-bg)] shadow-[0_24px_64px_rgba(0,0,0,0.28)]"
        style={{
          maxWidth: `${maxWidth}px`,
          maxHeight: 'min(940px, calc(100vh - 64px))',
        }}
      >
        <div className="min-h-0 flex-1 overflow-y-auto">{children}</div>
      </div>
    </div>
  );
}
