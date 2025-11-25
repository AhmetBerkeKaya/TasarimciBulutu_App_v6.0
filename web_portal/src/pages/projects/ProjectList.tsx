import { useState } from 'react';
import { 
  Table, ScrollArea, Group, Text, Badge, ActionIcon, 
  Menu, TextInput, Select, Title, Paper, LoadingOverlay, Box, SimpleGrid, ThemeIcon, Button, Avatar, RingProgress
} from '@mantine/core';
import { 
  IconDots, IconSearch, IconTrash, IconCheck, IconX, IconEye, IconBriefcase, IconCoin, IconFilter
} from '@tabler/icons-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../../services/api';
import { notifications } from '@mantine/notifications';
import dayjs from 'dayjs';
import ProjectDetailDrawer from './ProjectDetailDrawer';

// Veri Tipi
interface Project {
  id: string;
  title: string;
  category: string;
  budget_min: number;
  budget_max: number;
  status: string;
  created_at: string;
  owner?: {
    name: string;
    email: string;
  };
}

export default function ProjectList() {
  const queryClient = useQueryClient();
  
  // State'ler
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string | null>(null);
  const [categoryFilter, setCategoryFilter] = useState<string | null>(null);
  
  const [selectedProjectId, setSelectedProjectId] = useState<string | null>(null);
  const [drawerOpened, setDrawerOpened] = useState(false);

  // Verileri Çek
  const { data: projects, isLoading } = useQuery({
    queryKey: ['projects', search, statusFilter, categoryFilter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (search) params.append('search', search);
      if (statusFilter) params.append('status', statusFilter);
      if (categoryFilter) params.append('category', categoryFilter); // Backend destekliyorsa
      
      const res = await api.get('/admin/projects', { params });
      return res.data as Project[];
    },
  });

  // Detay Çekme
  const { data: projectDetail, isLoading: isDetailLoading } = useQuery({
      queryKey: ['project-detail', selectedProjectId],
      queryFn: () => api.get(`/admin/projects/${selectedProjectId}`).then(res => res.data),
      enabled: !!selectedProjectId,
  });

  // İstatistik Hesaplama (Frontend tarafında)
  const totalProjects = projects?.length || 0;
  const activeProjects = projects?.filter(p => p.status === 'open').length || 0;
  // Ortalama bütçe hacmi (Min + Max / 2)
  const totalVolume = projects?.reduce((acc, curr) => acc + ((curr.budget_min + curr.budget_max) / 2), 0) || 0;

  // Durum Güncelleme
  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      await api.patch(`/admin/projects/${id}/status`, null, { 
        params: { status } 
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
      notifications.show({ title: 'Başarılı', message: 'Proje durumu güncellendi', color: 'blue' });
    },
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'open': return 'green';
      case 'completed': return 'blue';
      case 'cancelled': return 'red';
      case 'in_progress': return 'orange';
      default: return 'gray';
    }
  };

  const rows = projects?.map((project) => (
    <Table.Tr key={project.id}>
      <Table.Td>
        <Group gap="sm">
            <ThemeIcon variant="light" color="blue" size="lg" radius="md">
                <IconBriefcase size={18} />
            </ThemeIcon>
            <div>
                <Text fw={600} size="sm" lineClamp={1}>{project.title}</Text>
                <Text size="xs" c="dimmed">{project.category}</Text>
            </div>
        </Group>
      </Table.Td>

      <Table.Td>
        <Group gap="xs">
            <Avatar size="sm" radius="xl" color="cyan">{project.owner?.name?.charAt(0)}</Avatar>
            <div>
                <Text size="sm" fw={500}>{project.owner?.name || 'Bilinmiyor'}</Text>
                <Text size="xs" c="dimmed">{dayjs(project.created_at).format('DD.MM.YYYY')}</Text>
            </div>
        </Group>
      </Table.Td>

      <Table.Td>
        <Badge variant="outline" color="gray" size="lg" style={{ textTransform: 'none' }}>
            {project.budget_min.toLocaleString()} - {project.budget_max.toLocaleString()} ₺
        </Badge>
      </Table.Td>

      <Table.Td>
        <Badge color={getStatusColor(project.status)} variant="dot" size="md">
          {project.status.toUpperCase()}
        </Badge>
      </Table.Td>

      <Table.Td>
        <Group gap={0} justify="flex-end">
          <Menu transitionProps={{ transition: 'pop' }} withArrow position="bottom-end" shadow="md">
            <Menu.Target>
              <ActionIcon variant="subtle" color="gray">
                <IconDots style={{ width: 16, height: 16 }} stroke={1.5} />
              </ActionIcon>
            </Menu.Target>
            <Menu.Dropdown>
              <Menu.Label>İşlemler</Menu.Label>
              <Menu.Item 
                leftSection={<IconEye size={16} />}
                onClick={() => { setSelectedProjectId(project.id); setDrawerOpened(true); }}
              >
                Detayları Gör
              </Menu.Item>
              
              <Menu.Divider />
              
              <Menu.Item 
                leftSection={<IconCheck size={16} />}
                color="green"
                onClick={() => updateStatusMutation.mutate({ id: project.id, status: 'open' })}
              >
                Yayına Al (Open)
              </Menu.Item>
              
              <Menu.Item 
                leftSection={<IconX size={16} />}
                color="red"
                onClick={() => updateStatusMutation.mutate({ id: project.id, status: 'cancelled' })}
              >
                İptal Et / Kapat
              </Menu.Item>
            </Menu.Dropdown>
          </Menu>
        </Group>
      </Table.Td>
    </Table.Tr>
  ));

  return (
    <Box w="100%" p={{ base: 'md', md: 'xl' }}>
        <LoadingOverlay visible={isLoading} />
        
        <Group justify="space-between" mb="xl">
            <div>
                <Title order={2} fw={700}>Proje Denetimi</Title>
                <Text c="dimmed" size="sm">Platformdaki tüm iş ilanlarını yönetin.</Text>
            </div>
            <Button leftSection={<IconFilter size={16}/>} variant="light" color="gray">
                Gelişmiş Filtrele
            </Button>
        </Group>

        {/* --- ÖZET KARTLAR --- */}
        <SimpleGrid cols={{ base: 1, sm: 3 }} mb="xl">
            <Paper withBorder p="md" radius="md" shadow="sm">
                <Group justify="space-between">
                    <Text size="xs" c="dimmed" fw={700} tt="uppercase">Toplam İlan</Text>
                    <ThemeIcon color="violet" variant="light" radius="xl"><IconBriefcase size={18}/></ThemeIcon>
                </Group>
                <Text fw={700} size="xl" mt="sm">{totalProjects}</Text>
            </Paper>
            <Paper withBorder p="md" radius="md" shadow="sm">
                <Group justify="space-between">
                    <Text size="xs" c="dimmed" fw={700} tt="uppercase">Aktif Projeler</Text>
                    <RingProgress 
                        size={30} thickness={4} 
                        sections={[{ value: (activeProjects/totalProjects)*100, color: 'teal' }]} 
                    />
                </Group>
                <Text fw={700} size="xl" mt="sm">{activeProjects}</Text>
            </Paper>
            <Paper withBorder p="md" radius="md" shadow="sm">
                <Group justify="space-between">
                    <Text size="xs" c="dimmed" fw={700} tt="uppercase">Toplam Bütçe Hacmi</Text>
                    <ThemeIcon color="green" variant="light" radius="xl"><IconCoin size={18}/></ThemeIcon>
                </Group>
                <Text fw={700} size="xl" mt="sm">₺{totalVolume.toLocaleString()}</Text>
            </Paper>
        </SimpleGrid>

        {/* --- FİLTRE VE TABLO --- */}
        <Paper withBorder radius="md" shadow="sm" p="md">
            <Group justify="space-between" mb="md">
                <TextInput 
                    placeholder="Başlık veya açıklama ara..." 
                    leftSection={<IconSearch size={16} />} 
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    w={300}
                />
                <Group>
                    <Select 
                        placeholder="Kategori"
                        data={['Mimari', 'Yazılım', 'Makine', 'Elektrik', 'İnşaat']}
                        clearable
                        value={categoryFilter}
                        onChange={setCategoryFilter}
                        w={150}
                    />
                    <Select 
                        placeholder="Durum"
                        data={[
                            { value: 'open', label: 'Açık' },
                            { value: 'in_progress', label: 'Sürüyor' },
                            { value: 'completed', label: 'Tamamlandı' },
                            { value: 'cancelled', label: 'İptal' }
                        ]}
                        clearable
                        value={statusFilter}
                        onChange={setStatusFilter}
                        w={150}
                    />
                </Group>
            </Group>

            <ScrollArea>
                <Table verticalSpacing="md" striped highlightOnHover withTableBorder={false}>
                    <Table.Thead bg="gray.0">
                        <Table.Tr>
                            <Table.Th>Proje Başlığı</Table.Th>
                            <Table.Th>Oluşturan</Table.Th>
                            <Table.Th>Bütçe Aralığı</Table.Th>
                            <Table.Th>Durum</Table.Th>
                            <Table.Th />
                        </Table.Tr>
                    </Table.Thead>
                    <Table.Tbody>{rows}</Table.Tbody>
                </Table>
            </ScrollArea>
            
            {projects?.length === 0 && (
                <Text c="dimmed" ta="center" py="xl">Kriterlere uygun proje bulunamadı.</Text>
            )}
        </Paper>

        {/* --- DETAY DRAWER --- */}
        <ProjectDetailDrawer 
            opened={drawerOpened}
            onClose={() => { setDrawerOpened(false); setSelectedProjectId(null); }}
            project={projectDetail}
            loading={isDetailLoading}
        />
    </Box>
  );
}