import { createContext, useContext, useEffect, useState } from 'react';
import { auth, db } from '../lib/firebase';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';

interface AuthContextType {
  user: User | null;
  role: string | null;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  role: null,
  loading: true,
});

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [role, setRole] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setLoading(true);
      setUser(user);
      if (user) {
        try {
          const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 5000));
          const userDoc = await Promise.race([
            getDoc(doc(db, 'users', user.uid)),
            timeoutPromise
          ]) as any;

          if (userDoc && userDoc.exists()) {
            const data = userDoc.data();
            const currentRole = data.role || 'user';
            setRole(currentRole);
            
            if (currentRole === 'admin') {
              try {
                await updateDoc(doc(db, 'users', user.uid), {
                  lastLoginAt: serverTimestamp()
                });
              } catch (updateErr) {
                console.error("Could not update lastLoginAt:", updateErr);
              }
            }
          } else {
            setRole('user');
          }
        } catch (error) {
          console.error("Error fetching user role or timeout:", error);
          setRole('user');
        }
      } else {
        setRole(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ user, role, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
