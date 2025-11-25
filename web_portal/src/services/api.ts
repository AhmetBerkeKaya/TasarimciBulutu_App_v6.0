import axios from 'axios';
import { useAuthStore } from '../store/authStore';

export const API_URL = 'http://localhost:8000'; 

const api = axios.create({
  baseURL: API_URL,
  // DİKKAT: 'Content-Type': 'application/json' satırını BURADAN SİLDİM.
  // Axios, biz FormData gönderirsek otomatik 'multipart/form-data' yapar,
  // JSON gönderirsek 'application/json' yapar. Elle yazmaya gerek yok.
});

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;