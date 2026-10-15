import React, { useEffect, useState } from 'react';
import { Outlet, NavLink, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { auth, db } from '../lib/firebase';
import { signOut } from 'firebase/auth';
import { collection, onSnapshot, query } from 'firebase/firestore';
import {
  LayoutDashboard,
  BookOpen,
  Users,
  LogOut,
  Plus,
  Search,
  ChevronRight,
  PanelLeftClose,
  PanelLeft,
  Bell,
  Sparkles,
  Database,
  Cloud,
} from 'lucide-react';
import { CommandPalette } from './ui/CommandPalette';

export default function Layout() {
  const { user, role } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [userCount, setUserCount] = useState<number | null>(null);
  const [storyCount, setStoryCount] = useState<number | null>(null);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [isCommandPaletteOpen, setIsCommandPaletteOpen] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
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

  // Listen for Ctrl+K / Cmd+K
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setIsCommandPaletteOpen((prev) => !prev);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  const handleLogout = async () => {
    await signOut(auth);
    navigate('/login');
  };

  // Breadcrumbs determination
  const getBreadcrumbs = () => {
    const path = location.pathname;
    if (path === '/') return [{ label: 'Dashboard', path: '/' }];
    if (path === '/stories') return [{ label: 'Stories', path: '/stories' }];
    if (path === '/stories/add')
      return [
        { label: 'Stories', path: '/stories' },
        { label: 'Create New Story', path: '/stories/add' },
      ];
    if (path.startsWith('/stories/'))
      return [
        { label: 'Stories', path: '/stories' },
        { label: 'Edit Story', path },
      ];
    if (path === '/users') return [{ label: 'Users', path: '/users' }];
    return [{ label: 'CMS', path: '/' }];
  };

  const breadcrumbs = getBreadcrumbs();

  return (
    <div className="flex w-full min-h-screen bg-[#0A0A0B] text-white overflow-hidden font-body-md">
      {/* Mobile Menu Backdrop */}
      {isMobileMenuOpen && (
        <div
          onClick={() => setIsMobileMenuOpen(false)}
          className="fixed inset-0 z-40 bg-black/80 backdrop-blur-sm lg:hidden"
        />
      )}

      {/* Left Sidebar */}
      <aside
        className={`fixed lg:static top-0 bottom-0 left-0 z-50 flex flex-col justify-between bg-[#101012] border-r border-white/[0.08] transition-all duration-300 ease-out select-none ${
          isSidebarCollapsed ? 'w-20' : 'w-64'
        } ${
          isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
        <div className="flex flex-col gap-5 p-3.5">
          {/* Brand Header */}
          <div className="flex items-center justify-between px-2.5 py-2">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-[#E53935] to-[#FF6B4A] flex items-center justify-center shadow-lg shadow-rose-950/50 shrink-0 border border-white/20">
                <Sparkles size={16} className="text-white fill-white/30" />
              </div>
              {!isSidebarCollapsed && (
                <div className="flex flex-col min-w-0">
                  <div className="flex items-center gap-1.5">
                    <span className="font-extrabold text-sm tracking-tight text-white truncate">
                      StoryVerse
                    </span>
                    <span className="text-[10px] font-black tracking-widest px-1.5 py-0.2 bg-rose-500/15 text-rose-400 border border-rose-500/30 rounded">
                      CMS
                    </span>
                  </div>
                  <span className="text-[10px] font-semibold text-zinc-400 uppercase tracking-widest">
                    Studio Suite
                  </span>
                </div>
              )}
            </div>

            {/* Sidebar collapse button (desktop) */}
            <button
              onClick={() => setIsSidebarCollapsed((prev) => !prev)}
              className="hidden lg:flex p-1.5 text-zinc-400 hover:text-white rounded-lg hover:bg-white/[0.06] transition-colors"
              title={isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar'}
            >
              {isSidebarCollapsed ? <PanelLeft size={16} /> : <PanelLeftClose size={16} />}
            </button>
          </div>

          {/* Quick Create Story button */}
          {!isSidebarCollapsed ? (
            <button
              onClick={() => {
                navigate('/stories/add');
                setIsMobileMenuOpen(false);
              }}
              className="w-full flex items-center justify-center gap-2 py-2 px-3 rounded-xl bg-gradient-to-r from-[#E53935] to-[#FF6B4A] text-white text-xs font-bold shadow-lg shadow-rose-950/40 hover:shadow-rose-900/60 hover:-translate-y-0.5 transition-all border border-white/10"
            >
              <Plus size={15} />
              <span>Create Story</span>
            </button>
          ) : (
            <button
              onClick={() => {
                navigate('/stories/add');
                setIsMobileMenuOpen(false);
              }}
              className="w-10 h-10 mx-auto rounded-xl bg-gradient-to-r from-[#E53935] to-[#FF6B4A] text-white flex items-center justify-center shadow-md hover:scale-105 transition-transform"
              title="Create Story"
            >
              <Plus size={18} />
            </button>
          )}

          {/* Navigation Groups */}
          <nav className="flex flex-col gap-6 pt-2">
            {/* Overview Section */}
            <div className="flex flex-col gap-1">
              {!isSidebarCollapsed && (
                <span className="px-3 text-[10px] font-bold uppercase tracking-wider text-zinc-400">
                  Overview
                </span>
              )}
              <NavLink
                to="/"
                end
                onClick={() => setIsMobileMenuOpen(false)}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-3 py-2.5 rounded-xl font-medium text-xs transition-all relative ${
                    isActive
                      ? 'bg-gradient-to-r from-rose-500/15 to-transparent text-white border border-rose-500/30'
                      : 'text-zinc-400 hover:bg-white/[0.04] hover:text-zinc-200'
                  } ${isSidebarCollapsed ? 'justify-center px-0' : ''}`
                }
                title="Dashboard"
              >
                {({ isActive }) => (
                  <>
                    <LayoutDashboard
                      size={18}
                      className={isActive ? 'text-rose-400' : 'text-zinc-400'}
                    />
                    {!isSidebarCollapsed && <span>Dashboard</span>}
                    {isActive && (
                      <span className="absolute left-0 top-2 bottom-2 w-1 bg-gradient-to-b from-[#E53935] to-[#FF6B4A] rounded-r-full" />
                    )}
                  </>
                )}
              </NavLink>
            </div>

            {/* Content Section */}
            <div className="flex flex-col gap-1">
              {!isSidebarCollapsed && (
                <span className="px-3 text-[10px] font-bold uppercase tracking-wider text-zinc-400">
                  Content
                </span>
              )}
              <NavLink
                to="/stories"
                onClick={() => setIsMobileMenuOpen(false)}
                className={({ isActive }) =>
                  `flex items-center justify-between px-3 py-2.5 rounded-xl font-medium text-xs transition-all relative ${
                    isActive
                      ? 'bg-gradient-to-r from-rose-500/15 to-transparent text-white border border-rose-500/30'
                      : 'text-zinc-400 hover:bg-white/[0.04] hover:text-zinc-200'
                  } ${isSidebarCollapsed ? 'justify-center px-0' : ''}`
                }
                title="Stories Library"
              >
                {({ isActive }) => (
                  <>
                    <div className="flex items-center gap-3 min-w-0">
                      <BookOpen
                        size={18}
                        className={isActive ? 'text-rose-400' : 'text-zinc-400'}
                      />
                      {!isSidebarCollapsed && <span>Stories</span>}
                    </div>
                    {!isSidebarCollapsed && storyCount !== null && (
                      <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-surface-3 text-zinc-300 border border-white/[0.06]">
                        {storyCount}
                      </span>
                    )}
                    {isActive && (
                      <span className="absolute left-0 top-2 bottom-2 w-1 bg-gradient-to-b from-[#E53935] to-[#FF6B4A] rounded-r-full" />
                    )}
                  </>
                )}
              </NavLink>
            </div>

            {/* Audience Section */}
            <div className="flex flex-col gap-1">
              {!isSidebarCollapsed && (
                <span className="px-3 text-[10px] font-bold uppercase tracking-wider text-zinc-400">
                  Audience
                </span>
              )}
              <NavLink
                to="/users"
                onClick={() => setIsMobileMenuOpen(false)}
                className={({ isActive }) =>
                  `flex items-center justify-between px-3 py-2.5 rounded-xl font-medium text-xs transition-all relative ${
                    isActive
                      ? 'bg-gradient-to-r from-rose-500/15 to-transparent text-white border border-rose-500/30'
                      : 'text-zinc-400 hover:bg-white/[0.04] hover:text-zinc-200'
                  } ${isSidebarCollapsed ? 'justify-center px-0' : ''}`
                }
                title="Users Management"
              >
                {({ isActive }) => (
                  <>
                    <div className="flex items-center gap-3 min-w-0">
                      <Users
                        size={18}
                        className={isActive ? 'text-rose-400' : 'text-zinc-400'}
                      />
                      {!isSidebarCollapsed && <span>Users</span>}
                    </div>
                    {!isSidebarCollapsed && userCount !== null && (
                      <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-surface-3 text-zinc-300 border border-white/[0.06]">
                        {userCount}
                      </span>
                    )}
                    {isActive && (
                      <span className="absolute left-0 top-2 bottom-2 w-1 bg-gradient-to-b from-[#E53935] to-[#FF6B4A] rounded-r-full" />
                    )}
                  </>
                )}
              </NavLink>
            </div>
          </nav>
        </div>

        {/* Bottom Profile Area */}
        <div className="p-3 border-t border-white/[0.07] bg-surface-2/40">
          {!isSidebarCollapsed ? (
            <div className="p-2 rounded-xl bg-surface-2 border border-white/[0.08] flex items-center justify-between gap-2">
              <div className="flex items-center gap-2.5 min-w-0">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-rose-500/20 to-orange-500/20 border border-rose-500/30 flex items-center justify-center text-xs font-bold text-rose-400 uppercase shrink-0">
                  {user?.email?.slice(0, 2) || 'AD'}
                </div>
                <div className="flex flex-col min-w-0">
                  <span className="text-xs font-bold text-white truncate max-w-[110px]">
                    {user?.email?.split('@')[0] || 'Admin'}
                  </span>
                  <span className="text-[10px] font-semibold text-rose-400 uppercase tracking-wider">
                    {role || 'Administrator'}
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-1 shrink-0">
                <button
                  onClick={handleLogout}
                  className="p-1.5 text-zinc-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors"
                  title="Sign Out"
                >
                  <LogOut size={15} />
                </button>
              </div>
            </div>
          ) : (
            <div className="flex flex-col items-center gap-2">
              <div
                className="w-9 h-9 rounded-full bg-rose-500/20 border border-rose-500/30 flex items-center justify-center text-xs font-bold text-rose-400 uppercase"
                title={user?.email || 'Admin'}
              >
                {user?.email?.slice(0, 2) || 'AD'}
              </div>
              <button
                onClick={handleLogout}
                className="p-2 text-zinc-400 hover:text-rose-400 rounded-lg hover:bg-rose-500/10"
                title="Sign Out"
              >
                <LogOut size={16} />
              </button>
            </div>
          )}
        </div>
      </aside>

      {/* Main Content Area with TopBar */}
      <div className="flex-1 flex flex-col min-w-0 h-screen overflow-hidden bg-[#0A0A0B]">
        {/* TopBar */}
        <header className="h-14 shrink-0 bg-[#101012]/80 backdrop-blur-md border-b border-white/[0.08] px-6 flex items-center justify-between gap-4 z-30">
          {/* Left: Mobile hamburger + Breadcrumbs */}
          <div className="flex items-center gap-3 min-w-0">
            <button
              onClick={() => setIsMobileMenuOpen(true)}
              className="p-1.5 rounded-lg text-zinc-400 hover:text-white lg:hidden hover:bg-white/10"
              title="Open Menu"
            >
              <PanelLeft size={18} />
            </button>

            <nav className="flex items-center gap-1.5 text-xs text-zinc-400 min-w-0 truncate">
              {breadcrumbs.map((crumb, idx) => (
                <React.Fragment key={crumb.path}>
                  {idx > 0 && <ChevronRight size={12} className="text-zinc-600 shrink-0" />}
                  <span
                    onClick={() => navigate(crumb.path)}
                    className={`cursor-pointer transition-colors truncate ${
                      idx === breadcrumbs.length - 1
                        ? 'text-white font-bold'
                        : 'hover:text-zinc-200'
                    }`}
                  >
                    {crumb.label}
                  </span>
                </React.Fragment>
              ))}
            </nav>
          </div>

          {/* Right: Search, System Status, Quick Actions */}
          <div className="flex items-center gap-3 shrink-0">
            {/* Quick Command Palette trigger */}
            <button
              onClick={() => setIsCommandPaletteOpen(true)}
              className="flex items-center gap-2.5 px-3 py-1.5 rounded-xl bg-surface-2 hover:bg-surface-3 border border-white/[0.08] text-xs text-zinc-400 hover:text-zinc-200 transition-colors shadow-sm"
              title="Quick Search (Ctrl+K)"
            >
              <Search size={14} className="text-zinc-400" />
              <span className="hidden sm:inline">Search stories, actions...</span>
              <kbd className="hidden sm:inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded bg-surface-3 text-[10px] font-mono text-zinc-400 border border-white/10">
                ⌘K
              </kbd>
            </button>

            {/* Live Status Indicators */}
            <div className="hidden md:flex items-center gap-3 px-3 py-1 bg-surface-2 rounded-xl border border-white/[0.08] text-[11px] font-semibold text-zinc-400">
              <span className="flex items-center gap-1.5" title="Firestore Connected">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                <Database size={12} className="text-zinc-400" />
                <span>Firestore</span>
              </span>
              <span className="w-px h-3 bg-white/10" />
              <span className="flex items-center gap-1.5" title="Supabase Storage Ready">
                <span className="w-2 h-2 rounded-full bg-emerald-400" />
                <Cloud size={12} className="text-zinc-400" />
                <span>Supabase</span>
              </span>
            </div>

            {/* Notifications Bell */}
            <button
              onClick={() => setIsCommandPaletteOpen(true)}
              className="relative p-2 rounded-xl text-zinc-400 hover:text-white hover:bg-white/[0.06] transition-colors"
              title="Quick Search & Actions"
            >
              <Bell size={17} />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-rose-500" />
            </button>
          </div>
        </header>

        {/* Page Canvas with Custom Scrollbar */}
        <main className="flex-1 overflow-y-auto px-6 lg:px-8 py-6">
          <Outlet />
        </main>
      </div>

      {/* Global Command Palette */}
      <CommandPalette
        isOpen={isCommandPaletteOpen}
        onClose={() => setIsCommandPaletteOpen(false)}
      />
    </div>
  );
}
