import React, { useEffect } from 'react';
import { X } from 'lucide-react';

export interface DrawerProps {
  isOpen: boolean;
  onClose: () => void;
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  badge?: React.ReactNode;
  children: React.ReactNode;
  footer?: React.ReactNode;
  width?: 'md' | 'lg' | 'xl' | '2xl';
}

export const Drawer: React.FC<DrawerProps> = ({
  isOpen,
  onClose,
  title,
  subtitle,
  badge,
  children,
  footer,
  width = 'xl',
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = '';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const widthStyles = {
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl',
    '2xl': 'max-w-2xl',
  }[width];

  return (
    <div className="fixed inset-0 z-50 overflow-hidden flex justify-end animate-in fade-in duration-200">
      {/* Backdrop */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-black/70 backdrop-blur-sm transition-opacity duration-300"
      />

      {/* Drawer Panel */}
      <div
        className={`relative w-full ${widthStyles} h-full bg-[#121214] border-l border-white/[0.09] shadow-2xl flex flex-col z-10 animate-in slide-in-from-right duration-300 ease-out`}
      >
        {/* Header */}
        <div className="p-6 border-b border-white/[0.07] flex items-start justify-between gap-4 bg-surface-2/60 backdrop-blur-md shrink-0">
          <div className="flex flex-col gap-1 min-w-0">
            <div className="flex items-center gap-2.5">
              <h2 className="text-lg font-bold text-white tracking-tight truncate">{title}</h2>
              {badge}
            </div>
            {subtitle && <p className="text-xs text-zinc-400 leading-relaxed">{subtitle}</p>}
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-xl text-zinc-400 hover:text-white hover:bg-white/10 transition-colors shrink-0"
            title="Close (Esc)"
          >
            <X size={18} />
          </button>
        </div>

        {/* Scrollable Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">{children}</div>

        {/* Sticky Footer */}
        {footer && (
          <div className="p-4 px-6 border-t border-white/[0.07] bg-surface-2/80 backdrop-blur-md flex items-center justify-end gap-3 shrink-0">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
};
