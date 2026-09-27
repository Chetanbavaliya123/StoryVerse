import { useEffect, useState } from 'react';
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { Users, BookOpen, Layers, PlayCircle } from 'lucide-react';

export default function Dashboard() {
  const [stats, setStats] = useState({
    users: 0,
    stories: 0,
    episodes: 0,
    publishedStories: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Real-time listener for users
    const unsubUsers = onSnapshot(collection(db, 'users'), (snapshot) => {
      setStats(prev => ({ ...prev, users: snapshot.size }));
    }, (error) => {
      console.error("Dashboard users error:", error);
    });

    // Real-time listener for stories
    const unsubStories = onSnapshot(collection(db, 'stories'), (snapshot) => {
      let publishedCount = 0;
      let totalEpisodes = 0;
      
      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.status === 'published' || data.isPublished === true) {
          publishedCount++;
        }
        if (data.totalEpisodes) {
          totalEpisodes += (data.totalEpisodes as number);
        } else if (data.episodeCount) {
          totalEpisodes += (data.episodeCount as number);
        }
      });
      
      setStats(prev => ({ 
        ...prev, 
        stories: snapshot.size,
        publishedStories: publishedCount,
        episodes: totalEpisodes
      }));
      setLoading(false);
    }, (error) => {
      console.error("Dashboard stories error:", error);
      setLoading(false);
    });

    return () => {
      unsubUsers();
      unsubStories();
    };
  }, []);

  return (
    <div className="flex flex-col gap-8">
      <header className="flex flex-col gap-1">
        <h1 className="text-display font-bold">Dashboard</h1>
        <p className="text-on-surface-variant">Live metrics and system overview</p>
      </header>

      {loading ? (
        <div className="flex items-center justify-center p-12">
          <div className="w-8 h-8 rounded-full border-2 border-primary border-t-transparent animate-spin"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard title="Total Users" value={stats.users} icon={<Users size={24} />} color="bg-tertiary" />
          <StatCard title="Total Stories" value={stats.stories} icon={<BookOpen size={24} />} color="bg-primary" />
          <StatCard title="Published Stories" value={stats.publishedStories} icon={<PlayCircle size={24} />} color="bg-secondary" />
          <StatCard title="Episodes" value={stats.episodes} icon={<Layers size={24} />} color="bg-surface-container-high" />
        </div>
      )}
    </div>
  );
}

function StatCard({ title, value, icon, color }: { title: string, value: number | string, icon: React.ReactNode, color: string }) {
  return (
    <div className="p-6 rounded-2xl bg-surface-container border border-surface-container-highest flex flex-col gap-4 relative overflow-hidden">
      <div className="flex items-center justify-between z-10">
        <div className={`p-3 rounded-xl ${color} bg-opacity-20 text-on-surface`}>
          {icon}
        </div>
      </div>
      <div className="flex flex-col z-10">
        <span className="text-display-mobile font-bold text-on-surface">{value}</span>
        <span className="text-label-md text-on-surface-variant uppercase tracking-wider">{title}</span>
      </div>
      <div className={`absolute -bottom-8 -right-8 w-32 h-32 rounded-full ${color} opacity-5 blur-2xl`}></div>
    </div>
  );
}
