import { useEffect, useState } from 'react';
import { collection, query, onSnapshot, doc, deleteDoc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { Link } from 'react-router-dom';
import { Plus, Edit, Trash2, Eye, EyeOff } from 'lucide-react';
import { format } from 'date-fns';

export default function Stories() {
  const [stories, setStories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'stories'));
    const unsubscribe = onSnapshot(q, 
      (snapshot) => {
        const fetched = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        // Sort in JS to avoid Firestore index requirements
        fetched.sort((a: any, b: any) => {
          const tA = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
          const tB = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
          return tB - tA;
        });
        setStories(fetched);
        setLoading(false);
      },
      (error) => {
        console.error("Error fetching stories:", error);
        alert("Error loading stories: " + error.message);
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

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div className="flex flex-col gap-1">
          <h1 className="text-display font-bold">Stories</h1>
          <p className="text-on-surface-variant">Manage the StoryVerse content library</p>
        </div>
        <Link 
          to="/stories/add" 
          className="flex items-center gap-2 px-6 py-3 bg-primary text-on-primary rounded-full font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors shadow-lg"
        >
          <Plus size={20} />
          Add Story
        </Link>
      </div>

      <div className="bg-surface-container rounded-2xl overflow-hidden border border-surface-container-highest">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-high border-b border-surface-container-highest">
                <th className="px-6 py-4 font-label-lg text-on-surface-variant w-16">Thumbnail</th>
                <th className="px-6 py-4 font-label-lg text-on-surface-variant">Title & Info</th>
                <th className="px-6 py-4 font-label-lg text-on-surface-variant">Status</th>
                <th className="px-6 py-4 font-label-lg text-on-surface-variant">Date Added</th>
                <th className="px-6 py-4 font-label-lg text-on-surface-variant text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={5} className="p-8 text-center text-on-surface-variant">Loading stories...</td>
                </tr>
              ) : stories.length === 0 ? (
                <tr>
                  <td colSpan={5} className="p-8 text-center text-on-surface-variant">No stories found.</td>
                </tr>
              ) : (
                stories.map((story) => (
                  <tr key={story.id} className="border-b border-surface-container-highest hover:bg-surface-container-high transition-colors">
                    <td className="px-6 py-4">
                      <div className="w-16 h-16 rounded overflow-hidden bg-surface-container-highest">
                        {story.thumbnailUrl ? (
                          <img src={story.thumbnailUrl} alt="thumbnail" className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-on-surface-variant">No Img</div>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col gap-1">
                        <span className="font-headline-sm text-on-surface">{story.title}</span>
                        <div className="flex items-center gap-2 font-label-sm text-outline">
                          <span>{story.author || 'Unknown Author'}</span>
                          <span>•</span>
                          <span className="uppercase">{story.categoryId || 'UNCATEGORIZED'}</span>
                          <span>•</span>
                          <span>{story.totalEpisodes || story.episodeCount || 0} eps</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <button 
                        onClick={() => togglePublish(story.id, story.status)}
                        className={`px-3 py-1 rounded-full font-label-sm uppercase tracking-wider flex items-center gap-1 w-max ${story.status === 'published' ? 'bg-tertiary-container text-on-tertiary-container' : 'bg-surface-container-highest text-on-surface-variant'}`}
                      >
                        {story.status === 'published' ? <Eye size={14} /> : <EyeOff size={14} />}
                        {story.status === 'published' ? 'Published' : 'Draft'}
                      </button>
                    </td>
                    <td className="px-6 py-4 text-on-surface-variant font-body-sm">
                      {story.createdAt?.toDate ? format(story.createdAt.toDate(), 'MMM d, yyyy') : 'Unknown'}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        <Link to={`/stories/${story.id}`} className="p-2 rounded bg-surface hover:bg-primary-container hover:text-on-primary-container transition-colors text-outline">
                          <Edit size={18} />
                        </Link>
                        <button onClick={() => handleDelete(story.id)} className="p-2 rounded bg-surface hover:bg-error-container hover:text-on-error-container transition-colors text-outline">
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
