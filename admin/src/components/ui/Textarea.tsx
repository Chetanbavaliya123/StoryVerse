import React from 'react';

export interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  helperText?: string;
  maxLength?: number;
  showCharCount?: boolean;
  required?: boolean;
}

export const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  (
    {
      label,
      error,
      helperText,
      maxLength,
      showCharCount = false,
      required,
      className = '',
      id,
      value,
      ...props
    },
    ref
  ) => {
    const textareaId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined);
    const currentLength = typeof value === 'string' ? value.length : 0;
    const isNearLimit = maxLength ? currentLength >= maxLength * 0.9 : false;

    return (
      <div className="flex flex-col gap-1.5 w-full">
        <div className="flex items-center justify-between">
          {label && (
            <label htmlFor={textareaId} className="text-xs font-bold text-zinc-300 flex items-center gap-1">
              {label}
              {required && <span className="text-rose-400">*</span>}
            </label>
          )}
          {showCharCount && maxLength && (
            <span
              className={`text-[11px] font-semibold tabular-nums ${
                isNearLimit ? 'text-amber-400' : 'text-zinc-500'
              }`}
            >
              {currentLength} / {maxLength}
            </span>
          )}
        </div>
        <textarea
          ref={ref}
          id={textareaId}
          value={value}
          maxLength={maxLength}
          className={`w-full bg-[#18181B] text-white placeholder-zinc-500 rounded-xl p-3.5 text-sm border transition-all duration-200 outline-none resize-y min-h-[90px] ${
            error
              ? 'border-rose-500/50 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20'
              : 'border-white/10 focus:border-accent-coral focus:ring-2 focus:ring-accent-coral/20'
          } disabled:opacity-50 disabled:bg-[#121214] ${className}`}
          {...props}
        />
        {error && <span className="text-xs font-medium text-rose-400">{error}</span>}
        {!error && helperText && <span className="text-xs text-zinc-400">{helperText}</span>}
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';
