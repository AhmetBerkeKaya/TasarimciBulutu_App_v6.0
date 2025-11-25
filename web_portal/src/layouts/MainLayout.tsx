import { useState } from 'react';
import { AppShell, Burger, Group, NavLink, Text, Avatar, Menu, UnstyledButton, Box, ScrollArea, ThemeIcon } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { 
  IconLayoutDashboard, IconUsers, IconBriefcase, IconPhoto, 
  IconCertificate, IconSettings, IconLogout, IconActivity, IconAlertTriangle
} from '@tabler/icons-react';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';

const data = [
  { link: '/', label: 'Dashboard', icon: IconLayoutDashboard },
  { link: '/users', label: 'Kullanıcılar', icon: IconUsers },
  { link: '/projects', label: 'Projeler', icon: IconBriefcase },
  { link: '/showcase', label: 'Vitrin', icon: IconPhoto },
  { link: '/skill-tests', label: 'Testler', icon: IconCertificate },
  { link: '/reports', label: 'Şikayetler', icon: IconAlertTriangle }, // <--- YENİ
  { link: '/settings', label: 'Ayarlar', icon: IconSettings },
];

export default function MainLayout() {
  const [opened, { toggle }] = useDisclosure();
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useAuthStore();

  const items = data.map((item) => (
    <NavLink
      key={item.label}
      active={location.pathname === item.link}
      label={<Text fw={500} size="sm">{item.label}</Text>}
      leftSection={<item.icon size="1.2rem" stroke={1.5} />}
      onClick={() => { navigate(item.link); if (opened) toggle(); }}
      variant="filled"
      color="cyan"
      styles={{
        root: { 
            color: location.pathname === item.link ? 'white' : '#94a3b8',
            borderRadius: '8px',
            marginBottom: '4px',
            padding: '10px 12px',
            '&:hover': { backgroundColor: 'rgba(255, 255, 255, 0.1)', color: 'white' }
        },
      }}
    />
  ));

  return (
    <AppShell
      header={{ height: 70 }}
      navbar={{ width: 260, breakpoint: 'sm', collapsed: { mobile: !opened } }}
      padding="0" 
      layout="alt"
      withBorder={false} // Doğru border kullanımı
    >
      <AppShell.Header withBorder={false} style={{ backgroundColor: 'transparent' }}>
        <Group h="100%" px="md" justify="space-between" style={{ backgroundColor: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
          <Group>
            <Burger opened={opened} onClick={toggle} hiddenFrom="sm" size="sm" />
            <div style={{ display: 'flex', flexDirection: 'column' }}>
                <Text size="sm" fw={700} c="gray.8" visibleFrom="sm" style={{ letterSpacing: '0.5px' }}>TASARIMCI BULUTU</Text>
                <Text size="xs" c="dimmed" visibleFrom="sm">Yönetim Paneli</Text>
            </div>
          </Group>

          <Group>
             <Menu shadow="md" width={200} trigger="hover">
                <Menu.Target>
                  <UnstyledButton>
                    <Group gap={8} style={{ cursor: 'pointer' }}>
                      <div style={{ textAlign: 'right' }}>
                          <Text size="sm" fw={600} c="gray.8">{user?.name || 'Admin'}</Text>
                          <Text size="xs" c="dimmed">Yönetici</Text>
                      </div>
                      <Avatar radius="xl" size="md" color="cyan">{user?.name?.charAt(0)}</Avatar>
                    </Group>
                  </UnstyledButton>
                </Menu.Target>
                <Menu.Dropdown>
                  <Menu.Item color="red" leftSection={<IconLogout size={14} />} onClick={() => { logout(); navigate('/login'); }}>
                    Çıkış Yap
                  </Menu.Item>
                </Menu.Dropdown>
             </Menu>
          </Group>
        </Group>
      </AppShell.Header>

      <AppShell.Navbar p="md" style={{ backgroundColor: '#1e1b4b', color: 'white', borderRight: 'none' }}>
        <Group mb={40} mt={10} px="xs">
            <ThemeIcon variant="gradient" gradient={{ from: 'cyan', to: 'indigo' }} size="lg" radius="md">
               <IconActivity size={22} />
            </ThemeIcon>
            <Text size="xl" fw={800} c="white" style={{ letterSpacing: '0.5px' }}>
                PROAEC
            </Text>
        </Group>

        <AppShell.Section grow component={ScrollArea}>
            <Box>{items}</Box>
        </AppShell.Section>
      </AppShell.Navbar>

      {/* --- DÜZELTME BURADA: minWidth: 0 ve flex özellikleri --- */}
      <AppShell.Main 
        style={{ 
            backgroundColor: '#f8fafc', 
            minHeight: '100vh', 
            display: 'flex', 
            flexDirection: 'column',
            width: '100%',
            minWidth: 0 // <--- Recharts hatasını çözen kilit nokta
        }}
      >
        {/* İçeriği sarmalayan bir Box ile full genişlik garanti edilir */}
        <Box style={{ flex: 1, width: '100%' }}>
            <Outlet />
        </Box>
      </AppShell.Main>
    </AppShell>
  );
}