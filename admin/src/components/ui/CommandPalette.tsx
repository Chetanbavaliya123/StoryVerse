import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, LayoutDashboard, BookOpen, Users, Plus, Film, X, Loader2 } from 'lucide-react';
import { collection, getDocs, limit, query } from 'firebase/firestore';
import { db } from '../../lib/firebase';

export interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CommandPalette: React.FC<CommandPaletteProps> = ({ isOpen, onClose }) => {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [stories, setStories] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  // Fetch quick list of stories when palette opens
  useEffect(() => {
    if (isOpen) {
      setSearch('');
      setSelectedIndex(0);
      setLoading(true);
      const fetchTopStories = async () => {
        try {
          const snap = await getDocs(query(collection(db, 'stories'), limit(25)));
          setStories(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        } catch (_) {}
        setLoading(false);
      };
      fetchTopStories();
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isOpen]);

  // Global Ctrl+K / Cmd+K listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        if (isOpen) onClose();
      }
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  // Filter actions & stories
  const staticActions = [
    {
      id: 'nav-dashboard',
      title: 'Go to Dashboard',
      category: 'Navigation',
      icon: <LayoutDashboard size={16} />,
      onSelect: () => {
        navigate('/');
        onClose();
      },
    },
    {
      id: 'nav-stories',
      title: 'Browse Stories',
      category: 'Navigation',
      icon: <BookOpen size={16} />,
      onSelect: () => {
        navigate('/stories');
        onClose();
      },
    },
    {
      id: 'action-add-story',
      title: 'Create New Story',
      category: 'Actions',
      icon: <Plus size={16} className="text-accent-coral" />,
      onSelect: () => {
        navigate('/stories/add');
        onClose();
      },
    },
    {
      id: 'nav-users',
      title: 'Manage Users',
      category: 'Navigation',
      icon: <Users size={16} />,
      onSelect: () => {
        navigate('/users');
        onClose();
      },
    },
  ];

  const filteredActions = staticActions.filter((a) =>
    a.title.toLowerCase().includes(search.toLowerCase())
  );

  const filteredStories = stories.filter((s) => {
    const q = search.toLowerCase();
    return (
      (s.title && s.title.toLowerCase().includes(q)) ||
      (s.genreId && s.genreId.toLowerCase().includes(q)) ||
      (s.language && s.language.toLowerCase().includes(q))
    );
  });

  const allItems = [
    ...filteredActions.map((a) => ({ ...a, type: 'action' })),
    ...filteredStories.slice(0, 8).map((s) => ({
      id: s.id,
      title: s.title || 'Untitled',
      subtitle: `${s.genreId || 'General'} • ${s.language || 'Hindi'} • ${s.totalEpisodes || 0} eps`,
      category: 'Stories',
      icon: <Film size={16} className="text-sky-400" />,
      type: 'story',
      onSelect: () => {
        navigate(`/stories/${s.id}`);
        onClose();
      },
    })),
  ];

  const handleKeyNav = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % (allItems.length || 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + (allItems.length || 1)) % (allItems.length || 1));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (allItems[selectedIndex]) {
        allItems[selectedIndex].onSelect();
      }
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto flex items-start justify-center p-4 pt-[12vh] animate-in fade-in duration-150">
      <div onClick={onClose} className="fixed inset-0 bg-black/80 backdrop-blur-md" />

      <div className="relative w-full max-w-xl bg-[#121214] border border-white/15 rounded-2xl shadow-2xl overflow-hidden z-10 flex flex-col">
        {/* Search Input */}
        <div className="flex items-center px-4 py-3.5 border-b border-white/10 gap-3">
          <Search size={18} className="text-zinc-400 shrink-0" />
          <input
            ref={inputRef}
            type="text"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setSelectedIndex(0);
            }}
            onKeyDown={handleKeyNav}
            placeholder="Type a command or search stories..."
            className="w-full bg-transparent text-white placeholder-zinc-500 text-sm outline-none"
          />
          {loading && <Loader2 size={16} className="text-accent-coral animate-spin shrink-0" />}
          {search && !loading && (
            <button onClick={() => setSearch('')} className="p-1 text-zinc-500 hover:text-zinc-300">
              <X size={14} />
            </button>
          )}
          <span className="text-[11px] font-mono text-zinc-400 bg-surface-2 px-1.5 py-0.5 rounded border border-white/10">
            ESC
          </span>
        </div>

        {/* Results list */}
        <div className="max-h-80 overflow-y-auto p-2 space-y-1">
          {allItems.length === 0 ? (
            <div className="p-8 text-center text-xs text-zinc-500">No results found for "{search}"</div>
          ) : (
            allItems.map((item, index) => {
              const isSelected = index === selectedIndex;
              return (
                <div
                  key={item.id}
                  onClick={item.onSelect}
                  onMouseEnter={() => setSelectedIndex(index)}
                  className={`flex items-center justify-between p-2.5 px-3 rounded-xl cursor-pointer transition-colors ${
                    isSelected ? 'bg-surface-3 text-white' : 'text-zinc-300 hover:bg-surface-2'
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="p-1.5 rounded-lg bg-surface-2 border border-white/10 shrink-0">
                      {item.icon}
                    </div>
                    <div className="flex flex-col min-w-0">
                      <span className="text-sm font-semibold truncate">{item.title}</span>
                      {'subtitle' in item && item.subtitle && (
                        <span className="text-xs text-zinc-400 truncate">{item.subtitle}</span>
                      )}
                    </div>
                  </div>

                  <span className="text-[10px] font-bold uppercase tracking-wider text-zinc-400 bg-surface-2 px-2 py-0.5 rounded border border-white/10 shrink-0 ml-2">
                    {item.category}
                  </span>
                </div>
              );
            })
          )}
        </div>

        {/* Footer shortcuts */}
        <div className="p-2.5 px-4 bg-surface-2/60 border-t border-white/10 flex items-center justify-between text-[11px] text-zinc-400">
          <div className="flex items-center gap-3">
            <span>
              <kbd className="px-1.5 py-0.5 bg-surface-3 border border-white/10 rounded font-mono">↑</kbd>{' '}
              <kbd className="px-1.5 py-0.5 bg-surface-3 border border-white/10 rounded font-mono">↓</kbd> Navigate
            </span>
            <span>
              <kbd className="px-1.5 py-0.5 bg-surface-3 border border-white/10 rounded font-mono">↵</kbd> Select
            </span>
          </div>
          <span>StoryVerse Quick Search</span>
        </div>
      </div>
    </div>
  );
};
