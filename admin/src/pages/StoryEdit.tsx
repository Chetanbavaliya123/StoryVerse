import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { doc, collection, getDoc, getDocs, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { db, storage } from '../lib/firebase';
import EpisodesManager from '../components/EpisodesManager';
import { ArrowLeft, Save, Image as ImageIcon } from 'lucide-react';

export default function StoryEdit() {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEditing = !!id;
  const [draftId] = useState(() => isEditing ? id! : doc(collection(db, 'stories')).id);

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    fullDescription: '',
    categoryId: 'fantasy',
    genreId: 'adventure',
    language: 'English',
    author: 'StoryVerse Admin',
    status: 'draft',
    isTrending: false,
    thumbnailUrl: '',
    bannerUrl: ''
  });

  const [loading, setLoading] = useState(isEditing);
  const [saving, setSaving] = useState(false);
  
  const [uploadingThumb, setUploadingThumb] = useState(false);
  const [uploadingBanner, setUploadingBanner] = useState(false);

  useEffect(() => {
    if (isEditing) {
      const fetchStory = async () => {
        const docSnap = await getDoc(doc(db, 'stories', id));
        if (docSnap.exists()) {
          setFormData({ ...formData, ...docSnap.data() });
        } else {
          alert('Story not found');
          navigate('/stories');
        }
        setLoading(false);
      };
      fetchStory();
    }
  }, [id, navigate]);

  const handleImageUpload = async (file: File, type: 'thumb' | 'banner') => {
    const isThumb = type === 'thumb';
    isThumb ? setUploadingThumb(true) : setUploadingBanner(true);
    
    const folder = isThumb ? 'thumbnail' : 'banner';
    const storageRef = ref(storage, `stories/${isEditing ? id : 'temp'}/${folder}/${Date.now()}_${file.name}`);
    const uploadTask = uploadBytesResumable(storageRef, file);

    uploadTask.on('state_changed', 
      null, 
      (error) => {
        console.error("Upload failed", error);
        alert("Upload failed: " + error.message);
        isThumb ? setUploadingThumb(false) : setUploadingBanner(false);
      }, 
      async () => {
        const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);
        setFormData(prev => ({
          ...prev,
          [isThumb ? 'thumbnailUrl' : 'bannerUrl']: downloadURL
        }));
        isThumb ? setUploadingThumb(false) : setUploadingBanner(false);
      }
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error('Firebase connection timeout (15s). The server did not respond.')), 15000));
      
      if (isEditing) {
        await Promise.race([
          updateDoc(doc(db, 'stories', id), {
            ...formData,
            categoryId: formData.categoryId,
            genreId: formData.genreId,
            isPublished: formData.status === 'published',
            updatedAt: serverTimestamp()
          }),
          timeoutPromise
        ]);
        alert('Story updated successfully on server!');
      } else {
        // Fetch actual episodes count in case user added them before saving
        const epsSnap = await getDocs(collection(db, 'stories', draftId, 'episodes'));
        const realCount = epsSnap.size;

        await Promise.race([
          setDoc(doc(db, 'stories', draftId), {
            ...formData,
            id: draftId,
            categoryId: formData.categoryId,
            genreId: formData.genreId,
            totalEpisodes: realCount,
            totalViews: 0,
            totalLikes: 0,
            totalFavorites: 0,
            isPublished: formData.status === 'published',
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
          }),
          timeoutPromise
        ]);
        alert('Story created successfully on server!');
        navigate(`/stories`);
      }
    } catch (error: any) {
      console.error("Failed to save story", error);
      alert("Failed to save story: " + error.message);
    } finally {
      setSaving(false);
    }
  };
  
  const fillDemoData = () => {
    setFormData({
      title: 'The Great Flutter Adventure',
      description: 'A developer\'s journey through the world of cross-platform apps.',
      fullDescription: 'Once upon a time in the land of widgets, a lone developer set out on a quest to build the ultimate app. Along the way, they faced state management monsters and asynchronous dragons, but armed with Riverpod and Firebase, victory was inevitable.',
      categoryId: 'fantasy',
      genreId: 'adventure',
      language: 'English',
      author: 'StoryVerse Admin',
      status: 'published',
      isTrending: true,
      thumbnailUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?q=80&w=500&auto=format&fit=crop',
      bannerUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1200&auto=format&fit=crop'
    });
  };

  if (loading) return <div className="p-8">Loading...</div>;

  return (
    <div className="flex flex-col gap-8 pb-12 max-w-5xl mx-auto w-full">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button onClick={() => navigate('/stories')} className="p-2 bg-surface-container rounded-full hover:bg-surface-container-high transition-colors">
            <ArrowLeft size={24} />
          </button>
          <div className="flex flex-col">
            <h1 className="text-display font-bold">{isEditing ? 'Edit Story' : 'New Story'}</h1>
            <p className="text-on-surface-variant">Configure story details and metadata</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          {!isEditing && (
            <button 
              onClick={fillDemoData}
              type="button"
              className="px-4 py-3 bg-surface-container border border-primary text-primary rounded-full font-bold hover:bg-primary-container transition-colors"
            >
              Fill Demo Data
            </button>
          )}
          <button 
            onClick={handleSubmit}
            disabled={saving || uploadingThumb || uploadingBanner}
            className="flex items-center gap-2 px-6 py-3 bg-primary text-on-primary rounded-full font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors disabled:opacity-50 shadow-lg"
          >
            <Save size={20} />
            {saving ? 'Saving...' : 'Save Story'}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 flex flex-col gap-6">
          {/* Main Info */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
            <h2 className="text-headline-sm font-bold border-b border-surface-container-highest pb-2 mb-2">Basic Information</h2>
            
            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Title</label>
              <input 
                type="text" required
                value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none"
              />
            </div>
            
            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Short Description</label>
              <textarea 
                rows={2} required
                value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Full Description (Optional)</label>
              <textarea 
                rows={4}
                value={formData.fullDescription} onChange={e => setFormData({...formData, fullDescription: e.target.value})}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none"
              />
            </div>
          </div>
          
          <div className="mt-8">
            <h2 className="text-headline-sm font-bold mb-4">Episodes</h2>
            <div className="bg-surface-container-low rounded-xl p-6 border border-surface-container">
              {!isEditing && <p className="text-tertiary text-sm mb-4">You can add episodes right now! They will be linked to this story once you click "Save Story".</p>}
              <EpisodesManager storyId={draftId} />
            </div>
          </div>
        </div>

        <div className="flex flex-col gap-6">
          {/* Settings */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
            <h2 className="text-headline-sm font-bold border-b border-surface-container-highest pb-2 mb-2">Settings & Metadata</h2>
            
            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Status</label>
              <select 
                value={formData.status} onChange={e => setFormData({...formData, status: e.target.value})}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none"
              >
                <option value="draft">Draft (Hidden)</option>
                <option value="published">Published</option>
              </select>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Category</label>
              <input 
                type="text" required
                value={formData.categoryId} onChange={e => setFormData({...formData, categoryId: e.target.value})}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Author</label>
              <input 
                type="text"
                value={formData.author} onChange={e => setFormData({...formData, author: e.target.value})}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none"
              />
            </div>

            <label className="flex items-center gap-3 mt-2 cursor-pointer">
              <input 
                type="checkbox" 
                checked={formData.isTrending} onChange={e => setFormData({...formData, isTrending: e.target.checked})}
                className="w-5 h-5 accent-primary rounded"
              />
              <span className="font-label-md">Feature as Trending</span>
            </label>
          </div>

          {/* Media */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
            <h2 className="text-headline-sm font-bold border-b border-surface-container-highest pb-2 mb-2">Media Assets</h2>
            
            <div className="flex flex-col gap-2">
              <label className="text-label-md text-on-surface-variant">Thumbnail (Portrait 2:3)</label>
              <div className="w-full aspect-[2/3] bg-surface-container-lowest rounded-xl overflow-hidden relative group border-2 border-dashed border-surface-container-highest">
                {formData.thumbnailUrl ? (
                  <img src={formData.thumbnailUrl} alt="Thumbnail" className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex flex-col items-center justify-center text-outline">
                    <ImageIcon size={32} className="mb-2" />
                    <span className="text-xs">No thumbnail</span>
                  </div>
                )}
                <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center">
                  <span className="text-white text-sm font-bold mb-2">Upload Image</span>
                  {uploadingThumb && <span className="text-primary text-xs">Uploading...</span>}
                  <input type="file" accept="image/*" onChange={e => e.target.files?.[0] && handleImageUpload(e.target.files[0], 'thumb')} className="absolute inset-0 opacity-0 cursor-pointer" />
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
