import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://isqxomfulycmxccbvfyi.supabase.co';
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_S2am5rwWRBOzl0p1efGwRA_xY3zrcFJ';

if (supabaseUrl === 'https://isqxomfulycmxccbvfyi.supabase.co' && !import.meta.env.VITE_SUPABASE_URL) {
  console.warn("Warning: Supabase configuration variables are missing. Using default fallback.");
}

export const supabase = createClient(supabaseUrl, supabaseKey);
