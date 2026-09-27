import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth, db } from '../lib/firebase';
import { doc, getDoc } from 'firebase/firestore';
import { Lock } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await signInWithEmailAndPassword(auth, email, password);
      // We navigate immediately. AuthContext will handle the role check on the next screen.
      navigate('/');
    } catch (err: any) {
      setError(err.message || 'Failed to login');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-surface-container-lowest">
      <div className="w-full max-w-md p-8 bg-surface rounded-2xl border border-surface-container shadow-2xl flex flex-col gap-6">
        <div className="flex flex-col items-center gap-2">
          <div className="w-12 h-12 rounded-xl bg-primary-container flex items-center justify-center mb-2">
            <Lock className="text-on-primary-container" size={24} />
          </div>
          <h1 className="text-display-mobile font-bold text-on-surface">Admin Portal</h1>
          <p className="text-on-surface-variant text-center">Sign in to StoryVerse Content Management System</p>
        </div>

        {error && (
          <div className="p-3 rounded bg-error-container text-on-error-container text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">Email Address</label>
            <input 
              type="email" 
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary focus:outline-none transition-colors"
              required
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">Password</label>
            <input 
              type="password" 
              value={password}
              onChange={e => setPassword(e.target.value)}
              className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary focus:outline-none transition-colors"
              required
            />
          </div>
          <button 
            type="submit" 
            disabled={loading}
            className="w-full mt-4 bg-primary text-on-primary py-3 rounded-full font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors disabled:opacity-50"
          >
            {loading ? 'Authenticating...' : 'Sign In'}
          </button>
          
          <button 
            type="button" 
            onClick={async () => {
              try {
                const cred = await import('firebase/auth').then(m => m.createUserWithEmailAndPassword(auth, email, password));
                await import('firebase/firestore').then(m => m.setDoc(m.doc(db, 'users', cred.user.uid), {
                  email: email,
                  role: 'admin',
                  createdAt: m.serverTimestamp()
                }));
                alert("Demo Admin Created! You will now be logged in.");
                navigate('/');
              } catch (err: any) {
                alert("Creation failed (user might already exist). Use normal login. " + err.message);
              }
            }}
            className="w-full mt-2 bg-surface-container text-on-surface py-3 rounded-full font-bold hover:bg-surface-container-highest transition-colors text-sm"
          >
            Create Demo Admin
          </button>
        </form>
      </div>
    </div>
  );
}
