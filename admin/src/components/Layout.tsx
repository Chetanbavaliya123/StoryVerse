import { useEffect, useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { auth, db } from '../lib/firebase';
import { signOut } from 'firebase/auth';
import { collection, onSnapshot, query } from 'firebase/firestore';
import { LayoutDashboard, BookOpen, Users, LogOut, Settings } from 'lucide-react';

export default function Layout() {
  const { user, role } = useAuth();
  const navigate = useNavigate();
  const [userCount, setUserCount] = useState<number | null>(null);
  const [storyCount, setStoryCount] = useState<number | null>(null);

  useEffect(() => {
    // We only care about counts here, but since other parts of the app listen to these collections,
    // they will likely hit local cache heavily, making this cheap.
    const unsubUsers = onSnapshot(query(collection(db, 'users')), (snapshot) => {
      setUserCount(snapshot.size);
    });
    
    const unsubStories = onSnapshot(query(collection(db, 'stories')), (snapshot) => {
      setStoryCount(snapshot.size);
    });

    return () => {
      unsubUsers();
      unsubStories();
    };
  }, []);

  const handleLogout = async () => {
    await signOut(auth);
    navigate('/login');
  };

  return (
    <div className="flex w-full min-h-screen bg-surface-container-lowest text-on-surface">
      {/* Left Sidebar */}
      <aside className="w-72 shrink-0 bg-surface-container-lowest flex flex-col justify-between p-4 border-r border-surface-container">
        <div className="flex flex-col gap-6">
          {/* Header */}
          <div className="flex items-center gap-3 px-2 py-3">
            <div className="w-8 h-8 rounded-lg bg-primary-container flex items-center justify-center shadow-md">
              <span className="material-symbols-outlined text-surface-container-lowest font-bold text-lg">play_shapes</span>
            </div>
            <div className="flex flex-col">
              <div className="flex items-center gap-1.5">
                <span className="font-headline-sm text-headline-sm font-bold tracking-tight">StoryVerse</span>
                <span className="font-label-sm text-label-sm uppercase tracking-widest px-1.5 py-0.5 rounded bg-surface-container-high text-primary font-bold">CMS</span>
              </div>
              <span className="font-label-sm text-label-sm text-outline tracking-wider uppercase">Production Studio</span>
            </div>
          </div>

          {/* Nav Links */}
          <nav className="flex flex-col gap-1">
            <NavLink to="/" className={({isActive}) => `flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors ${isActive ? 'bg-primary-container text-on-primary-container' : 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}`}>
              <LayoutDashboard size={20} />
              <span className="font-label-lg font-medium">Dashboard</span>
            </NavLink>
            <NavLink to="/stories" className={({isActive}) => `flex items-center justify-between px-3 py-2.5 rounded-lg transition-colors ${isActive ? 'bg-primary-container text-on-primary-container' : 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}`}>
              <div className="flex items-center gap-3">
                <BookOpen size={20} />
                <span className="font-label-lg font-medium">Stories</span>
              </div>
              {storyCount !== null && (
                <span className="text-xs font-bold bg-surface-container-highest px-2 py-0.5 rounded-full text-on-surface-variant">{storyCount}</span>
              )}
            </NavLink>
            <NavLink to="/users" className={({isActive}) => `flex items-center justify-between px-3 py-2.5 rounded-lg transition-colors ${isActive ? 'bg-primary-container text-on-primary-container' : 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}`}>
              <div className="flex items-center gap-3">
                <Users size={20} />
                <span className="font-label-lg font-medium">Users</span>
              </div>
              {userCount !== null && (
                <span className="text-xs font-bold bg-surface-container-highest px-2 py-0.5 rounded-full text-on-surface-variant">{userCount}</span>
              )}
            </NavLink>
          </nav>
        </div>

        {/* Bottom User Area */}
        <div className="flex flex-col gap-2 pt-4">
          <div className="p-2.5 rounded-lg bg-surface-container flex items-center justify-between">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-8 h-8 rounded-full bg-surface-container-highest flex items-center justify-center font-label-sm font-bold text-primary shrink-0 uppercase">
                {user?.email?.substring(0, 2) || 'AD'}
              </div>
              <div className="flex flex-col min-w-0">
                <span className="font-label-sm text-on-surface font-semibold truncate">{user?.email}</span>
                <span className="font-label-sm text-outline truncate uppercase">{role}</span>
              </div>
            </div>
            <div className="flex items-center gap-1 shrink-0">
              <button className="p-1.5 text-outline hover:text-on-surface transition-colors rounded hover:bg-surface-container-high" title="Settings">
                <Settings size={16} />
              </button>
              <button onClick={handleLogout} className="p-1.5 text-outline hover:text-primary-container transition-colors rounded hover:bg-surface-container-high" title="Sign Out">
                <LogOut size={16} />
              </button>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Canvas */}
      <main className="flex-1 flex flex-col min-w-0 bg-surface px-8 py-6 gap-6 h-screen overflow-y-auto">
        <Outlet />
      </main>
    </div>
  );
}
