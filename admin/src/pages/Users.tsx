import { useEffect, useState, useMemo } from 'react';
import { collection, query, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { format, formatDistanceToNow, isAfter, subDays } from 'date-fns';
import {
  Mail,
  Shield,
  User,
  Search,
  RefreshCw,
  AlertCircle,
  Eye,
  X,
  Filter,
  Download,
  Users as UsersIcon,
  UserCheck,
  ShieldCheck,
  Ban,
  Calendar,
  Clock,
  ExternalLink,
} from 'lucide-react';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Drawer } from '../components/ui/Drawer';
import { useToast } from '../components/ui/ToastContext';

interface UserRecord {
  id: string;
  name?: string;
  email?: string;
  photoUrl?: string;
  role?: string;
  isBlocked?: boolean;
  status?: string;
  createdAt?: any;
  lastLoginAt?: any;
}

export default function Users() {
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const toast = useToast();

  // Search & Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [activityFilter, setActivityFilter] = useState('all');
  const [regFilter, setRegFilter] = useState('all');

  // Drawer details
  const [selectedUser, setSelectedUser] = useState<UserRecord | null>(null);
  const [isUpdatingUser, setIsUpdatingUser] = useState(false);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = () => {
    setLoading(true);
    setError(null);
    const q = query(collection(db, 'users'));
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const mapped = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as UserRecord));
        mapped.sort((a, b) => {
          const dateA = a.lastLoginAt?.toDate
            ? a.lastLoginAt.toDate().getTime()
            : a.createdAt?.toDate
            ? a.createdAt.toDate().getTime()
            : 0;
          const dateB = b.lastLoginAt?.toDate
            ? b.lastLoginAt.toDate().getTime()
            : b.createdAt?.toDate
            ? b.createdAt.toDate().getTime()
            : 0;
          return dateB - dateA;
        });
        setUsers(mapped);
        setLoading(false);
      },
      (err) => {
        setError('Failed to load users: ' + err.message);
        setLoading(false);
      }
    );
    return () => unsubscribe();
  };

  // Metrics
  const metrics = useMemo(() => {
    const total = users.length;
    const activeLast7d = users.filter((u) => {
      if (!u.lastLoginAt?.toDate) return false;
      return isAfter(u.lastLoginAt.toDate(), subDays(new Date(), 7));
    }).length;
    const admins = users.filter((u) => u.role === 'admin').length;
    const standard = total - admins;

    return { total, activeLast7d, admins, standard };
  }, [users]);

  // Filtered users
  const filteredUsers = useMemo(() => {
    return users.filter((user) => {
      const q = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !q ||
        (user.name && user.name.toLowerCase().includes(q)) ||
        (user.email && user.email.toLowerCase().includes(q)) ||
        user.id.toLowerCase().includes(q);

      const matchesRole = roleFilter === 'all' || (user.role || 'user') === roleFilter;

      let matchesActivity = true;
      if (activityFilter === 'recent') {
        matchesActivity =
          !!user.lastLoginAt?.toDate &&
          isAfter(user.lastLoginAt.toDate(), subDays(new Date(), 7));
      } else if (activityFilter === 'never') {
        matchesActivity = !user.lastLoginAt?.toDate;
      }

      let matchesReg = true;
      if (regFilter === 'new') {
        matchesReg =
          !!user.createdAt?.toDate && isAfter(user.createdAt.toDate(), subDays(new Date(), 7));
      }

      return matchesSearch && matchesRole && matchesActivity && matchesReg;
    });
  }, [users, searchQuery, roleFilter, activityFilter, regFilter]);

  // CSV Export
  const exportCSV = () => {
    if (filteredUsers.length === 0) {
      toast.showToast({
        type: 'info',
        title: 'No users to export',
        message: 'The current filter produces 0 rows.',
      });
      return;
    }

    const headers = ['User ID', 'Name', 'Email', 'Role', 'Status', 'Registered Date', 'Last Active'];
    const rows = filteredUsers.map((u) => [
      `"${u.id}"`,
      `"${(u.name || 'Unknown').replace(/"/g, '""')}"`,
      `"${(u.email || '').replace(/"/g, '""')}"`,
      `"${u.role || 'user'}"`,
      `"${u.isBlocked ? 'Blocked' : 'Active'}"`,
      `"${u.createdAt?.toDate ? format(u.createdAt.toDate(), 'yyyy-MM-dd') : 'Unknown'}"`,
      `"${u.lastLoginAt?.toDate ? format(u.lastLoginAt.toDate(), 'yyyy-MM-dd HH:mm') : 'Never'}"`,
    ]);

    const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `storyverse_users_${format(new Date(), 'yyyy-MM-dd')}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.showToast({
      type: 'success',
      title: 'Export Complete',
      message: `Exported ${filteredUsers.length} user records to CSV.`,
    });
  };

  // Toggle user role
  const handleToggleRole = async (user: UserRecord) => {
    const nextRole = user.role === 'admin' ? 'user' : 'admin';
    if (!window.confirm(`Change ${user.name || user.email}'s role to ${nextRole.toUpperCase()}?`)) {
      return;
    }

    try {
      setIsUpdatingUser(true);
      await updateDoc(doc(db, 'users', user.id), {
        role: nextRole,
      });

      if (selectedUser?.id === user.id) {
        setSelectedUser({ ...selectedUser, role: nextRole });
      }

      toast.showToast({
        type: 'success',
        title: 'Role Updated',
        message: `${user.name || 'User'} is now an ${nextRole}.`,
      });
    } catch (e: any) {
      toast.showToast({
        type: 'error',
        title: 'Update Failed',
        message: e.message,
      });
    } finally {
      setIsUpdatingUser(false);
    }
  };

  // Toggle block state
  const handleToggleBlock = async (user: UserRecord) => {
    const isCurrentlyBlocked = user.isBlocked === true;
    const action = isCurrentlyBlocked ? 'unblock' : 'block';

    if (!window.confirm(`Are you sure you want to ${action} this user?`)) {
      return;
    }

    try {
      setIsUpdatingUser(true);
      await updateDoc(doc(db, 'users', user.id), {
        isBlocked: !isCurrentlyBlocked,
        status: !isCurrentlyBlocked ? 'blocked' : 'active',
      });

      if (selectedUser?.id === user.id) {
        setSelectedUser({
          ...selectedUser,
          isBlocked: !isCurrentlyBlocked,
          status: !isCurrentlyBlocked ? 'blocked' : 'active',
        });
      }

      toast.showToast({
        type: 'success',
        title: `User ${isCurrentlyBlocked ? 'Unblocked' : 'Blocked'}`,
        message: `${user.name || user.email} was successfully ${action}ed.`,
      });
    } catch (e: any) {
      toast.showToast({
        type: 'error',
        title: 'Action Failed',
        message: e.message,
      });
    } finally {
      setIsUpdatingUser(false);
    }
  };

  return (
    <div className="flex flex-col gap-6 pb-12 max-w-7xl mx-auto w-full">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Audience & Users</h1>
          <p className="text-xs text-zinc-400 mt-0.5">
            Manage registered accounts, permissions, and session activity ({users.length} registered)
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Button
            type="button"
            variant="secondary"
            size="sm"
            onClick={exportCSV}
            leftIcon={<Download size={15} />}
          >
            Export CSV
          </Button>

          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={() => {
              fetchUsers();
            }}
            leftIcon={<RefreshCw size={15} />}
          >
            Refresh
          </Button>
        </div>
      </div>

      {/* Hero Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-4 rounded-2xl bg-surface-1/70 border border-white/[0.08] flex items-center gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-accent-coral/10 border border-accent-coral/20 flex items-center justify-center text-accent-coral shrink-0">
            <UsersIcon size={20} />
          </div>
          <div>
            <span className="text-[11px] font-medium text-zinc-400">Total Accounts</span>
            <div className="text-xl font-bold text-white tracking-tight">{metrics.total}</div>
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-surface-1/70 border border-white/[0.08] flex items-center gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 shrink-0">
            <UserCheck size={20} />
          </div>
          <div>
            <span className="text-[11px] font-medium text-zinc-400">Active (7 Days)</span>
            <div className="text-xl font-bold text-white tracking-tight">{metrics.activeLast7d}</div>
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-surface-1/70 border border-white/[0.08] flex items-center gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center text-purple-400 shrink-0">
            <ShieldCheck size={20} />
          </div>
          <div>
            <span className="text-[11px] font-medium text-zinc-400">Administrators</span>
            <div className="text-xl font-bold text-white tracking-tight">{metrics.admins}</div>
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-surface-1/70 border border-white/[0.08] flex items-center gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-sky-500/10 border border-sky-500/20 flex items-center justify-center text-sky-400 shrink-0">
            <User size={20} />
          </div>
          <div>
            <span className="text-[11px] font-medium text-zinc-400">Standard Viewers</span>
            <div className="text-xl font-bold text-white tracking-tight">{metrics.standard}</div>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="p-3.5 bg-surface-1/60 rounded-2xl border border-white/[0.08] flex flex-col md:flex-row gap-3">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-zinc-500" />
          <input
            type="text"
            placeholder="Search by user name, email, or Firebase ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-9 py-2 bg-surface-2/60 border border-white/[0.08] rounded-xl text-xs text-white placeholder:text-zinc-500 focus:border-accent-coral outline-none transition-all"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-white"
            >
              <X size={14} />
            </button>
          )}
        </div>

        <div className="flex items-center gap-2 overflow-x-auto pb-1 md:pb-0">
          {/* Role Filter */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-surface-2/60 border border-white/[0.08] shrink-0 text-xs">
            <Filter size={13} className="text-zinc-400" />
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="bg-transparent text-zinc-200 outline-none cursor-pointer text-xs"
            >
              <option value="all" className="bg-surface-0">
                All Roles
              </option>
              <option value="admin" className="bg-surface-0">
                Admin
              </option>
              <option value="user" className="bg-surface-0">
                User
              </option>
            </select>
          </div>

          {/* Activity Filter */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-surface-2/60 border border-white/[0.08] shrink-0 text-xs">
            <select
              value={activityFilter}
              onChange={(e) => setActivityFilter(e.target.value)}
              className="bg-transparent text-zinc-200 outline-none cursor-pointer text-xs"
            >
              <option value="all" className="bg-surface-0">
                All Activity
              </option>
              <option value="recent" className="bg-surface-0">
                Active in Last 7d
              </option>
              <option value="never" className="bg-surface-0">
                Never Logged In
              </option>
            </select>
          </div>

          {/* Registration Filter */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-surface-2/60 border border-white/[0.08] shrink-0 text-xs">
            <select
              value={regFilter}
              onChange={(e) => setRegFilter(e.target.value)}
              className="bg-transparent text-zinc-200 outline-none cursor-pointer text-xs"
            >
              <option value="all" className="bg-surface-0">
                All Registrations
              </option>
              <option value="new" className="bg-surface-0">
                Joined in Last 7d
              </option>
            </select>
          </div>

          {(searchQuery || roleFilter !== 'all' || activityFilter !== 'all' || regFilter !== 'all') && (
            <button
              onClick={() => {
                setSearchQuery('');
                setRoleFilter('all');
                setActivityFilter('all');
                setRegFilter('all');
              }}
              className="text-xs text-accent-coral hover:underline font-semibold px-2 shrink-0"
            >
              Clear filters
            </button>
          )}
        </div>
      </div>

      {error ? (
        <div className="p-6 bg-red-500/10 border border-red-500/20 text-red-400 rounded-2xl flex items-center gap-3">
          <AlertCircle size={20} />
          <p className="text-sm">{error}</p>
        </div>
      ) : (
        /* Users Data Table */
        <div className="bg-surface-1/60 rounded-2xl border border-white/[0.08] overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-[760px]">
              <thead>
                <tr className="border-b border-white/[0.06] bg-surface-2/40 text-[11px] font-semibold text-zinc-400 uppercase tracking-wider">
                  <th className="px-6 py-3.5">User</th>
                  <th className="px-6 py-3.5">Role</th>
                  <th className="px-6 py-3.5">Status</th>
                  <th className="px-6 py-3.5">Registered</th>
                  <th className="px-6 py-3.5">Last Active</th>
                  <th className="px-6 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.04]">
                {loading && users.length === 0 ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <tr key={i}>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-full bg-white/[0.05] animate-pulse shrink-0" />
                          <div className="space-y-1.5">
                            <div className="w-28 h-3.5 bg-white/[0.06] rounded animate-pulse" />
                            <div className="w-36 h-3 bg-white/[0.04] rounded animate-pulse" />
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="w-16 h-5 rounded-full bg-white/[0.05] animate-pulse" />
                      </td>
                      <td className="px-6 py-4">
                        <div className="w-14 h-5 rounded-full bg-white/[0.05] animate-pulse" />
                      </td>
                      <td className="px-6 py-4">
                        <div className="w-20 h-3.5 bg-white/[0.04] rounded animate-pulse" />
                      </td>
                      <td className="px-6 py-4">
                        <div className="w-20 h-3.5 bg-white/[0.04] rounded animate-pulse" />
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="w-7 h-7 rounded-lg bg-white/[0.05] animate-pulse ml-auto" />
                      </td>
                    </tr>
                  ))
                ) : filteredUsers.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-16 text-center">
                      <div className="flex flex-col items-center justify-center gap-2 max-w-sm mx-auto">
                        <div className="w-12 h-12 rounded-2xl bg-white/[0.04] border border-white/[0.08] flex items-center justify-center text-zinc-500 mb-1">
                          <UsersIcon size={22} />
                        </div>
                        <h4 className="text-sm font-semibold text-white">No users match filters</h4>
                        <p className="text-xs text-zinc-400">
                          Try adjusting search terms or resetting filters to see results.
                        </p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  filteredUsers.map((user) => {
                    const initials = (user.name || user.email || 'U').slice(0, 2).toUpperCase();
                    const isBlocked = user.isBlocked === true;

                    return (
                      <tr
                        key={user.id}
                        className="hover:bg-white/[0.02] transition-colors group text-xs"
                      >
                        {/* User Identity */}
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-accent-coral/20 to-accent-orange/20 border border-white/[0.1] flex items-center justify-center text-white font-bold text-xs shrink-0 overflow-hidden">
                              {user.photoUrl ? (
                                <img
                                  src={user.photoUrl}
                                  alt="avatar"
                                  className="w-full h-full object-cover"
                                  onError={(e) => {
                                    (e.currentTarget as HTMLElement).style.display = 'none';
                                  }}
                                />
                              ) : (
                                initials
                              )}
                            </div>
                            <div className="flex flex-col min-w-0">
                              <span className="font-semibold text-white tracking-tight truncate max-w-[180px]">
                                {user.name || 'Anonymous User'}
                              </span>
                              <span className="text-[11px] text-zinc-400 truncate max-w-[200px]">
                                {user.email || 'No email registered'}
                              </span>
                            </div>
                          </div>
                        </td>

                        {/* Role */}
                        <td className="px-6 py-4">
                          <Badge variant={user.role === 'admin' ? 'admin' : 'user'} size="sm">
                            {user.role === 'admin' ? 'Admin' : 'User'}
                          </Badge>
                        </td>

                        {/* Status */}
                        <td className="px-6 py-4">
                          {isBlocked ? (
                            <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-red-400 bg-red-500/10 border border-red-500/20 px-2 py-0.5 rounded-full">
                              <Ban size={11} /> Blocked
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 rounded-full">
                              <div className="w-1.5 h-1.5 rounded-full bg-emerald-400" /> Active
                            </span>
                          )}
                        </td>

                        {/* Registered */}
                        <td className="px-6 py-4 text-zinc-400">
                          {user.createdAt?.toDate
                            ? format(user.createdAt.toDate(), 'MMM d, yyyy')
                            : 'Unknown'}
                        </td>

                        {/* Last Active */}
                        <td className="px-6 py-4 text-zinc-400">
                          {user.lastLoginAt?.toDate
                            ? formatDistanceToNow(user.lastLoginAt.toDate(), { addSuffix: true })
                            : 'Never'}
                        </td>

                        {/* Actions */}
                        <td className="px-6 py-4 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              onClick={() => setSelectedUser(user)}
                              className="p-1.5 rounded-lg text-zinc-400 hover:text-white hover:bg-white/[0.08] transition-colors"
                              title="View User Sheet"
                            >
                              <Eye size={16} />
                            </button>
                            <button
                              onClick={() => handleToggleRole(user)}
                              className="p-1.5 rounded-lg text-zinc-400 hover:text-purple-400 hover:bg-purple-500/10 transition-colors"
                              title={user.role === 'admin' ? 'Demote to User' : 'Promote to Admin'}
                            >
                              <Shield size={16} />
                            </button>
                            <button
                              onClick={() => handleToggleBlock(user)}
                              className={`p-1.5 rounded-lg transition-colors ${
                                isBlocked
                                  ? 'text-emerald-400 hover:bg-emerald-500/10'
                                  : 'text-zinc-500 hover:text-red-400 hover:bg-red-500/10'
                              }`}
                              title={isBlocked ? 'Unblock user' : 'Block user'}
                            >
                              <Ban size={16} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ================= USER DETAILS SLIDE-OVER DRAWER ================= */}
      <Drawer
        isOpen={!!selectedUser}
        onClose={() => setSelectedUser(null)}
        title={selectedUser?.name || 'User Profile'}
        subtitle={`Account registered with StoryVerse Mobile`}
        badge={
          selectedUser && (
            <Badge variant={selectedUser.role === 'admin' ? 'admin' : 'user'} size="sm">
              {selectedUser.role || 'user'}
            </Badge>
          )
        }
        width="lg"
        footer={
          selectedUser && (
            <div className="flex items-center justify-between w-full">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedUser(null)}
              >
                Close
              </Button>

              <div className="flex items-center gap-2">
                <Button
                  variant="secondary"
                  size="sm"
                  loading={isUpdatingUser}
                  onClick={() => handleToggleRole(selectedUser)}
                >
                  {selectedUser.role === 'admin' ? 'Revoke Admin' : 'Make Admin'}
                </Button>

                <Button
                  variant={selectedUser.isBlocked ? 'secondary' : 'danger'}
                  size="sm"
                  loading={isUpdatingUser}
                  onClick={() => handleToggleBlock(selectedUser)}
                >
                  {selectedUser.isBlocked ? 'Unblock User' : 'Block Account'}
                </Button>
              </div>
            </div>
          )
        }
      >
        {selectedUser && (
          <div className="space-y-6">
            {/* User Profile Card */}
            <div className="flex items-center gap-4 p-4 rounded-2xl bg-surface-1 border border-white/[0.08]">
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-accent-coral/20 to-accent-orange/20 border border-white/[0.1] flex items-center justify-center text-white text-lg font-bold shrink-0 overflow-hidden">
                {selectedUser.photoUrl ? (
                  <img
                    src={selectedUser.photoUrl}
                    alt="avatar"
                    className="w-full h-full object-cover"
                  />
                ) : (
                  (selectedUser.name || 'U').slice(0, 2).toUpperCase()
                )}
              </div>
              <div className="flex flex-col min-w-0">
                <h3 className="text-base font-bold text-white tracking-tight truncate">
                  {selectedUser.name || 'Unknown User'}
                </h3>
                <span className="text-xs text-zinc-400 truncate">{selectedUser.email}</span>
                <span className="text-[11px] text-zinc-500 font-mono mt-0.5">
                  ID: {selectedUser.id}
                </span>
              </div>
            </div>

            {/* Quick Metrics Grid */}
            <div className="grid grid-cols-2 gap-3">
              <div className="p-3.5 rounded-xl bg-surface-1 border border-white/[0.06] flex flex-col gap-1">
                <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider">
                  Account Status
                </span>
                <div className="flex items-center gap-2 mt-0.5">
                  <div
                    className={`w-2 h-2 rounded-full ${
                      selectedUser.isBlocked ? 'bg-red-400' : 'bg-emerald-400'
                    }`}
                  />
                  <span className="text-xs font-semibold text-white">
                    {selectedUser.isBlocked ? 'Suspended / Blocked' : 'Active Subscriber'}
                  </span>
                </div>
              </div>

              <div className="p-3.5 rounded-xl bg-surface-1 border border-white/[0.06] flex flex-col gap-1">
                <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider">
                  Role Permission
                </span>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <Shield size={14} className="text-accent-coral" />
                  <span className="text-xs font-semibold text-white capitalize">
                    {selectedUser.role || 'User'}
                  </span>
                </div>
              </div>

              <div className="p-3.5 rounded-xl bg-surface-1 border border-white/[0.06] flex flex-col gap-1">
                <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider">
                  Registered Date
                </span>
                <div className="flex items-center gap-1.5 mt-0.5 text-xs text-white font-medium">
                  <Calendar size={13} className="text-zinc-500" />
                  <span>
                    {selectedUser.createdAt?.toDate
                      ? format(selectedUser.createdAt.toDate(), 'PPP')
                      : 'Unknown'}
                  </span>
                </div>
              </div>

              <div className="p-3.5 rounded-xl bg-surface-1 border border-white/[0.06] flex flex-col gap-1">
                <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider">
                  Last Activity
                </span>
                <div className="flex items-center gap-1.5 mt-0.5 text-xs text-white font-medium">
                  <Clock size={13} className="text-zinc-500" />
                  <span>
                    {selectedUser.lastLoginAt?.toDate
                      ? formatDistanceToNow(selectedUser.lastLoginAt.toDate(), { addSuffix: true })
                      : 'Never logged in'}
                  </span>
                </div>
              </div>
            </div>

            {/* Email link */}
            {selectedUser.email && (
              <a
                href={`mailto:${selectedUser.email}`}
                className="flex items-center justify-between p-3.5 rounded-xl bg-surface-1 hover:bg-surface-2 border border-white/[0.06] text-xs text-zinc-300 hover:text-white transition-colors"
              >
                <div className="flex items-center gap-2">
                  <Mail size={15} className="text-accent-coral" />
                  <span>Send direct email to {selectedUser.email}</span>
                </div>
                <ExternalLink size={14} className="text-zinc-500" />
              </a>
            )}

            {/* System Info */}
            <div className="space-y-2">
              <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider block">
                Raw Firebase Record
              </span>
              <pre className="p-3.5 rounded-xl bg-surface-0 border border-white/[0.06] text-[11px] font-mono text-zinc-400 overflow-x-auto leading-relaxed">
                {JSON.stringify(
                  {
                    id: selectedUser.id,
                    name: selectedUser.name,
                    email: selectedUser.email,
                    role: selectedUser.role || 'user',
                    isBlocked: !!selectedUser.isBlocked,
                  },
                  null,
                  2
                )}
              </pre>
            </div>
          </div>
        )}
      </Drawer>
    </div>
  );
}
