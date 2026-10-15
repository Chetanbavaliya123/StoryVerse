import { useEffect, useState, useMemo } from 'react';
import { collection, onSnapshot, doc, deleteDoc, updateDoc, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { useNavigate } from 'react-router-dom';
import {
  Search,
  Plus,
  Trash2,
  Edit,
  Eye,
  EyeOff,
  Layers,
  LayoutGrid,
  List as ListIcon,
  Star,
  Trophy,
  Copy,
  X,
} from 'lucide-react';
import { format } from 'date-fns';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Card } from '../components/ui/Card';
import { ImageFallback } from '../components/ui/ImageFallback';
import { SegmentedControl } from '../components/ui/SegmentedControl';
import { Modal } from '../components/ui/Modal';
import { useToast } from '../components/ui/ToastContext';

export default function Stories() {
  const navigate = useNavigate();
  const { success, error: toastError, info } = useToast();

  const [stories, setStories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // View state: 'table' | 'grid' | 'placements'
  const [viewMode, setViewMode] = useState<'table' | 'grid' | 'placements'>('table');

  // Filters & Search
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [genreFilter, setGenreFilter] = useState('all');
  const [languageFilter, setLanguageFilter] = useState('all');
  const [featureFilter, setFeatureFilter] = useState('all'); // all, hero, topTen, trending, new
  const [sortBy, setSortBy] = useState('newest');

  // Bulk Selection
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  // Delete Confirm Modal State
  const [storyToDelete, setStoryToDelete] = useState<any | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, 'stories'),
      (snapshot) => {
        const fetchedStories = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setStories(fetchedStories);
        setLoading(false);
      },
      (err) => {
        console.error('Error fetching stories:', err);
        toastError('Failed to load stories: ' + err.message);
        setLoading(false);
      }
    );
    return () => unsubscribe();
  }, [toastError]);

  const handleDelete = async () => {
    if (!storyToDelete) return;
    setIsDeleting(true);
    try {
      await deleteDoc(doc(db, 'stories', storyToDelete.id));
      success(`Story "${storyToDelete.title || 'Untitled'}" deleted.`);
      setStoryToDelete(null);
    } catch (err: any) {
      toastError('Failed to delete story: ' + err.message);
    } finally {
      setIsDeleting(false);
    }
  };

  const handleDuplicate = async (story: any) => {
    try {
      const copyData = {
        ...story,
        title: `${story.title || 'Untitled'} (Copy)`,
        status: 'draft',
        isPublished: false,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };
      delete copyData.id;
      const ref = await addDoc(collection(db, 'stories'), copyData);
      success('Story duplicated as Draft!', 'Click to edit new copy', {
        label: 'Open',
        onClick: () => navigate(`/stories/${ref.id}`),
      });
    } catch (err: any) {
      toastError('Failed to duplicate: ' + err.message);
    }
  };

  const togglePublish = async (id: string, currentStatus: string) => {
    const newStatus = currentStatus === 'published' ? 'draft' : 'published';
    try {
      await updateDoc(doc(db, 'stories', id), {
        status: newStatus,
        isPublished: newStatus === 'published',
        updatedAt: serverTimestamp(),
      });
      success(`Story marked as ${newStatus}`);
    } catch (err: any) {
      toastError('Failed to update status: ' + err.message);
    }
  };

  const toggleHero = async (id: string, currentHero: boolean) => {
    try {
      await updateDoc(doc(db, 'stories', id), {
        isPopular: !currentHero,
        isHero: !currentHero,
        updatedAt: serverTimestamp(),
      });
      info(
        !currentHero
          ? 'Featured in Hero Carousel'
          : 'Removed from Hero Carousel'
      );
    } catch (err: any) {
      toastError('Failed to toggle hero status: ' + err.message);
    }
  };

  // Bulk actions
  const handleBulkPublish = async (status: 'published' | 'draft') => {
    if (selectedIds.length === 0) return;
    try {
      await Promise.all(
        selectedIds.map((id) =>
          updateDoc(doc(db, 'stories', id), {
            status,
            isPublished: status === 'published',
            updatedAt: serverTimestamp(),
          })
        )
      );
      success(`Updated ${selectedIds.length} stories to ${status}`);
      setSelectedIds([]);
    } catch (err: any) {
      toastError('Bulk update failed: ' + err.message);
    }
  };

  const handleBulkDelete = async () => {
    if (selectedIds.length === 0) return;
    if (!window.confirm(`Are you sure you want to delete ${selectedIds.length} stories?`)) return;
    try {
      await Promise.all(selectedIds.map((id) => deleteDoc(doc(db, 'stories', id))));
      success(`Deleted ${selectedIds.length} stories`);
      setSelectedIds([]);
    } catch (err: any) {
      toastError('Bulk delete failed: ' + err.message);
    }
  };

  const clearAllFilters = () => {
    setSearchQuery('');
    setStatusFilter('all');
    setCategoryFilter('all');
    setGenreFilter('all');
    setLanguageFilter('all');
    setFeatureFilter('all');
    setSortBy('newest');
  };

  const hasActiveFilters =
    searchQuery !== '' ||
    statusFilter !== 'all' ||
    categoryFilter !== 'all' ||
    genreFilter !== 'all' ||
    languageFilter !== 'all' ||
    featureFilter !== 'all';

  // Filtered & sorted stories
  const filteredAndSortedStories = useMemo(() => {
    const result = stories.filter((story) => {
      const q = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !q ||
        (story.title && story.title.toLowerCase().includes(q)) ||
        (story.author && story.author.toLowerCase().includes(q));

      const isPub = story.status === 'published' || story.isPublished === true;
      let matchesStatus = true;
      if (statusFilter === 'published') matchesStatus = isPub;
      if (statusFilter === 'draft') matchesStatus = !isPub;

      let matchesCat = true;
      if (categoryFilter !== 'all') {
        matchesCat = (story.categoryId || '').toLowerCase() === categoryFilter.toLowerCase();
      }

      let matchesGenre = true;
      if (genreFilter !== 'all') {
        matchesGenre = (story.genreId || '').toLowerCase() === genreFilter.toLowerCase();
      }

      let matchesLanguage = true;
      if (languageFilter !== 'all') {
        const sl = (story.language || '').toLowerCase().trim();
        const ql = languageFilter.toLowerCase().trim();
        matchesLanguage = sl === ql;
      }

      let matchesFeature = true;
      if (featureFilter === 'trending') matchesFeature = story.isTrending === true;
      if (featureFilter === 'new') matchesFeature = story.isNew === true || story.isNewArrival === true;
      if (featureFilter === 'topTen') matchesFeature = story.isTopTen === true;
      if (featureFilter === 'popular' || featureFilter === 'hero')
        matchesFeature = story.isPopular === true || story.isHero === true;

      return (
        matchesSearch &&
        matchesStatus &&
        matchesCat &&
        matchesGenre &&
        matchesLanguage &&
        matchesFeature
      );
    });

    result.sort((a, b) => {
      const tA = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
      const tB = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;

      if (sortBy === 'newest') return tB - tA;
      if (sortBy === 'oldest') return tA - tB;
      if (sortBy === 'views') {
        const vA = a.totalViews || a.views || 0;
        const vB = b.totalViews || b.views || 0;
        return vB - vA;
      }
      if (sortBy === 'episodes') {
        const eA = a.totalEpisodes || a.episodeCount || 0;
        const eB = b.totalEpisodes || b.episodeCount || 0;
        return eB - eA;
      }
      if (sortBy === 'az') {
        const titleA = a.title?.toLowerCase() || '';
        const titleB = b.title?.toLowerCase() || '';
        return titleA.localeCompare(titleB);
      }
      return 0;
    });

    return result;
  }, [stories, searchQuery, statusFilter, categoryFilter, genreFilter, languageFilter, featureFilter, sortBy]);

  const toggleSelectAll = () => {
    if (selectedIds.length === filteredAndSortedStories.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(filteredAndSortedStories.map((s) => s.id));
    }
  };

  const toggleSelectRow = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  return (
    <div className="flex flex-col gap-6 pb-20">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-white tracking-tight flex items-center gap-2">
            Stories Library
          </h1>
          <p className="text-xs text-zinc-400 mt-1">
            Manage shows, episodes, categorization, and placement flags across the mobile app.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* View Mode Switcher */}
          <SegmentedControl
            value={viewMode}
            onChange={(v) => setViewMode(v as any)}
            options={[
              { value: 'table', label: 'Table', icon: <ListIcon size={14} /> },
              { value: 'grid', label: 'Posters', icon: <LayoutGrid size={14} /> },
              { value: 'placements', label: 'Placements', icon: <Layers size={14} /> },
            ]}
          />

          <Button
            variant="primary"
            iconLeft={<Plus size={16} />}
            onClick={() => navigate('/stories/add')}
          >
            Create Story
          </Button>
        </div>
      </div>

      {/* Toolbar: Search, Filters & Sort */}
      <Card className="p-4 flex flex-col gap-3">
        {/* Top search & sort row */}
        <div className="flex flex-col md:flex-row items-center gap-3">
          <div className="relative flex-1 w-full">
            <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-zinc-400 pointer-events-none" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by title, creator, or keyword..."
              className="w-full bg-[#18181B] text-white placeholder-zinc-500 rounded-xl pl-10 pr-4 py-2.5 text-xs border border-white/10 focus:border-accent-coral focus:ring-1 focus:ring-accent-coral/20 outline-none transition-all"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-white"
              >
                <X size={14} />
              </button>
            )}
          </div>

          <div className="flex items-center gap-2.5 w-full md:w-auto">
            {/* Sort Dropdown */}
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="bg-[#18181B] text-white text-xs font-semibold rounded-xl px-3 py-2.5 border border-white/10 outline-none cursor-pointer hover:border-white/20 transition-colors"
            >
              <option value="newest" className="bg-[#18181B] text-white">Sort: Newest First</option>
              <option value="oldest" className="bg-[#18181B] text-white">Sort: Oldest First</option>
              <option value="views" className="bg-[#18181B] text-white">Sort: Most Views</option>
              <option value="episodes" className="bg-[#18181B] text-white">Sort: Most Episodes</option>
              <option value="az" className="bg-[#18181B] text-white">Sort: Title A-Z</option>
            </select>
          </div>
        </div>

        {/* Filter Pills / Selectors */}
        <div className="flex flex-wrap items-center gap-2 pt-1 text-xs">
          {/* Status filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-[#18181B] text-white rounded-lg px-2.5 py-1.5 border border-white/10 outline-none text-xs cursor-pointer"
          >
            <option value="all" className="bg-[#18181B] text-white">Status: All</option>
            <option value="published" className="bg-[#18181B] text-white">Status: Published</option>
            <option value="draft" className="bg-[#18181B] text-white">Status: Drafts</option>
          </select>

          {/* Feature Badge filter */}
          <select
            value={featureFilter}
            onChange={(e) => setFeatureFilter(e.target.value)}
            className="bg-[#18181B] text-white rounded-lg px-2.5 py-1.5 border border-white/10 outline-none text-xs cursor-pointer"
          >
            <option value="all" className="bg-[#18181B] text-white">Feature: All Badges</option>
            <option value="hero" className="bg-[#18181B] text-white">⭐ Hero Carousel</option>
            <option value="topTen" className="bg-[#18181B] text-white">🏆 Top 10</option>
            <option value="trending" className="bg-[#18181B] text-white">🔥 Trending</option>
            <option value="new" className="bg-[#18181B] text-white">✨ New Arrivals</option>
          </select>

          {/* Category Filter */}
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="bg-[#18181B] text-white rounded-lg px-2.5 py-1.5 border border-white/10 outline-none text-xs cursor-pointer"
          >
            <option value="all" className="bg-[#18181B] text-white">Category: All</option>
            <option value="romance" className="bg-[#18181B] text-white">Romance</option>
            <option value="horror" className="bg-[#18181B] text-white">Horror</option>
            <option value="comedy" className="bg-[#18181B] text-white">Comedy</option>
            <option value="thriller" className="bg-[#18181B] text-white">Thriller</option>
            <option value="action" className="bg-[#18181B] text-white">Action</option>
            <option value="fantasy" className="bg-[#18181B] text-white">Fantasy</option>
            <option value="drama" className="bg-[#18181B] text-white">Drama</option>
            <option value="sci-fi" className="bg-[#18181B] text-white">Sci-Fi</option>
            <option value="adventure" className="bg-[#18181B] text-white">Adventure</option>
            <option value="mystery" className="bg-[#18181B] text-white">Mystery</option>
          </select>

          {/* Genre Filter */}
          <select
            value={genreFilter}
            onChange={(e) => setGenreFilter(e.target.value)}
            className="bg-[#18181B] text-white rounded-lg px-2.5 py-1.5 border border-white/10 outline-none text-xs cursor-pointer"
          >
            <option value="all" className="bg-[#18181B] text-white">Genre: All</option>
            <option value="romance" className="bg-[#18181B] text-white">Romance</option>
            <option value="horror" className="bg-[#18181B] text-white">Horror</option>
            <option value="comedy" className="bg-[#18181B] text-white">Comedy</option>
            <option value="thriller" className="bg-[#18181B] text-white">Thriller</option>
            <option value="action" className="bg-[#18181B] text-white">Action</option>
            <option value="fantasy" className="bg-[#18181B] text-white">Fantasy</option>
            <option value="drama" className="bg-[#18181B] text-white">Drama</option>
            <option value="sci-fi" className="bg-[#18181B] text-white">Sci-Fi</option>
            <option value="adventure" className="bg-[#18181B] text-white">Adventure</option>
            <option value="mystery" className="bg-[#18181B] text-white">Mystery</option>
            <option value="fable" className="bg-[#18181B] text-white">Fable</option>
          </select>

          {/* Language filter */}
          <select
            value={languageFilter}
            onChange={(e) => setLanguageFilter(e.target.value)}
            className="bg-[#18181B] text-white rounded-lg px-2.5 py-1.5 border border-white/10 outline-none text-xs cursor-pointer"
          >
            <option value="all" className="bg-[#18181B] text-white">Language: All</option>
            <option value="Hindi" className="bg-[#18181B] text-white">Hindi (हिंदी)</option>
            <option value="English" className="bg-[#18181B] text-white">English</option>
            <option value="Gujarati" className="bg-[#18181B] text-white">Gujarati (ગુજરાતી)</option>
            <option value="Marathi" className="bg-[#18181B] text-white">Marathi (मराठी)</option>
            <option value="Bengali" className="bg-[#18181B] text-white">Bengali (বাংলা)</option>
            <option value="Tamil" className="bg-[#18181B] text-white">Tamil (தமிழ்)</option>
            <option value="Telugu" className="bg-[#18181B] text-white">Telugu (తెలుగు)</option>
          </select>

          {hasActiveFilters && (
            <button
              onClick={clearAllFilters}
              className="text-xs font-bold text-rose-400 hover:text-rose-300 px-2 py-1 flex items-center gap-1 transition-colors ml-auto"
            >
              <X size={12} /> Clear all filters
            </button>
          )}
        </div>
      </Card>

      {/* Main Content Area */}
      {loading ? (
        <div className="p-12 text-center text-zinc-400">Loading catalog stories...</div>
      ) : filteredAndSortedStories.length === 0 ? (
        <Card className="p-12 text-center flex flex-col items-center justify-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-surface-2 border border-white/10 flex items-center justify-center text-zinc-500">
            <Search size={22} />
          </div>
          <h3 className="text-base font-bold text-white">No stories match your criteria</h3>
          <p className="text-xs text-zinc-400 max-w-sm">
            Try adjusting your search query, clearing filter chips, or adding a new story.
          </p>
          <Button variant="secondary" size="sm" onClick={clearAllFilters} className="mt-2">
            Reset Filters
          </Button>
        </Card>
      ) : viewMode === 'grid' ? (
        /* ---------------- POSTER GRID VIEW ---------------- */
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
          {filteredAndSortedStories.map((story) => {
            const isPub = story.status === 'published' || story.isPublished === true;
            const isHero = story.isPopular || story.isHero;
            const isSelected = selectedIds.includes(story.id);

            return (
              <div
                key={story.id}
                className={`group relative rounded-2xl bg-surface-1 border overflow-hidden flex flex-col transition-all duration-200 hover:-translate-y-1 hover:shadow-xl hover:shadow-black/50 ${
                  isSelected ? 'border-rose-500 ring-2 ring-rose-500/30' : 'border-white/[0.08] hover:border-white/20'
                }`}
              >
                {/* Poster 2:3 aspect container */}
                <div className="relative aspect-[2/3] w-full bg-surface-2 overflow-hidden">
                  <ImageFallback
                    src={story.thumbnailUrl}
                    fallbackTitle={story.title}
                    genre={story.genreId}
                    aspectRatio="2:3"
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />

                  {/* Gradient Overlay on Hover */}
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex flex-col justify-between p-2.5">
                    <div className="flex items-center justify-between">
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => toggleSelectRow(story.id)}
                        className="w-4 h-4 accent-rose-500 rounded cursor-pointer"
                      />
                      <button
                        onClick={() => toggleHero(story.id, !!isHero)}
                        className={`p-1.5 rounded-lg backdrop-blur-md transition-colors ${
                          isHero ? 'bg-sky-500 text-white' : 'bg-black/60 text-zinc-300 hover:text-white'
                        }`}
                        title="Toggle Hero Carousel"
                      >
                        <Star size={13} className={isHero ? 'fill-white' : ''} />
                      </button>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => navigate(`/stories/${story.id}`)}
                        className="flex-1 py-1.5 bg-white text-black font-bold text-xs rounded-lg flex items-center justify-center gap-1 shadow-md hover:bg-zinc-200 transition-colors"
                      >
                        <Edit size={12} /> Edit
                      </button>
                      <button
                        onClick={() => handleDuplicate(story)}
                        className="p-1.5 bg-black/70 text-zinc-200 hover:text-white rounded-lg backdrop-blur-md border border-white/20"
                        title="Duplicate"
                      >
                        <Copy size={13} />
                      </button>
                    </div>
                  </div>

                  {/* Badges Overlay */}
                  <div className="absolute top-2 left-2 flex flex-col gap-1 pointer-events-none">
                    {isHero && (
                      <span className="px-1.5 py-0.5 bg-sky-500 text-white font-bold rounded text-[9px] flex items-center gap-0.5 shadow">
                        <Star size={8} className="fill-white" /> Hero
                      </span>
                    )}
                    {story.isTopTen && (
                      <span className="px-1.5 py-0.5 bg-purple-600 text-white font-bold rounded text-[9px] flex items-center gap-0.5 shadow">
                        <Trophy size={8} /> Top 10
                      </span>
                    )}
                  </div>

                  {/* Bottom info pill */}
                  <div className="absolute bottom-2 right-2 px-1.5 py-0.5 bg-black/80 backdrop-blur-sm rounded text-[9px] font-bold text-white border border-white/10 pointer-events-none">
                    {story.totalEpisodes || story.episodeCount || 0} EPS
                  </div>
                </div>

                {/* Card Text Footer */}
                <div className="p-3 flex flex-col gap-1">
                  <div className="flex items-center justify-between text-[10px] text-zinc-400">
                    <span className="uppercase font-bold text-rose-400 tracking-wider">
                      {story.genreId || 'Drama'}
                    </span>
                    <span className="text-zinc-500">{story.language || 'Hindi'}</span>
                  </div>
                  <h4 className="text-xs font-bold text-white truncate leading-tight" title={story.title}>
                    {story.title}
                  </h4>
                  <div className="flex items-center justify-between pt-1 mt-0.5 border-t border-white/[0.05]">
                    <span
                      onClick={() => togglePublish(story.id, isPub ? 'published' : 'draft')}
                      className={`text-[10px] font-bold cursor-pointer transition-colors ${
                        isPub ? 'text-emerald-400 hover:underline' : 'text-zinc-400 hover:text-white'
                      }`}
                    >
                      {isPub ? '● Published' : '○ Draft'}
                    </span>
                    <span className="text-[10px] text-zinc-400">{story.views || 0} views</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : viewMode === 'placements' ? (
        /* ---------------- PLACEMENTS VIEW ---------------- */
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Hero Carousel Section */}
          <Card>
            <div className="p-4 border-b border-white/[0.08] flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-sky-500/10 text-sky-400 flex items-center justify-center border border-sky-500/20">
                  <Star size={16} className="fill-sky-400/30" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-white">Hero Carousel (Top Banner)</h3>
                  <p className="text-xs text-zinc-400">Stories featured on the home header banner slider</p>
                </div>
              </div>
              <Badge variant="hero">{stories.filter((s) => s.isPopular || s.isHero).length} Active</Badge>
            </div>
            <div className="p-4 space-y-2.5 max-h-[500px] overflow-y-auto">
              {stories
                .filter((s) => s.isPopular || s.isHero)
                .map((story) => (
                  <div
                    key={story.id}
                    className="p-3 rounded-xl bg-surface-2 border border-white/[0.08] flex items-center justify-between gap-3"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-10 h-14 rounded-lg overflow-hidden shrink-0">
                        <ImageFallback
                          src={story.thumbnailUrl}
                          fallbackTitle={story.title}
                          genre={story.genreId}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div className="flex flex-col min-w-0">
                        <span className="text-xs font-bold text-white truncate">{story.title}</span>
                        <span className="text-[10px] text-zinc-400 uppercase">
                          {story.genreId} • {story.language} • {story.totalEpisodes || 0} eps
                        </span>
                      </div>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => toggleHero(story.id, true)}
                      className="text-rose-400 hover:text-rose-300 border-rose-500/30"
                    >
                      Remove
                    </Button>
                  </div>
                ))}
            </div>
          </Card>

          {/* Top 10 Carousel Section */}
          <Card>
            <div className="p-4 border-b border-white/[0.08] flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-purple-500/10 text-purple-400 flex items-center justify-center border border-purple-500/20">
                  <Trophy size={16} />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-white">Top 10 Section</h3>
                  <p className="text-xs text-zinc-400">Stories ranked in the Top 10 carousel</p>
                </div>
              </div>
              <Badge variant="topTen">{stories.filter((s) => s.isTopTen).length} Stories</Badge>
            </div>
            <div className="p-4 space-y-2.5 max-h-[500px] overflow-y-auto">
              {stories
                .filter((s) => s.isTopTen)
                .map((story, i) => (
                  <div
                    key={story.id}
                    className="p-3 rounded-xl bg-surface-2 border border-white/[0.08] flex items-center justify-between gap-3"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <span className="text-xs font-black text-purple-400 w-5 text-center">#{i + 1}</span>
                      <div className="w-10 h-14 rounded-lg overflow-hidden shrink-0">
                        <ImageFallback
                          src={story.thumbnailUrl}
                          fallbackTitle={story.title}
                          genre={story.genreId}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div className="flex flex-col min-w-0">
                        <span className="text-xs font-bold text-white truncate">{story.title}</span>
                        <span className="text-[10px] text-zinc-400 uppercase">
                          {story.genreId} • {story.language}
                        </span>
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => navigate(`/stories/${story.id}`)}
                    >
                      Edit
                    </Button>
                  </div>
                ))}
            </div>
          </Card>
        </div>
      ) : (
        /* ---------------- TABLE VIEW ---------------- */
        <Card className="overflow-hidden border border-white/[0.08]">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-white/[0.08] bg-surface-2/60 text-zinc-400 uppercase tracking-wider font-bold text-[10px] select-none sticky top-0 backdrop-blur-md z-10">
                  <th className="py-3.5 px-4 w-10 text-center">
                    <input
                      type="checkbox"
                      checked={
                        selectedIds.length > 0 &&
                        selectedIds.length === filteredAndSortedStories.length
                      }
                      onChange={toggleSelectAll}
                      className="w-4 h-4 accent-rose-500 rounded cursor-pointer"
                    />
                  </th>
                  <th className="py-3.5 px-4 w-16">Poster</th>
                  <th className="py-3.5 px-4">Title & Placement</th>
                  <th className="py-3.5 px-4">Genre / Lang</th>
                  <th className="py-3.5 px-4">Episodes</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-4">Created</th>
                  <th className="py-3.5 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.05]">
                {filteredAndSortedStories.map((story) => {
                  const isPub = story.status === 'published' || story.isPublished === true;
                  const isHero = story.isPopular || story.isHero;
                  const isSelected = selectedIds.includes(story.id);

                  return (
                    <tr
                      key={story.id}
                      className={`hover:bg-surface-2/50 transition-colors group ${
                        isSelected ? 'bg-rose-500/[0.04]' : ''
                      }`}
                    >
                      {/* Checkbox */}
                      <td className="py-3 px-4 text-center">
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => toggleSelectRow(story.id)}
                          className="w-4 h-4 accent-rose-500 rounded cursor-pointer"
                        />
                      </td>

                      {/* Poster 2:3 */}
                      <td className="py-3 px-4">
                        <div className="w-10 h-14 rounded-lg overflow-hidden shrink-0 border border-white/10 shadow-sm">
                          <ImageFallback
                            src={story.thumbnailUrl}
                            fallbackTitle={story.title}
                            genre={story.genreId}
                            className="w-full h-full object-cover"
                          />
                        </div>
                      </td>

                      {/* Title & Badges */}
                      <td className="py-3 px-4 max-w-xs">
                        <div className="flex flex-col gap-1 min-w-0">
                          <span
                            onClick={() => navigate(`/stories/${story.id}`)}
                            className="font-bold text-white hover:text-rose-400 cursor-pointer transition-colors text-sm truncate"
                            title={story.title}
                          >
                            {story.title}
                          </span>

                          <div className="flex flex-wrap items-center gap-1.5 pt-0.5">
                            {/* Interactive Hero Toggle Button */}
                            <Badge
                              variant="hero"
                              size="xs"
                              onClick={() => toggleHero(story.id, !!isHero)}
                              className={
                                isHero
                                  ? 'bg-sky-500/20 text-sky-300 border-sky-500/40'
                                  : 'bg-zinc-800 text-zinc-500 border-zinc-700/60 opacity-60 hover:opacity-100'
                              }
                              title={isHero ? 'Remove from Hero Carousel' : 'Feature in Hero Carousel'}
                            >
                              Hero
                            </Badge>

                            {story.isTopTen && <Badge variant="topTen" size="xs" />}
                            {story.isTrending && <Badge variant="trending" size="xs" />}
                            {(story.isNew || story.isNewArrival) && <Badge variant="new" size="xs" />}
                          </div>
                        </div>
                      </td>

                      {/* Genre & Language */}
                      <td className="py-3 px-4">
                        <div className="flex flex-col gap-0.5">
                          <span className="font-bold uppercase text-[11px] text-zinc-300">
                            {story.genreId || 'Drama'}
                          </span>
                          <span className="text-[11px] text-zinc-400">{story.language || 'Hindi'}</span>
                        </div>
                      </td>

                      {/* Episodes & Views */}
                      <td className="py-3 px-4">
                        <div className="flex flex-col gap-0.5">
                          <span className="font-bold text-white">
                            {story.totalEpisodes || story.episodeCount || 0} eps
                          </span>
                          <span className="text-[11px] text-zinc-400">
                            {Number(story.views || 0).toLocaleString()} views
                          </span>
                        </div>
                      </td>

                      {/* Publishing Status */}
                      <td className="py-3 px-4">
                        <button
                          onClick={() => togglePublish(story.id, isPub ? 'published' : 'draft')}
                          className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider flex items-center gap-1.5 transition-colors ${
                            isPub
                              ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/25'
                              : 'bg-zinc-800 text-zinc-400 border border-zinc-700 hover:bg-zinc-700'
                          }`}
                        >
                          {isPub ? <Eye size={12} /> : <EyeOff size={12} />}
                          {isPub ? 'Published' : 'Draft'}
                        </button>
                      </td>

                      {/* Created Date */}
                      <td className="py-3 px-4 text-zinc-400 text-[11px] whitespace-nowrap">
                        {story.createdAt?.toDate
                          ? format(story.createdAt.toDate(), 'MMM d, yyyy')
                          : 'Recent'}
                      </td>

                      {/* Actions */}
                      <td className="py-3 px-4 text-right">
                        <div className="flex items-center justify-end gap-1.5 opacity-80 group-hover:opacity-100 transition-opacity">
                          <button
                            onClick={() => navigate(`/stories/${story.id}`)}
                            className="p-1.5 rounded-lg bg-surface-2 hover:bg-white/10 text-zinc-300 hover:text-white transition-colors"
                            title="Edit Story & Episodes"
                          >
                            <Edit size={15} />
                          </button>
                          <button
                            onClick={() => handleDuplicate(story)}
                            className="p-1.5 rounded-lg bg-surface-2 hover:bg-white/10 text-zinc-300 hover:text-white transition-colors"
                            title="Duplicate Story"
                          >
                            <Copy size={15} />
                          </button>
                          <button
                            onClick={() => setStoryToDelete(story)}
                            className="p-1.5 rounded-lg bg-surface-2 hover:bg-rose-500/20 text-zinc-400 hover:text-rose-400 transition-colors"
                            title="Delete Story"
                          >
                            <Trash2 size={15} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Floating Bulk Action Bar */}
      {selectedIds.length > 0 && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-40 bg-[#18181B]/95 border border-white/20 rounded-2xl shadow-2xl p-3 px-5 flex items-center gap-4 backdrop-blur-xl animate-in slide-in-from-bottom-5 duration-200">
          <div className="flex items-center gap-2 text-xs font-bold text-white border-r border-white/15 pr-3">
            <span className="w-5 h-5 rounded-full bg-rose-500 text-white flex items-center justify-center text-[10px]">
              {selectedIds.length}
            </span>
            <span>Selected</span>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              iconLeft={<Eye size={14} />}
              onClick={() => handleBulkPublish('published')}
            >
              Publish
            </Button>
            <Button
              variant="outline"
              size="sm"
              iconLeft={<EyeOff size={14} />}
              onClick={() => handleBulkPublish('draft')}
            >
              Draft
            </Button>
            <Button
              variant="danger"
              size="sm"
              iconLeft={<Trash2 size={14} />}
              onClick={handleBulkDelete}
            >
              Delete
            </Button>
          </div>

          <button
            onClick={() => setSelectedIds([])}
            className="p-1 text-zinc-400 hover:text-white rounded ml-2"
            title="Deselect all"
          >
            <X size={16} />
          </button>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={Boolean(storyToDelete)}
        onClose={() => setStoryToDelete(null)}
        title="Delete Story"
        subtitle="This action cannot be undone."
        maxWidth="sm"
        footer={
          <>
            <Button variant="ghost" size="sm" onClick={() => setStoryToDelete(null)}>
              Cancel
            </Button>
            <Button
              variant="danger"
              size="sm"
              loading={isDeleting}
              onClick={handleDelete}
            >
              Confirm Delete
            </Button>
          </>
        }
      >
        <p className="text-xs text-zinc-300 leading-relaxed">
          Are you sure you want to permanently remove{' '}
          <strong className="text-white font-bold">{storyToDelete?.title}</strong>? All
          linked episodes and player metadata will be deleted.
        </p>
      </Modal>
    </div>
  );
}
