import React, { useEffect } from 'react';
import { X } from 'lucide-react';

export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  children: React.ReactNode;
  footer?: React.ReactNode;
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl';
}

export const Modal: React.FC<ModalProps> = ({
  isOpen,
  onClose,
  title,
  subtitle,
  children,
  footer,
  maxWidth = 'md',
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

  const maxWidthStyles = {
    sm: 'max-w-sm',
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl',
    '2xl': 'max-w-2xl',
    '3xl': 'max-w-3xl',
    '4xl': 'max-w-4xl',
  }[maxWidth];

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4 animate-in fade-in duration-200">
      {/* Backdrop */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-black/75 backdrop-blur-md transition-opacity duration-300"
      />

      {/* Modal Dialog */}
      <div
        className={`relative w-full ${maxWidthStyles} bg-[#121214] border border-white/[0.1] rounded-2xl shadow-2xl overflow-hidden z-10 animate-in zoom-in-95 duration-200 ease-out`}
      >
        {/* Header */}
        <div className="p-5 px-6 border-b border-white/[0.07] flex items-start justify-between gap-4 bg-surface-2/40">
          <div className="flex flex-col min-w-0">
            <h3 className="text-lg font-bold text-white tracking-tight truncate">{title}</h3>
            {subtitle && <p className="text-xs text-zinc-400 mt-0.5 leading-relaxed">{subtitle}</p>}
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-zinc-400 hover:text-white hover:bg-white/10 transition-colors shrink-0"
            title="Close"
          >
            <X size={18} />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-4 max-h-[75vh] overflow-y-auto">{children}</div>

        {/* Footer */}
        {footer && (
          <div className="p-4 px-6 border-t border-white/[0.07] bg-white/[0.01] flex items-center justify-end gap-3">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
};
