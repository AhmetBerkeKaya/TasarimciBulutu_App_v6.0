import { useState } from 'react';
import { 
  Table, Group, Text, Badge, ActionIcon, Menu, Title, Paper, Button, Box, LoadingOverlay, ThemeIcon
} from '@mantine/core';
import { 
  IconDots, IconTrash, IconPlus, IconPencil, IconCertificate
} from '@tabler/icons-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import api from '../../services/api';
import { notifications } from '@mantine/notifications';
import dayjs from 'dayjs';

interface SkillTest {
  id: string;
  title: string;
  description: string;
  software: string;
  created_at: string;
  questions?: any[]; // Soru sayısını göstermek için
}

export default function TestList() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  // Verileri Çek
  const { data: tests, isLoading } = useQuery({
    queryKey: ['skill-tests'],
    queryFn: async () => {
      const res = await api.get('/admin/skill-tests');
      return res.data as SkillTest[];
    }
  });

  // Silme İşlemi
  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      await api.delete(`/admin/skill-tests/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['skill-tests'] });
      notifications.show({ title: 'Başarılı', message: 'Test silindi', color: 'red' });
    }
  });

  const rows = tests?.map((test) => (
    <Table.Tr key={test.id}>
      <Table.Td>
        <Group gap="sm">
            <ThemeIcon variant="light" color="violet" size="lg" radius="md">
                <IconCertificate size={18} />
            </ThemeIcon>
            <div>
                <Text fw={600} size="sm">{test.title}</Text>
                <Text size="xs" c="dimmed" lineClamp={1}>{test.description}</Text>
            </div>
        </Group>
      </Table.Td>

      <Table.Td>
        <Badge variant="dot" size="md" color="blue">{test.software}</Badge>
      </Table.Td>

      <Table.Td>
        <Text size="sm" fw={500}>{test.questions ? test.questions.length : '-'} Soru</Text>
      </Table.Td>

      <Table.Td>
        <Text size="sm" c="dimmed">{dayjs(test.created_at).format('DD.MM.YYYY')}</Text>
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
              {/* Edit özelliği sonra eklenebilir */}
              <Menu.Item 
                leftSection={<IconPencil size={16} />}
                disabled
              >
                Düzenle (Yakında)
              </Menu.Item>
              <Menu.Item 
                leftSection={<IconTrash size={16} />}
                color="red"
                onClick={() => {
                    if(confirm('Bu testi ve bağlı soruları silmek istediğine emin misin?')) 
                        deleteMutation.mutate(test.id);
                }}
              >
                Testi Sil
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
                <Title order={2} fw={700}>Yetenek Testleri</Title>
                <Text c="dimmed" size="sm">Kullanıcı yetkinliklerini ölçmek için testler oluşturun.</Text>
            </div>
            <Button 
                leftSection={<IconPlus size={16}/>} 
                color="blue"
                onClick={() => navigate('/skill-tests/create')}
            >
                Yeni Test Oluştur
            </Button>
        </Group>

        <Paper withBorder radius="md" shadow="sm" p="md">
            {tests?.length === 0 ? (
                <Text c="dimmed" ta="center" py="xl">Henüz bir test oluşturulmamış.</Text>
            ) : (
                <Table verticalSpacing="md" striped highlightOnHover withTableBorder={false}>
                    <Table.Thead bg="gray.0">
                        <Table.Tr>
                            <Table.Th>Test Başlığı</Table.Th>
                            <Table.Th>Yazılım</Table.Th>
                            <Table.Th>Soru Sayısı</Table.Th>
                            <Table.Th>Oluşturulma</Table.Th>
                            <Table.Th />
                        </Table.Tr>
                    </Table.Thead>
                    <Table.Tbody>{rows}</Table.Tbody>
                </Table>
            )}
        </Paper>
    </Box>
  );
}