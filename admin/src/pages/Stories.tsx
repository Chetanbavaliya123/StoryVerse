import { useEffect, useState, useMemo } from 'react';
import { collection, query, onSnapshot, doc, deleteDoc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { Link } from 'react-router-dom';
import { Plus, Edit, Trash2, Eye, EyeOff, Search, X, Filter, BookOpen, Clock, AlertCircle } from 'lucide-react';
import { format } from 'date-fns';

export default function Stories() {
  const [stories, setStories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [sortBy, setSortBy] = useState('newest');

  useEffect(() => {
    setLoading(true);
    setError(null);
    const q = query(collection(db, 'stories'));
    const unsubscribe = onSnapshot(q, 
      (snapshot) => {
        const fetched = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        setStories(fetched);
        setLoading(false);
      },
      (error) => {
        console.error("Error fetching stories:", error);
        setError("Failed to load stories: " + error.message);
        setLoading(false);
      }
    );
    return () => unsubscribe();
  }, []);

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this story?')) {
      await deleteDoc(doc(db, 'stories', id));
    }
  };

  const togglePublish = async (id: string, currentStatus: string) => {
    const newStatus = currentStatus === 'published' ? 'draft' : 'published';
    await updateDoc(doc(db, 'stories', id), {
      status: newStatus,
      isPublished: newStatus === 'published'
    });
  };

  const filteredAndSortedStories = useMemo(() => {
    let result = stories.filter(story => {
      const q = searchQuery.toLowerCase();
      const matchesSearch = !q || (story.title && story.title.toLowerCase().includes(q));
      
      const isPublished = story.status === 'published' || story.isPublished === true;
      let matchesStatus = true;
      if (statusFilter === 'published') matchesStatus = isPublished;
      if (statusFilter === 'draft') matchesStatus = !isPublished;

      return matchesSearch && matchesStatus;
    });

    result.sort((a, b) => {
      const tA = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
      const tB = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
      
      if (sortBy === 'newest') return tB - tA;
      if (sortBy === 'oldest') return tA - tB;
      if (sortBy === 'az') {
        const titleA = a.title?.toLowerCase() || '';
        const titleB = b.title?.toLowerCase() || '';
        return titleA.localeCompare(titleB);
      }
      return 0;
    });

    return result;
  }, [stories, searchQuery, statusFilter, sortBy]);

  return (
    <div className="flex flex-col gap-6 pb-12">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex flex-col gap-1">
          <h1 className="text-display font-bold">Stories</h1>
          <p className="text-on-surface-variant">Manage the StoryVerse content library</p>
        </div>
        <Link 
          to="/stories/add" 
          className="flex items-center gap-2 px-6 py-3 bg-primary text-on-primary rounded-full font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors shadow-lg w-max"
        >
          <Plus size={20} />
          Add Story
        </Link>
      </div>

      {/* FILTERS & SEARCH */}
      <div className="flex flex-col md:flex-row gap-4 bg-surface-container p-4 rounded-2xl border border-surface-container-highest">
        <div className="relative flex-1">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-on-surface-variant">
            <Search size={18} />
          </div>
          <input
            type="text"
            placeholder="Search stories by title..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-10 py-2.5 bg-surface-container-highest border-none rounded-xl focus:ring-2 focus:ring-primary text-on-surface placeholder:text-on-surface-variant transition-all outline-none"
          />
          {searchQuery && (
            <button 
              onClick={() => setSearchQuery('')}
              className="absolute inset-y-0 right-0 pr-3 flex items-center text-on-surface-variant hover:text-on-surface"
            >
              <X size={18} />
            </button>
          )}
        </div>
        
        <div className="flex items-center gap-2 overflow-x-auto pb-2 md:pb-0 hide-scrollbar">
          <div className="flex items-center gap-2 bg-surface-container-highest rounded-xl px-3 py-1.5 flex-shrink-0">
            <Filter size={14} className="text-on-surface-variant" />
            <select 
              value={statusFilter} 
              onChange={e => setStatusFilter(e.target.value)}
              className="bg-transparent border-none text-sm text-on-surface outline-none cursor-pointer"
            >
              <option value="all">All Status</option>
              <option value="published">Published</option>
              <option value="draft">Drafts</option>
            </select>
          </div>
          
          <div className="flex items-center gap-2 bg-surface-container-highest rounded-xl px-3 py-1.5 flex-shrink-0">
            <Clock size={14} className="text-on-surface-variant" />
            <select 
              value={sortBy} 
              onChange={e => setSortBy(e.target.value)}
              className="bg-transparent border-none text-sm text-on-surface outline-none cursor-pointer"
            >
              <option value="newest">Newest First</option>
              <option value="oldest">Oldest First</option>
              <option value="az">Title (A-Z)</option>
            </select>
          </div>
        </div>
      </div>

      {error ? (
        <div className="p-6 bg-error-container text-on-error-container rounded-2xl flex items-center gap-3">
          <AlertCircle size={24} />
          <p>{error}</p>
        </div>
      ) : (
        <div className="bg-surface-container rounded-2xl overflow-hidden border border-surface-container-highest">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-[800px]">
              <thead>
                <tr className="bg-surface-container-high border-b border-surface-container-highest">
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant w-24">Thumbnail</th>
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant">Title & Info</th>
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant">Status</th>
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant">Date Added</th>
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading && stories.length === 0 ? (
                  Array.from({ length: 3 }).map((_, i) => (
                    <tr key={i} className="border-b border-surface-container-highest">
                      <td className="px-6 py-4">
                        <div className="w-16 h-20 bg-surface-container-highest animate-pulse rounded-lg"></div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-2">
                          <div className="w-48 h-5 bg-surface-container-highest animate-pulse rounded"></div>
                          <div className="w-32 h-4 bg-surface-container-highest animate-pulse rounded"></div>
                        </div>
                      </td>
                      <td className="px-6 py-4"><div className="w-24 h-6 bg-surface-container-highest animate-pulse rounded-full"></div></td>
                      <td className="px-6 py-4"><div className="w-24 h-4 bg-surface-container-highest animate-pulse rounded"></div></td>
                      <td className="px-6 py-4">
                        <div className="flex gap-2 justify-end">
                          <div className="w-8 h-8 bg-surface-container-highest animate-pulse rounded"></div>
                          <div className="w-8 h-8 bg-surface-container-highest animate-pulse rounded"></div>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : filteredAndSortedStories.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="p-16 text-center text-on-surface-variant">
                      <div className="flex flex-col items-center justify-center gap-3">
                        <div className="p-4 bg-surface-container-highest rounded-full">
                          <BookOpen size={32} className="opacity-50" />
                        </div>
                        <span className="font-bold text-on-surface">No stories found</span>
                        <span className="text-sm">Try adjusting your search or filters.</span>
                        {(searchQuery || statusFilter !== 'all') && (
                          <button 
                            onClick={() => { setSearchQuery(''); setStatusFilter('all'); }}
                            className="mt-2 text-primary hover:underline text-sm font-bold"
                          >
                            Clear all filters
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ) : (
                  filteredAndSortedStories.map((story) => {
                    const isPublished = story.status === 'published' || story.isPublished === true;
                    return (
                      <tr key={story.id} className="border-b border-surface-container-highest hover:bg-surface-container-high transition-colors group">
                        <td className="px-6 py-4">
                          <div className="w-16 h-24 rounded-lg overflow-hidden bg-surface-container-highest flex items-center justify-center border border-surface-container-highest">
                            {story.thumbnailUrl ? (
                              <img src={story.thumbnailUrl} alt={story.title} className="w-full h-full object-cover" />
                            ) : (
                              <BookOpen size={24} className="text-on-surface-variant opacity-50" />
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-col gap-2">
                            <span className="font-headline-sm text-on-surface font-bold text-lg">{story.title || 'Untitled'}</span>
                            <div className="flex flex-wrap items-center gap-2 font-label-sm text-outline">
                              {story.categoryId && (
                                <span className="bg-surface-container-highest px-2 py-0.5 rounded text-xs uppercase tracking-wider text-on-surface-variant">
                                  {story.categoryId}
                                </span>
                              )}
                              <span>•</span>
                              <span className="text-primary font-bold">{story.totalEpisodes || story.episodeCount || 0} Episodes</span>
                              {story.author && (
                                <>
                                  <span>•</span>
                                  <span className="truncate max-w-[150px]">{story.author}</span>
                                </>
                              )}
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <button 
                            onClick={() => togglePublish(story.id, isPublished ? 'published' : 'draft')}
                            className={`px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider flex items-center gap-1.5 w-max transition-colors ${
                              isPublished 
                                ? 'bg-secondary-container/50 text-secondary hover:bg-secondary-container' 
                                : 'bg-surface-variant text-on-surface-variant hover:bg-surface-container-highest'
                            }`}
                            title={isPublished ? "Click to unpublish" : "Click to publish"}
                          >
                            {isPublished ? <Eye size={14} /> : <EyeOff size={14} />}
                            {isPublished ? 'Published' : 'Draft'}
                          </button>
                        </td>
                        <td className="px-6 py-4 text-on-surface-variant font-body-sm">
                          {story.createdAt?.toDate ? format(story.createdAt.toDate(), 'MMM d, yyyy') : 'Unknown'}
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center justify-end gap-2 opacity-50 group-hover:opacity-100 transition-opacity">
                            <Link 
                              to={`/stories/${story.id}`} 
                              className="p-2 rounded-lg bg-surface hover:bg-primary-container hover:text-on-primary-container transition-colors text-outline"
                              title="Edit Story"
                            >
                              <Edit size={18} />
                            </Link>
                            <button 
                              onClick={() => handleDelete(story.id)} 
                              className="p-2 rounded-lg bg-surface hover:bg-error-container hover:text-on-error-container transition-colors text-outline"
                              title="Delete Story"
                            >
                              <Trash2 size={18} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
