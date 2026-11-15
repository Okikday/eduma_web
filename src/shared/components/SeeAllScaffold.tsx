import React from 'react';
import { DesktopPageHeader } from './DesktopPageHeader';
import { DesktopPopupFrame } from './DesktopPopupFrame';
import { PureAppBar } from './PureAppBar';
import { useFormFactor } from './formFactor';

interface SeeAllScaffoldProps {
  title: string;
  subtitle?: string;
  backTo?: string;
  trailing?: React.ReactNode;
  children: React.ReactNode;
}

export function SeeAllScaffold({
  title,
  subtitle,
  backTo = '/main',
  trailing,
  children,
}: SeeAllScaffoldProps) {
  const { isExpanded } = useFormFactor();

  if (isExpanded) {
    return (
      <DesktopPopupFrame maxWidth={880} backTo={backTo}>
        <DesktopPageHeader
          title={title}
          subtitle={subtitle}
          backTo={backTo}
          trailing={trailing}
        />
        <div className="px-7 pb-8 pt-2">{children}</div>
      </DesktopPopupFrame>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--eduma-bg)] pb-24">
      <PureAppBar
        title={title}
        subtitle={subtitle}
        backTo={backTo}
        trailing={trailing}
      />
      <div className="mx-auto max-w-3xl px-4 pt-4">{children}</div>
    </div>
  );
}
