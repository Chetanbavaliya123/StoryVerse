import { useEffect, useState } from 'react';
import { collection, query, onSnapshot, doc, deleteDoc, addDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { db, storage } from '../lib/firebase';
import { Plus, Edit, Trash2, X, Image as ImageIcon, Video } from 'lucide-react';


export default function EpisodesManager({ storyId }: { storyId: string }) {
  const [episodes, setEpisodes] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingEpisode, setEditingEpisode] = useState<any>(null);
  
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    episodeNumber: 1,
    videoUrl: '',
    duration: 0,
    thumbnailUrl: ''
  });

  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  useEffect(() => {
    const q = query(collection(db, 'stories', storyId, 'episodes'));
    
    const unsubscribe = onSnapshot(q, 
      (snapshot) => {
        const fetched = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        fetched.sort((a: any, b: any) => (a.episodeNumber || 0) - (b.episodeNumber || 0));
        setEpisodes(fetched);
        setLoading(false);
      },
      (error) => {
        console.error("Error fetching episodes:", error);
        alert("Error loading episodes: " + error.message);
        setLoading(false);
      }
    );
    
    return () => unsubscribe();
  }, [storyId]);

  const handleImageUpload = async (file: File) => {
    setUploading(true);
    const storageRef = ref(storage, `stories/${storyId}/episodes/${editingEpisode ? editingEpisode.id : 'temp'}/thumbnail/${Date.now()}_${file.name}`);
    const uploadTask = uploadBytesResumable(storageRef, file);

    uploadTask.on('state_changed', 
      (snapshot) => {
        const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        setUploadProgress(progress);
      }, 
      (error) => {
        console.error("Upload failed", error);
        setUploading(false);
      }, 
      async () => {
        const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);
        setFormData(prev => ({ ...prev, thumbnailUrl: downloadURL }));
        setUploading(false);
        setUploadProgress(0);
      }
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.videoUrl) {
      alert("Please provide a valid video URL.");
      return;
    }
    if (formData.videoUrl.includes('youtube.com') || formData.videoUrl.includes('youtu.be')) {
      alert("Use a direct video file URL (.mp4) for StoryVerse.");
      return;
    }

    try {
      if (editingEpisode) {
        await updateDoc(doc(db, 'stories', storyId, 'episodes', editingEpisode.id), {
          ...formData,
          updatedAt: serverTimestamp()
        });
      } else {
        await addDoc(collection(db, 'stories', storyId, 'episodes'), {
          ...formData,
          storyId,
          isPublished: true,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        });
        // Update episode count if parent document exists
        try {
          await updateDoc(doc(db, 'stories', storyId), {
            totalEpisodes: episodes.length + 1
          });
        } catch (updateErr) {
          console.warn("Parent story doesn't exist yet to update count (Draft Mode)");
        }
      }
      setIsModalOpen(false);
      resetForm();
    } catch (error) {
      console.error("Failed to save episode", error);
      alert("Failed to save episode.");
    }
  };

  const handleDelete = async (episodeId: string) => {
    if (window.confirm('Are you sure you want to delete this episode?')) {
      await deleteDoc(doc(db, 'stories', storyId, 'episodes', episodeId));
      try {
        await updateDoc(doc(db, 'stories', storyId), {
          totalEpisodes: Math.max(0, episodes.length - 1)
        });
      } catch (err) {
        console.warn("Parent story doesn't exist yet to update count");
      }
    }
  };

  const openAddModal = () => {
    resetForm();
    setFormData(prev => ({ ...prev, episodeNumber: episodes.length + 1 }));
    setIsModalOpen(true);
  };

  const openEditModal = (ep: any) => {
    setEditingEpisode(ep);
    setFormData({
      title: ep.title || '',
      description: ep.description || '',
      episodeNumber: ep.episodeNumber || 1,
      videoUrl: ep.videoUrl || '',
      duration: ep.duration || 0,
      thumbnailUrl: ep.thumbnailUrl || ''
    });
    setIsModalOpen(true);
  };

  const resetForm = () => {
    setEditingEpisode(null);
    setFormData({ title: '', description: '', episodeNumber: 1, videoUrl: '', duration: 0, thumbnailUrl: '' });
  };

  return (
    <div className="flex flex-col gap-4 mt-8 pt-8 border-t border-surface-container-highest">
      <div className="flex items-center justify-between">
        <h2 className="text-headline-md font-bold">Episodes</h2>
        <button 
          onClick={openAddModal}
          className="flex items-center gap-2 px-4 py-2 bg-surface-container-highest text-on-surface rounded-full font-bold hover:bg-surface-container transition-colors"
        >
          <Plus size={18} />
          Add Episode
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {loading ? (
          <div className="text-on-surface-variant">Loading episodes...</div>
        ) : episodes.length === 0 ? (
          <div className="text-on-surface-variant col-span-full p-8 text-center bg-surface-container rounded-2xl">
            No episodes yet. Click "Add Episode" to create one.
          </div>
        ) : (
          episodes.map(ep => (
            <div key={ep.id} className="bg-surface-container rounded-2xl overflow-hidden border border-surface-container-highest flex flex-col group">
              <div className="h-40 bg-surface-container-highest relative">
                {ep.thumbnailUrl ? (
                  <img src={ep.thumbnailUrl} alt={ep.title} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-outline">
                    <ImageIcon size={32} />
                  </div>
                )}
                <div className="absolute top-2 left-2 px-2 py-1 bg-black/60 backdrop-blur rounded text-white font-label-sm font-bold">
                  EP {ep.episodeNumber}
                </div>
              </div>
              <div className="p-4 flex flex-col gap-2 flex-1">
                <h3 className="font-headline-sm font-bold truncate">{ep.title}</h3>
                <p className="text-body-sm text-on-surface-variant line-clamp-2">{ep.description}</p>
                
                <div className="mt-auto pt-4 flex items-center justify-between border-t border-surface-container-highest">
                  <div className="flex items-center gap-1 text-label-sm text-outline">
                    <Video size={14} />
                    <span className="truncate w-24" title={ep.videoUrl}>{ep.videoUrl ? 'Video linked' : 'No video'}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <button onClick={() => openEditModal(ep)} className="p-1.5 rounded hover:bg-surface-container-highest text-outline hover:text-on-surface">
                      <Edit size={16} />
                    </button>
                    <button onClick={() => handleDelete(ep.id)} className="p-1.5 rounded hover:bg-error-container text-outline hover:text-on-error-container">
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <div className="bg-surface w-full max-w-2xl rounded-2xl overflow-hidden shadow-2xl flex flex-col max-h-[90vh]">
            <div className="p-6 border-b border-surface-container flex items-center justify-between bg-surface-container-lowest">
              <h2 className="text-headline-md font-bold">{editingEpisode ? 'Edit Episode' : 'Add Episode'}</h2>
              <button onClick={() => setIsModalOpen(false)} className="p-2 hover:bg-surface-container rounded-full transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-6 overflow-y-auto flex-1">
              <form id="episode-form" onSubmit={handleSubmit} className="flex flex-col gap-6">
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5 col-span-2 md:col-span-1">
                    <label className="text-label-md text-on-surface-variant">Episode Title</label>
                    <input 
                      type="text" required
                      value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})}
                      className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary outline-none"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5 col-span-2 md:col-span-1">
                    <label className="text-label-md text-on-surface-variant">Episode Number</label>
                    <input 
                      type="number" required min="1"
                      value={formData.episodeNumber} onChange={e => setFormData({...formData, episodeNumber: parseInt(e.target.value)})}
                      className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary outline-none"
                    />
                  </div>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-label-md text-on-surface-variant">Description</label>
                  <textarea 
                    rows={3}
                    value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}
                    className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary outline-none"
                  ></textarea>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-label-md text-on-surface-variant">Video URL</label>
                  <input 
                    type="url" required
                    placeholder="https://example.com/video.mp4 (direct media URL)"
                    value={formData.videoUrl} onChange={e => setFormData({...formData, videoUrl: e.target.value})}
                    className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary outline-none"
                  />
                  <span className="text-xs text-outline">Must be a direct HTTPS video URL (.mp4, .m3u8, etc). YouTube links are not supported.</span>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-label-md text-on-surface-variant">Thumbnail Image</label>
                  <div className="flex items-center gap-4">
                    {formData.thumbnailUrl && (
                      <div className="w-24 h-16 rounded overflow-hidden bg-surface-container">
                        <img src={formData.thumbnailUrl} alt="Thumb" className="w-full h-full object-cover" />
                      </div>
                    )}
                    <div className="flex-1">
                      <input 
                        type="file" accept="image/*"
                        onChange={e => e.target.files?.[0] && handleImageUpload(e.target.files[0])}
                        className="w-full text-sm text-on-surface-variant file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-surface-container-high file:text-on-surface hover:file:bg-surface-container-highest cursor-pointer"
                      />
                      {uploading && <div className="text-xs text-tertiary mt-2">Uploading: {Math.round(uploadProgress)}%</div>}
                    </div>
                  </div>
                </div>
              </form>
            </div>
            <div className="p-6 border-t border-surface-container bg-surface-container-lowest flex justify-end gap-3">
              <button onClick={() => setIsModalOpen(false)} type="button" className="px-6 py-2.5 rounded-full font-bold hover:bg-surface-container transition-colors">
                Cancel
              </button>
              <button form="episode-form" type="submit" disabled={uploading} className="px-6 py-2.5 bg-primary text-on-primary rounded-full font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors disabled:opacity-50">
                {editingEpisode ? 'Save Changes' : 'Create Episode'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
