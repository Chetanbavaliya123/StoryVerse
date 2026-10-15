import { useEffect, useState, useRef, useMemo } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  doc,
  collection,
  getDoc,
  setDoc,
  updateDoc,
  serverTimestamp,
  onSnapshot,
  query,
} from 'firebase/firestore';
import { db } from '../lib/firebase';
import { supabase } from '../lib/supabase';
import EpisodesManager from '../components/EpisodesManager';
import {
  ArrowLeft,
  Save,
  CheckCircle2,
  AlertTriangle,
  UploadCloud,
  FileText,
  Image as ImageIcon,
  Film,
  Tag,
  Sparkles,
  SlidersHorizontal,
  Flame,
  Award,
  Star,
  Check,
  X,
  Send,
} from 'lucide-react';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Textarea } from '../components/ui/Textarea';
import { ToggleSwitch } from '../components/ui/ToggleSwitch';
import { SegmentedControl } from '../components/ui/SegmentedControl';
import { Card, CardHeader, CardContent } from '../components/ui/Card';
import { MobileAppSimulator } from '../components/ui/MobileAppSimulator';
import { useToast } from '../components/ui/ToastContext';

export const CATEGORY_OPTIONS = [
  { value: 'romance', label: 'Romance' },
  { value: 'horror', label: 'Horror' },
  { value: 'comedy', label: 'Comedy' },
  { value: 'thriller', label: 'Thriller' },
  { value: 'action', label: 'Action' },
  { value: 'fantasy', label: 'Fantasy' },
  { value: 'drama', label: 'Drama' },
  { value: 'sci-fi', label: 'Sci-Fi' },
  { value: 'adventure', label: 'Adventure' },
  { value: 'mystery', label: 'Mystery' },
  { value: 'popular', label: 'Popular' },
  { value: 'trending', label: 'Trending' },
  { value: 'new', label: 'New' },
];

export const GENRE_OPTIONS = [
  { value: 'romance', label: 'Romance' },
  { value: 'horror', label: 'Horror' },
  { value: 'comedy', label: 'Comedy' },
  { value: 'thriller', label: 'Thriller' },
  { value: 'action', label: 'Action' },
  { value: 'fantasy', label: 'Fantasy' },
  { value: 'drama', label: 'Drama' },
  { value: 'sci-fi', label: 'Sci-Fi' },
  { value: 'adventure', label: 'Adventure' },
  { value: 'mystery', label: 'Mystery' },
  { value: 'fable', label: 'Fable' },
];

export const LANGUAGE_OPTIONS = [
  { value: 'Hindi', label: 'Hindi (हिंदी)' },
  { value: 'English', label: 'English' },
  { value: 'Gujarati', label: 'Gujarati (ગુજરાતી)' },
  { value: 'Marathi', label: 'Marathi (मराठी)' },
  { value: 'Bengali', label: 'Bengali (বাংলা)' },
  { value: 'Tamil', label: 'Tamil (தமிழ்)' },
  { value: 'Telugu', label: 'Telugu (తెలుగు)' },
];

export const AGE_RATINGS = [
  { value: 'All', label: 'All Ages (U)' },
  { value: '13+', label: '13+ (Teen)' },
  { value: '16+', label: '16+ (Young Adult)' },
  { value: '18+', label: '18+ (Mature / A)' },
];

const SECTIONS = [
  { id: 'basics', label: '1. Basics', icon: FileText, desc: 'Title & synopsis' },
  { id: 'media', label: '2. Media & Poster', icon: ImageIcon, desc: '2:3 cover art' },
  { id: 'episodes', label: '3. Episodes', icon: Film, desc: 'Videos & chapters' },
  { id: 'classification', label: '4. Classification', icon: SlidersHorizontal, desc: 'Genre & language' },
  { id: 'placements', label: '5. Badges & Featured', icon: Sparkles, desc: 'Hero, Trending, Top 10' },
  { id: 'extras', label: '6. SEO & Ratings', icon: Tag, desc: 'Tags & age rating' },
];

