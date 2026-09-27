import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './contexts/AuthContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Stories from './pages/Stories';
import StoryEdit from './pages/StoryEdit';
import Users from './pages/Users';

function ProtectedRoute({ children, requireAdmin = false }: { children: React.ReactNode, requireAdmin?: boolean }) {
  const { user, role, loading } = useAuth();

  if (loading) return <div className="min-h-screen flex items-center justify-center">Loading...</div>;

  if (!user) return <Navigate to="/login" />;

  if (requireAdmin && role !== 'admin') {
    return (
      <div className="min-h-screen flex items-center justify-center flex-col gap-4 text-center">
        <h1 className="text-display text-primary">Access Denied</h1>
        <p className="text-on-surface-variant">You need administrator privileges to access this area.</p>
        <button 
          onClick={async () => {
            const { getAuth, signOut } = await import('firebase/auth');
            await signOut(getAuth());
            window.location.href = '/login';
          }} 
          className="px-6 py-2 bg-primary text-on-primary rounded font-bold hover:bg-primary-container transition-colors mt-2"
        >
          Sign Out & Return to Login
        </button>
      </div>
    );
  }

  return <>{children}</>;
}

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />

        <Route path="/" element={<ProtectedRoute requireAdmin={true}><Layout /></ProtectedRoute>}>
          <Route index element={<Dashboard />} />
          <Route path="stories" element={<Stories />} />
          <Route path="stories/add" element={<StoryEdit />} />
          <Route path="stories/:id" element={<StoryEdit />} />
          <Route path="users" element={<Users />} />
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
