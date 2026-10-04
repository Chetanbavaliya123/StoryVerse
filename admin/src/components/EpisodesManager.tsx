import { useEffect, useState, useRef } from 'react';
import { collection, query, onSnapshot, doc, deleteDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { supabase } from '../lib/supabase';
import { Plus, Edit, Trash2, X, Image as ImageIcon, Video, UploadCloud, Link as LinkIcon, AlertTriangle, CheckCircle2 } from 'lucide-react';

export default function EpisodesManager({ storyId }: { storyId: string }) {
  const [episodes, setEpisodes] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingEpisode, setEditingEpisode] = useState<any>(null);
  const [draftId, setDraftId] = useState('');
  
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    episodeNumber: 1,
    duration: 0,
    thumbnailUrl: '',
    mediaType: 'video',
    sourceType: 'external', // 'external' or 'uploaded'
    videoUrl: '',
    storagePath: ''
  });

  // Separate states for operations as required
  const [thumbnailFile, setThumbnailFile] = useState<File | null>(null);
  const [thumbnailPreview, setThumbnailPreview] = useState<string>('');
  const [isUploadingThumbnail, setIsUploadingThumbnail] = useState(false);

  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [isUploadingVideo, setIsUploadingVideo] = useState(false);
  const [videoUploadProgress, setVideoUploadProgress] = useState(0);

  const [isSavingEpisode, setIsSavingEpisode] = useState(false);

  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const fileInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const q = query(collection(db, 'stories', storyId, 'episodes'));
    const unsubscribe = onSnapshot(q, 
      (snapshot) => {
        const fetched = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
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

  useEffect(() => {
    // Cleanup object URL to prevent memory leaks
    return () => {
      if (thumbnailPreview) {
        URL.revokeObjectURL(thumbnailPreview);
      }
    };
  }, [thumbnailPreview]);

  const resetForm = () => {
    setEditingEpisode(null);
    setDraftId('');
    setErrorMsg('');
    setSuccessMsg('');
    setFormData({ 
      title: '', description: '', episodeNumber: 1, duration: 0, thumbnailUrl: '',
      mediaType: 'video', sourceType: 'external', videoUrl: '', storagePath: ''
    });
    setThumbnailFile(null);
    if (thumbnailPreview) URL.revokeObjectURL(thumbnailPreview);
    setThumbnailPreview('');
    setIsUploadingThumbnail(false);

    setVideoFile(null);
    setIsUploadingVideo(false);
    setVideoUploadProgress(0);
    setIsSavingEpisode(false);
  };

  const handleThumbnailSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      setErrorMsg("Please select a valid image file for the thumbnail.");
      return;
    }
    if (file.size > 45 * 1024 * 1024) {
      setErrorMsg("Thumbnail file size should be less than 45 MB.");
      return;
    }
    setErrorMsg('');
    setThumbnailFile(file);
    const objectUrl = URL.createObjectURL(file);
    setThumbnailPreview(objectUrl);
  };

  const handleVideoSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    
    const isMp4 = file.type === 'video/mp4' || file.name.toLowerCase().endsWith('.mp4');
    if (!isMp4) {
      setErrorMsg("Please select a valid MP4 video file.");
      return;
    }
    if (file.size > 45 * 1024 * 1024) {
      setErrorMsg("Video must be smaller than 45 MB on the Supabase Free plan.");
      return;
    }

    setErrorMsg('');
    setVideoFile(file);
    uploadVideo(file);
  };

  const uploadVideo = async (file: File) => {
    setIsUploadingVideo(true);
    setVideoUploadProgress(0);
    setErrorMsg('');
    
    try {
      const safeFileName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_');
      const filePath = `videos/${Date.now()}-${safeFileName}`;

      // Simulate a generic progress since standard upload doesn't have progress callback
      setVideoUploadProgress(10);

      setVideoUploadProgress(50);

      const { error } = await supabase.storage
        .from('storyverse-media')
        .upload(filePath, file, {
          contentType: file.type || 'video/mp4',
          cacheControl: '3600',
          upsert: false
        });

      if (error) {
        console.error("Supabase Upload Error Diagnostic:", {
          operation: "Upload MP4 Video",
          bucket: "storyverse-media",
          fileName: file.name,
          fileSize: file.size,
          fileMimeType: file.type,
          uploadPath: filePath,
          errorMessage: error.message,
          errorName: error.name
        });
        throw error;
      }

      setVideoUploadProgress(100);

      const { data: { publicUrl } } = supabase.storage
        .from('storyverse-media')
        .getPublicUrl(filePath);

      setFormData(prev => ({
        ...prev,
        videoUrl: publicUrl,
        storagePath: filePath,
        sourceType: 'uploaded'
      }));
      setSuccessMsg("Video uploaded successfully.");
      setTimeout(() => setSuccessMsg(''), 3000);
      setIsUploadingVideo(false);
    } catch (err: any) {
      console.error("Upload preparation failed:", err);
      let errorCategory = "Network/Storage Error";
      if (err.message && err.message.toLowerCase().includes('mime')) errorCategory = "Unsupported file type";
      else if (err.message && err.message.toLowerCase().includes('fetch')) errorCategory = "Network error";
      else if (err.message && err.message.toLowerCase().includes('permission')) errorCategory = "Storage permission error";
      else if (err.message && err.message.toLowerCase().includes('bucket')) errorCategory = "Bucket error";
      
      setErrorMsg(`Upload failed [${errorCategory}]: ${err.message || 'Please check your connection and try again.'}`);
      setIsUploadingVideo(false);
    }
  };

  const handleRemoveVideo = async () => {
    if (formData.storagePath && formData.sourceType === 'uploaded') {
      try {
        await supabase.storage.from('storyverse-media').remove([formData.storagePath]);
      } catch (err) {
        console.warn("Could not delete old video", err);
      }
    }
    setFormData(prev => ({ ...prev, videoUrl: '', storagePath: '' }));
    setVideoFile(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');
    setSuccessMsg('');

    if (!formData.title.trim()) {
      setErrorMsg("Episode title is required.");
      return;
    }

    let finalVideoUrl = formData.videoUrl;

    if (formData.sourceType === 'external') {
      if (!formData.videoUrl) {
        setErrorMsg("Please provide a valid video URL.");
        return;
      }
      
      try {
        const parsed = new URL(formData.videoUrl);
        
        if (parsed.hostname.includes('youtube.com') || parsed.hostname.includes('youtu.be')) {
          setErrorMsg("YouTube URLs are not supported as direct video sources. Please use an MP4 link or Supabase upload.");
          return;
        }

        if (parsed.hostname.includes('drive.google.com')) {
          const match = parsed.pathname.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
          if (match && match[1]) {
            // Convert to download/stream URL for Google Drive
            finalVideoUrl = `https://drive.google.com/uc?export=download&id=${match[1]}`;
          } else {
            setErrorMsg("Invalid Google Drive sharing URL format. Please use the 'Copy link' option directly on the video file.");
            return;
          }
        }
      } catch (e) {
        setErrorMsg("Please provide a valid URL (starting with http:// or https://).");
        return;
      }
    }

    if (formData.sourceType === 'uploaded' && !formData.videoUrl) {
      if (isUploadingVideo) {
        setErrorMsg("Please wait for the video to finish uploading.");
      } else if (videoFile) {
        setErrorMsg("Video upload failed previously. Please verify your connection or try a smaller video.");
      } else {
        setErrorMsg("Please upload an MP4 video.");
      }
      return;
    }

    try {
      let finalThumbnailUrl = formData.thumbnailUrl;

      // Upload thumbnail only when appropriate (during save)
      if (thumbnailFile) {
        setIsUploadingThumbnail(true);
        const fileName = `${Date.now()}_${thumbnailFile.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
        const filePath = `stories/${storyId}/episodes/${draftId}/thumbnail/${fileName}`;
        
        const { error: uploadError } = await supabase.storage
          .from('storyverse-media')
          .upload(filePath, thumbnailFile, {
            contentType: thumbnailFile.type || 'image/jpeg',
            cacheControl: '3600',
            upsert: false
          });

        if (uploadError) {
          console.error("Supabase Upload Error Diagnostic:", {
            operation: "Upload Episode Thumbnail",
            bucket: "storyverse-media",
            fileName: thumbnailFile.name,
            fileSize: thumbnailFile.size,
            fileMimeType: thumbnailFile.type,
            uploadPath: filePath,
            errorMessage: uploadError.message,
            errorName: uploadError.name
          });
          throw new Error(`Thumbnail upload failed: ${uploadError.message}`);
        }

        const { data: { publicUrl } } = supabase.storage
          .from('storyverse-media')
          .getPublicUrl(filePath);

        finalThumbnailUrl = publicUrl;
        setIsUploadingThumbnail(false);
      }

      setIsSavingEpisode(true);

      const payload = {
        ...formData,
        videoUrl: finalVideoUrl,
        thumbnailUrl: finalThumbnailUrl,
        storyId,
        isPublished: true,
        updatedAt: serverTimestamp()
      };

      if (editingEpisode) {
        await updateDoc(doc(db, 'stories', storyId, 'episodes', editingEpisode.id), payload);
        setSuccessMsg("Episode updated successfully!");
      } else {
        await setDoc(doc(db, 'stories', storyId, 'episodes', draftId), {
          ...payload,
          createdAt: serverTimestamp()
        });
        
        // Update episode count if parent document exists
        try {
          await updateDoc(doc(db, 'stories', storyId), {
            totalEpisodes: episodes.length + 1
          });
        } catch (updateErr) {
          console.warn("Parent story doesn't exist yet to update count (Draft Mode)");
        }
        setSuccessMsg("Episode saved successfully!");
      }
      
      setTimeout(() => {
        setIsModalOpen(false);
        resetForm();
      }, 1000);
      
    } catch (error: any) {
      console.error("Failed to save episode", error);
      setErrorMsg("Failed to save episode: " + error.message);
    } finally {
      setIsUploadingThumbnail(false);
      setIsSavingEpisode(false);
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
    console.log("Opening Add Episode Modal. Story ID:", storyId);
    try {
      resetForm();
      const newId = doc(collection(db, 'stories', storyId, 'episodes')).id;
      setDraftId(newId);
      setFormData(prev => ({ ...prev, episodeNumber: episodes.length + 1, sourceType: 'external' }));
      setIsModalOpen(true);
    } catch (e) {
      console.error("Error opening modal:", e);
    }
  };

  const openEditModal = (ep: any) => {
    resetForm();
    setEditingEpisode(ep);
    setDraftId(ep.id);
    setFormData({
      title: ep.title || '',
      description: ep.description || '',
      episodeNumber: ep.episodeNumber || 1,
      duration: ep.duration || 0,
      thumbnailUrl: ep.thumbnailUrl || '',
      mediaType: ep.mediaType || 'video',
      sourceType: ep.sourceType || 'external',
      videoUrl: ep.videoUrl || '',
      storagePath: ep.storagePath || ''
    });
    setIsModalOpen(true);
  };

  // Compute Save Button text
  let saveButtonText = editingEpisode ? 'Save Changes' : 'Create Episode';
  if (isUploadingVideo) saveButtonText = 'Uploading Video...';
  if (isUploadingThumbnail) saveButtonText = 'Uploading Thumbnail...';
  if (isSavingEpisode) saveButtonText = 'Saving Episode...';

  const isFormBusy = isUploadingVideo || isUploadingThumbnail || isSavingEpisode;

  return (
    <div className="flex flex-col gap-4 mt-8 pt-8 border-t border-surface-container-highest">
      <div className="flex items-center justify-between">
        <h2 className="text-headline-md font-bold">Episodes</h2>
        <button 
          type="button"
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
              <button onClick={() => setIsModalOpen(false)} className="p-2 hover:bg-surface-container rounded-full transition-colors" disabled={isFormBusy}>
                <X size={20} />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 flex flex-col gap-6">
              {errorMsg && (
                <div className="p-3 bg-error-container text-on-error-container rounded-lg flex items-center gap-2 font-medium text-sm">
                  <AlertTriangle size={18} className="shrink-0" />
                  <p>{errorMsg}</p>
                </div>
              )}
              {successMsg && (
                <div className="p-3 bg-tertiary-container text-on-tertiary-container rounded-lg flex items-center gap-2 font-medium text-sm">
                  <CheckCircle2 size={18} className="shrink-0" />
                  <p>{successMsg}</p>
                </div>
              )}

              <form id="episode-form" onSubmit={handleSubmit} className="flex flex-col gap-6">
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5 col-span-2 md:col-span-1">
                    <label className="text-label-md text-on-surface-variant">Episode Title <span className="text-primary">*</span></label>
                    <input 
                      type="text" required disabled={isFormBusy}
                      value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})}
                      className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary outline-none disabled:opacity-50"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5 col-span-2 md:col-span-1">
                    <label className="text-label-md text-on-surface-variant">Episode Number <span className="text-primary">*</span></label>
                    <input 
                      type="number" required min="1" disabled={isFormBusy}
                      value={formData.episodeNumber} onChange={e => setFormData({...formData, episodeNumber: parseInt(e.target.value)})}
                      className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary outline-none disabled:opacity-50"
                    />
                  </div>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-label-md text-on-surface-variant">Description</label>
                  <textarea 
                    rows={3} disabled={isFormBusy}
                    value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}
                    className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary outline-none disabled:opacity-50"
                  ></textarea>
                </div>

                <div className="bg-surface-container-low rounded-xl p-4 border border-surface-container-high flex flex-col gap-4">
                  <h3 className="text-label-lg font-bold">Media Source <span className="text-primary">*</span></h3>
                  <div className="flex gap-4">
                    <label className="flex items-center gap-2 cursor-pointer p-3 rounded-lg border border-surface-container hover:bg-surface-container-high transition-colors flex-1">
                      <input 
                        type="radio" name="sourceType" value="external" disabled={isFormBusy}
                        checked={formData.sourceType === 'external'}
                        onChange={() => setFormData({...formData, sourceType: 'external', videoUrl: '', storagePath: ''})}
                        className="accent-primary w-4 h-4 disabled:opacity-50"
                      />
                      <LinkIcon size={16} className="text-outline" />
                      <span className="font-label-md">External URL</span>
                    </label>
                    <label className="flex items-center gap-2 cursor-pointer p-3 rounded-lg border border-surface-container hover:bg-surface-container-high transition-colors flex-1">
                      <input 
                        type="radio" name="sourceType" value="uploaded" disabled={isFormBusy}
                        checked={formData.sourceType === 'uploaded'}
                        onChange={() => setFormData({...formData, sourceType: 'uploaded', videoUrl: ''})}
                        className="accent-primary w-4 h-4 disabled:opacity-50"
                      />
                      <UploadCloud size={16} className="text-outline" />
                      <span className="font-label-md">Upload MP4</span>
                    </label>
                  </div>

                  {formData.sourceType === 'external' ? (
                    <div className="flex flex-col gap-1.5 mt-2">
                      <label className="text-label-md text-on-surface-variant">External Video URL</label>
                      <input 
                        type="url" disabled={isFormBusy}
                        placeholder="https://example.com/video.mp4"
                        value={formData.videoUrl} onChange={e => setFormData({...formData, videoUrl: e.target.value})}
                        className="w-full bg-surface-container px-4 py-3 rounded-lg border border-surface-container-high focus:border-primary outline-none disabled:opacity-50"
                      />
                    </div>
                  ) : (
                    <div className="flex flex-col gap-4 mt-2">
                      <div className="flex items-center justify-between">
                        <label className="text-label-md text-on-surface-variant">Upload MP4 Video</label>
                        {formData.videoUrl && !isFormBusy && (
                          <button onClick={handleRemoveVideo} type="button" className="text-xs text-error hover:underline flex items-center gap-1">
                            <X size={12} /> Remove Video
                          </button>
                        )}
                      </div>
                      
                      {formData.videoUrl ? (
                        <div className="flex flex-col gap-2">
                           <div className="relative aspect-video rounded-lg overflow-hidden bg-black border border-surface-container">
                             <video src={formData.videoUrl} controls className="w-full h-full object-contain" />
                           </div>
                           <div className="text-sm font-medium text-primary">Video uploaded successfully.</div>
                        </div>
                      ) : (
                        <div className={`flex flex-col items-center justify-center p-6 border-2 border-dashed border-surface-container-high rounded-xl bg-surface-container hover:bg-surface-container-high transition-colors ${isFormBusy ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
                             onClick={() => { if (!isFormBusy) videoInputRef.current?.click(); }}
                        >
                          <Video size={32} className="text-outline mb-2" />
                          <span className="font-label-md">{videoFile ? videoFile.name : 'Click to select MP4'}</span>
                          <span className="text-xs text-on-surface-variant mt-1">{videoFile ? `${(videoFile.size / (1024 * 1024)).toFixed(2)} MB` : 'Max 45MB'}</span>
                          <input 
                            type="file" ref={videoInputRef} accept="video/mp4,.mp4" disabled={isFormBusy}
                            onChange={handleVideoSelect}
                            className="hidden" 
                          />
                        </div>
                      )}
                      
                      {isUploadingVideo && (
                        <div className="flex flex-col gap-1">
                          <div className="flex justify-between text-xs text-on-surface-variant">
                            <span>Uploading video...</span>
                            <span>{Math.round(videoUploadProgress)}%</span>
                          </div>
                          <div className="w-full bg-surface-container-high rounded-full h-1.5 overflow-hidden">
                            <div className="bg-primary h-full transition-all duration-300" style={{ width: `${videoUploadProgress}%` }}></div>
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </div>

                <div className="flex flex-col gap-2">
                  <label className="text-label-md text-on-surface-variant">Episode Thumbnail</label>
                  <div className="flex items-center gap-4">
                    {(thumbnailPreview || formData.thumbnailUrl) ? (
                      <div className="w-32 aspect-video rounded overflow-hidden bg-surface-container relative group border border-surface-container-high cursor-pointer" onClick={() => { if (!isFormBusy) fileInputRef.current?.click(); }}>
                        <img src={thumbnailPreview || formData.thumbnailUrl} alt="Thumb" className="w-full h-full object-cover" />
                        <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                          <UploadCloud size={24} className="text-white" />
                        </div>
                      </div>
                    ) : (
                      <div 
                        className={`w-32 aspect-video rounded flex flex-col items-center justify-center bg-surface-container hover:bg-surface-container-high border border-surface-container-high transition-colors text-outline ${isFormBusy ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
                        onClick={() => { if (!isFormBusy) fileInputRef.current?.click(); }}
                      >
                        <ImageIcon size={24} className="mb-1" />
                        <span className="text-[10px]">Add Thumb</span>
                      </div>
                    )}
                    <div className="flex-1 flex flex-col gap-2">
                      {thumbnailFile && <span className="text-sm text-on-surface font-medium">{thumbnailFile.name}</span>}
                      <input 
                        type="file" ref={fileInputRef} accept="image/*" disabled={isFormBusy}
                        onChange={handleThumbnailSelect}
                        className="hidden"
                      />
                      {isUploadingThumbnail && (
                        <div className="flex flex-col gap-1">
                          <div className="flex justify-between text-xs text-on-surface-variant">
                            <span>Uploading thumbnail...</span>
                          </div>
                          <div className="w-full bg-surface-container-high rounded-full h-1.5 overflow-hidden relative">
                            <div className="bg-primary h-full w-full animate-pulse"></div>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </form>
            </div>
            
            <div className="p-6 border-t border-surface-container bg-surface-container-lowest flex justify-end gap-3">
              <button onClick={() => setIsModalOpen(false)} type="button" disabled={isFormBusy} className="px-6 py-2.5 rounded-full font-bold hover:bg-surface-container transition-colors disabled:opacity-50">
                Cancel
              </button>
              <button 
                form="episode-form" type="submit" 
                disabled={isFormBusy} 
                className="px-6 py-2.5 bg-primary text-on-primary rounded-full font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors disabled:opacity-50"
              >
                {saveButtonText}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
