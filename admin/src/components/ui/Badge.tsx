import React from 'react';
import { Star, Trophy, Flame, Sparkles, Eye, EyeOff, Shield, User, Globe } from 'lucide-react';

export type BadgeVariant =
  | 'hero'
  | 'topTen'
  | 'trending'
  | 'new'
  | 'published'
  | 'draft'
  | 'admin'
  | 'user'
  | 'category'
  | 'language'
  | 'custom';

export interface BadgeProps {
  variant?: BadgeVariant;
  children?: React.ReactNode;
  size?: 'xs' | 'sm' | 'md';
  className?: string;
  onClick?: (e: React.MouseEvent) => void;
  title?: string;
}

export const Badge: React.FC<BadgeProps> = ({
  variant = 'category',
  children,
  size = 'sm',
  className = '',
  onClick,
  title,
}) => {
  const sizeStyles = {
    xs: 'text-[10px] px-1.5 py-0.5 gap-1',
    sm: 'text-[11px] px-2 py-0.5 gap-1.5',
    md: 'text-xs px-2.5 py-1 gap-1.5',
  }[size];

  const variantConfig = {
    hero: {
      style: 'bg-sky-500/15 text-sky-400 border-sky-500/30 hover:bg-sky-500/25',
      icon: <Star size={size === 'xs' ? 10 : 12} className="fill-sky-400/40" />,
      defaultText: 'Hero',
    },
    topTen: {
      style: 'bg-purple-500/15 text-purple-400 border-purple-500/30 hover:bg-purple-500/25',
      icon: <Trophy size={size === 'xs' ? 10 : 12} />,
      defaultText: 'Top 10',
    },
    trending: {
      style: 'bg-amber-500/15 text-amber-400 border-amber-500/30 hover:bg-amber-500/25',
      icon: <Flame size={size === 'xs' ? 10 : 12} />,
      defaultText: 'Trending',
    },
    new: {
      style: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/25',
      icon: <Sparkles size={size === 'xs' ? 10 : 12} />,
      defaultText: 'New',
    },
    published: {
      style: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/25',
      icon: <Eye size={size === 'xs' ? 10 : 12} />,
      defaultText: 'Published',
    },
    draft: {
      style: 'bg-zinc-800 text-zinc-400 border-zinc-700 hover:bg-zinc-700/60',
      icon: <EyeOff size={size === 'xs' ? 10 : 12} />,
      defaultText: 'Draft',
    },
    admin: {
      style: 'bg-rose-500/15 text-rose-400 border-rose-500/30',
      icon: <Shield size={size === 'xs' ? 10 : 12} />,
      defaultText: 'Admin',
    },
    user: {
      style: 'bg-zinc-800/80 text-zinc-400 border-white/10',
      icon: <User size={size === 'xs' ? 10 : 12} />,
      defaultText: 'User',
    },
    category: {
      style: 'bg-surface-3 text-zinc-300 border-white/[0.08]',
      icon: null,
      defaultText: '',
    },
    language: {
      style: 'bg-surface-3 text-zinc-300 border-white/[0.08]',
      icon: <Globe size={size === 'xs' ? 10 : 12} className="text-zinc-400" />,
      defaultText: '',
    },
    custom: {
      style: 'bg-surface-3 text-zinc-200 border-white/10',
      icon: null,
      defaultText: '',
    },
  }[variant];

  const content = children || variantConfig.defaultText;
  const isClickable = Boolean(onClick);

  return (
    <span
      onClick={onClick}
      title={title}
      className={`inline-flex items-center font-semibold rounded-md border tracking-wide transition-colors ${
        variantConfig.style
      } ${sizeStyles} ${isClickable ? 'cursor-pointer hover:border-white/30' : ''} ${className}`}
    >
      {variantConfig.icon}
      <span>{content}</span>
    </span>
  );
};
