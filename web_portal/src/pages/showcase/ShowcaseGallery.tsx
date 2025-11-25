import { useState } from 'react';
import { 
  SimpleGrid, Card, Image, Text, Badge, Group, ActionIcon, 
  Menu, TextInput, Select, Title, LoadingOverlay, Button, Modal, Box, ThemeIcon, Avatar, Grid, Stack, Divider, ScrollArea
} from '@mantine/core';
import { 
  IconSearch, IconTrash, IconDots, IconExternalLink, IconPhotoOff, IconPhoto, IconActivity, IconCalendar, IconUser, IconFileDescription
} from '@tabler/icons-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useDisclosure } from '@mantine/hooks';
import api from '../../services/api';
import { notifications } from '@mantine/notifications';
import dayjs from 'dayjs';

// Backend Veri Tipi
interface ShowcasePost {
  id: string;
  title: string;
  description: string;
  category: string;
  thumbnail_url?: string;
  file_url: string;
  processing_status: 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED';
  created_at: string;
  model_format?: string; 
  owner?: {
    name: string;
    email: string;
  };
}

export default function ShowcaseGallery() {
  const queryClient = useQueryClient();
  
  // State'ler
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState<string | null>(null);
  
  const [opened, { open, close }] = useDisclosure(false);
  const [selectedPost, setSelectedPost] = useState<ShowcasePost | null>(null);

  // Verileri Çek
  const { data: posts, isLoading } = useQuery({
    queryKey: ['showcase', search, category],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (search) params.append('search', search);
      if (category) params.append('category', category);
      
      const res = await api.get('/admin/showcase', { params });
      return res.data as ShowcasePost[];
    },
  });

  const totalPosts = posts?.length || 0;
  const processingPosts = posts?.filter(p => p.processing_status === 'PROCESSING').length || 0;

  // Silme İşlemi
  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      await api.delete(`/admin/showcase/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['showcase'] });
      notifications.show({ title: 'Başarılı', message: 'İçerik yayından kaldırıldı', color: 'red' });
      close(); 
    },
  });

  const handleCardClick = (post: ShowcasePost) => {
    setSelectedPost(post);
    open();
  };

  const getStatusColor = (status: string) => {
      switch(status) {
          case 'COMPLETED': return 'green';
          case 'PROCESSING': return 'blue';
          case 'FAILED': return 'red';
          default: return 'yellow';
      }
  };

  return (
    <Box w="100%" p={{ base: 'md', md: 'xl' }}>
        <LoadingOverlay visible={isLoading} />
        
        <Group justify="space-between" mb="xl">
            <div>
                <Title order={2} fw={700}>Vitrin Yönetimi</Title>
                <Text c="dimmed" size="sm">Kullanıcıların paylaştığı portfolyo ve görselleri denetleyin.</Text>
            </div>
            <Group>
                <Badge size="lg" variant="light" color="gray" leftSection={<IconPhoto size={14}/>}>
                    Toplam: {totalPosts}
                </Badge>
                {processingPosts > 0 && (
                    <Badge size="lg" variant="light" color="blue" leftSection={<IconActivity size={14}/>}>
                        İşleniyor: {processingPosts}
                    </Badge>
                )}
            </Group>
        </Group>

        <Box mb="xl" style={{ backgroundColor: 'white', padding: '16px', borderRadius: '8px', border: '1px solid #e5e7eb' }}>
            <Group justify="space-between">
                <TextInput 
                    placeholder="Başlık veya açıklama ara..." 
                    leftSection={<IconSearch size={16} />} 
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    w={300}
                />
                <Select 
                    placeholder="Kategori"
                    data={['Mimari', 'Makine', 'Endüstriyel Tasarım', '3D Baskı', 'Yazılım']}
                    clearable
                    value={category}
                    onChange={setCategory}
                    w={200}
                />
            </Group>
        </Box>

        {/* --- GALERİ GRID --- */}
        {posts?.length === 0 ? (
           <Box p="xl" style={{ textAlign: 'center', backgroundColor: '#f8fafc', borderRadius: '8px' }}>
               <ThemeIcon size={60} radius="xl" color="gray" variant="light" mb="md">
                   <IconPhotoOff size={30} />
               </ThemeIcon>
               <Text c="dimmed" fw={500}>Görüntülenecek içerik bulunamadı.</Text>
           </Box>
        ) : (
          <SimpleGrid cols={{ base: 1, sm: 2, lg: 4, xl: 5 }} spacing="lg">
            {posts?.map((post) => (
              <Card 
                key={post.id} 
                shadow="sm" 
                padding={0} 
                radius="md" 
                withBorder 
                style={{ cursor: 'pointer', transition: 'transform 0.2s' }}
                onClick={() => handleCardClick(post)}
              >
                <Card.Section>
                  <div style={{ position: 'relative', height: 180, backgroundColor: '#f1f3f5' }}>
                    {post.file_url ? (
                        <Image
                            src={post.thumbnail_url || post.file_url}
                            height={180}
                            fit="cover"
                            alt={post.title}
                            fallbackSrc="https://placehold.co/600x400?text=Resim+Yok"
                        />
                    ) : (
                        <Group justify="center" align="center" h="100%">
                            <IconPhotoOff size={40} color="gray" />
                        </Group>
                    )}
                    
                    <div style={{ position: 'absolute', top: 10, right: 10 }}>
                        <Badge color={getStatusColor(post.processing_status)} variant="filled" size="xs">
                            {post.processing_status}
                        </Badge>
                    </div>
                  </div>
                </Card.Section>

                <Box p="md">
                    <Text fw={600} size="sm" lineClamp={1} mb={5}>{post.title}</Text>
                    <Group justify="space-between" align="center">
                        <Badge size="xs" variant="outline" color="gray">{post.category}</Badge>
                        <Text size="xs" c="dimmed">{dayjs(post.created_at).format('DD.MM.YY')}</Text>
                    </Group>
                </Box>
              </Card>
            ))}
          </SimpleGrid>
        )}

        {/* --- DETAYLI MODAL --- */}
        <Modal 
            opened={opened} 
            onClose={close} 
            size="xl"
            padding={0}
            radius="md"
            centered
            withCloseButton={false}
        >
            {selectedPost && (
                <Grid gutter={0}>
                    {/* SOL TARAF: RESİM */}
                    <Grid.Col span={{ base: 12, md: 7 }} style={{ backgroundColor: '#000', minHeight: 400, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {/* --- DÜZELTME BURADA: src kısmını thumbnail öncelikli yaptık --- */}
                        <Image 
                            src={selectedPost.thumbnail_url || selectedPost.file_url} 
                            fit="contain"
                            style={{ maxHeight: 500, width: '100%' }}
                            fallbackSrc="https://placehold.co/600x400?text=Önizleme+Yok"
                        />
                    </Grid.Col>

                    {/* SAĞ TARAF: BİLGİLER */}
                    <Grid.Col span={{ base: 12, md: 5 }}>
                        <Stack h="100%" justify="space-between" gap={0}>
                            <Box p="lg">
                                <Group justify="space-between" align="start" mb="md">
                                    <Box style={{ flex: 1 }}>
                                        <Badge color={getStatusColor(selectedPost.processing_status)} mb={5}>
                                            {selectedPost.processing_status}
                                        </Badge>
                                        <Title order={4} style={{ lineHeight: 1.3 }}>{selectedPost.title}</Title>
                                        <Text size="sm" c="dimmed">{selectedPost.category}</Text>
                                    </Box>
                                    
                                    <Menu position="bottom-end" shadow="md">
                                        <Menu.Target>
                                            <ActionIcon variant="subtle" color="gray"><IconDots /></ActionIcon>
                                        </Menu.Target>
                                        <Menu.Dropdown>
                                            <Menu.Item 
                                                color="red" 
                                                leftSection={<IconTrash size={14}/>}
                                                onClick={() => {
                                                    if(confirm('Silmek istediğine emin misin?')) 
                                                        deleteMutation.mutate(selectedPost.id);
                                                }}
                                            >
                                                İçeriği Sil
                                            </Menu.Item>
                                        </Menu.Dropdown>
                                    </Menu>
                                </Group>

                                <Divider mb="md" />

                                <ScrollArea h={200} type="auto" offsetScrollbars>
                                    <Group mb="xs" gap="xs">
                                        <IconFileDescription size={16} color="gray" />
                                        <Text fw={600} size="sm">Açıklama</Text>
                                    </Group>
                                    <Text size="sm" c="gray.7" style={{ lineHeight: 1.6 }}>
                                        {selectedPost.description || 'Kullanıcı açıklama girmemiş.'}
                                    </Text>
                                </ScrollArea>
                            </Box>

                            {/* ALT BİLGİ */}
                            <Box p="lg" bg="gray.0" style={{ borderTop: '1px solid #e5e7eb' }}>
                                <Stack gap="sm">
                                    <Group>
                                        <Avatar color="blue" radius="xl">{selectedPost.owner?.name?.charAt(0)}</Avatar>
                                        <div style={{ flex: 1 }}>
                                            <Text size="sm" fw={600}>{selectedPost.owner?.name || 'Bilinmiyor'}</Text>
                                            <Text size="xs" c="dimmed">{selectedPost.owner?.email}</Text>
                                        </div>
                                    </Group>
                                    
                                    <Group gap="xs">
                                        <IconCalendar size={14} color="gray" />
                                        <Text size="xs" c="dimmed">
                                            Yüklenme Tarihi: {dayjs(selectedPost.created_at).format('DD MMMM YYYY - HH:mm')}
                                        </Text>
                                    </Group>

                                    <Group mt="sm" grow>
                                        <Button variant="default" onClick={close}>Kapat</Button>
                                        <Button 
                                            component="a" 
                                            href={selectedPost.file_url} 
                                            target="_blank" 
                                            leftSection={<IconExternalLink size={16} />}
                                        >
                                            Dosyayı Aç
                                        </Button>
                                    </Group>
                                </Stack>
                            </Box>
                        </Stack>
                    </Grid.Col>
                </Grid>
            )}
        </Modal>
    </Box>
  );
}