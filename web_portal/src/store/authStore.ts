// src/store/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: string;
  email: string;
  role: 'admin' | 'freelancer' | 'client';
  name: string;
}

interface AuthState {
  accessToken: string | null;
  refreshToken: string | null;
  user: User | null;
  login: (accessToken: string, refreshToken: string, user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      refreshToken: null,
      user: null,
      
      login: (accessToken, refreshToken, user) => set({ 
        accessToken, 
        refreshToken, 
        user,
      }),
      
      logout: () => set({ 
        accessToken: null, 
        refreshToken: null, 
        user: null 
      }),
    }),
    {
      name: 'admin-auth-storage', // LocalStorage'da bu isimle saklanacak
    }
  )
);