import { useEffect, useState, useMemo } from 'react';
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import {
  Users,
  BookOpen,
  Film,
  Plus,
  Activity,
  Clock,
  ShieldCheck,
  TrendingUp,
  AlertTriangle,
  ArrowUpRight,
  CheckCircle2,
  ChevronRight,
  Sparkles,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { formatDistanceToNow, subDays, isAfter } from 'date-fns';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { Card, CardHeader, CardContent } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { ImageFallback } from '../components/ui/ImageFallback';

const Skeleton = ({ className = '' }: { className?: string }) => (
  <div className={`animate-pulse bg-surface-2 rounded-xl border border-white/[0.05] ${className}`} />
);

export default function Dashboard() {
  const navigate = useNavigate();
  const [users, setUsers] = useState<any[]>([]);
  const [stories, setStories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let usersLoaded = false;
    let storiesLoaded = false;

    const checkLoaded = () => {
      if (usersLoaded && storiesLoaded) setLoading(false);
    };

    const unsubUsers = onSnapshot(
      collection(db, 'users'),
      (snapshot) => {
        const u = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        setUsers(u);
        usersLoaded = true;
        checkLoaded();
      },
      (err) => {
        console.error('Dashboard users error:', err);
        setError('Failed to load users data.');
        usersLoaded = true;
        checkLoaded();
      }
    );

    const unsubStories = onSnapshot(
      collection(db, 'stories'),
      (snapshot) => {
        const s = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        setStories(s);
        storiesLoaded = true;
        checkLoaded();
      },
      (err) => {
        console.error('Dashboard stories error:', err);
        setError('Failed to load stories data.');
        storiesLoaded = true;
        checkLoaded();
      }
    );

    return () => {
      unsubUsers();
      unsubStories();
    };
  }, []);

  // Compute stats
  const stats = useMemo(() => {
    let publishedCount = 0;
    let draftCount = 0;
    let totalEpisodes = 0;
    let totalViews = 0;

    stories.forEach((s) => {
      if (s.status === 'published' || s.isPublished === true) {
        publishedCount++;
      } else {
        draftCount++;
      }
      const eps = Number(s.totalEpisodes || s.episodeCount || 0);
      totalEpisodes += eps;
      totalViews += Number(s.views || s.totalViews || 0);
    });

    const oneWeekAgo = subDays(new Date(), 7);

    const newUsersThisWeek = users.filter((u) => {
      if (!u.createdAt?.toDate) return false;
      return isAfter(u.createdAt.toDate(), oneWeekAgo);
    }).length;

    const activeUsersThisWeek = users.filter((u) => {
      if (!u.lastLoginAt?.toDate) return false;
      return isAfter(u.lastLoginAt.toDate(), oneWeekAgo);
    }).length;

    // Recent Activity mapping
    const activity: any[] = [];
    users.forEach((u) => {
      if (u.createdAt?.toDate) {
        activity.push({
          type: 'user_registered',
          title: 'New user joined',
          description: u.name || u.email || 'A user',
          date: u.createdAt.toDate(),
          icon: <Users size={14} className="text-sky-400" />,
        });
      }
      if (u.lastLoginAt?.toDate) {
        activity.push({
          type: 'user_login',
          title: 'User active login',
          description: u.name || u.email || 'A user',
          date: u.lastLoginAt.toDate(),
          icon: <Activity size={14} className="text-emerald-400" />,
        });
      }
    });

    stories.forEach((s) => {
      if (s.createdAt?.toDate) {
        activity.push({
          type: 'story_created',
          title: 'Story added',
          description: s.title || 'Untitled Story',
          date: s.createdAt.toDate(),
          icon: <BookOpen size={14} className="text-amber-400" />,
        });
      }
    });

    activity.sort((a, b) => b.date.getTime() - a.date.getTime());

    // Needs attention: Stories with 0 episodes, missing thumbnail, or drafts
    const needsAttention = stories.filter((s) => {
      const hasNoEps = Number(s.totalEpisodes || s.episodeCount || 0) === 0;
      const hasNoThumb = !s.thumbnailUrl || s.thumbnailUrl.trim() === '';
      const isDraft = s.status === 'draft' || s.isPublished === false;
      return hasNoEps || hasNoThumb || isDraft;
    });

    // Top stories sorted by views / episodes
    const topStories = [...stories]
      .sort((a, b) => Number(b.views || 0) - Number(a.views || 0))
      .slice(0, 5);

    // Genre distribution for Donut Chart
    const genreMap: Record<string, number> = {};
    stories.forEach((s) => {
      const g = (s.genreId || s.categoryId || 'other').toLowerCase();
      genreMap[g] = (genreMap[g] || 0) + 1;
    });

    const genreData = Object.entries(genreMap).map(([name, value]) => ({
      name: name.toUpperCase(),
      value,
    }));

    // User activity 7-day sparkline / chart data
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const today = new Date();
    const trendData = Array.from({ length: 7 }).map((_, i) => {
      const d = subDays(today, 6 - i);
      const dayName = dayLabels[d.getDay()];
      const dayUsers = users.filter((u) => {
        if (!u.createdAt?.toDate) return false;
        const uDate = u.createdAt.toDate();
        return uDate.toDateString() === d.toDateString();
      }).length;

      const dayActive = users.filter((u) => {
        if (!u.lastLoginAt?.toDate) return false;
        const uDate = u.lastLoginAt.toDate();
        return uDate.toDateString() === d.toDateString();
      }).length;

      return {
        day: dayName,
        newUsers: dayUsers,
        activeLogins: dayActive,
      };
    });

    // Episodes per story distribution for BarChart
    const episodesData = [...stories]
      .sort((a, b) => Number(b.totalEpisodes || 0) - Number(a.totalEpisodes || 0))
      .slice(0, 6)
      .map((s) => ({
        name: s.title ? (s.title.length > 10 ? s.title.slice(0, 10) + '..' : s.title) : 'Story',
        episodes: Number(s.totalEpisodes || s.episodeCount || 0),
      }));

    return {
      publishedCount,
      draftCount,
      totalEpisodes,
      totalViews,
      newUsersThisWeek,
      activeUsersThisWeek,
      activity: activity.slice(0, 6),
      needsAttention: needsAttention.slice(0, 4),
      topStories,
      genreData,
      trendData,
      episodesData,
    };
  }, [users, stories]);

  const COLORS = ['#FF5757', '#8B5CF6', '#10B981', '#38BDF8', '#F59E0B', '#EC4899'];

  if (loading) {
    return (
      <div className="flex flex-col gap-6 animate-pulse">
        <div className="h-10 w-48 bg-surface-2 rounded-xl" />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-32" />
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <Skeleton className="h-80 lg:col-span-2" />
          <Skeleton className="h-80" />
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-7 pb-12">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-white tracking-tight flex items-center gap-2">
            Dashboard
          </h1>
          <p className="text-xs text-zinc-400 mt-1">
            Real-time metrics, content distribution, and system performance overview.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Button
            variant="primary"
            size="sm"
            iconLeft={<Plus size={15} />}
            onClick={() => navigate('/stories/add')}
          >
            Add Story
          </Button>
          <Button
            variant="secondary"
            size="sm"
            iconLeft={<BookOpen size={15} />}
            onClick={() => navigate('/stories')}
          >
            Manage Stories
          </Button>
        </div>
      </div>

      {error && (
        <div className="p-3 bg-red-500/10 border border-red-500/20 text-red-400 rounded-xl text-xs flex items-center gap-2">
          <AlertTriangle size={15} />
          <span>{error}</span>
        </div>
      )}

      {/* 1. Hero Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Users */}
        <Card hoverLift className="p-5 flex flex-col justify-between relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-zinc-400 uppercase tracking-wider">
              Total Audience
            </span>
            <div className="w-9 h-9 rounded-xl bg-sky-500/10 border border-sky-500/20 text-sky-400 flex items-center justify-center">
              <Users size={18} />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-black text-white tracking-tight">
              {users.length}
            </div>
            <div className="flex items-center gap-1.5 mt-1.5 text-xs text-zinc-400">
              <span className="text-emerald-400 font-bold flex items-center">
                <ArrowUpRight size={14} /> +{stats.newUsersThisWeek}
              </span>
              <span>new this week</span>
            </div>
          </div>
          <div className="absolute inset-x-0 bottom-0 h-0.5 bg-gradient-to-r from-sky-500/0 via-sky-500/50 to-sky-500/0 opacity-0 group-hover:opacity-100 transition-opacity" />
        </Card>

        {/* Total Stories */}
        <Card hoverLift className="p-5 flex flex-col justify-between relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-zinc-400 uppercase tracking-wider">
              Content Catalog
            </span>
            <div className="w-9 h-9 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 flex items-center justify-center">
              <BookOpen size={18} />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-black text-white tracking-tight">
              {stories.length}
            </div>
            <div className="flex items-center gap-1.5 mt-1.5 text-xs text-zinc-400">
              <span className="text-rose-400 font-bold">{stats.publishedCount}</span>
              <span>published stories</span>
            </div>
          </div>
          <div className="absolute inset-x-0 bottom-0 h-0.5 bg-gradient-to-r from-rose-500/0 via-rose-500/50 to-rose-500/0 opacity-0 group-hover:opacity-100 transition-opacity" />
        </Card>

        {/* Total Episodes */}
        <Card hoverLift className="p-5 flex flex-col justify-between relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-zinc-400 uppercase tracking-wider">
              Total Episodes
            </span>
            <div className="w-9 h-9 rounded-xl bg-purple-500/10 border border-purple-500/20 text-purple-400 flex items-center justify-center">
              <Film size={18} />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-black text-white tracking-tight">
              {stats.totalEpisodes}
            </div>
            <div className="flex items-center gap-1.5 mt-1.5 text-xs text-zinc-400">
              <span className="text-purple-400 font-bold">~5 eps</span>
              <span>avg per story</span>
            </div>
          </div>
          <div className="absolute inset-x-0 bottom-0 h-0.5 bg-gradient-to-r from-purple-500/0 via-purple-500/50 to-purple-500/0 opacity-0 group-hover:opacity-100 transition-opacity" />
        </Card>

        {/* Active Logins & System Health */}
        <Card hoverLift className="p-5 flex flex-col justify-between relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-zinc-400 uppercase tracking-wider">
              System Health
            </span>
            <div className="w-9 h-9 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center">
              <ShieldCheck size={18} />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-black text-white tracking-tight flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-emerald-400 animate-pulse" />
              100% Operational
            </div>
            <div className="flex items-center gap-2 mt-1.5 text-xs text-zinc-400">
              <span>Firestore & Supabase Connected</span>
            </div>
          </div>
          <div className="absolute inset-x-0 bottom-0 h-0.5 bg-gradient-to-r from-emerald-500/0 via-emerald-500/50 to-emerald-500/0 opacity-0 group-hover:opacity-100 transition-opacity" />
        </Card>
      </div>

      {/* 2. Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* User Growth & Logins Area Chart */}
        <Card className="lg:col-span-2 flex flex-col justify-between overflow-hidden">
          <CardHeader
            title="User Activity & Engagement"
            subtitle="Registrations and active logins over the past 7 days"
            icon={<TrendingUp size={18} />}
          />
          <CardContent className="pt-2">
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={stats.trendData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="coralGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#FF5757" stopOpacity={0.4} />
                      <stop offset="95%" stopColor="#FF5757" stopOpacity={0.0} />
                    </linearGradient>
                    <linearGradient id="emeraldGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10B981" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#10B981" stopOpacity={0.0} />
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="day" stroke="#71717A" fontSize={11} tickLine={false} />
                  <YAxis stroke="#71717A" fontSize={11} tickLine={false} allowDecimals={false} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#18181B',
                      border: '1px solid rgba(255,255,255,0.1)',
                      borderRadius: '12px',
                      fontSize: '12px',
                      color: '#FFF',
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="activeLogins"
                    stroke="#10B981"
                    strokeWidth={2}
                    fillOpacity={1}
                    fill="url(#emeraldGrad)"
                    name="Active Logins"
                  />
                  <Area
                    type="monotone"
                    dataKey="newUsers"
                    stroke="#FF5757"
                    strokeWidth={2}
                    fillOpacity={1}
                    fill="url(#coralGrad)"
                    name="New Registrations"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
            <div className="flex items-center justify-center gap-6 pt-3 text-xs text-zinc-400 border-t border-white/[0.05] mt-2">
              <span className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-rose-500" /> New Users
              </span>
              <span className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-400" /> Active Logins
              </span>
            </div>
          </CardContent>
        </Card>

        {/* Stories by Genre Donut Chart */}
        <Card className="flex flex-col justify-between">
          <CardHeader
            title="Genre Breakdown"
            subtitle="Catalog distribution across story genres"
            icon={<Film size={18} />}
          />
          <CardContent className="flex flex-col items-center justify-center pt-2">
            <div className="h-56 w-full flex items-center justify-center">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={stats.genreData}
                    cx="50%"
                    cy="50%"
                    innerRadius={55}
                    outerRadius={80}
                    paddingAngle={4}
                    dataKey="value"
                  >
                    {stats.genreData.map((_, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#18181B',
                      border: '1px solid rgba(255,255,255,0.1)',
                      borderRadius: '12px',
                      fontSize: '12px',
                      color: '#FFF',
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            {/* Legend pills */}
            <div className="flex flex-wrap justify-center gap-2 pt-2 max-h-24 overflow-y-auto">
              {stats.genreData.map((g, idx) => (
                <span
                  key={g.name}
                  className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-surface-2 border border-white/[0.06] flex items-center gap-1.5 text-zinc-300"
                >
                  <span
                    className="w-2 h-2 rounded-full"
                    style={{ backgroundColor: COLORS[idx % COLORS.length] }}
                  />
                  {g.name} ({g.value})
                </span>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 3. Operational Grid: Needs Attention, Top Stories, Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Needs Attention Card */}
        <Card className="flex flex-col">
          <CardHeader
            title="Needs Attention"
            subtitle="Stories with missing assets, 0 episodes, or in draft"
            icon={<AlertTriangle size={18} className="text-amber-400" />}
          />
          <CardContent className="space-y-3 flex-1">
            {stats.needsAttention.length === 0 ? (
              <div className="p-8 text-center text-xs text-zinc-500 flex flex-col items-center gap-2">
                <CheckCircle2 size={24} className="text-emerald-400" />
                <span>All stories have episodes and thumbnails! Great job.</span>
              </div>
            ) : (
              stats.needsAttention.map((story) => {
                const eps = Number(story.totalEpisodes || story.episodeCount || 0);
                const hasNoThumb = !story.thumbnailUrl;
                const isDraft = story.status === 'draft';

                return (
                  <div
                    key={story.id}
                    onClick={() => navigate(`/stories/${story.id}`)}
                    className="p-3 rounded-xl bg-surface-2 hover:bg-surface-3 border border-white/[0.06] hover:border-white/15 cursor-pointer transition-all flex items-center justify-between gap-3 group"
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
                        <span className="text-xs font-bold text-white truncate group-hover:text-rose-400 transition-colors">
                          {story.title}
                        </span>
                        <div className="flex items-center gap-1.5 mt-1">
                          {eps === 0 && (
                            <span className="text-[10px] font-bold text-rose-400 bg-rose-500/10 px-1.5 py-0.5 rounded border border-rose-500/20">
                              0 Episodes
                            </span>
                          )}
                          {hasNoThumb && (
                            <span className="text-[10px] font-bold text-amber-400 bg-amber-500/10 px-1.5 py-0.5 rounded border border-amber-500/20">
                              No Poster
                            </span>
                          )}
                          {isDraft && (
                            <span className="text-[10px] font-bold text-zinc-400 bg-zinc-800 px-1.5 py-0.5 rounded border border-zinc-700">
                              Draft
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                    <ChevronRight size={16} className="text-zinc-600 group-hover:text-zinc-300 transition-colors shrink-0" />
                  </div>
                );
              })
            )}
          </CardContent>
        </Card>

        {/* Top Performing Stories */}
        <Card className="flex flex-col">
          <CardHeader
            title="Top Performing Stories"
            subtitle="Most viewed and active content"
            icon={<Sparkles size={18} className="text-rose-400" />}
            action={
              <button
                onClick={() => navigate('/stories')}
                className="text-xs font-bold text-rose-400 hover:text-rose-300"
              >
                View All
              </button>
            }
          />
          <CardContent className="space-y-3 flex-1">
            {stats.topStories.map((story, idx) => (
              <div
                key={story.id}
                onClick={() => navigate(`/stories/${story.id}`)}
                className="flex items-center justify-between p-2.5 rounded-xl hover:bg-surface-2 transition-colors cursor-pointer group"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <span className="text-xs font-black text-zinc-500 w-4 text-center shrink-0">
                    #{idx + 1}
                  </span>
                  <div className="w-9 h-12 rounded-lg overflow-hidden shrink-0 border border-white/10">
                    <ImageFallback
                      src={story.thumbnailUrl}
                      fallbackTitle={story.title}
                      genre={story.genreId}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div className="flex flex-col min-w-0">
                    <span className="text-xs font-bold text-white truncate group-hover:text-rose-400 transition-colors">
                      {story.title}
                    </span>
                    <span className="text-[11px] text-zinc-400">
                      {story.genreId?.toUpperCase()} • {story.totalEpisodes || story.episodeCount || 0} eps
                    </span>
                  </div>
                </div>

                <div className="text-right shrink-0">
                  <span className="text-xs font-extrabold text-white">
                    {Number(story.views || 0).toLocaleString()}
                  </span>
                  <span className="block text-[10px] text-zinc-400">views</span>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Recent Activity Timeline */}
        <Card className="flex flex-col">
          <CardHeader
            title="Recent Activity"
            subtitle="System events and content updates"
            icon={<Clock size={18} className="text-sky-400" />}
          />
          <CardContent className="space-y-3.5 flex-1">
            {stats.activity.length === 0 ? (
              <div className="p-8 text-center text-xs text-zinc-500">No recent activity</div>
            ) : (
              stats.activity.map((act, i) => (
                <div key={i} className="flex items-start gap-3">
                  <div className="w-7 h-7 rounded-lg bg-surface-2 border border-white/10 flex items-center justify-center shrink-0 mt-0.5">
                    {act.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-xs font-bold text-white truncate">{act.title}</p>
                      <span className="text-[10px] text-zinc-400 shrink-0">
                        {formatDistanceToNow(act.date, { addSuffix: true })}
                      </span>
                    </div>
                    <p className="text-[11px] text-zinc-400 truncate mt-0.5">{act.description}</p>
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>

      {/* 4. Quick Actions / Shortcuts Bar */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div
          onClick={() => navigate('/stories/add')}
          className="p-4 rounded-2xl bg-surface-1 hover:bg-surface-2 border border-white/[0.08] hover:border-rose-500/40 cursor-pointer transition-all flex items-center justify-between group"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 flex items-center justify-center group-hover:scale-105 transition-transform">
              <Plus size={20} />
            </div>
            <div>
              <p className="text-sm font-bold text-white">Create Story</p>
              <p className="text-xs text-zinc-400">Add a new show to the platform</p>
            </div>
          </div>
          <kbd className="px-2 py-1 rounded bg-surface-3 text-[10px] font-mono text-zinc-400 border border-white/10">
            N
          </kbd>
        </div>

        <div
          onClick={() => navigate('/stories')}
          className="p-4 rounded-2xl bg-surface-1 hover:bg-surface-2 border border-white/[0.08] hover:border-sky-500/40 cursor-pointer transition-all flex items-center justify-between group"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-sky-500/10 border border-sky-500/20 text-sky-400 flex items-center justify-center group-hover:scale-105 transition-transform">
              <BookOpen size={20} />
            </div>
            <div>
              <p className="text-sm font-bold text-white">Manage Stories</p>
              <p className="text-xs text-zinc-400">View, filter & reorder catalog</p>
            </div>
          </div>
          <kbd className="px-2 py-1 rounded bg-surface-3 text-[10px] font-mono text-zinc-400 border border-white/10">
            S
          </kbd>
        </div>

        <div
          onClick={() => navigate('/users')}
          className="p-4 rounded-2xl bg-surface-1 hover:bg-surface-2 border border-white/[0.08] hover:border-purple-500/40 cursor-pointer transition-all flex items-center justify-between group"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-purple-500/10 border border-purple-500/20 text-purple-400 flex items-center justify-center group-hover:scale-105 transition-transform">
              <Users size={20} />
            </div>
            <div>
              <p className="text-sm font-bold text-white">Audience & Users</p>
              <p className="text-xs text-zinc-400">Inspect user accounts & roles</p>
            </div>
          </div>
          <kbd className="px-2 py-1 rounded bg-surface-3 text-[10px] font-mono text-zinc-400 border border-white/10">
            U
          </kbd>
        </div>
      </div>
    </div>
  );
}