export default function StoryEdit() {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEditing = !!id;
  const [draftId] = useState(() => (isEditing ? id! : doc(collection(db, 'stories')).id));
  const toast = useToast();

  const [activeSection, setActiveSection] = useState('basics');

  // Form State
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    fullDescription: '',
    categoryId: 'romance',
    genreId: 'romance',
    language: 'Hindi',
    author: 'StoryVerse Admin',
    status: 'draft',
    isTrending: false,
    isNew: true,
    isTopTen: false,
    isPopular: false,
    thumbnailUrl: '',
    bannerUrl: '',
    ageRating: '13+',
    tags: '',
  });

  const [episodesCount, setEpisodesCount] = useState(0);
  const [loading, setLoading] = useState(isEditing);
  const [isDirty, setIsDirty] = useState(false);
  const [lastSavedTime, setLastSavedTime] = useState<string | null>(null);

  // File Upload states
  const [thumbnailFile, setThumbnailFile] = useState<File | null>(null);
  const [thumbnailPreview, setThumbnailPreview] = useState<string>('');
  const [isUploadingThumbnail, setIsUploadingThumbnail] = useState(false);
  const [isSavingStory, setIsSavingStory] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const fileInputRef = useRef<HTMLInputElement>(null);

  // Track episode count dynamically
  useEffect(() => {
    if (!draftId) return;
    const epsQuery = query(collection(db, 'stories', draftId, 'episodes'));
    const unsub = onSnapshot(epsQuery, (snap: any) => {
      setEpisodesCount(snap.size);
    });
    return () => unsub();
  }, [draftId]);

  // Load existing story
  useEffect(() => {
    if (isEditing) {
      const fetchStory = async () => {
        try {
          const docSnap = await getDoc(doc(db, 'stories', id));
          if (docSnap.exists()) {
            const data = docSnap.data();
            setFormData({
              title: data.title || '',
              description: data.description || '',
              fullDescription: data.fullDescription || '',
              categoryId: (data.categoryId || 'romance').toLowerCase(),
              genreId: (data.genreId || 'romance').toLowerCase(),
              language: data.language || 'Hindi',
              author: data.author || 'StoryVerse Admin',
              status: data.isPublished ? 'published' : 'draft',
              isTrending: data.isTrending === true,
              isNew: data.isNew === true || data.isNewArrival === true,
              isTopTen: data.isTopTen === true,
              isPopular: data.isPopular === true || data.isHero === true,
              thumbnailUrl: data.thumbnailUrl || '',
              bannerUrl: data.bannerUrl || '',
              ageRating: data.ageRating || '13+',
              tags: Array.isArray(data.tags) ? data.tags.join(', ') : data.tags || '',
            });
            setLastSavedTime('Saved');
          } else {
            toast.showToast({
              type: 'error',
              title: 'Not Found',
              message: 'Story document was not found.',
            });
            navigate('/stories');
          }
        } catch (e: any) {
          setErrorMsg('Failed to load story: ' + e.message);
        } finally {
          setLoading(false);
        }
      };
      fetchStory();
    }
  }, [id, navigate]);

  // Cleanup object URL
  useEffect(() => {
    return () => {
      if (thumbnailPreview && thumbnailPreview.startsWith('blob:')) {
        URL.revokeObjectURL(thumbnailPreview);
      }
    };
  }, [thumbnailPreview]);

  // Unsaved changes window prompt
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (isDirty) {
        e.preventDefault();
        e.returnValue = '';
      }
    };
    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [isDirty]);

  // Keyboard shortcut Ctrl+S
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault();
        handleSave(formData.status === 'published');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [formData, thumbnailFile]);

  const updateField = (field: string, value: any) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    setIsDirty(true);
  };

  const handleImageSelect = (file: File) => {
    if (!file.type.startsWith('image/')) {
      setErrorMsg('Please select a valid image file for the thumbnail.');
      return;
    }
    if (file.size > 25 * 1024 * 1024) {
      setErrorMsg('Thumbnail file size should be less than 25 MB.');
      return;
    }

    setErrorMsg('');
    setThumbnailFile(file);
    const objectUrl = URL.createObjectURL(file);
    setThumbnailPreview(objectUrl);
    setIsDirty(true);
  };

  // Publish Checklist validation
  const checklist = useMemo(() => {
    const hasTitle = formData.title.trim().length >= 3;
    const hasDesc = formData.description.trim().length >= 10;
    const hasThumb = !!(thumbnailFile || formData.thumbnailUrl);
    const hasEpisodes = episodesCount >= 1;
    const hasClassification = !!formData.categoryId && !!formData.genreId;

    const allPassed = hasTitle && hasDesc && hasThumb && hasEpisodes && hasClassification;

    return {
      hasTitle,
      hasDesc,
      hasThumb,
      hasEpisodes,
      hasClassification,
      allPassed,
    };
  }, [formData, thumbnailFile, episodesCount]);

  const handleSave = async (publishImmediate = false) => {
    setErrorMsg('');

    if (!formData.title.trim()) {
      setErrorMsg('Story title is required.');
      setActiveSection('basics');
      return;
    }

    if (publishImmediate && !checklist.allPassed) {
      setErrorMsg('Please satisfy all publish checklist items before publishing.');
      return;
    }

    try {
      setIsSavingStory(true);
      let finalThumbnailUrl = formData.thumbnailUrl;

      // Upload thumbnail to Supabase if newly selected
      if (thumbnailFile) {
        setIsUploadingThumbnail(true);
        const fileName = `${Date.now()}_${thumbnailFile.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
        const filePath = `stories/${draftId}/thumbnail/${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from('storyverse-media')
          .upload(filePath, thumbnailFile, {
            contentType: thumbnailFile.type || 'image/jpeg',
            cacheControl: '3600',
            upsert: false,
          });

        if (uploadError) {
          throw new Error('Supabase Upload Error: ' + uploadError.message);
        }

        const {
          data: { publicUrl },
        } = supabase.storage.from('storyverse-media').getPublicUrl(filePath);

        finalThumbnailUrl = publicUrl;
        setIsUploadingThumbnail(false);
      }

      const tagsArray = formData.tags
        ? formData.tags
            .split(',')
            .map((t) => t.trim())
            .filter(Boolean)
        : [];

      const newStatus = publishImmediate ? 'published' : formData.status;

      const payload = {
        title: formData.title.trim(),
        description: formData.description.trim(),
        fullDescription: formData.fullDescription.trim(),
        thumbnailUrl: finalThumbnailUrl,
        bannerUrl: formData.bannerUrl || finalThumbnailUrl,
        categoryId: formData.categoryId.toLowerCase(),
        genreId: formData.genreId.toLowerCase(),
        language: formData.language,
        author: formData.author.trim() || 'StoryVerse Admin',
        isTrending: !!formData.isTrending,
        isNew: !!formData.isNew,
        isNewArrival: !!formData.isNew,
        isTopTen: !!formData.isTopTen,
        isPopular: !!formData.isPopular,
        isHero: !!formData.isPopular,
        isPublished: newStatus === 'published',
        status: newStatus,
        ageRating: formData.ageRating,
        tags: tagsArray,
        updatedAt: serverTimestamp(),
      };

      if (isEditing) {
        await updateDoc(doc(db, 'stories', id), payload);
        toast.showToast({
          type: 'success',
          title: publishImmediate ? 'Story Published' : 'Story Updated',
          message: `"${formData.title}" was saved successfully.`,
        });
      } else {
        await setDoc(doc(db, 'stories', draftId), {
          ...payload,
          id: draftId,
          totalEpisodes: episodesCount,
          totalViews: 0,
          views: 0,
          rating: 0,
          createdAt: serverTimestamp(),
        });
        toast.showToast({
          type: 'success',
          title: publishImmediate ? 'Story Published' : 'Draft Created',
          message: `Story "${formData.title}" created successfully.`,
        });
        setTimeout(() => navigate('/stories'), 800);
      }

      setFormData((prev) => ({
        ...prev,
        thumbnailUrl: finalThumbnailUrl,
        status: newStatus,
      }));
      setThumbnailFile(null);
      setIsDirty(false);
      const timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      setLastSavedTime(`Saved • ${timeStr}`);
    } catch (error: any) {
      console.error('Failed to save story:', error);
      setErrorMsg('Failed to save story: ' + error.message);
      toast.showToast({
        type: 'error',
        title: 'Save Failed',
        message: error.message,
      });
    } finally {
      setIsUploadingThumbnail(false);
      setIsSavingStory(false);
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center p-24 gap-3">
        <div className="w-9 h-9 rounded-full border-2 border-accent-coral border-t-transparent animate-spin" />
        <span className="text-xs text-zinc-400">Loading Story Data...</span>
      </div>
    );
  }

  const isFormBusy = isUploadingThumbnail || isSavingStory;

  return (
    <div className="flex flex-col gap-6 pb-20 max-w-7xl mx-auto w-full">
      {/* ================= TOP ACTION BAR (NO BLUR OVERLAY) ================= */}
      <div className="p-4 rounded-2xl bg-[#121214] border border-white/[0.08] flex items-center justify-between gap-4 shadow-sm">
        {/* Left: Back & Title */}
        <div className="flex items-center gap-3.5 min-w-0">
          <button
            onClick={() => {
              if (isDirty && !window.confirm('You have unsaved changes. Leave anyway?')) return;
              navigate('/stories');
            }}
            className="p-2 rounded-xl bg-surface-1 border border-white/[0.08] text-zinc-400 hover:text-white hover:bg-surface-2 transition-colors shrink-0"
            title="Back to Stories"
          >
            <ArrowLeft size={18} />
          </button>

          <div className="flex flex-col min-w-0">
            <div className="flex items-center gap-2">
              <h1 className="text-base font-bold text-white tracking-tight truncate max-w-md">
                {formData.title ? formData.title : isEditing ? 'Edit Story' : 'New Story'}
              </h1>
              <span
                className={`text-[10px] font-semibold uppercase tracking-wider px-2 py-0.5 rounded-full border ${
                  formData.status === 'published'
                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                    : 'bg-zinc-800 text-zinc-400 border-white/[0.06]'
                }`}
              >
                {formData.status === 'published' ? 'Live in App' : 'Draft'}
              </span>
            </div>

            {/* Autosave status indicator */}
            <div className="flex items-center gap-2 text-[11px] text-zinc-500">
              {isDirty ? (
                <span className="text-amber-400 flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-pulse" />
                  Unsaved changes
                </span>
              ) : lastSavedTime ? (
                <span className="text-zinc-400 flex items-center gap-1">
                  <Check size={11} className="text-emerald-400" />
                  {lastSavedTime}
                </span>
              ) : (
                <span>Ready</span>
              )}
              <span>•</span>
              <span className="text-zinc-500">Ctrl+S to save</span>
            </div>
          </div>
        </div>

        {/* Right: Actions */}
        <div className="flex items-center gap-2.5 shrink-0">
          <Button
            type="button"
            variant="secondary"
            size="sm"
            disabled={isFormBusy}
            loading={isSavingStory && formData.status === 'draft'}
            onClick={() => handleSave(false)}
            leftIcon={<Save size={15} />}
          >
            Save Draft
          </Button>

          <Button
            type="button"
            variant="primary"
            size="sm"
            disabled={isFormBusy}
            loading={isSavingStory && formData.status === 'published'}
            onClick={() => handleSave(true)}
            leftIcon={<Send size={15} />}
          >
            {formData.status === 'published' ? 'Update Live' : 'Publish Story'}
          </Button>
        </div>
      </div>

      {/* Global Error Notice */}
      {errorMsg && (
        <div className="p-4 bg-red-500/10 border border-red-500/20 text-red-400 rounded-2xl flex items-center gap-3 text-sm">
          <AlertTriangle size={18} className="shrink-0" />
          <p className="flex-1">{errorMsg}</p>
          <button onClick={() => setErrorMsg('')} className="p-1 hover:text-white">
            <X size={16} />
          </button>
        </div>
      )}

      {/* ================= MAIN 3-COLUMN / 2-COLUMN GRID ================= */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* ================= COLUMN 1: LEFT VERTICAL STEPPER / TABS (3 Cols) ================= */}
        <div className="lg:col-span-3 sticky top-20 flex flex-col gap-2">
          <div className="p-3 bg-surface-1/60 rounded-2xl border border-white/[0.08] backdrop-blur-md">
            <span className="text-[11px] font-bold text-zinc-400 uppercase tracking-wider px-3 py-1.5 block">
              Editor Sections
            </span>
            <div className="flex flex-col gap-1 mt-1">
              {SECTIONS.map((sec) => {
                const Icon = sec.icon;
                const isActive = activeSection === sec.id;
                return (
                  <button
                    key={sec.id}
                    type="button"
                    onClick={() => {
                      setActiveSection(sec.id);
                      document.getElementById(`section-${sec.id}`)?.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start',
                      });
                    }}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-left transition-all ${
                      isActive
                        ? 'bg-accent-coral/15 text-accent-coral font-semibold border border-accent-coral/25 shadow-sm'
                        : 'text-zinc-400 hover:text-white hover:bg-white/[0.04]'
                    }`}
                  >
                    <Icon size={16} className={isActive ? 'text-accent-coral' : 'text-zinc-500'} />
                    <div className="flex flex-col min-w-0">
                      <span className="text-xs leading-none">{sec.label}</span>
                      <span className="text-[10px] text-zinc-500 truncate mt-0.5">{sec.desc}</span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Quick Stats Pill */}
          <div className="p-4 bg-surface-1/40 rounded-2xl border border-white/[0.06] text-xs text-zinc-400 space-y-2">
            <div className="flex items-center justify-between">
              <span>Episodes</span>
              <span className="font-semibold text-white">{episodesCount}</span>
            </div>
            <div className="flex items-center justify-between">
              <span>Audience</span>
              <span className="font-semibold text-white">{formData.language}</span>
            </div>
            <div className="flex items-center justify-between">
              <span>Rating</span>
              <span className="font-semibold text-white">{formData.ageRating}</span>
            </div>
          </div>
        </div>

        {/* ================= COLUMN 2: MAIN EDITOR FORMS (5 Cols) ================= */}
        <div className="lg:col-span-5 flex flex-col gap-6">
          {/* SECTION 1: BASICS */}
          <div id="section-basics" className="scroll-mt-24">
            <Card>
              <CardHeader
                title="Basic Information"
                subtitle="Primary title and synopsis displayed throughout the mobile app"
              />
              <CardContent className="space-y-4">
                <Input
                  label="Story Title"
                  required
                  placeholder="e.g. Prem Ki Dastaan"
                  value={formData.title}
                  onChange={(e) => updateField('title', e.target.value)}
                  disabled={isFormBusy}
                  helperText="Keep titles punchy and evocative (under 60 characters recommended)."
                />

                <Textarea
                  label="Short Synopsis / Logline"
                  required
                  rows={3}
                  maxLength={180}
                  showCharCount
                  placeholder="A two-sentence hook that captures the premise..."
                  value={formData.description}
                  onChange={(e) => updateField('description', e.target.value)}
                  disabled={isFormBusy}
                  helperText="Displayed directly on the mobile story card and preview carousel."
                />

                <Textarea
                  label="Full Synopsis (Optional)"
                  rows={4}
                  maxLength={1000}
                  showCharCount
                  placeholder="Detailed background, season overview, or creator notes..."
                  value={formData.fullDescription}
                  onChange={(e) => updateField('fullDescription', e.target.value)}
                  disabled={isFormBusy}
                />
              </CardContent>
            </Card>
          </div>

          {/* SECTION 2: MEDIA & POSTER */}
          <div id="section-media" className="scroll-mt-24">
            <Card>
              <CardHeader
                title="Media & Cover Art"
                subtitle="Vertical 2:3 aspect ratio is required for mobile feed cards"
              />
              <CardContent className="space-y-4">
                <div className="flex flex-col gap-2">
                  <label className="text-xs font-medium text-zinc-300">
                    Portrait Poster (2:3 Aspect) <span className="text-accent-coral">*</span>
                  </label>

                  <div
                    onClick={() => {
                      if (!isFormBusy) fileInputRef.current?.click();
                    }}
                    className={`relative w-48 aspect-[2/3] mx-auto bg-surface-1 rounded-2xl overflow-hidden border-2 border-dashed transition-all group ${
                      isFormBusy
                        ? 'opacity-50 cursor-not-allowed border-white/[0.08]'
                        : 'cursor-pointer border-white/[0.15] hover:border-accent-coral hover:bg-surface-2'
                    }`}
                  >
                    {thumbnailPreview || formData.thumbnailUrl ? (
                      <img
                        src={thumbnailPreview || formData.thumbnailUrl}
                        alt="Story Thumbnail"
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex flex-col items-center justify-center p-4 text-center text-zinc-500">
                        <ImageIcon size={32} className="mb-2 text-zinc-400" />
                        <span className="text-xs font-semibold text-white">Select Poster</span>
                        <span className="text-[10px] text-zinc-500 mt-1">2:3 Portrait • JPG, PNG</span>
                      </div>
                    )}

                    {!isFormBusy && (
                      <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-1 text-white">
                        <UploadCloud size={24} className="text-accent-coral" />
                        <span className="text-xs font-semibold">Replace Cover</span>
                      </div>
                    )}

                    <input
                      type="file"
                      ref={fileInputRef}
                      accept="image/*"
                      disabled={isFormBusy}
                      onChange={(e) => e.target.files?.[0] && handleImageSelect(e.target.files[0])}
                      className="hidden"
                    />
                  </div>

                  {/* Upload Progress Bar */}
                  {isUploadingThumbnail && (
                    <div className="space-y-1.5 p-3 rounded-xl bg-surface-1 border border-accent-coral/20">
                      <div className="flex items-center justify-between text-xs text-zinc-300">
                        <span>Uploading poster to Supabase...</span>
                        <span className="text-accent-coral font-mono">Syncing</span>
                      </div>
                      <div className="w-full bg-surface-0 rounded-full h-1.5 overflow-hidden">
                        <div className="bg-gradient-to-r from-accent-coral to-accent-orange h-full w-full animate-pulse" />
                      </div>
                    </div>
                  )}

                  <p className="text-[11px] text-zinc-500 text-center">
                    Recommended resolution: 600 x 900 px. Max file size: 25 MB.
                  </p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* SECTION 3: EPISODES */}
          <div id="section-episodes" className="scroll-mt-24">
            <Card>
              <CardContent className="pt-6">
                <EpisodesManager storyId={draftId} />
              </CardContent>
            </Card>
          </div>

          {/* SECTION 4: CLASSIFICATION */}
          <div id="section-classification" className="scroll-mt-24">
            <Card>
              <CardHeader
                title="Classification & Metadata"
                subtitle="Categories, genres, audio track language, and author"
              />
              <CardContent className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-medium text-zinc-300">Publishing Status</label>
                  <SegmentedControl
                    value={formData.status}
                    onChange={(val) => updateField('status', val)}
                    options={[
                      { value: 'draft', label: 'Draft (Hidden from App)' },
                      { value: 'published', label: 'Published (Live)' },
                    ]}
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-xs font-medium text-zinc-300">Category</label>
                    <select
                      value={formData.categoryId}
                      onChange={(e) => updateField('categoryId', e.target.value)}
                      disabled={isFormBusy}
                      className="w-full bg-[#18181B] px-3.5 py-2.5 rounded-xl border border-white/10 focus:border-accent-coral text-white text-xs outline-none"
                    >
                      {CATEGORY_OPTIONS.map((opt) => (
                        <option key={opt.value} value={opt.value} className="bg-[#18181B] text-white">
                          {opt.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-xs font-medium text-zinc-300">Genre</label>
                    <select
                      value={formData.genreId}
                      onChange={(e) => updateField('genreId', e.target.value)}
                      disabled={isFormBusy}
                      className="w-full bg-[#18181B] px-3.5 py-2.5 rounded-xl border border-white/10 focus:border-accent-coral text-white text-xs outline-none"
                    >
                      {GENRE_OPTIONS.map((opt) => (
                        <option key={opt.value} value={opt.value} className="bg-[#18181B] text-white">
                          {opt.label}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-xs font-medium text-zinc-300">Audio Language</label>
                    <select
                      value={formData.language}
                      onChange={(e) => updateField('language', e.target.value)}
                      disabled={isFormBusy}
                      className="w-full bg-[#18181B] px-3.5 py-2.5 rounded-xl border border-white/10 focus:border-accent-coral text-white text-xs outline-none"
                    >
                      {LANGUAGE_OPTIONS.map((opt) => (
                        <option key={opt.value} value={opt.value} className="bg-[#18181B] text-white">
                          {opt.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <Input
                    label="Author / Production"
                    value={formData.author}
                    onChange={(e) => updateField('author', e.target.value)}
                    disabled={isFormBusy}
                    placeholder="e.g. Kabir Sharma"
                  />
                </div>
              </CardContent>
            </Card>
          </div>

          {/* SECTION 5: PLACEMENTS & BADGES */}
          <div id="section-placements" className="scroll-mt-24">
            <Card>
              <CardHeader
                title="Featured Badges & Placements"
                subtitle="Controls which carousels and highlight sections feature this story"
              />
              <CardContent>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                  {/* Hero Carousel */}
                  <div className="p-3.5 rounded-xl bg-surface-1/70 border border-white/[0.08] flex items-start justify-between gap-3">
                    <div className="flex items-start gap-2.5">
                      <div className="w-8 h-8 rounded-lg bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400 shrink-0 mt-0.5">
                        <Star size={16} />
                      </div>
                      <div className="flex flex-col">
                        <span className="text-xs font-semibold text-white">Hero Carousel</span>
                        <span className="text-[11px] text-zinc-400">Featured banner on home screen</span>
                      </div>
                    </div>
                    <ToggleSwitch
                      checked={formData.isPopular}
                      onChange={(val) => updateField('isPopular', val)}
                      disabled={isFormBusy}
                    />
                  </div>

                  {/* Top 10 */}
                  <div className="p-3.5 rounded-xl bg-surface-1/70 border border-white/[0.08] flex items-start justify-between gap-3">
                    <div className="flex items-start gap-2.5">
                      <div className="w-8 h-8 rounded-lg bg-purple-500/10 border border-purple-500/20 flex items-center justify-center text-purple-400 shrink-0 mt-0.5">
                        <Award size={16} />
                      </div>
                      <div className="flex flex-col">
                        <span className="text-xs font-semibold text-white">Top 10 Rank</span>
                        <span className="text-[11px] text-zinc-400">Home screen numbered rank list</span>
                      </div>
                    </div>
                    <ToggleSwitch
                      checked={formData.isTopTen}
                      onChange={(val) => updateField('isTopTen', val)}
                      disabled={isFormBusy}
                    />
                  </div>

                  {/* Trending */}
                  <div className="p-3.5 rounded-xl bg-surface-1/70 border border-white/[0.08] flex items-start justify-between gap-3">
                    <div className="flex items-start gap-2.5">
                      <div className="w-8 h-8 rounded-lg bg-orange-500/10 border border-orange-500/20 flex items-center justify-center text-orange-400 shrink-0 mt-0.5">
                        <Flame size={16} />
                      </div>
                      <div className="flex flex-col">
                        <span className="text-xs font-semibold text-white">Trending</span>
                        <span className="text-[11px] text-zinc-400">Home Trending carousel & badge</span>
                      </div>
                    </div>
                    <ToggleSwitch
                      checked={formData.isTrending}
                      onChange={(val) => updateField('isTrending', val)}
                      disabled={isFormBusy}
                    />
                  </div>

                  {/* New Arrivals */}
                  <div className="p-3.5 rounded-xl bg-surface-1/70 border border-white/[0.08] flex items-start justify-between gap-3">
                    <div className="flex items-start gap-2.5">
                      <div className="w-8 h-8 rounded-lg bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 shrink-0 mt-0.5">
                        <Sparkles size={16} />
                      </div>
                      <div className="flex flex-col">
                        <span className="text-xs font-semibold text-white">New Arrivals</span>
                        <span className="text-[11px] text-zinc-400">New tab & recent catalog</span>
                      </div>
                    </div>
                    <ToggleSwitch
                      checked={formData.isNew}
                      onChange={(val) => updateField('isNew', val)}
                      disabled={isFormBusy}
                    />
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* SECTION 6: SEO & EXTRAS */}
          <div id="section-extras" className="scroll-mt-24">
            <Card>
              <CardHeader
                title="SEO & Content Rating"
                subtitle="Search tags and viewer age guidance"
              />
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-xs font-medium text-zinc-300">Age Rating</label>
                    <select
                      value={formData.ageRating}
                      onChange={(e) => updateField('ageRating', e.target.value)}
                      disabled={isFormBusy}
                      className="w-full bg-[#18181B] px-3.5 py-2.5 rounded-xl border border-white/10 focus:border-accent-coral text-white text-xs outline-none"
                    >
                      {AGE_RATINGS.map((rate) => (
                        <option key={rate.value} value={rate.value} className="bg-[#18181B] text-white">
                          {rate.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <Input
                    label="Search Tags"
                    placeholder="drama, thriller, suspense, episodic"
                    value={formData.tags}
                    onChange={(e) => updateField('tags', e.target.value)}
                    helperText="Comma separated tags for search discovery."
                    disabled={isFormBusy}
                  />
                </div>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* ================= COLUMN 3: RIGHT STICKY PREVIEW & CHECKLIST (4 Cols) ================= */}
        <div className="lg:col-span-4 sticky top-20 flex flex-col gap-5">
          {/* Mobile App Live Simulator */}
          <MobileAppSimulator
            title={formData.title}
            description={formData.description}
            genre={formData.genreId}
            language={formData.language}
            thumbnailUrl={thumbnailPreview || formData.thumbnailUrl}
            episodesCount={episodesCount}
            isHero={formData.isPopular}
            isTopTen={formData.isTopTen}
            isTrending={formData.isTrending}
            isNew={formData.isNew}
          />

          {/* Interactive Publish Checklist */}
          <Card className="border-white/[0.08]">
            <CardHeader
              title="Publish Checklist"
              subtitle="Requirements to publish live into the mobile app"
            />
            <CardContent>
              <div className="space-y-2.5 text-xs">
                <ChecklistItem
                  label="Title configured (min 3 characters)"
                  passed={checklist.hasTitle}
                />
                <ChecklistItem
                  label="Logline / description (min 10 characters)"
                  passed={checklist.hasDesc}
                />
                <ChecklistItem
                  label="Portrait thumbnail image uploaded"
                  passed={checklist.hasThumb}
                />
                <ChecklistItem
                  label="At least 1 episode created"
                  passed={checklist.hasEpisodes}
                />
                <ChecklistItem
                  label="Classification (Genre & Category) chosen"
                  passed={checklist.hasClassification}
                />
              </div>

              <div className="mt-4 pt-3.5 border-t border-white/[0.08] flex items-center justify-between">
                <span className="text-[11px] text-zinc-400">Status</span>
                {checklist.allPassed ? (
                  <span className="text-[11px] font-semibold text-emerald-400 flex items-center gap-1">
                    <CheckCircle2 size={13} /> Ready to Publish
                  </span>
                ) : (
                  <span className="text-[11px] font-semibold text-amber-400 flex items-center gap-1">
                    <AlertTriangle size={13} /> Items incomplete
                  </span>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

function ChecklistItem({ label, passed }: { label: string; passed: boolean }) {
  return (
    <div className="flex items-center gap-2.5">
      <div
        className={`w-4 h-4 rounded-full flex items-center justify-center shrink-0 text-[10px] transition-colors ${
          passed ? 'bg-emerald-500/20 text-emerald-400' : 'bg-white/[0.06] text-zinc-600'
        }`}
      >
        {passed ? <Check size={11} strokeWidth={3} /> : <div className="w-1.5 h-1.5 rounded-full bg-zinc-600" />}
      </div>
      <span className={passed ? 'text-zinc-200' : 'text-zinc-500'}>{label}</span>
    </div>
  );
}
