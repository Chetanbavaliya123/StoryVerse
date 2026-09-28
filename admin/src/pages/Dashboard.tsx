import { useEffect, useState, useMemo } from 'react';
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { Users, BookOpen, Layers, PlayCircle, Plus, Activity, Server, Clock, ShieldCheck, Database, HardDrive } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { formatDistanceToNow, subDays, isAfter } from 'date-fns';

const Skeleton = ({ className }: { className?: string }) => (
  <div className={`animate-pulse bg-surface-container-highest rounded ${className}`}></div>
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

    const unsubUsers = onSnapshot(collection(db, 'users'), (snapshot) => {
      const u = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setUsers(u);
      usersLoaded = true;
      checkLoaded();
    }, (err) => {
      console.error("Dashboard users error:", err);
      setError("Failed to load users data. Check connection.");
      usersLoaded = true;
      checkLoaded();
    });

    const unsubStories = onSnapshot(collection(db, 'stories'), (snapshot) => {
      const s = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setStories(s);
      storiesLoaded = true;
      checkLoaded();
    }, (err) => {
      console.error("Dashboard stories error:", err);
      setError("Failed to load stories data. Check connection.");
      storiesLoaded = true;
      checkLoaded();
    });

    return () => {
      unsubUsers();
      unsubStories();
    };
  }, []);

  // Memoized computations
  const stats = useMemo(() => {
    let publishedCount = 0;
    let draftCount = 0;
    let totalEpisodes = 0;
    
    stories.forEach(s => {
      if (s.status === 'published' || s.isPublished === true) {
        publishedCount++;
      } else {
        draftCount++;
      }
      if (s.totalEpisodes) {
        totalEpisodes += (s.totalEpisodes as number);
      } else if (s.episodeCount) {
        totalEpisodes += (s.episodeCount as number);
      }
    });

    const oneWeekAgo = subDays(new Date(), 7);
    
    const newUsersThisWeek = users.filter(u => {
      if (!u.createdAt?.toDate) return false;
      return isAfter(u.createdAt.toDate(), oneWeekAgo);
    }).length;

    const activeUsersThisWeek = users.filter(u => {
      if (!u.lastLoginAt?.toDate) return false;
      return isAfter(u.lastLoginAt.toDate(), oneWeekAgo);
    }).length;

    // Recent Activity mapping
    const activity: any[] = [];
    users.forEach(u => {
      if (u.createdAt?.toDate) {
        activity.push({
          type: 'user_registered',
          title: 'New user registered',
          description: `${u.name || u.email || 'A user'} joined StoryVerse`,
          date: u.createdAt.toDate(),
          icon: <Users size={16} />
        });
      }
      if (u.lastLoginAt?.toDate) {
        activity.push({
          type: 'user_login',
          title: 'User login',
          description: `${u.name || u.email || 'A user'} logged in`,
          date: u.lastLoginAt.toDate(),
          icon: <Activity size={16} />
        });
      }
    });

    stories.forEach(s => {
      if (s.createdAt?.toDate) {
        activity.push({
          type: 'story_created',
          title: 'Story added',
          description: `"${s.title}" was added`,
          date: s.createdAt.toDate(),
          icon: <BookOpen size={16} />
        });
      }
      if (s.updatedAt?.toDate && s.status === 'published') {
        activity.push({
          type: 'story_published',
          title: 'Story published',
          description: `"${s.title}" is now published`,
          date: s.updatedAt.toDate(),
          icon: <PlayCircle size={16} />
        });
      }
    });

    // Sort descending by date
    activity.sort((a, b) => b.date.getTime() - a.date.getTime());

    return {
      totalUsers: users.length,
      newUsersThisWeek,
      activeUsersThisWeek,
      totalStories: stories.length,
      publishedCount,
      draftCount,
      totalEpisodes,
      recentActivity: activity.slice(0, 5),
      avgEpisodes: stories.length > 0 ? (totalEpisodes / stories.length).toFixed(1) : 0
    };
  }, [users, stories]);

  if (error) {
    return (
      <div className="flex flex-col gap-6">
        <header className="flex flex-col gap-1">
          <h1 className="text-display font-bold">Dashboard</h1>
        </header>
        <div className="p-6 bg-error-container text-on-error-container rounded-2xl flex items-center gap-3">
          <ShieldCheck size={24} />
          <p>{error}</p>
          <button onClick={() => window.location.reload()} className="ml-auto px-4 py-2 bg-error text-on-error rounded-full text-sm font-bold">Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-8 pb-12">
      <header className="flex flex-col gap-1">
        <h1 className="text-display font-bold">Dashboard</h1>
        <p className="text-on-surface-variant">Live metrics and system overview</p>
      </header>

      {/* TOP CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard 
          loading={loading}
          title="Total Users" 
          value={stats.totalUsers} 
          subtitle={stats.newUsersThisWeek > 0 ? `+${stats.newUsersThisWeek} this week` : 'No new this week'}
          icon={<Users size={24} />} 
          color="bg-tertiary" 
        />
        <StatCard 
          loading={loading}
          title="Total Stories" 
          value={stats.totalStories} 
          subtitle={`${stats.publishedCount} published`}
          icon={<BookOpen size={24} />} 
          color="bg-primary" 
        />
        <StatCard 
          loading={loading}
          title="Published Stories" 
          value={stats.publishedCount} 
          subtitle={stats.totalStories > 0 ? `${Math.round((stats.publishedCount / stats.totalStories) * 100)}% of stories` : '0%'}
          icon={<PlayCircle size={24} />} 
          color="bg-secondary" 
        />
        <StatCard 
          loading={loading}
          title="Episodes" 
          value={stats.totalEpisodes} 
          subtitle="Across all stories"
          icon={<Layers size={24} />} 
          color="bg-surface-container-high" 
        />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        
        {/* MAIN COLUMN (Analytics & Actions) */}
        <div className="xl:col-span-2 flex flex-col gap-6">
          
          {/* CONTENT SUMMARY & ANALYTICS */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
              <h2 className="font-headline-sm text-on-surface flex items-center gap-2">
                <BookOpen size={20} className="text-primary" /> Story Publishing Overview
              </h2>
              {loading ? <Skeleton className="h-32 w-full rounded-xl" /> : (
                <div className="flex flex-col gap-3 mt-2">
                  <div className="flex justify-between items-center">
                    <span className="text-on-surface-variant">Published</span>
                    <span className="font-bold text-on-surface">{stats.publishedCount}</span>
                  </div>
                  <div className="w-full bg-surface-container-highest rounded-full h-2">
                    <div className="bg-secondary h-2 rounded-full" style={{ width: `${stats.totalStories > 0 ? (stats.publishedCount / stats.totalStories) * 100 : 0}%` }}></div>
                  </div>
                  
                  <div className="flex justify-between items-center mt-2">
                    <span className="text-on-surface-variant">Drafts</span>
                    <span className="font-bold text-on-surface">{stats.draftCount}</span>
                  </div>
                  <div className="w-full bg-surface-container-highest rounded-full h-2">
                    <div className="bg-surface-variant h-2 rounded-full" style={{ width: `${stats.totalStories > 0 ? (stats.draftCount / stats.totalStories) * 100 : 0}%` }}></div>
                  </div>
                </div>
              )}
            </div>

            <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
              <h2 className="font-headline-sm text-on-surface flex items-center gap-2">
                <Users size={20} className="text-tertiary" /> User Growth & Activity
              </h2>
              {loading ? <Skeleton className="h-32 w-full rounded-xl" /> : (
                <div className="flex flex-col gap-4 mt-2">
                  <div className="flex justify-between items-center bg-surface-container-high p-3 rounded-xl border border-surface-container-highest">
                    <span className="text-on-surface-variant text-sm">Registrations (7d)</span>
                    <span className="font-bold text-tertiary text-lg">+{stats.newUsersThisWeek}</span>
                  </div>
                  <div className="flex justify-between items-center bg-surface-container-high p-3 rounded-xl border border-surface-container-highest">
                    <span className="text-on-surface-variant text-sm">Active Logins (7d)</span>
                    <span className="font-bold text-primary text-lg">{stats.activeUsersThisWeek}</span>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* QUICK ACTIONS */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
            <h2 className="font-headline-sm text-on-surface">Quick Actions</h2>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <button onClick={() => navigate('/stories/add')} className="flex items-center gap-3 p-4 bg-surface-container-high hover:bg-primary-container hover:text-on-primary-container text-on-surface transition-colors rounded-xl border border-surface-container-highest text-left group">
                <div className="p-2 bg-primary/10 text-primary rounded-lg group-hover:bg-primary group-hover:text-on-primary transition-colors">
                  <Plus size={20} />
                </div>
                <span className="font-bold">Add Story</span>
              </button>
              <button onClick={() => navigate('/stories')} className="flex items-center gap-3 p-4 bg-surface-container-high hover:bg-surface-variant text-on-surface transition-colors rounded-xl border border-surface-container-highest text-left group">
                <div className="p-2 bg-surface-variant text-on-surface-variant rounded-lg group-hover:bg-on-surface-variant group-hover:text-surface-variant transition-colors">
                  <BookOpen size={20} />
                </div>
                <span className="font-bold">Manage Stories</span>
              </button>
              <button onClick={() => navigate('/users')} className="flex items-center gap-3 p-4 bg-surface-container-high hover:bg-surface-variant text-on-surface transition-colors rounded-xl border border-surface-container-highest text-left group">
                <div className="p-2 bg-surface-variant text-on-surface-variant rounded-lg group-hover:bg-on-surface-variant group-hover:text-surface-variant transition-colors">
                  <Users size={20} />
                </div>
                <span className="font-bold">Manage Users</span>
              </button>
            </div>
          </div>

        </div>

        {/* SIDE COLUMN (Activity & Status) */}
        <div className="flex flex-col gap-6">
          
          {/* SYSTEM STATUS */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4">
            <h2 className="font-headline-sm text-on-surface flex items-center gap-2">
              <Server size={20} className="text-on-surface-variant" /> System Status
            </h2>
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between p-2">
                <div className="flex items-center gap-3">
                  <Database size={18} className="text-on-surface-variant" />
                  <span className="text-sm font-bold text-on-surface">Firestore</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="relative flex h-3 w-3">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                  </span>
                  <span className="text-xs text-on-surface-variant uppercase tracking-wider">Connected</span>
                </div>
              </div>
              <div className="flex items-center justify-between p-2">
                <div className="flex items-center gap-3">
                  <HardDrive size={18} className="text-on-surface-variant" />
                  <span className="text-sm font-bold text-on-surface">Supabase Storage</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="relative flex h-3 w-3">
                    <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                  </span>
                  <span className="text-xs text-on-surface-variant uppercase tracking-wider">Configured</span>
                </div>
              </div>
            </div>
          </div>

          {/* RECENT ACTIVITY */}
          <div className="bg-surface-container rounded-2xl p-6 border border-surface-container-highest flex flex-col gap-4 flex-grow">
            <div className="flex items-center justify-between">
              <h2 className="font-headline-sm text-on-surface flex items-center gap-2">
                <Clock size={20} className="text-on-surface-variant" /> Recent Activity
              </h2>
            </div>
            
            {loading ? (
              <div className="flex flex-col gap-4 mt-2">
                {[1,2,3,4].map(i => (
                  <div key={i} className="flex gap-3 items-start">
                    <Skeleton className="w-8 h-8 rounded-full flex-shrink-0" />
                    <div className="flex flex-col gap-2 w-full">
                      <Skeleton className="h-4 w-3/4 rounded" />
                      <Skeleton className="h-3 w-1/2 rounded" />
                    </div>
                  </div>
                ))}
              </div>
            ) : stats.recentActivity.length === 0 ? (
              <div className="flex flex-col items-center justify-center p-8 text-center text-on-surface-variant gap-2 bg-surface-container-highest rounded-xl mt-2 border border-dashed border-outline">
                <Activity size={32} className="opacity-50" />
                <span className="text-sm">No recent activity found.</span>
              </div>
            ) : (
              <div className="flex flex-col gap-5 mt-2">
                {stats.recentActivity.map((act, i) => (
                  <div key={i} className="flex gap-4 items-start relative">
                    {i !== stats.recentActivity.length -1 && (
                      <div className="absolute left-4 top-10 bottom-[-20px] w-px bg-surface-container-highest"></div>
                    )}
                    <div className="w-8 h-8 rounded-full bg-surface-container-high border border-surface-container-highest flex items-center justify-center text-on-surface-variant flex-shrink-0 z-10">
                      {act.icon}
                    </div>
                    <div className="flex flex-col gap-1">
                      <div className="flex items-baseline gap-2 flex-wrap">
                        <span className="text-sm font-bold text-on-surface">{act.title}</span>
                        <span className="text-xs text-on-surface-variant bg-surface-container-high px-2 py-0.5 rounded-full">
                          {formatDistanceToNow(act.date, { addSuffix: true })}
                        </span>
                      </div>
                      <span className="text-sm text-on-surface-variant">{act.description}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

        </div>
      </div>
    </div>
  );
}

function StatCard({ loading, title, value, subtitle, icon, color }: { loading?: boolean, title: string, value: number | string, subtitle?: string, icon: React.ReactNode, color: string }) {
  return (
    <div className="p-6 rounded-2xl bg-surface-container border border-surface-container-highest flex flex-col gap-4 relative overflow-hidden group">
      <div className="flex items-center justify-between z-10">
        <div className={`p-3 rounded-xl ${color} bg-opacity-20 text-on-surface transition-transform group-hover:scale-110 duration-300`}>
          {icon}
        </div>
      </div>
      <div className="flex flex-col z-10">
        {loading ? (
          <Skeleton className="h-10 w-16 rounded mt-1 mb-1" />
        ) : (
          <span className="text-display-mobile font-bold text-on-surface">{value}</span>
        )}
        <span className="text-label-md text-on-surface-variant tracking-wider">{title}</span>
        {subtitle && !loading && (
          <span className="text-xs text-on-surface-variant mt-2 font-medium">{subtitle}</span>
        )}
        {loading && subtitle && (
          <Skeleton className="h-3 w-20 rounded mt-2" />
        )}
      </div>
      <div className={`absolute -bottom-8 -right-8 w-32 h-32 rounded-full ${color} opacity-5 blur-2xl group-hover:opacity-10 transition-opacity duration-300`}></div>
    </div>
  );
}
