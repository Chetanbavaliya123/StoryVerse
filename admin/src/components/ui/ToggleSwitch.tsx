import React from 'react';

export interface ToggleSwitchProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  description?: string;
  disabled?: boolean;
  icon?: React.ReactNode;
  size?: 'sm' | 'md';
  className?: string;
}

export const ToggleSwitch: React.FC<ToggleSwitchProps> = ({
  checked,
  onChange,
  label,
  description,
  disabled = false,
  icon,
  size = 'md',
  className = '',
}) => {
  const switchWidth = size === 'sm' ? 'w-9 h-5' : 'w-11 h-6';
  const knobSize = size === 'sm' ? 'w-4 h-4' : 'w-5 h-5';
  const knobTranslate = size === 'sm' ? 'translate-x-4' : 'translate-x-5';

  return (
    <label
      className={`group flex items-start gap-3 cursor-pointer select-none ${
        disabled ? 'opacity-50 pointer-events-none' : ''
      } ${className}`}
    >
      <div className="relative inline-flex items-center mt-0.5 shrink-0">
        <input
          type="checkbox"
          checked={checked}
          disabled={disabled}
          onChange={(e) => onChange(e.target.checked)}
          className="sr-only"
        />
        <div
          className={`${switchWidth} rounded-full transition-colors duration-200 ease-in-out border border-white/10 ${
            checked
              ? 'bg-gradient-to-r from-[#E53935] to-[#FF6B4A] shadow-md shadow-rose-950/40'
              : 'bg-zinc-800 group-hover:bg-zinc-700'
          }`}
        >
          <div
            className={`${knobSize} rounded-full bg-white shadow-md transform transition-transform duration-200 ease-in-out ${
              checked ? knobTranslate : 'translate-x-0.5'
            } mt-[1px]`}
          />
        </div>
      </div>

      {(label || description) && (
        <div className="flex flex-col min-w-0">
          {label && (
            <span className="text-sm font-semibold text-zinc-100 flex items-center gap-1.5 group-hover:text-white transition-colors">
              {icon}
              {label}
            </span>
          )}
          {description && <span className="text-xs text-zinc-400 mt-0.5 leading-relaxed">{description}</span>}
        </div>
      )}
    </label>
  );
};
