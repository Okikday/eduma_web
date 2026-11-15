import React, { useState } from 'react';
import { normalizeApiUrl } from '../../core/config/appConfig';

interface AdaptiveImageProps {
  src?: string | null;
  alt: string;
  className?: string;
  fallback?: React.ReactNode;
  loading?: 'lazy' | 'eager';
}

export function AdaptiveImage({
  src,
  alt,
  className = '',
  fallback = null,
  loading = 'lazy',
}: AdaptiveImageProps) {
  const [failedSrc, setFailedSrc] = useState<string | null>(null);
  const resolved = normalizeApiUrl(src);

  if (!resolved || failedSrc === resolved) {
    return <>{fallback}</>;
  }

  return (
    <img
      src={resolved}
      alt={alt}
      loading={loading}
      onError={() => setFailedSrc(resolved)}
      className={className}
    />
  );
}
