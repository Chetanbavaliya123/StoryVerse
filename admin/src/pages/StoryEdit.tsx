import { useEffect, useState, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { doc, collection, getDoc, getDocs, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { supabase } from '../lib/supabase';
import EpisodesManager from '../components/EpisodesManager';
import { ArrowLeft, Save, Image as ImageIcon, AlertTriangle, UploadCloud, CheckCircle2 } from 'lucide-react';

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

  // Separate states for uploading and saving
  const [isSavingStory, setIsSavingStory] = useState(false);
  const [isUploadingThumbnail, setIsUploadingThumbnail] = useState(false);

  // Local thumbnail preview states
  const [thumbnailFile, setThumbnailFile] = useState<File | null>(null);
  const [thumbnailPreview, setThumbnailPreview] = useState<string>('');

  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isEditing) {
      const fetchStory = async () => {
        try {
          const docSnap = await getDoc(doc(db, 'stories', id));
          if (docSnap.exists()) {
            setFormData({ ...formData, ...docSnap.data() });
          } else {
            alert('Story not found');
            navigate('/stories');
          }
        } catch (e: any) {
          setErrorMsg("Failed to load story: " + e.message);
        } finally {
          setLoading(false);
        }
      };
      fetchStory();
    }
  }, [id, navigate]);

  useEffect(() => {
    // Cleanup object URL to avoid memory leaks
    return () => {
      if (thumbnailPreview) {
        URL.revokeObjectURL(thumbnailPreview);
      }
    };
  }, [thumbnailPreview]);

  const handleImageSelect = (file: File) => {
    if (!file.type.startsWith('image/')) {
      setErrorMsg("Please select a valid image file for the thumbnail.");
      return;
    }
    // Limit to 45 MB as per requirements
    if (file.size > 45 * 1024 * 1024) {
      setErrorMsg("Thumbnail file size should be less than 45 MB.");
      return;
    }

    setErrorMsg('');
    setThumbnailFile(file);
    const objectUrl = URL.createObjectURL(file);
    setThumbnailPreview(objectUrl);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');
    setSuccessMsg('');

    if (!formData.title.trim()) {
      setErrorMsg("Story title is required.");
      return;
    }

    if (!formData.thumbnailUrl && !thumbnailFile) {
      setErrorMsg("Please select a thumbnail for the story before saving.");
      return;
    }

    if (isUploadingThumbnail || isSavingStory) {
      return;
    }

    try {
      let finalThumbnailUrl = formData.thumbnailUrl;

      // Upload thumbnail to Supabase if a new file was selected
      if (thumbnailFile) {
        setIsUploadingThumbnail(true);
        const fileName = `${Date.now()}_${thumbnailFile.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
        const filePath = `stories/${draftId}/thumbnail/${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from('storyverse-media')
          .upload(filePath, thumbnailFile, {
            cacheControl: '3600',
            upsert: false
          });

        if (uploadError) {
          console.error("Supabase Upload Error Diagnostic:", {
            operation: "Upload Story Thumbnail",
            bucket: "storyverse-media",
            fileName: thumbnailFile.name,
            fileSize: thumbnailFile.size,
            fileMimeType: thumbnailFile.type,
            uploadPath: filePath,
            errorMessage: uploadError.message,
            errorName: uploadError.name
          });
          throw new Error("Supabase Upload Error: " + uploadError.message);
        }

        const { data: { publicUrl } } = supabase.storage
          .from('storyverse-media')
          .getPublicUrl(filePath);

        finalThumbnailUrl = publicUrl;
        setIsUploadingThumbnail(false);
      }

      setIsSavingStory(true);
      const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error('Firebase connection timeout (15s). The server did not respond.')), 15000));

      const payload = {
        ...formData,
        thumbnailUrl: finalThumbnailUrl,
        categoryId: formData.categoryId.toLowerCase(),
        genreId: formData.genreId.toLowerCase(),
        isPublished: formData.status === 'published',
        updatedAt: serverTimestamp()
      };

      if (isEditing) {
        await Promise.race([
          updateDoc(doc(db, 'stories', id), payload),
          timeoutPromise
        ]);
        setSuccessMsg('Story updated successfully!');
      } else {
        // Fetch actual episodes count in case user added them before saving (Draft Mode)
        let realCount = 0;
        try {
          const epsSnap = await getDocs(collection(db, 'stories', draftId, 'episodes'));
          realCount = epsSnap.size;
        } catch (e) { }

        await Promise.race([
          setDoc(doc(db, 'stories', draftId), {
            ...payload,
            id: draftId,
            totalEpisodes: realCount,
            totalViews: 0,
            views: 0,
            rating: 0,
            createdAt: serverTimestamp(),
          }),
          timeoutPromise
        ]);
        setSuccessMsg('Story created successfully!');
        setTimeout(() => navigate(`/stories`), 1500);
      }
    } catch (error: any) {
      console.error("Failed to save story", error);
      setErrorMsg("Failed to save story: " + error.message);
    } finally {
      setIsUploadingThumbnail(false);
      setIsSavingStory(false);
    }
  };

  if (loading) return (
    <div className="flex items-center justify-center p-20">
      <div className="w-10 h-10 rounded-full border-4 border-primary border-t-transparent animate-spin"></div>
    </div>
  );

  const isFormBusy = isUploadingThumbnail || isSavingStory;
  let saveButtonText = isSavingStory ? 'Saving...' : 'Save Story';
  if (isUploadingThumbnail) saveButtonText = 'Uploading Thumbnail...';

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
          <button
            onClick={handleSubmit}
            disabled={isFormBusy}
            className="flex items-center gap-2 px-6 py-3 bg-primary text-on-primary rounded-full font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors disabled:opacity-50 shadow-lg"
          >
            <Save size={20} />
            {saveButtonText}
          </button>
        </div>
      </div>

      {errorMsg && (
        <div className="p-4 bg-error-container text-on-error-container rounded-xl flex items-center gap-3 font-medium">
          <AlertTriangle size={20} className="shrink-0" />
          <p>{errorMsg}</p>
        </div>
      )}

      {successMsg && (
        <div className="p-4 bg-tertiary-container text-on-tertiary-container rounded-xl flex items-center gap-3 font-medium">
          <CheckCircle2 size={20} className="shrink-0" />
          <p>{successMsg}</p>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 flex flex-col gap-6">
          {/* Main Info */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
            <h2 className="text-headline-sm font-bold border-b border-surface-container-highest pb-2 mb-2">Basic Information</h2>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Title <span className="text-primary">*</span></label>
              <input
                type="text" required disabled={isFormBusy}
                value={formData.title} onChange={e => setFormData({ ...formData, title: e.target.value })}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none text-on-surface disabled:opacity-50"
                placeholder="Enter story title"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Short Description</label>
              <textarea
                rows={2} required disabled={isFormBusy}
                value={formData.description} onChange={e => setFormData({ ...formData, description: e.target.value })}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none text-on-surface disabled:opacity-50"
                placeholder="Brief summary"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Full Description (Optional)</label>
              <textarea
                rows={4} disabled={isFormBusy}
                value={formData.fullDescription} onChange={e => setFormData({ ...formData, fullDescription: e.target.value })}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none text-on-surface disabled:opacity-50"
                placeholder="Detailed story background..."
              />
            </div>
          </div>

          <div className="mt-2">
            <h2 className="text-headline-sm font-bold mb-4">Episodes</h2>
            <div className="bg-surface-container-low rounded-xl p-6 border border-surface-container">
              {!isEditing && <p className="text-tertiary text-sm mb-4">You can add episodes right now! They will be linked to this story once you click "Save Story".</p>}
              <EpisodesManager storyId={draftId} />
            </div>
          </div>
        </div>

        <div className="flex flex-col gap-6">
          {/* Media Assets (Thumbnail) */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
            <h2 className="text-headline-sm font-bold border-b border-surface-container-highest pb-2 mb-2">Story Thumbnail <span className="text-primary">*</span></h2>

            <div className="flex flex-col gap-2">
              <label className="text-label-md text-on-surface-variant">Thumbnail (Portrait 2:3)</label>
              <div
                className={`w-full aspect-[2/3] bg-surface-container-lowest rounded-xl overflow-hidden relative group border-2 border-dashed border-surface-container-highest transition-colors ${isFormBusy ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer hover:border-primary'}`}
                onClick={() => { if (!isFormBusy) fileInputRef.current?.click(); }}
              >
                {(thumbnailPreview || formData.thumbnailUrl) ? (
                  <img src={thumbnailPreview || formData.thumbnailUrl} alt="Thumbnail" className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex flex-col items-center justify-center text-outline">
                    <ImageIcon size={40} className="mb-3" />
                    <span className="font-label-lg">Select Image</span>
                    <span className="text-xs mt-1">JPG, PNG, WebP</span>
                  </div>
                )}

                {!isFormBusy && (
                  <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center">
                    <UploadCloud size={32} className="text-white mb-2" />
                    <span className="text-white text-sm font-bold">Replace Thumbnail</span>
                  </div>
                )}

                <input
                  type="file" ref={fileInputRef} accept="image/*" disabled={isFormBusy}
                  onChange={e => e.target.files?.[0] && handleImageSelect(e.target.files[0])}
                  className="hidden"
                />
              </div>

              {isUploadingThumbnail && (
                <div className="flex flex-col gap-1 mt-2">
                  <div className="flex justify-between text-xs text-on-surface-variant">
                    <span>Uploading thumbnail...</span>
                  </div>
                  <div className="w-full bg-surface-container-highest rounded-full h-1.5 overflow-hidden relative">
                    <div className="bg-primary h-full w-full animate-pulse"></div>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Settings */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
            <h2 className="text-headline-sm font-bold border-b border-surface-container-highest pb-2 mb-2">Metadata</h2>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Status</label>
              <select
                value={formData.status} onChange={e => setFormData({ ...formData, status: e.target.value })}
                disabled={isFormBusy}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none disabled:opacity-50"
              >
                <option value="draft">Draft (Hidden)</option>
                <option value="published">Published</option>
              </select>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Category</label>
              <input
                type="text" required disabled={isFormBusy}
                value={formData.categoryId} onChange={e => setFormData({ ...formData, categoryId: e.target.value })}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none disabled:opacity-50"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-label-md text-on-surface-variant">Author</label>
              <input
                type="text" disabled={isFormBusy}
                value={formData.author} onChange={e => setFormData({ ...formData, author: e.target.value })}
                className="w-full bg-surface-container-lowest px-4 py-3 rounded-lg border border-surface-container-highest focus:border-primary outline-none disabled:opacity-50"
              />
            </div>

            <label className="flex items-center gap-3 mt-4 cursor-pointer p-3 border border-surface-container-highest rounded-lg bg-surface-container-lowest hover:bg-surface-container-high transition-colors">
              <input
                type="checkbox" disabled={isFormBusy}
                checked={formData.isTrending} onChange={e => setFormData({ ...formData, isTrending: e.target.checked })}
                className="w-5 h-5 accent-primary rounded cursor-pointer disabled:opacity-50"
              />
              <span className="font-label-lg">Feature as Trending</span>
            </label>
          </div>

        </div>
      </div>
    </div>
  );
}
