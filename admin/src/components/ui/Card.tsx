import React from 'react';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  hoverLift?: boolean;
  glow?: boolean;
  variant?: 'default' | 'surface-2' | 'glass';
}

export const Card: React.FC<CardProps> = ({
  children,
  className = '',
  hoverLift = false,
  glow = false,
  variant = 'default',
  ...props
}) => {
  const variantStyles = {
    default: 'bg-surface-1 border border-white/[0.07]',
    'surface-2': 'bg-surface-2 border border-white/[0.09]',
    glass: 'glass-panel',
  }[variant];

  return (
    <div
      className={`rounded-2xl transition-all duration-200 ${variantStyles} ${
        hoverLift ? 'hover:-translate-y-0.5 hover:border-white/[0.14] hover:shadow-xl hover:shadow-black/40' : ''
      } ${glow ? 'glow-coral-sm border-accent-coral/30' : ''} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

export const CardHeader: React.FC<{
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  action?: React.ReactNode;
  icon?: React.ReactNode;
  className?: string;
}> = ({ title, subtitle, action, icon, className = '' }) => {
  return (
    <div className={`p-5 flex items-start justify-between gap-4 border-b border-white/[0.05] ${className}`}>
      <div className="flex items-center gap-3 min-w-0">
        {icon && (
          <div className="w-9 h-9 rounded-xl bg-surface-2 border border-white/[0.08] flex items-center justify-center text-accent-coral shrink-0 shadow-inner">
            {icon}
          </div>
        )}
        <div className="flex flex-col min-w-0">
          <h3 className="text-base font-bold text-white tracking-tight truncate">{title}</h3>
          {subtitle && <p className="text-xs text-zinc-400 mt-0.5 leading-relaxed">{subtitle}</p>}
        </div>
      </div>
      {action && <div className="shrink-0">{action}</div>}
    </div>
  );
};

export const CardContent: React.FC<{ children: React.ReactNode; className?: string }> = ({
  children,
  className = '',
}) => {
  return <div className={`p-5 ${className}`}>{children}</div>;
};

export const CardFooter: React.FC<{ children: React.ReactNode; className?: string }> = ({
  children,
  className = '',
}) => {
  return (
    <div className={`p-4 px-5 border-t border-white/[0.05] bg-white/[0.01] rounded-b-2xl flex items-center justify-between gap-3 ${className}`}>
      {children}
    </div>
  );
};
