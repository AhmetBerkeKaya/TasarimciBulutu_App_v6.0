import { Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/auth/LoginPage';
import DashboardHome from './pages/dashboard/Home';
import UsersList from './pages/users/UsersList';
import ProjectList from './pages/projects/ProjectList';
import ShowcaseGallery from './pages/showcase/ShowcaseGallery';
import TestList from './pages/skill-tests/TestList';
import CreateTest from './pages/skill-tests/CreateTest';
import ReportsList from './pages/reports/ReportsList'; // <--- EKLENDİ
import MainLayout from './layouts/MainLayout';
import { useAuthStore } from './store/authStore';

// Korumalı Rota (Giriş Yapılmamışsa Login'e atar)
const ProtectedRoute = ({ children }: { children: JSX.Element }) => {
  const accessToken = useAuthStore((state) => state.accessToken);
  
  if (!accessToken) {
    return <Navigate to="/login" replace />;
  }
  return children;
};

function App() {
  return (
    <Routes>
      {/* Public Rota */}
      <Route path="/login" element={<LoginPage />} />

      {/* Korumalı Rotalar (Admin Paneli) */}
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <MainLayout /> 
          </ProtectedRoute>
        }
      >
        {/* Anasayfa */}
        <Route index element={<DashboardHome />} />
        
        {/* Kullanıcılar */}
        <Route path="users" element={<UsersList />} />
        
        {/* Projeler */}
        <Route path="projects" element={<ProjectList />} />
        
        {/* Vitrin */}
        <Route path="showcase" element={<ShowcaseGallery />} />
        
        {/* Yetenek Testleri */}
        <Route path="skill-tests" element={<TestList />} />
        <Route path="skill-tests/create" element={<CreateTest />} />
        
        {/* Şikayetler (EKLENDİ) */}
        <Route path="reports" element={<ReportsList />} /> 
        
        {/* Ayarlar */}
        <Route path="settings" element={<div>Ayarlar Sayfası (Yakında)</div>} />
      </Route>
    </Routes>
  );
}

export default App;