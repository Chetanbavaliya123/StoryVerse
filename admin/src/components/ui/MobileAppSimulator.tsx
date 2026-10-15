import React, { useState } from 'react';
import { Play, Bookmark, Star, Sparkles, Flame, Trophy } from 'lucide-react';
import { ImageFallback } from './ImageFallback';

export interface MobileAppSimulatorProps {
  title: string;
  thumbnailUrl: string;
  bannerUrl?: string;
  description?: string;
  genre: string;
  category?: string;
  language: string;
  episodeCount?: number;
  episodesCount?: number;
  isPopular?: boolean;
  isHero?: boolean;
  isTrending?: boolean;
  isTopTen?: boolean;
  isNew?: boolean;
  mode?: 'hero' | 'card';
}

export const MobileAppSimulator: React.FC<MobileAppSimulatorProps> = ({
  title,
  thumbnailUrl,
  bannerUrl,
  genre,
  category = '',
  language,
  episodeCount,
  episodesCount,
  isPopular = false,
  isHero = false,
  isTrending = false,
  isTopTen = false,
  isNew = false,
  mode: initialMode = 'card',
}) => {
  const [viewMode, setViewMode] = useState<'card' | 'hero'>(initialMode);
  const totalEps = episodesCount ?? episodeCount ?? 0;
  const isHeroBanner = isPopular || isHero;

  return (
    <div className="flex flex-col gap-3 w-full">
      {/* Mode switcher tabs */}
      <div className="flex items-center justify-between text-xs font-bold text-zinc-400 px-1">
        <span className="uppercase tracking-wider text-[11px] text-zinc-400">Mobile App Preview</span>
        <div className="flex items-center bg-surface-2 p-0.5 rounded-lg border border-white/10">
          <button
            type="button"
            onClick={() => setViewMode('card')}
            className={`px-2 py-0.5 rounded text-[11px] transition-colors ${
              viewMode === 'card' ? 'bg-surface-3 text-white font-bold' : 'text-zinc-400 hover:text-white'
            }`}
          >
            Story Card
          </button>
          <button
            type="button"
            onClick={() => setViewMode('hero')}
            className={`px-2 py-0.5 rounded text-[11px] transition-colors ${
              viewMode === 'hero' ? 'bg-surface-3 text-white font-bold' : 'text-zinc-400 hover:text-white'
            }`}
          >
            Hero Banner
          </button>
        </div>
      </div>

      {/* Simulator Frame (Simulates dark mobile viewport) */}
      <div className="relative rounded-2xl bg-black border border-white/15 p-4 shadow-2xl overflow-hidden">
        {/* Subtle device status bar simulation */}
        <div className="flex items-center justify-between text-[10px] text-zinc-400 font-semibold mb-3 px-1">
          <span>9:41</span>
          <div className="flex items-center gap-1">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500/80 inline-block"></span>
            <span>5G</span>
          </div>
        </div>

        {viewMode === 'hero' ? (
          /* HERO BANNER SIMULATION */
          <div className="relative aspect-[4/5] w-full rounded-xl overflow-hidden border border-white/10 shadow-lg">
            <ImageFallback
              src={bannerUrl || thumbnailUrl}
              fallbackTitle={title}
              genre={genre}
              aspectRatio="2:3"
              className="absolute inset-0 w-full h-full object-cover"
            />
            {/* Gradient Overlay */}
            <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent" />

            {/* Badges & Content */}
            <div className="absolute bottom-3 left-3 right-3 flex flex-col gap-2">
              <div className="flex flex-wrap items-center gap-1.5">
                <span className="px-2 py-0.5 bg-rose-600 text-white rounded font-bold text-[10px] uppercase tracking-wider">
                  {genre || 'DRAMA'}
                </span>
                {category && category.toLowerCase() !== genre.toLowerCase() && (
                  <span className="px-2 py-0.5 bg-white/20 backdrop-blur-sm text-white/90 rounded text-[10px] font-semibold uppercase">
                    {category}
                  </span>
                )}
                <span className="text-[10px] text-zinc-300 font-medium">
                  {language || 'Hindi'}
                </span>
              </div>

              <h4 className="text-base font-extrabold text-white leading-tight line-clamp-2 drop-shadow-md">
                {title || 'Untitled Story'}
              </h4>

              <div className="flex items-center gap-2 pt-1">
                <div className="flex-1 flex items-center justify-center gap-1.5 bg-white text-black py-1.5 px-3 rounded-full font-bold text-xs shadow-md">
                  <Play size={13} className="fill-black" />
                  <span>Play Now</span>
                </div>
                <div className="w-8 h-8 rounded-full bg-black/60 border border-white/20 flex items-center justify-center text-white">
                  <Bookmark size={14} />
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* STORY CARD (PORTRAIT 2:3) SIMULATION */
          <div className="flex flex-col gap-2 max-w-[170px] mx-auto">
            <div className="relative aspect-[2/3] w-full rounded-xl overflow-hidden border border-white/10 shadow-lg group">
              <ImageFallback
                src={thumbnailUrl}
                fallbackTitle={title}
                genre={genre}
                aspectRatio="2:3"
                className="w-full h-full object-cover"
              />

              {/* Badges Overlay */}
              <div className="absolute top-2 left-2 flex flex-col gap-1">
                {isHeroBanner && (
                  <span className="px-1.5 py-0.5 bg-sky-500/90 text-white font-bold rounded text-[9px] flex items-center gap-0.5 shadow">
                    <Star size={9} className="fill-white" /> Hero
                  </span>
                )}
                {isTopTen && (
                  <span className="px-1.5 py-0.5 bg-purple-600/90 text-white font-bold rounded text-[9px] flex items-center gap-0.5 shadow">
                    <Trophy size={9} /> Top 10
                  </span>
                )}
                {isTrending && (
                  <span className="px-1.5 py-0.5 bg-amber-500/90 text-white font-bold rounded text-[9px] flex items-center gap-0.5 shadow">
                    <Flame size={9} /> Trending
                  </span>
                )}
                {isNew && (
                  <span className="px-1.5 py-0.5 bg-emerald-500/90 text-white font-bold rounded text-[9px] flex items-center gap-0.5 shadow">
                    <Sparkles size={9} /> New
                  </span>
                )}
              </div>

              {/* Bottom Episode count pill */}
              <div className="absolute bottom-2 right-2 px-1.5 py-0.5 bg-black/75 backdrop-blur-sm rounded text-[9px] font-bold text-white border border-white/10">
                {totalEps} EPS
              </div>
            </div>

            <div className="flex flex-col">
              <span className="text-[10px] font-bold uppercase tracking-wider text-rose-400">
                {genre || 'Drama'}
              </span>
              <span className="text-xs font-bold text-white leading-snug truncate">
                {title || 'Story Title'}
              </span>
              <span className="text-[10px] text-zinc-400">
                {language || 'Hindi'}
              </span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
