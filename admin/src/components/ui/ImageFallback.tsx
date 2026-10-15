import React, { useState, useEffect } from 'react';
import { Film } from 'lucide-react';

export interface ImageFallbackProps extends React.ImgHTMLAttributes<HTMLImageElement> {
  fallbackTitle?: string;
  genre?: string;
  aspectRatio?: '2:3' | '16:9' | '1:1';
}

export const ImageFallback: React.FC<ImageFallbackProps> = ({
  src,
  alt = '',
  fallbackTitle = '',
  genre,
  aspectRatio = '2:3',
  className = '',
  ...props
}) => {
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    setHasError(false);
  }, [src]);

  const aspectStyles = {
    '2:3': 'aspect-[2/3]',
    '16:9': 'aspect-[16/9]',
    '1:1': 'aspect-square',
  }[aspectRatio];

  const getGradientForTitle = (str: string) => {
    const gradients = [
      'from-rose-950 via-zinc-900 to-black',
      'from-indigo-950 via-zinc-900 to-black',
      'from-amber-950 via-zinc-900 to-black',
      'from-purple-950 via-zinc-900 to-black',
      'from-cyan-950 via-zinc-900 to-black',
      'from-emerald-950 via-zinc-900 to-black',
    ];
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    const index = Math.abs(hash) % gradients.length;
    return gradients[index];
  };

  const title = fallbackTitle || alt;
  const gradient = getGradientForTitle(title || 'Story');
  const initials = title
    ? title
        .split(' ')
        .map((w) => w[0])
        .join('')
        .slice(0, 2)
        .toUpperCase()
    : 'SV';

  if (!src || hasError) {
    return (
      <div
        className={`relative ${aspectStyles} w-full rounded-lg bg-gradient-to-b ${gradient} border border-white/10 flex flex-col items-center justify-center p-2 text-center overflow-hidden select-none shadow-inner ${className}`}
      >
        <div className="w-8 h-8 rounded-full bg-white/10 backdrop-blur-sm flex items-center justify-center text-white/80 mb-1 border border-white/15">
          <Film size={16} />
        </div>
        <span className="text-[11px] font-bold text-white tracking-wider uppercase opacity-90 truncate max-w-full px-1">
          {initials}
        </span>
        {genre && (
          <span className="text-[9px] font-semibold text-accent-coral/90 uppercase tracking-widest mt-0.5 truncate max-w-full">
            {genre}
          </span>
        )}
      </div>
    );
  }

  return (
    <div className={`relative ${aspectStyles} overflow-hidden rounded-lg bg-[#18181B] border border-white/10 ${className}`}>
      <img
        src={src}
        alt={alt}
        onError={() => setHasError(true)}
        className="w-full h-full object-cover"
        {...props}
      />
    </div>
  );
};
