import React, { useEffect, useState, useRef } from 'react';
import { collection, query, onSnapshot, doc, deleteDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { supabase } from '../lib/supabase';
import * as tus from 'tus-js-client';
import {
  Plus,
  Pencil,
  Trash2,
  Image as ImageIcon,
  Video,
  UploadCloud,
  Link as LinkIcon,
  AlertTriangle,
  Lock,
  MoveUp,
  MoveDown,
  Camera,
  Clock,
  Film,
  CheckCircle2,
} from 'lucide-react';
import { Modal } from './ui/Modal';
import { Button } from './ui/Button';
import { Input } from './ui/Input';
import { Textarea } from './ui/Textarea';
import { ToggleSwitch } from './ui/ToggleSwitch';
import { SegmentedControl } from './ui/SegmentedControl';
import { Badge } from './ui/Badge';
import { useToast } from './ui/ToastContext';

interface EpisodeItem {
  id: string;
  title: string;
  description?: string;
  episodeNumber: number;
  duration?: number;
  thumbnailUrl?: string;
  mediaType?: string;
  sourceType?: 'external' | 'uploaded';
  videoUrl?: string;
  storagePath?: string;
  isPublished?: boolean;
  isLocked?: boolean;
}

export default function EpisodesManager({ storyId }: { storyId: string }) {
  const [episodes, setEpisodes] = useState<EpisodeItem[]>([]);
  const [loading, setLoading] = useState(true);
  const toast = useToast();

  // Drawer states
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingEpisode, setEditingEpisode] = useState<EpisodeItem | null>(null);
  const [draftId, setDraftId] = useState('');

  // Form states
  const [formData, setFormData] = useState<{
    title: string;
    description: string;
    episodeNumber: number;
    duration: number;
    thumbnailUrl: string;
    mediaType: string;
    sourceType: 'external' | 'uploaded';
    videoUrl: string;
    storagePath: string;
    isPublished: boolean;
    isLocked: boolean;
  }>({
    title: '',
    description: '',
    episodeNumber: 1,
    duration: 0,
    thumbnailUrl: '',
    mediaType: 'video',
    sourceType: 'external',
    videoUrl: '',
    storagePath: '',
    isPublished: true,
    isLocked: false,
  });

  // Media files & uploads
  const [thumbnailFile, setThumbnailFile] = useState<File | null>(null);
  const [thumbnailPreview, setThumbnailPreview] = useState<string>('');
  const [isUploadingThumbnail, setIsUploadingThumbnail] = useState(false);

  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [isUploadingVideo, setIsUploadingVideo] = useState(false);
  const [videoUploadProgress, setVideoUploadProgress] = useState(0);
  const activeTusUploadRef = useRef<tus.Upload | null>(null);

  const [isSavingEpisode, setIsSavingEpisode] = useState(false);
  const [formError, setFormError] = useState('');

  const fileInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);
  const previewVideoRef = useRef<HTMLVideoElement>(null);

  // Subscribe to episodes
  useEffect(() => {
    if (!storyId) return;
    const q = query(collection(db, 'stories', storyId, 'episodes'));
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const fetched = snapshot.docs.map((d) => ({ id: d.id, ...d.data() } as EpisodeItem));
        fetched.sort((a, b) => (a.episodeNumber || 0) - (b.episodeNumber || 0));
        setEpisodes(fetched);
        setLoading(false);
      },
      (error) => {
        console.error('Error fetching episodes:', error);
        toast.showToast({
          type: 'error',
          title: 'Failed to load episodes',
          message: error.message,
        });
        setLoading(false);
      }
    );
    return () => unsubscribe();
  }, [storyId]);

  // Clean object preview URL
  useEffect(() => {
    return () => {
      if (thumbnailPreview && thumbnailPreview.startsWith('blob:')) {
        URL.revokeObjectURL(thumbnailPreview);
      }
    };
  }, [thumbnailPreview]);

  const resetForm = (nextEpNumber?: number) => {
    setEditingEpisode(null);
    setDraftId('');
    setFormError('');
    setFormData({
      title: '',
      description: '',
      episodeNumber: nextEpNumber ?? (episodes.length + 1),
      duration: 0,
      thumbnailUrl: '',
      mediaType: 'video',
      sourceType: 'external',
      videoUrl: '',
      storagePath: '',
      isPublished: true,
      isLocked: false,
    });
    setThumbnailFile(null);
    if (thumbnailPreview && thumbnailPreview.startsWith('blob:')) {
      URL.revokeObjectURL(thumbnailPreview);
    }
    setThumbnailPreview('');
    setIsUploadingThumbnail(false);

    setVideoFile(null);
    setIsUploadingVideo(false);
    setVideoUploadProgress(0);
    if (activeTusUploadRef.current) {
      try {
        activeTusUploadRef.current.abort();
      } catch (e) {}
      activeTusUploadRef.current = null;
    }
    setIsSavingEpisode(false);
  };

  const openAddDrawer = () => {
    resetForm(episodes.length + 1);
    const newId = doc(collection(db, 'stories', storyId, 'episodes')).id;
    setDraftId(newId);
    setIsDrawerOpen(true);
  };

  const openEditDrawer = (ep: EpisodeItem) => {
    resetForm(ep.episodeNumber);
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
      storagePath: ep.storagePath || '',
      isPublished: ep.isPublished !== false,
      isLocked: ep.isLocked === true,
    });
    setIsDrawerOpen(true);
  };

  const handleThumbnailSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      setFormError('Please select a valid image file for the thumbnail.');
      return;
    }
    if (file.size > 25 * 1024 * 1024) {
      setFormError('Thumbnail file size should be less than 25 MB.');
      return;
    }
    setFormError('');
    setThumbnailFile(file);
    const objectUrl = URL.createObjectURL(file);
    setThumbnailPreview(objectUrl);
  };

  // Capture video frame as thumbnail
  const handleCaptureVideoFrame = () => {
    const video = previewVideoRef.current;
    if (!video || !video.videoWidth) {
      toast.showToast({
        type: 'info',
        title: 'Video not ready',
        message: 'Play or pause the video at the frame you wish to capture.',
      });
      return;
    }

    try {
      const canvas = document.createElement('canvas');
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const ctx = canvas.getContext('2d');
      if (!ctx) return;
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

      canvas.toBlob(
        (blob) => {
          if (!blob) return;
          const capturedFile = new File(
            [blob],
            `frame_ep${formData.episodeNumber}_${Date.now()}.jpg`,
            { type: 'image/jpeg' }
          );
          setThumbnailFile(capturedFile);
          const objectUrl = URL.createObjectURL(capturedFile);
          setThumbnailPreview(objectUrl);
          toast.showToast({
            type: 'success',
            title: 'Frame Captured',
            message: 'Current video frame set as episode thumbnail.',
          });
        },
        'image/jpeg',
        0.88
      );
    } catch (err: any) {
      console.error('Frame capture failed:', err);
      toast.showToast({
        type: 'error',
        title: 'Capture Failed',
        message: 'Could not capture frame. (Cross-origin CORS restrictions may apply for external URLs).',
      });
    }
  };

  const handleVideoSelect = (file: File) => {
    const isMp4 = file.type === 'video/mp4' || file.name.toLowerCase().endsWith('.mp4');
    if (!isMp4) {
      setFormError('Please select a valid MP4 video file.');
      return;
    }
    if (file.size > 45 * 1024 * 1024) {
      setFormError('Video must be smaller than 45 MB on the Supabase Free plan.');
      return;
    }

    setFormError('');
    setVideoFile(file);
    uploadVideoWithTus(file);
  };

  const uploadVideoWithTus = async (file: File) => {
    setIsUploadingVideo(true);
    setVideoUploadProgress(0);
    setFormError('');

    try {
      const safeFileName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_');
      const filePath = `videos/${Date.now()}-${safeFileName}`;

      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://isqxomfulycmxccbvfyi.supabase.co';
      const supabaseKey =
        import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
        'sb_publishable_S2am5rwWRBOzl0p1efGwRA_xY3zrcFJ';

      const {
        data: { session },
      } = await supabase.auth.getSession();
      const authToken = session?.access_token || supabaseKey;

      const upload = new tus.Upload(file, {
        endpoint: `${supabaseUrl}/storage/v1/upload/resumable`,
        retryDelays: [0, 3000, 5000, 10000, 20000],
        headers: {
          authorization: `Bearer ${authToken}`,
          apikey: supabaseKey,
          'x-upsert': 'false',
        },
        uploadDataDuringCreation: true,
        removeFingerprintOnSuccess: true,
        metadata: {
          bucketName: 'storyverse-media',
          objectName: filePath,
          contentType: file.type || 'video/mp4',
          cacheControl: '3600',
        },
        chunkSize: 6 * 1024 * 1024,
        onError: function (error) {
          console.error('TUS Upload failed:', error);
          setFormError(`Upload failed: ${error.message || 'Please check your connection.'}`);
          setIsUploadingVideo(false);
        },
        onProgress: function (bytesUploaded, bytesTotal) {
          const percentage = (bytesUploaded / bytesTotal) * 100;
          setVideoUploadProgress(percentage);
        },
        onSuccess: function () {
          const {
            data: { publicUrl },
          } = supabase.storage.from('storyverse-media').getPublicUrl(filePath);

          setFormData((prev) => ({
            ...prev,
            videoUrl: publicUrl,
            storagePath: filePath,
            sourceType: 'uploaded',
          }));
          toast.showToast({
            type: 'success',
            title: 'Upload Complete',
            message: 'MP4 video successfully uploaded to Supabase.',
          });
          setIsUploadingVideo(false);
          activeTusUploadRef.current = null;
        },
      });

      activeTusUploadRef.current = upload;
      upload.findPreviousUploads().then((previousUploads) => {
        if (previousUploads.length) {
          upload.resumeFromPreviousUpload(previousUploads[0]);
        }
        upload.start();
      });
    } catch (err: any) {
      console.error('Upload preparation failed:', err);
      setFormError(`Upload failed: ${err.message || 'Please check your connection and try again.'}`);
      setIsUploadingVideo(false);
    }
  };

  const cancelVideoUpload = () => {
    if (activeTusUploadRef.current) {
      activeTusUploadRef.current.abort();
      activeTusUploadRef.current = null;
    }
    setIsUploadingVideo(false);
    setVideoUploadProgress(0);
    setVideoFile(null);
    toast.showToast({
      type: 'info',
      title: 'Upload cancelled',
      message: 'Video upload was stopped.',
    });
  };

  const handleRemoveVideo = async () => {
    if (formData.storagePath && formData.sourceType === 'uploaded') {
      try {
        await supabase.storage.from('storyverse-media').remove([formData.storagePath]);
      } catch (err) {
        console.warn('Could not delete old video', err);
      }
    }
    setFormData((prev) => ({ ...prev, videoUrl: '', storagePath: '' }));
    setVideoFile(null);
  };

  // Save episode (and optional: keep drawer open for next)
  const saveEpisode = async (andAddAnother = false) => {
    setFormError('');

    if (!formData.title.trim()) {
      setFormError('Episode title is required.');
      return;
    }

    let finalVideoUrl = formData.videoUrl.trim();

    if (formData.sourceType === 'external') {
      if (!finalVideoUrl) {
        setFormError('Please provide a valid video URL.');
        return;
      }

      try {
        const parsed = new URL(finalVideoUrl);
        if (parsed.hostname.includes('youtube.com') || parsed.hostname.includes('youtu.be')) {
          setFormError('YouTube links cannot stream directly in-app. Please use direct MP4 or Supabase upload.');
          return;
        }
        if (parsed.hostname.includes('drive.google.com')) {
          const match = parsed.pathname.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
          if (match && match[1]) {
            finalVideoUrl = `https://drive.google.com/uc?export=download&id=${match[1]}`;
          }
        }
      } catch (e) {
        setFormError('Please enter a valid URL beginning with http:// or https://');
        return;
      }
    }

    if (formData.sourceType === 'uploaded' && !formData.videoUrl) {
      if (isUploadingVideo) {
        setFormError('Please wait for the video to complete uploading.');
      } else {
        setFormError('Please upload an MP4 video file.');
      }
      return;
    }

    try {
      setIsSavingEpisode(true);
      let finalThumbnailUrl = formData.thumbnailUrl;

      // Upload thumbnail if a new one was selected/captured
      if (thumbnailFile) {
        setIsUploadingThumbnail(true);
        const fileName = `${Date.now()}_${thumbnailFile.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
        const filePath = `stories/${storyId}/episodes/${draftId}/thumbnail/${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from('storyverse-media')
          .upload(filePath, thumbnailFile, {
            contentType: thumbnailFile.type || 'image/jpeg',
            cacheControl: '3600',
            upsert: false,
          });

        if (uploadError) {
          throw new Error(`Thumbnail upload failed: ${uploadError.message}`);
        }

        const {
          data: { publicUrl },
        } = supabase.storage.from('storyverse-media').getPublicUrl(filePath);

        finalThumbnailUrl = publicUrl;
        setIsUploadingThumbnail(false);
      }

      const payload = {
        ...formData,
        videoUrl: finalVideoUrl,
        thumbnailUrl: finalThumbnailUrl,
        storyId,
        duration: Number(formData.duration) || 0,
        episodeNumber: Number(formData.episodeNumber) || 1,
        isPublished: formData.isPublished !== false,
        isLocked: !!formData.isLocked,
        updatedAt: serverTimestamp(),
      };

      if (editingEpisode) {
        await updateDoc(doc(db, 'stories', storyId, 'episodes', editingEpisode.id), payload);
        toast.showToast({
          type: 'success',
          title: 'Episode Updated',
          message: `Episode ${payload.episodeNumber}: "${payload.title}" saved.`,
        });
      } else {
        await setDoc(doc(db, 'stories', storyId, 'episodes', draftId), {
          ...payload,
          createdAt: serverTimestamp(),
        });

        // Update story parent counter if exists
        try {
          await updateDoc(doc(db, 'stories', storyId), {
            totalEpisodes: episodes.length + 1,
          });
        } catch (updateErr) {
          // Parent story might be in new draft mode
        }

        toast.showToast({
          type: 'success',
          title: 'Episode Created',
          message: `Episode ${payload.episodeNumber} added successfully.`,
        });
      }

      if (andAddAnother) {
        const nextNum = (Number(formData.episodeNumber) || episodes.length) + 1;
        resetForm(nextNum);
        const nextDraftId = doc(collection(db, 'stories', storyId, 'episodes')).id;
        setDraftId(nextDraftId);
      } else {
        setIsDrawerOpen(false);
        resetForm();
      }
    } catch (err: any) {
      console.error('Failed to save episode:', err);
      setFormError(`Save failed: ${err.message}`);
    } finally {
      setIsSavingEpisode(false);
      setIsUploadingThumbnail(false);
    }
  };

  const handleDelete = async (ep: EpisodeItem) => {
    if (window.confirm(`Delete Episode ${ep.episodeNumber}: "${ep.title}"?`)) {
      try {
        await deleteDoc(doc(db, 'stories', storyId, 'episodes', ep.id));
        try {
          await updateDoc(doc(db, 'stories', storyId), {
            totalEpisodes: Math.max(0, episodes.length - 1),
          });
        } catch (e) {}

        toast.showToast({
          type: 'info',
          title: 'Episode Deleted',
          message: `Episode ${ep.episodeNumber} was removed.`,
        });
      } catch (err: any) {
        toast.showToast({
          type: 'error',
          title: 'Delete Failed',
          message: err.message,
        });
      }
    }
  };

  // Reorder episodes up/down
  const handleReorder = async (index: number, direction: 'up' | 'down') => {
    const targetIndex = direction === 'up' ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= episodes.length) return;

    const currentEp = episodes[index];
    const targetEp = episodes[targetIndex];

    try {
      const currentNumber = currentEp.episodeNumber;
      const targetNumber = targetEp.episodeNumber;

      // Swap episode numbers
      await updateDoc(doc(db, 'stories', storyId, 'episodes', currentEp.id), {
        episodeNumber: targetNumber,
      });
      await updateDoc(doc(db, 'stories', storyId, 'episodes', targetEp.id), {
        episodeNumber: currentNumber,
      });

      toast.showToast({
        type: 'success',
        title: 'Order Updated',
        message: `Reordered Episode ${currentNumber} and ${targetNumber}.`,
      });
    } catch (e: any) {
      toast.showToast({
        type: 'error',
        title: 'Reorder Failed',
        message: e.message,
      });
    }
  };

  const formatDuration = (seconds?: number) => {
    if (!seconds || seconds <= 0) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
  };

  const isBusy = isUploadingVideo || isUploadingThumbnail || isSavingEpisode;

  return (
    <div className="flex flex-col gap-5">
      {/* Episodes Header & Stats */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-accent-coral/10 border border-accent-coral/20 flex items-center justify-center text-accent-coral">
            <Film size={18} />
          </div>
          <div>
            <h3 className="text-base font-semibold text-white tracking-tight">Story Episodes</h3>
            <p className="text-xs text-zinc-400">
              {episodes.length} {episodes.length === 1 ? 'episode' : 'episodes'} configured
            </p>
          </div>
        </div>

        <Button
          type="button"
          variant="primary"
          size="sm"
          onClick={openAddDrawer}
          leftIcon={<Plus size={16} />}
        >
          Add Episode
        </Button>
      </div>

      {/* Episode List */}
      {loading ? (
        <div className="p-10 flex flex-col items-center justify-center gap-3 bg-surface-1/40 rounded-2xl border border-white/[0.06]">
          <div className="w-7 h-7 rounded-full border-2 border-accent-coral border-t-transparent animate-spin" />
          <span className="text-xs text-zinc-500">Loading episodes...</span>
        </div>
      ) : episodes.length === 0 ? (
        <div className="p-10 flex flex-col items-center justify-center text-center gap-3 bg-surface-1/30 rounded-2xl border border-dashed border-white/[0.08]">
          <div className="w-12 h-12 rounded-2xl bg-white/[0.04] border border-white/[0.06] flex items-center justify-center text-zinc-500">
            <Film size={22} />
          </div>
          <div className="flex flex-col gap-1 max-w-sm">
            <h4 className="text-sm font-semibold text-white">No episodes created yet</h4>
            <p className="text-xs text-zinc-400 leading-relaxed">
              Every story needs at least 1 episode. Add your first episode with video URL or upload
              an MP4 file directly.
            </p>
          </div>
          <Button
            type="button"
            variant="secondary"
            size="sm"
            onClick={openAddDrawer}
            leftIcon={<Plus size={14} />}
            className="mt-2"
          >
            Create Episode 1
          </Button>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {episodes.map((ep, idx) => (
            <div
              key={ep.id}
              className="group flex flex-col sm:flex-row sm:items-center justify-between p-3.5 bg-surface-1/60 hover:bg-surface-2/70 border border-white/[0.06] hover:border-white/[0.12] rounded-xl transition-all duration-200 gap-3.5"
            >
              {/* Left Details */}
              <div className="flex items-center gap-3.5 min-w-0 flex-1">
                {/* Reorder Arrows */}
                <div className="flex flex-col items-center gap-0.5 text-zinc-500 shrink-0">
                  <button
                    type="button"
                    disabled={idx === 0}
                    onClick={() => handleReorder(idx, 'up')}
                    className="p-1 hover:text-white disabled:opacity-20 transition-colors"
                    title="Move up"
                  >
                    <MoveUp size={13} />
                  </button>
                  <button
                    type="button"
                    disabled={idx === episodes.length - 1}
                    onClick={() => handleReorder(idx, 'down')}
                    className="p-1 hover:text-white disabled:opacity-20 transition-colors"
                    title="Move down"
                  >
                    <MoveDown size={13} />
                  </button>
                </div>

                {/* 16:9 Thumbnail preview */}
                <div className="relative w-24 h-14 bg-surface-0 rounded-lg overflow-hidden border border-white/[0.08] shrink-0">
                  {ep.thumbnailUrl ? (
                    <img
                      src={ep.thumbnailUrl}
                      alt={ep.title}
                      className="w-full h-full object-cover"
                      onError={(e) => {
                        (e.currentTarget as HTMLElement).style.display = 'none';
                      }}
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-zinc-600 bg-surface-0">
                      <ImageIcon size={18} />
                    </div>
                  )}

                  {/* Episode Number badge */}
                  <div className="absolute bottom-1 left-1 px-1.5 py-0.5 bg-black/80 backdrop-blur-md rounded text-[10px] font-bold text-white tracking-wide">
                    EP {ep.episodeNumber}
                  </div>
                </div>

                {/* Meta */}
                <div className="flex flex-col gap-1 min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-sm font-semibold text-white tracking-tight truncate">
                      {ep.title}
                    </span>
                    {ep.isLocked && (
                      <span className="inline-flex items-center gap-1 text-[10px] font-medium text-amber-400 bg-amber-500/10 px-1.5 py-0.5 rounded border border-amber-500/20">
                        <Lock size={10} /> Locked
                      </span>
                    )}
                    {ep.isPublished === false && (
                      <span className="text-[10px] font-medium text-zinc-400 bg-white/[0.04] px-1.5 py-0.5 rounded">
                        Draft
                      </span>
                    )}
                  </div>

                  <div className="flex items-center gap-3 text-xs text-zinc-400 flex-wrap">
                    <span className="flex items-center gap-1 font-mono text-[11px] text-zinc-300">
                      <Clock size={11} className="text-zinc-500" />
                      {formatDuration(ep.duration)}
                    </span>
                    <span className="text-zinc-600">•</span>
                    <span className="flex items-center gap-1 text-zinc-400 text-[11px]">
                      {ep.sourceType === 'uploaded' ? (
                        <>
                          <UploadCloud size={11} className="text-sky-400" /> MP4 Upload
                        </>
                      ) : (
                        <>
                          <LinkIcon size={11} className="text-accent-coral" /> External URL
                        </>
                      )}
                    </span>
                  </div>
                </div>
              </div>

              {/* Action buttons */}
              <div className="flex items-center gap-1 self-end sm:self-center shrink-0">
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={() => openEditDrawer(ep)}
                  leftIcon={<Pencil size={13} />}
                  className="text-xs px-2.5 h-8"
                >
                  Edit
                </Button>
                <button
                  type="button"
                  onClick={() => handleDelete(ep)}
                  className="p-2 rounded-lg text-zinc-500 hover:text-red-400 hover:bg-red-500/10 transition-colors"
                  title="Delete episode"
                >
                  <Trash2 size={15} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ================= EPISODE MODAL (CENTERED) ================= */}
      <Modal
        isOpen={isDrawerOpen}
        onClose={() => {
          if (!isBusy) setIsDrawerOpen(false);
        }}
        title={
          <div className="flex items-center gap-2.5">
            <span>{editingEpisode ? `Edit Episode ${formData.episodeNumber}` : 'Add New Episode'}</span>
            <Badge variant={formData.isPublished ? 'published' : 'draft'} size="sm">
              {formData.isPublished ? 'Active' : 'Draft'}
            </Badge>
          </div>
        }
        subtitle={`Configure video stream, duration, and metadata for Story #${storyId.slice(0, 8)}`}
        maxWidth="3xl"
        footer={
          <div className="flex items-center justify-between w-full">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              disabled={isBusy}
              onClick={() => setIsDrawerOpen(false)}
            >
              Cancel
            </Button>

            <div className="flex items-center gap-2">
              {!editingEpisode && (
                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  disabled={isBusy}
                  onClick={() => saveEpisode(true)}
                >
                  Save & Add Another
                </Button>
              )}
              <Button
                type="button"
                variant="primary"
                size="sm"
                loading={isSavingEpisode}
                disabled={isBusy}
                onClick={() => saveEpisode(false)}
              >
                {isUploadingVideo
                  ? 'Uploading Video...'
                  : isUploadingThumbnail
                  ? 'Uploading Thumbnail...'
                  : editingEpisode
                  ? 'Save Changes'
                  : 'Create Episode'}
              </Button>
            </div>
          </div>
        }
      >
        <div className="space-y-6">
          {formError && (
            <div className="p-3.5 bg-red-500/10 border border-red-500/20 text-red-400 rounded-xl flex items-start gap-3 text-xs leading-relaxed">
              <AlertTriangle size={16} className="shrink-0 mt-0.5" />
              <p>{formError}</p>
            </div>
          )}

          {/* Section 1: Episode Details */}
          <div className="space-y-4">
            <h4 className="text-xs font-semibold text-zinc-400 uppercase tracking-wider">
              1. Basic Information
            </h4>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="sm:col-span-2">
                <Input
                  label="Episode Title"
                  required
                  placeholder="e.g. The Mysterious Encounter"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  disabled={isBusy}
                />
              </div>

              <div>
                <Input
                  label="Episode #"
                  type="number"
                  min="1"
                  required
                  value={formData.episodeNumber}
                  onChange={(e) =>
                    setFormData({ ...formData, episodeNumber: parseInt(e.target.value) || 1 })
                  }
                  disabled={isBusy}
                />
              </div>
            </div>

            <Textarea
              label="Episode Description (Optional)"
              placeholder="Summary of what happens in this episode..."
              rows={2}
              maxLength={300}
              showCharCount
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              disabled={isBusy}
            />

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
              <div className="p-3 rounded-xl bg-surface-1 border border-white/[0.06] flex items-center justify-between">
                <div className="flex flex-col">
                  <span className="text-xs font-semibold text-white">Published State</span>
                  <span className="text-[11px] text-zinc-400">Episode visible in app</span>
                </div>
                <ToggleSwitch
                  checked={formData.isPublished}
                  onChange={(val) => setFormData({ ...formData, isPublished: val })}
                  disabled={isBusy}
                />
              </div>

              <div className="p-3 rounded-xl bg-surface-1 border border-white/[0.06] flex items-center justify-between">
                <div className="flex flex-col">
                  <span className="text-xs font-semibold text-white">Premium Locked</span>
                  <span className="text-[11px] text-zinc-400">Requires subscription/coins</span>
                </div>
                <ToggleSwitch
                  checked={formData.isLocked}
                  onChange={(val) => setFormData({ ...formData, isLocked: val })}
                  disabled={isBusy}
                />
              </div>
            </div>
          </div>

          {/* Section 2: Video Stream Source */}
          <div className="space-y-4 pt-3 border-t border-white/[0.06]">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                2. Video Stream Source
              </h4>
              <span className="text-[11px] text-zinc-500">MP4 format supported</span>
            </div>

            {/* Source Segmented Control */}
            <SegmentedControl
              value={formData.sourceType}
              onChange={(val) => {
                if (isUploadingVideo) return;
                setFormData((prev) => ({
                  ...prev,
                  sourceType: val as 'external' | 'uploaded',
                  videoUrl: val === prev.sourceType ? prev.videoUrl : '',
                }));
              }}
              options={[
                { value: 'external', label: 'External URL (HTTP / MP4)' },
                { value: 'uploaded', label: 'Upload MP4 (Supabase)' },
              ]}
            />

            {/* If External URL */}
            {formData.sourceType === 'external' ? (
              <div className="space-y-3">
                <Input
                  label="Direct Video URL"
                  placeholder="https://commondatastorage.googleapis.com/.../video.mp4"
                  value={formData.videoUrl}
                  onChange={(e) => setFormData({ ...formData, videoUrl: e.target.value })}
                  helperText="Supports direct MP4 links and Google Drive video stream URLs."
                  disabled={isBusy}
                />
              </div>
            ) : (
              /* If MP4 Upload */
              <div className="space-y-3">
                {formData.videoUrl ? (
                  <div className="p-3 rounded-xl bg-surface-1 border border-white/[0.08] flex items-center justify-between">
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-8 h-8 rounded-lg bg-sky-500/10 border border-sky-500/20 flex items-center justify-center text-sky-400 shrink-0">
                        <Video size={16} />
                      </div>
                      <div className="flex flex-col min-w-0">
                        <span className="text-xs font-semibold text-white truncate">
                          {videoFile?.name || 'Uploaded Video Asset'}
                        </span>
                        <span className="text-[10px] text-sky-400 flex items-center gap-1">
                          <CheckCircle2 size={10} /> Ready in Supabase Storage
                        </span>
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={handleRemoveVideo}
                      disabled={isBusy}
                      className="text-xs text-red-400 hover:text-red-300 p-1.5 hover:bg-red-500/10 rounded-lg transition-colors flex items-center gap-1"
                    >
                      <Trash2 size={13} /> Remove
                    </button>
                  </div>
                ) : (
                  <div
                    onClick={() => {
                      if (!isBusy) videoInputRef.current?.click();
                    }}
                    className={`flex flex-col items-center justify-center p-6 border-2 border-dashed rounded-xl bg-surface-1 transition-all ${
                      isBusy
                        ? 'opacity-50 cursor-not-allowed border-white/[0.08]'
                        : 'cursor-pointer border-white/[0.12] hover:border-accent-coral/60 hover:bg-surface-2'
                    }`}
                  >
                    <div className="w-10 h-10 rounded-xl bg-white/[0.04] border border-white/[0.08] flex items-center justify-center text-zinc-400 mb-2">
                      <UploadCloud size={20} />
                    </div>
                    <span className="text-xs font-semibold text-white">Click or drag MP4 video</span>
                    <span className="text-[11px] text-zinc-500 mt-0.5">
                      Max 45MB on Supabase Storage Free Tier
                    </span>
                    <input
                      type="file"
                      ref={videoInputRef}
                      accept="video/mp4,.mp4"
                      disabled={isBusy}
                      onChange={(e) => e.target.files?.[0] && handleVideoSelect(e.target.files[0])}
                      className="hidden"
                    />
                  </div>
                )}

                {/* TUS Resumable Upload Progress */}
                {isUploadingVideo && (
                  <div className="p-3 rounded-xl bg-surface-1 border border-accent-coral/20 space-y-2">
                    <div className="flex items-center justify-between text-xs">
                      <span className="text-zinc-300 font-medium flex items-center gap-1.5">
                        <UploadCloud size={13} className="text-accent-coral animate-bounce" />
                        Uploading MP4 ({videoFile?.name})...
                      </span>
                      <span className="text-accent-coral font-bold font-mono">
                        {Math.round(videoUploadProgress)}%
                      </span>
                    </div>

                    <div className="w-full bg-surface-0 rounded-full h-1.5 overflow-hidden">
                      <div
                        className="bg-gradient-to-r from-accent-coral to-accent-orange h-full transition-all duration-200"
                        style={{ width: `${videoUploadProgress}%` }}
                      />
                    </div>

                    <div className="flex justify-end pt-1">
                      <button
                        type="button"
                        onClick={cancelVideoUpload}
                        className="text-[11px] text-zinc-400 hover:text-red-400 transition-colors"
                      >
                        Cancel upload
                      </button>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Video Preview Player with Auto Duration */}
            {formData.videoUrl && (
              <div className="space-y-2 pt-1">
                <div className="flex items-center justify-between">
                  <span className="text-xs text-zinc-400 font-medium">Video Player & Frame Grab</span>
                  <button
                    type="button"
                    onClick={handleCaptureVideoFrame}
                    className="inline-flex items-center gap-1.5 text-xs text-accent-coral hover:text-accent-orange font-semibold transition-colors"
                  >
                    <Camera size={13} />
                    Capture current frame as thumbnail
                  </button>
                </div>

                <div className="relative aspect-video rounded-xl overflow-hidden bg-black border border-white/[0.1] shadow-lg">
                  <video
                    ref={previewVideoRef}
                    src={formData.videoUrl}
                    controls
                    crossOrigin="anonymous"
                    playsInline
                    className="w-full h-full object-contain"
                    onLoadedMetadata={(e) => {
                      const dur = Math.round(e.currentTarget.duration);
                      if (dur && dur > 0 && !formData.duration) {
                        setFormData((prev) => ({ ...prev, duration: dur }));
                        toast.showToast({
                          type: 'info',
                          title: 'Duration Detected',
                          message: `Auto-detected length: ${formatDuration(dur)}`,
                        });
                      }
                    }}
                  />
                </div>
              </div>
            )}
          </div>

          {/* Section 3: Thumbnail & Duration */}
          <div className="space-y-4 pt-3 border-t border-white/[0.06]">
            <h4 className="text-xs font-semibold text-zinc-400 uppercase tracking-wider">
              3. Episode Poster & Duration
            </h4>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-start">
              {/* Thumbnail selector */}
              <div>
                <label className="text-xs font-medium text-zinc-300 mb-1.5 block">
                  Episode Poster (16:9 Landscape)
                </label>
                <div
                  onClick={() => {
                    if (!isBusy) fileInputRef.current?.click();
                  }}
                  className={`relative aspect-video rounded-xl overflow-hidden border border-white/[0.1] group bg-surface-1 transition-all ${
                    isBusy ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer hover:border-accent-coral'
                  }`}
                >
                  {thumbnailPreview || formData.thumbnailUrl ? (
                    <img
                      src={thumbnailPreview || formData.thumbnailUrl}
                      alt="Episode thumb"
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex flex-col items-center justify-center text-zinc-500">
                      <ImageIcon size={22} className="mb-1" />
                      <span className="text-[11px]">Select poster image</span>
                    </div>
                  )}

                  {!isBusy && (
                    <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-1 text-white text-xs font-semibold">
                      <UploadCloud size={16} /> Replace
                    </div>
                  )}
                  <input
                    type="file"
                    ref={fileInputRef}
                    accept="image/*"
                    disabled={isBusy}
                    onChange={handleThumbnailSelect}
                    className="hidden"
                  />
                </div>
              </div>

              {/* Duration input */}
              <div className="space-y-3">
                <Input
                  label="Duration (in seconds)"
                  type="number"
                  min="0"
                  value={formData.duration || ''}
                  onChange={(e) =>
                    setFormData({ ...formData, duration: parseInt(e.target.value) || 0 })
                  }
                  helperText={`App displays: ${formatDuration(formData.duration)}`}
                  disabled={isBusy}
                />
              </div>
            </div>
          </div>
        </div>
      </Modal>
    </div>
  );
}
