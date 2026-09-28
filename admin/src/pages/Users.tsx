import { useEffect, useState, useMemo } from 'react';
import { collection, query, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { format, formatDistanceToNow, isAfter, subDays } from 'date-fns';
import { Mail, Shield, User, Search, RefreshCw, AlertCircle, Eye, X, Filter } from 'lucide-react';

export default function Users() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Search & Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [activityFilter, setActivityFilter] = useState('all');
  const [regFilter, setRegFilter] = useState('all');
  
  const [selectedUser, setSelectedUser] = useState<any | null>(null);
  const [, setTick] = useState(0);

  useEffect(() => {
    fetchUsers();
    const intervalId = setInterval(() => {
      setTick(t => t + 1);
    }, 60000); 
    return () => clearInterval(intervalId);
  }, []);

  const fetchUsers = () => {
    setLoading(true);
    setError(null);
    const q = query(collection(db, 'users'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      let mapped = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as any));
      // Sort client-side by lastLoginAt (most recent first), fallback to createdAt
      mapped.sort((a, b) => {
        const dateA = a.lastLoginAt?.toDate ? a.lastLoginAt.toDate().getTime() : (a.createdAt?.toDate ? a.createdAt.toDate().getTime() : 0);
        const dateB = b.lastLoginAt?.toDate ? b.lastLoginAt.toDate().getTime() : (b.createdAt?.toDate ? b.createdAt.toDate().getTime() : 0);
        return dateB - dateA; 
      });
      setUsers(mapped);
      setLoading(false);
    }, (error) => {
      setError("Failed to load users: " + error.message);
      setLoading(false);
    });
    return () => unsubscribe();
  };

  const filteredUsers = useMemo(() => {
    return users.filter(user => {
      const q = searchQuery.toLowerCase();
      const matchesSearch = !q || (
        (user.name && typeof user.name === 'string' && user.name.toLowerCase().includes(q)) ||
        (user.email && typeof user.email === 'string' && user.email.toLowerCase().includes(q)) ||
        (user.id && typeof user.id === 'string' && user.id.toLowerCase().includes(q))
      );

      const matchesRole = roleFilter === 'all' || (user.role || 'user') === roleFilter;
      
      let matchesActivity = true;
      if (activityFilter === 'recent') {
        matchesActivity = user.lastLoginAt?.toDate && isAfter(user.lastLoginAt.toDate(), subDays(new Date(), 7));
      } else if (activityFilter === 'never') {
        matchesActivity = !user.lastLoginAt?.toDate;
      }

      let matchesReg = true;
      if (regFilter === 'new') {
        matchesReg = user.createdAt?.toDate && isAfter(user.createdAt.toDate(), subDays(new Date(), 7));
      }

      return matchesSearch && matchesRole && matchesActivity && matchesReg;
    });
  }, [users, searchQuery, roleFilter, activityFilter, regFilter]);

  return (
    <div className="flex flex-col gap-6 pb-12">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex flex-col gap-1">
          <h1 className="text-display font-bold">Users</h1>
          <p className="text-on-surface-variant">Manage application users and roles ({users.length} total)</p>
        </div>
        <button 
          onClick={fetchUsers}
          className="flex items-center gap-2 px-4 py-2 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-full transition-colors font-bold text-sm border border-surface-container-highest w-max"
        >
          <RefreshCw size={16} />
          Refresh
        </button>
      </div>

      {/* FILTERS & SEARCH */}
      <div className="flex flex-col md:flex-row gap-4 bg-surface-container p-4 rounded-2xl border border-surface-container-highest">
        <div className="relative flex-1">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-on-surface-variant">
            <Search size={18} />
          </div>
          <input
            type="text"
            placeholder="Search by name, email, or ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-10 py-2.5 bg-surface-container-highest border-none rounded-xl focus:ring-2 focus:ring-primary text-on-surface placeholder:text-on-surface-variant transition-all outline-none"
          />
          {searchQuery && (
            <button 
              onClick={() => setSearchQuery('')}
              className="absolute inset-y-0 right-0 pr-3 flex items-center text-on-surface-variant hover:text-on-surface"
            >
              <X size={18} />
            </button>
          )}
        </div>
        
        <div className="flex items-center gap-2 overflow-x-auto pb-2 md:pb-0 hide-scrollbar">
          <div className="flex items-center gap-2 bg-surface-container-highest rounded-xl px-3 py-1.5 flex-shrink-0">
            <Filter size={14} className="text-on-surface-variant" />
            <select 
              value={roleFilter} 
              onChange={e => setRoleFilter(e.target.value)}
              className="bg-transparent border-none text-sm text-on-surface outline-none cursor-pointer"
            >
              <option value="all">All Roles</option>
              <option value="admin">Admin</option>
              <option value="user">User</option>
            </select>
          </div>
          
          <div className="flex items-center gap-2 bg-surface-container-highest rounded-xl px-3 py-1.5 flex-shrink-0">
            <select 
              value={activityFilter} 
              onChange={e => setActivityFilter(e.target.value)}
              className="bg-transparent border-none text-sm text-on-surface outline-none cursor-pointer"
            >
              <option value="all">All Activity</option>
              <option value="recent">Recently Active (7d)</option>
              <option value="never">Never Logged In</option>
            </select>
          </div>

          <div className="flex items-center gap-2 bg-surface-container-highest rounded-xl px-3 py-1.5 flex-shrink-0">
            <select 
              value={regFilter} 
              onChange={e => setRegFilter(e.target.value)}
              className="bg-transparent border-none text-sm text-on-surface outline-none cursor-pointer"
            >
              <option value="all">All Registrations</option>
              <option value="new">New Users (7d)</option>
            </select>
          </div>
        </div>
      </div>

      {error ? (
        <div className="p-6 bg-error-container text-on-error-container rounded-2xl flex items-center gap-3">
          <AlertCircle size={24} />
          <p>{error}</p>
        </div>
      ) : (
        <div className="bg-surface-container rounded-2xl overflow-hidden border border-surface-container-highest">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-[800px]">
              <thead>
                <tr className="bg-surface-container-high border-b border-surface-container-highest">
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant">User</th>
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant">Role</th>
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant">Registered</th>
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant">Last Active</th>
                  <th className="px-6 py-4 font-label-lg text-on-surface-variant text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading && users.length === 0 ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <tr key={i} className="border-b border-surface-container-highest">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-surface-container-highest animate-pulse"></div>
                          <div className="flex flex-col gap-2">
                            <div className="w-24 h-4 bg-surface-container-highest animate-pulse rounded"></div>
                            <div className="w-32 h-3 bg-surface-container-highest animate-pulse rounded"></div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4"><div className="w-16 h-6 bg-surface-container-highest animate-pulse rounded-full"></div></td>
                      <td className="px-6 py-4"><div className="w-24 h-4 bg-surface-container-highest animate-pulse rounded"></div></td>
                      <td className="px-6 py-4"><div className="w-24 h-4 bg-surface-container-highest animate-pulse rounded"></div></td>
                      <td className="px-6 py-4"><div className="w-8 h-8 bg-surface-container-highest animate-pulse rounded ml-auto"></div></td>
                    </tr>
                  ))
                ) : filteredUsers.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="p-16 text-center text-on-surface-variant">
                      <div className="flex flex-col items-center justify-center gap-3">
                        <div className="p-4 bg-surface-container-highest rounded-full">
                          <Search size={32} className="opacity-50" />
                        </div>
                        <span className="font-bold text-on-surface">No users found</span>
                        <span className="text-sm">Try adjusting your search or filters.</span>
                        {(searchQuery || roleFilter !== 'all' || activityFilter !== 'all' || regFilter !== 'all') && (
                          <button 
                            onClick={() => { setSearchQuery(''); setRoleFilter('all'); setActivityFilter('all'); setRegFilter('all'); }}
                            className="mt-2 text-primary hover:underline text-sm font-bold"
                          >
                            Clear all filters
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ) : (
                  filteredUsers.map((user) => (
                    <tr key={user.id} className="border-b border-surface-container-highest hover:bg-surface-container-high transition-colors group">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-surface-container-highest flex items-center justify-center text-on-surface-variant overflow-hidden flex-shrink-0">
                            {user.photoUrl ? (
                              <img src={user.photoUrl} alt="avatar" className="w-full h-full object-cover" />
                            ) : (
                              <User size={20} />
                            )}
                          </div>
                          <div className="flex flex-col">
                            <span className="font-headline-sm text-on-surface">{user.name || 'Unknown User'}</span>
                            <div className="flex items-center gap-1 text-on-surface-variant font-body-sm text-sm">
                              <Mail size={12} />
                              <span className="truncate max-w-[200px]">{user.email || 'No email provided'}</span>
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${
                          user.role === 'admin' 
                            ? 'bg-tertiary-container text-on-tertiary-container' 
                            : 'bg-surface-variant text-on-surface-variant'
                        }`}>
                          <Shield size={12} />
                          {user.role || 'user'}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-on-surface-variant font-body-sm">
                        {user.createdAt?.toDate ? format(user.createdAt.toDate(), 'MMM d, yyyy') : 'Unknown'}
                      </td>
                      <td className="px-6 py-4 text-on-surface-variant font-body-sm">
                        {user.lastLoginAt?.toDate 
                          ? formatDistanceToNow(user.lastLoginAt.toDate(), { addSuffix: true }) 
                          : 'Never'}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end">
                          <button 
                            onClick={() => setSelectedUser(user)}
                            className="p-2 rounded-lg bg-surface hover:bg-primary-container hover:text-on-primary-container transition-colors text-outline opacity-0 group-hover:opacity-100 focus:opacity-100"
                            title="View Details"
                          >
                            <Eye size={18} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* USER DETAILS MODAL */}
      {selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-surface-container border border-surface-container-highest rounded-2xl w-full max-w-md shadow-2xl overflow-hidden flex flex-col">
            <div className="flex items-center justify-between p-6 border-b border-surface-container-highest bg-surface-container-high">
              <h2 className="font-display text-lg font-bold">User Details</h2>
              <button 
                onClick={() => setSelectedUser(null)}
                className="p-2 hover:bg-surface-variant rounded-full transition-colors text-on-surface-variant"
              >
                <X size={20} />
              </button>
            </div>
            
            <div className="p-6 flex flex-col gap-6">
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 rounded-full bg-surface-container-highest flex items-center justify-center text-on-surface-variant overflow-hidden flex-shrink-0">
                  {selectedUser.photoUrl ? (
                    <img src={selectedUser.photoUrl} alt="avatar" className="w-full h-full object-cover" />
                  ) : (
                    <User size={32} />
                  )}
                </div>
                <div className="flex flex-col">
                  <span className="font-display text-xl font-bold">{selectedUser.name || 'Unknown User'}</span>
                  <span className="text-on-surface-variant">{selectedUser.email || 'No email provided'}</span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1 p-3 bg-surface-container-highest rounded-xl">
                  <span className="text-xs text-on-surface-variant uppercase tracking-wider font-bold">Role</span>
                  <div className="flex items-center gap-2">
                    <Shield size={14} className={selectedUser.role === 'admin' ? 'text-tertiary' : 'text-on-surface'} />
                    <span className="capitalize font-medium">{selectedUser.role || 'User'}</span>
                  </div>
                </div>
                <div className="flex flex-col gap-1 p-3 bg-surface-container-highest rounded-xl">
                  <span className="text-xs text-on-surface-variant uppercase tracking-wider font-bold">Status</span>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-green-500"></div>
                    <span className="capitalize font-medium">Active</span>
                  </div>
                </div>
                <div className="flex flex-col gap-1 p-3 bg-surface-container-highest rounded-xl">
                  <span className="text-xs text-on-surface-variant uppercase tracking-wider font-bold">Registered</span>
                  <span className="font-medium">{selectedUser.createdAt?.toDate ? format(selectedUser.createdAt.toDate(), 'MMM d, yyyy') : 'Unknown'}</span>
                </div>
                <div className="flex flex-col gap-1 p-3 bg-surface-container-highest rounded-xl">
                  <span className="text-xs text-on-surface-variant uppercase tracking-wider font-bold">Last Login</span>
                  <span className="font-medium">{selectedUser.lastLoginAt?.toDate ? formatDistanceToNow(selectedUser.lastLoginAt.toDate(), { addSuffix: true }) : 'Never'}</span>
                </div>
              </div>

              <div className="flex flex-col gap-1 p-4 bg-surface-container-high rounded-xl border border-surface-container-highest mt-2">
                <span className="text-xs text-on-surface-variant uppercase tracking-wider font-bold">User ID</span>
                <code className="text-xs font-mono text-outline break-all">{selectedUser.id}</code>
              </div>
            </div>
            
            <div className="p-4 border-t border-surface-container-highest flex justify-end bg-surface-container-high">
              <button 
                onClick={() => setSelectedUser(null)}
                className="px-6 py-2 bg-surface-variant hover:bg-surface-container-highest text-on-surface rounded-full font-bold transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
