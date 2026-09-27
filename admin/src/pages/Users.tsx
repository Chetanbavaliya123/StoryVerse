import { useEffect, useState } from 'react';
import { collection, query, orderBy, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { format } from 'date-fns';
import { Mail, Shield, User } from 'lucide-react';

export default function Users() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Assuming you have a createdAt field on users
    const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setUsers(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    }, (error) => {
      // If index is missing or query fails, just fetch without ordering
      if(error.code === 'failed-precondition') {
        const fallbackQ = query(collection(db, 'users'));
        onSnapshot(fallbackQ, (snapshot) => {
          setUsers(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
          setLoading(false);
        });
      }
    });
    return () => unsubscribe();
  }, []);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div className="flex flex-col gap-1">
          <h1 className="text-display font-bold">Users</h1>
          <p className="text-on-surface-variant">Manage application users and roles</p>
        </div>
      </div>

      <div className="bg-surface-container rounded-2xl overflow-hidden border border-surface-container-highest">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-high border-b border-surface-container-highest">
                <th className="px-6 py-4 font-label-lg text-on-surface-variant">User ID</th>
                <th className="px-6 py-4 font-label-lg text-on-surface-variant">Email & Name</th>
                <th className="px-6 py-4 font-label-lg text-on-surface-variant">Role</th>
                <th className="px-6 py-4 font-label-lg text-on-surface-variant">Joined</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={4} className="p-8 text-center text-on-surface-variant">Loading users...</td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={4} className="p-8 text-center text-on-surface-variant">No users found.</td>
                </tr>
              ) : (
                users.map((user) => (
                  <tr key={user.id} className="border-b border-surface-container-highest hover:bg-surface-container-high transition-colors">
                    <td className="px-6 py-4 font-mono text-xs text-outline">{user.id}</td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-surface-container-highest flex items-center justify-center shrink-0">
                          {user.photoUrl ? (
                            <img src={user.photoUrl} alt="avatar" className="w-full h-full rounded-full object-cover" />
                          ) : (
                            <User size={20} className="text-outline" />
                          )}
                        </div>
                        <div className="flex flex-col">
                          <span className="font-headline-sm text-on-surface">{user.name || 'Anonymous User'}</span>
                          <span className="flex items-center gap-1 font-label-sm text-outline">
                            <Mail size={12} />
                            {user.email || 'No email'}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2.5 py-1 rounded-full font-label-sm uppercase tracking-wider flex items-center gap-1 w-max ${user.role === 'admin' ? 'bg-primary-container text-on-primary-container' : 'bg-surface-container-highest text-on-surface-variant'}`}>
                        {user.role === 'admin' && <Shield size={14} />}
                        {user.role || 'user'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-on-surface-variant font-body-sm">
                      {user.createdAt?.toDate ? format(user.createdAt.toDate(), 'MMM d, yyyy') : 'Unknown'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
