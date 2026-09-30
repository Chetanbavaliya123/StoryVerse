import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { auth, db } from '../lib/firebase';
import { doc, getDoc } from 'firebase/firestore';
import { Lock, Eye, EyeOff } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      
      try {
        const userDoc = await getDoc(doc(db, 'users', userCredential.user.uid));

        if (!userDoc.exists()) {
          await signOut(auth);
          setError(`Access denied. No Firestore document found in 'users' collection for UID: ${userCredential.user.uid}. Please create the document manually in your Firebase Console.`);
          return;
        }

        if (userDoc.data().role !== 'admin') {
          await signOut(auth);
          setError(`Access denied. Your Firestore role is "${userDoc.data().role}", but "admin" is required.`);
          return;
        }
      } catch (dbErr: any) {
        // If we can't read the user document, sign out and show error
        await signOut(auth);
        setError(dbErr.message || 'Failed to verify admin status.');
        return;
      }

      navigate('/');
    } catch (err: any) {
      setError(err.message || 'Incorrect email or password.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-surface-container-lowest py-8 px-4">
      <div className="w-full max-w-md p-8 bg-surface rounded-2xl border border-surface-container shadow-2xl flex flex-col gap-6">
        <div className="flex flex-col items-center gap-2">
          <div className="w-12 h-12 rounded-xl bg-primary-container flex items-center justify-center mb-2">
            <Lock className="text-on-primary-container" size={24} />
          </div>
          <h1 className="text-display-mobile font-bold text-on-surface">Admin Portal</h1>
          <p className="text-on-surface-variant text-center">Sign in to StoryVerse Production Studio</p>
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
              placeholder="Enter your admin email"
              className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary focus:outline-none transition-colors"
              required
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">Password</label>
            <div className="relative">
              <input 
                type={showPassword ? "text" : "password"} 
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="Enter your password"
                className="w-full bg-surface-container pl-4 pr-12 py-3 rounded-lg border border-surface-container-high focus:border-primary focus:outline-none transition-colors"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-on-surface"
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <button 
            type="submit" 
            disabled={loading}
            className="w-full mt-2 bg-primary text-on-primary py-3 rounded-full font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors disabled:opacity-50"
          >
            {loading ? 'Authenticating...' : 'Sign In'}
          </button>
        </form>

      </div>
    </div>
  );
}
