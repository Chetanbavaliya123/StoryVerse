import React from 'react';

export interface SegmentedOption<T extends string = string> {
  value: T;
  label: React.ReactNode;
  icon?: React.ReactNode;
}

export interface SegmentedControlProps<T extends string = string> {
  value: T;
  onChange: (value: T) => void;
  options: SegmentedOption<T>[];
  size?: 'sm' | 'md';
  className?: string;
  fullWidth?: boolean;
}

export function SegmentedControl<T extends string = string>({
  value,
  onChange,
  options,
  size = 'md',
  className = '',
  fullWidth = false,
}: SegmentedControlProps<T>) {
  const sizeStyles = {
    sm: 'p-0.5 text-xs h-8',
    md: 'p-1 text-xs h-10',
  }[size];

  const itemPadding = {
    sm: 'px-2.5 py-1',
    md: 'px-3.5 py-1.5',
  }[size];

  return (
    <div
      className={`inline-flex items-center bg-surface-2 rounded-xl border border-white/[0.08] ${sizeStyles} ${
        fullWidth ? 'w-full' : ''
      } ${className}`}
    >
      {options.map((opt) => {
        const isSelected = opt.value === value;
        return (
          <button
            key={opt.value}
            type="button"
            onClick={() => onChange(opt.value)}
            className={`flex items-center justify-center gap-1.5 font-bold rounded-lg transition-all duration-200 select-none ${itemPadding} ${
              fullWidth ? 'flex-1' : ''
            } ${
              isSelected
                ? 'bg-surface-3 text-white shadow-sm border border-white/[0.1] text-accent-coral'
                : 'text-zinc-400 hover:text-zinc-200 hover:bg-white/[0.04]'
            }`}
          >
            {opt.icon && <span className="shrink-0">{opt.icon}</span>}
            <span>{opt.label}</span>
          </button>
        );
      })}
    </div>
  );
}
