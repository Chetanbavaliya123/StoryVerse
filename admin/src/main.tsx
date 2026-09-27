import { StrictMode, Component } from 'react'
import type { ErrorInfo, ReactNode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import './index.css'
import { AuthProvider } from './contexts/AuthContext.tsx'
import { isFirebaseConfigured } from './lib/firebase.ts'

class ErrorBoundary extends Component<{children: ReactNode}, {hasError: boolean, error: Error | null}> {
  constructor(props: {children: ReactNode}) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("Uncaught error:", error, errorInfo);
  }
  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-surface-container-lowest text-on-surface p-8">
          <div className="max-w-md p-8 bg-surface rounded-2xl border border-surface-container text-center flex flex-col gap-4">
            <h1 className="text-display-mobile text-error font-bold">Something went wrong</h1>
            <p className="text-on-surface-variant text-sm bg-surface-container p-4 rounded text-left overflow-auto max-h-32">
              {this.state.error?.toString()}
            </p>
            <button onClick={() => window.location.reload()} className="px-6 py-2 bg-primary text-on-primary rounded-full font-bold">
              Reload
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

function Root() {
  if (!isFirebaseConfigured) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-surface-container-lowest text-on-surface p-8">
        <div className="max-w-md p-8 bg-surface rounded-2xl border border-error text-center flex flex-col gap-4">
          <h1 className="text-headline-md text-error font-bold">Configuration Missing</h1>
          <p className="text-on-surface-variant">
            Firebase environment variables are missing. Please configure VITE_FIREBASE_API_KEY and related variables in Vercel.
          </p>
        </div>
      </div>
    );
  }
  return (
    <ErrorBoundary>
      <AuthProvider>
        <App />
      </AuthProvider>
    </ErrorBoundary>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Root />
  </StrictMode>,
)
