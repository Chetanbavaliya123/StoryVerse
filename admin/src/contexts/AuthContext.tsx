import { createContext, useContext, useEffect, useState } from 'react';
import { auth, db } from '../lib/firebase';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';

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
      setUser(user);
      if (user) {
        try {
          const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 2000));
          const userDoc = await Promise.race([
            getDoc(doc(db, 'users', user.uid)),
            timeoutPromise
          ]) as any;

          if (userDoc && userDoc.exists()) {
            setRole(userDoc.data().role || 'admin');
            // Update lastLoginAt for existing user
            try {
              await updateDoc(doc(db, 'users', user.uid), {
                lastLoginAt: serverTimestamp()
              });
            } catch (updateErr) {
              console.error("Could not update lastLoginAt:", updateErr);
            }
          } else {
            // Create the user document if it doesn't exist
            try {
              await setDoc(doc(db, 'users', user.uid), {
                email: user.email,
                role: 'admin',
                createdAt: serverTimestamp(),
                lastLoginAt: serverTimestamp()
              });
            } catch (err) {
              console.error("Could not create user document:", err);
            }
            setRole('admin');
          }
        } catch (error) {
          console.error("Error fetching user role or timeout:", error);
          setRole('admin');
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
