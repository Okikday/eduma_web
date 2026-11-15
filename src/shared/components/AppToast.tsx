import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';
import { EdumaIcon } from '../../core/icons/EdumaIcon';

export type ToastTone = 'info' | 'success' | 'error';

interface ToastMessage {
  id: number;
  message: string;
  tone: ToastTone;
}

interface ToastContextValue {
  showToast: (message: string, tone?: ToastTone) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  const showToast = useCallback((message: string, tone: ToastTone = 'info') => {
    const id = Date.now() + Math.floor(Math.random() * 1000);
    setToasts((prev) => [...prev.slice(-3), { id, message, tone }]);
    window.setTimeout(() => {
      setToasts((prev) => prev.filter((item) => item.id !== id));
    }, 3600);
  }, []);

  const value = useMemo(() => ({ showToast }), [showToast]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div
        aria-live="polite"
        className="pointer-events-none fixed right-4 bottom-24 z-50 flex flex-col gap-2 md:bottom-6"
      >
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={`pointer-events-auto flex max-w-sm items-center gap-2.5 rounded-[14px] border px-4 py-3 text-[13.5px] font-semibold shadow-lg backdrop-blur-md ${
              toast.tone === 'error'
                ? 'border-[var(--eduma-error)]/40 bg-[var(--eduma-surface)] text-[var(--eduma-error)]'
                : toast.tone === 'success'
                ? 'border-[var(--eduma-success)]/40 bg-[var(--eduma-surface)] text-[var(--eduma-success)]'
                : 'border-[var(--eduma-border)] bg-[var(--eduma-surface)] text-[var(--eduma-text-primary)]'
            }`}
          >
            <EdumaIcon
              family="huge-stroke"
              name={
                toast.tone === 'error'
                  ? 'informationCircle'
                  : toast.tone === 'success'
                  ? 'checkmarkCircle02'
                  : 'informationCircle'
              }
              size={18}
            />
            <span>{toast.message}</span>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error('useToast must be used within ToastProvider');
  }
  return ctx;
}
