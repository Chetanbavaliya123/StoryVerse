import React from 'react';
import { Loader2 } from 'lucide-react';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  iconLeft?: React.ReactNode;
  iconRight?: React.ReactNode;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      children,
      variant = 'secondary',
      size = 'md',
      loading = false,
      disabled,
      className = '',
      iconLeft,
      iconRight,
      leftIcon,
      rightIcon,
      ...props
    },
    ref
  ) => {
    const baseStyles =
      'inline-flex items-center justify-center font-semibold rounded-xl transition-all duration-200 select-none disabled:opacity-50 disabled:pointer-events-none active:scale-[0.98] outline-none focus-visible:ring-2 focus-visible:ring-accent-coral/50';

    const sizeStyles = {
      sm: 'text-xs px-3 py-1.5 gap-1.5 h-8',
      md: 'text-sm px-4 py-2 gap-2 h-10',
      lg: 'text-base px-5 py-2.5 gap-2.5 h-12',
    }[size];

    const variantStyles = {
      primary:
        'bg-gradient-to-r from-[#E53935] to-[#FF6B4A] hover:from-[#FF453A] hover:to-[#FF7A59] text-white shadow-lg shadow-rose-950/40 hover:shadow-rose-900/50 hover:-translate-y-0.5 border border-white/10',
      secondary:
        'bg-surface-2 hover:bg-surface-3 text-zinc-100 hover:text-white border border-white/[0.08] hover:border-white/[0.16] shadow-sm',
      outline:
        'bg-transparent hover:bg-white/[0.06] text-zinc-300 hover:text-white border border-white/[0.12] hover:border-white/[0.25]',
      ghost:
        'bg-transparent hover:bg-white/[0.06] text-zinc-400 hover:text-zinc-100 border border-transparent',
      danger:
        'bg-rose-500/15 hover:bg-rose-500/25 text-rose-400 hover:text-rose-300 border border-rose-500/30 hover:border-rose-500/50',
    }[variant];

    return (
      <button
        ref={ref}
        disabled={disabled || loading}
        className={`${baseStyles} ${sizeStyles} ${variantStyles} ${className}`}
        {...props}
      >
        {loading ? (
          <Loader2 size={size === 'sm' ? 14 : size === 'lg' ? 20 : 16} className="animate-spin" />
        ) : (
          iconLeft || leftIcon
        )}
        {children}
        {!loading && (iconRight || rightIcon)}
      </button>
    );
  }
);

Button.displayName = 'Button';
