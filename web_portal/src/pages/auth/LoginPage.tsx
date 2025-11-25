import React, { useState } from 'react';
import { TextInput, PasswordInput, Button, Paper, Title, Container, Alert, LoadingOverlay } from '@mantine/core';
import { IconAlertCircle } from '@tabler/icons-react';
import { useNavigate } from 'react-router-dom';
import api from '../../services/api';
import { useAuthStore } from '../../store/authStore';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  
  const login = useAuthStore((state) => state.login);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      // 1. Backend OAuth2 standardı gereği Form Data bekliyor
      const formData = new FormData();
      formData.append('username', email); 
      formData.append('password', password);

      // 2. Token İsteği (ADRES DÜZELTİLDİ: /auth/token -> /token)
      // Auth router'ında prefix olmadığı için direkt /token adresine atıyoruz.
      const response = await api.post('/token', formData);
      
      const { access_token, refresh_token } = response.data;
      
      // 3. Kullanıcı detaylarını çek (Rol kontrolü için)
      // Token alındıktan sonra bu istek Bearer token ile gider
      const userResponse = await api.get('/users/me', {
          headers: { Authorization: `Bearer ${access_token}` }
      });
      const userData = userResponse.data;

      // 4. Admin kontrolü
      if (userData.role !== 'admin') {
          setError('Bu panele sadece Yöneticiler girebilir.');
          setLoading(false);
          return;
      }

      // 5. Giriş başarılı! Store'a kaydet ve yönlendir.
      login(access_token, refresh_token, userData);
      navigate('/'); 
      
    } catch (err: any) {
      console.error(err);
      // Hata detayını yakala
      const errorMessage = err.response?.data?.detail || 'Giriş başarısız. Sunucu hatası.';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container size={420} my={40}>
      <Title ta="center">Tasarımcı Bulutu Yönetim</Title>
      
      <Paper withBorder shadow="md" p={30} mt={30} radius="md" pos="relative">
        <LoadingOverlay visible={loading} zIndex={1000} overlayProps={{ radius: "sm", blur: 2 }} />
        
        <form onSubmit={handleLogin}>
          {error && (
            <Alert icon={<IconAlertCircle size="1rem" />} title="Hata" color="red" mb="md">
              {error}
            </Alert>
          )}
          
          <TextInput 
            label="Email Adresi" 
            placeholder="admin@proaec.com" 
            required 
            value={email}
            onChange={(e) => setEmail(e.currentTarget.value)}
          />
          <PasswordInput 
            label="Şifre" 
            placeholder="Şifreniz" 
            required 
            mt="md" 
            value={password}
            onChange={(e) => setPassword(e.currentTarget.value)}
          />
          
          <Button fullWidth mt="xl" type="submit">
            Yönetici Girişi
          </Button>
        </form>
      </Paper>
    </Container>
  );
}