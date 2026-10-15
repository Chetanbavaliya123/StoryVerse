import React, { createContext, useContext, useState, useCallback } from 'react';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';

export type ToastType = 'success' | 'error' | 'info';

export interface ToastItem {
  id: string;
  type: ToastType;
  title: string;
  description?: string;
  duration?: number;
  action?: {
    label: string;
    onClick: () => void;
  };
}

interface ToastContextValue {
  toast: (opts: Omit<ToastItem, 'id'>) => void;
  showToast: (opts: { type: ToastType; title: string; message?: string; description?: string }) => void;
  success: (title: string, description?: string, action?: ToastItem['action']) => void;
  error: (title: string, description?: string) => void;
  info: (title: string, description?: string) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const toast = useCallback(({ type, title, description, duration = 4000, action }: Omit<ToastItem, 'id'>) => {
    const id = Math.random().toString(36).substring(2, 9);
    setToasts((prev) => [...prev, { id, type, title, description, duration, action }]);

    if (duration > 0) {
      setTimeout(() => {
        removeToast(id);
      }, duration);
    }
  }, [removeToast]);

  const showToast = useCallback(({ type, title, message, description }: { type: ToastType; title: string; message?: string; description?: string }) => {
    toast({ type, title, description: message || description });
  }, [toast]);

  const success = useCallback((title: string, description?: string, action?: ToastItem['action']) => {
    toast({ type: 'success', title, description, action });
  }, [toast]);

  const error = useCallback((title: string, description?: string) => {
    toast({ type: 'error', title, description, duration: 6000 });
  }, [toast]);

  const info = useCallback((title: string, description?: string) => {
    toast({ type: 'info', title, description });
  }, [toast]);

  return (
    <ToastContext.Provider value={{ toast, showToast, success, error, info }}>
      {children}
      {/* Toast container floating in bottom-right */}
      <div className="fixed bottom-5 right-5 z-[9999] flex flex-col gap-2.5 max-w-sm w-full pointer-events-none">
        {toasts.map((t) => {
          const isSuccess = t.type === 'success';
          const isError = t.type === 'error';

          return (
            <div
              key={t.id}
              className={`pointer-events-auto flex items-start gap-3 p-3.5 rounded-xl shadow-2xl border transition-all duration-300 animate-in slide-in-from-bottom-3 backdrop-blur-xl ${
                isSuccess
                  ? 'bg-[#121814]/90 border-emerald-500/30 text-emerald-100 shadow-emerald-950/40'
                  : isError
                  ? 'bg-[#1C1214]/90 border-rose-500/30 text-rose-100 shadow-rose-950/40'
                  : 'bg-[#14151A]/90 border-white/10 text-zinc-100 shadow-black/60'
              }`}
            >
              <div className="shrink-0 mt-0.5">
                {isSuccess && <CheckCircle2 size={18} className="text-emerald-400" />}
                {isError && <AlertCircle size={18} className="text-rose-400" />}
                {!isSuccess && !isError && <Info size={18} className="text-sky-400" />}
              </div>

              <div className="flex-1 min-w-0">
                <p className="text-xs font-bold leading-tight">{t.title}</p>
                {t.description && (
                  <p className="text-[11px] text-zinc-400 mt-0.5 leading-snug line-clamp-2">{t.description}</p>
                )}
                {t.action && (
                  <button
                    onClick={() => {
                      t.action?.onClick();
                      removeToast(t.id);
                    }}
                    className="mt-2 text-xs font-bold underline hover:no-underline text-emerald-300 hover:text-emerald-200"
                  >
                    {t.action.label}
                  </button>
                )}
              </div>

              <button
                onClick={() => removeToast(t.id)}
                className="shrink-0 p-1 rounded-md text-zinc-400 hover:text-white hover:bg-white/10 transition-colors"
                title="Dismiss"
              >
                <X size={14} />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
};

export const useToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
};
