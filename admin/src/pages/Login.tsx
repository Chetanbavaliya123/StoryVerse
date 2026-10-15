import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { auth, db } from '../lib/firebase';
import { doc, getDoc } from 'firebase/firestore';
import { Lock, Eye, EyeOff, Sparkles, AlertCircle, Shield } from 'lucide-react';
import { Button } from '../components/ui/Button';

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
          setError(
            `Access denied. No Firestore document found in 'users' collection for UID: ${userCredential.user.uid}.`
          );
          return;
        }

        if (userDoc.data().role !== 'admin') {
          await signOut(auth);
          setError(`Access denied. Your role is "${userDoc.data().role}", but "admin" is required.`);
          return;
        }
      } catch (dbErr: any) {
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
    <div className="min-h-screen flex items-center justify-center bg-surface-0 px-4 py-12 relative overflow-hidden">
      {/* Background radial glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-accent-coral/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md bg-surface-1 border border-white/[0.08] rounded-2xl shadow-2xl p-8 flex flex-col gap-6 relative z-10">
        {/* Brand Header */}
        <div className="flex flex-col items-center text-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-accent-coral to-accent-orange p-0.5 shadow-lg shadow-rose-950/40">
            <div className="w-full h-full bg-[#141416] rounded-[14px] flex items-center justify-center text-accent-coral">
              <Sparkles size={22} className="text-accent-coral" />
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <div className="flex items-center justify-center gap-2">
              <h1 className="text-xl font-bold text-white tracking-tight">StoryVerse CMS</h1>
              <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-accent-coral/15 text-accent-coral border border-accent-coral/25">
                Studio
              </span>
            </div>
            <p className="text-xs text-zinc-400">Production Studio & Episodic Content Management</p>
          </div>
        </div>

        {error && (
          <div className="p-3.5 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs flex items-start gap-2.5">
            <AlertCircle size={16} className="shrink-0 mt-0.5" />
            <span className="leading-relaxed">{error}</span>
          </div>
        )}

        {/* Login Form */}
        <form onSubmit={handleLogin} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-semibold text-zinc-300">Admin Email Address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@storyverse.com"
              className="w-full bg-surface-2 px-3.5 py-2.5 rounded-xl border border-white/[0.08] focus:border-accent-coral text-white placeholder:text-zinc-500 text-xs outline-none transition-colors"
              required
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-semibold text-zinc-300">Password</label>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••••"
                className="w-full bg-surface-2 pl-3.5 pr-10 py-2.5 rounded-xl border border-white/[0.08] focus:border-accent-coral text-white placeholder:text-zinc-500 text-xs outline-none transition-colors"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-white transition-colors"
              >
                {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          <Button
            type="submit"
            variant="primary"
            size="md"
            loading={loading}
            className="w-full mt-2"
            iconLeft={<Lock size={15} />}
          >
            {loading ? 'Authenticating...' : 'Sign In to Studio'}
          </Button>
        </form>

        {/* Security badge note */}
        <div className="pt-2 border-t border-white/[0.06] flex items-center justify-center gap-1.5 text-[11px] text-zinc-500">
          <Shield size={12} className="text-emerald-500/80" />
          <span>Role-gated admin portal with Firebase Authentication</span>
        </div>
      </div>
    </div>
  );
}
