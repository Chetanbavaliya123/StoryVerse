import React from 'react';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  iconLeft?: React.ReactNode;
  iconRight?: React.ReactNode;
  required?: boolean;
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, iconLeft, iconRight, required, className = '', id, ...props }, ref) => {
    const inputId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined);

    return (
      <div className="flex flex-col gap-1.5 w-full">
        {label && (
          <label htmlFor={inputId} className="text-xs font-bold text-zinc-300 flex items-center gap-1">
            {label}
            {required && <span className="text-rose-400">*</span>}
          </label>
        )}
        <div className="relative flex items-center w-full">
          {iconLeft && (
            <div className="absolute left-3.5 flex items-center pointer-events-none text-zinc-400">
              {iconLeft}
            </div>
          )}
          <input
            ref={ref}
            id={inputId}
            className={`w-full bg-[#18181B] text-white placeholder-zinc-500 rounded-xl px-3.5 py-2.5 text-sm border transition-all duration-200 outline-none ${
              iconLeft ? 'pl-10' : ''
            } ${iconRight ? 'pr-10' : ''} ${
              error
                ? 'border-rose-500/50 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20'
                : 'border-white/10 focus:border-accent-coral focus:ring-2 focus:ring-accent-coral/20'
            } disabled:opacity-50 disabled:bg-[#121214] ${className}`}
            {...props}
          />
          {iconRight && (
            <div className="absolute right-3.5 flex items-center text-zinc-400">
              {iconRight}
            </div>
          )}
        </div>
        {error && <span className="text-xs font-medium text-rose-400">{error}</span>}
        {!error && helperText && <span className="text-xs text-zinc-400">{helperText}</span>}
      </div>
    );
  }
);

Input.displayName = 'Input';
