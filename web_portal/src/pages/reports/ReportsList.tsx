import { useState } from 'react';
import { 
  Table, Group, Text, Badge, ActionIcon, Title, Paper, Button, Box, LoadingOverlay, Avatar, Tooltip, Tabs, Modal, Grid, Stack, Divider, ScrollArea, ThemeIcon
} from '@mantine/core';
import { 
  IconTrash, IconCheck, IconX, IconAlertTriangle, IconExternalLink, IconMessageReport, IconEye, IconFileDescription, IconUser
} from '@tabler/icons-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useDisclosure } from '@mantine/hooks';
import api from '../../services/api';
import { notifications } from '@mantine/notifications';
import dayjs from 'dayjs';

// Backend'den gelen veri yapısı
interface Report {
    id: string;
    reporter_name: string;
    showcase_title: string;
    showcase_id: string;
    showcase_image?: string;
    reason: string;
    description?: string;
    status: string;
    created_at: string;
}

export default function ReportsList() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<string | null>('pending');
  
  // Modal State
  const [opened, { open, close }] = useDisclosure(false);
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);

  // Raporları Çek
  const { data: reports, isLoading } = useQuery({
    queryKey: ['reports', activeTab],
    queryFn: async () => {
      const res = await api.get('/admin/reports', { params: { status: activeTab } });
      return res.data as Report[];
    }
  });

  // Rapor Durumu Güncelleme (Yoksay / Çözüldü)
  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      await api.patch(`/admin/reports/${id}/status`, null, { params: { status } });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['reports'] });
      notifications.show({ title: 'İşlem Tamam', message: 'Rapor durumu güncellendi', color: 'blue' });
      close(); // Modalı kapat
    },
  });

  // İçeriği Silme (Ve Raporu Çözüldü Yapma)
  const deleteContentMutation = useMutation({
    mutationFn: async ({ reportId, showcaseId }: { reportId: string; showcaseId: string }) => {
      // 1. Sadece içeriği silmemiz yeterli.
      // Cascade ayarı sayesinde rapor da veritabanından otomatik silinecek.
      await api.delete(`/admin/showcase/${showcaseId}`);
      
      // AŞAĞIDAKİ SATIRI SİLDİK ÇÜNKÜ RAPOR ARTIK YOK (404 HATASI VERİYORDU)
      // await api.patch(`/admin/reports/${reportId}/status`, null, { params: { status: 'resolved' } });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['reports'] });
      queryClient.invalidateQueries({ queryKey: ['showcase'] }); // Vitrin listesini de yenile
      notifications.show({ title: 'Temizlendi', message: 'İçerik ve ilgili şikayet silindi.', color: 'red' });
      close(); // Modalı kapat
    },
    onError: (error) => {
       // Hata olursa kullanıcıyı bilgilendir
       console.error(error);
       notifications.show({ title: 'Hata', message: 'Silme işlemi başarısız oldu.', color: 'red' });
    }
  });

  // Detayları Göster Butonu
  const handleViewDetails = (report: Report) => {
      setSelectedReport(report);
      open();
  };

  const rows = reports?.map((report) => (
    <Table.Tr key={report.id}>
      <Table.Td>
        <Group gap="sm">
            <Avatar src={report.showcase_image} radius="md" size="md" color="blue" />
            <div>
                <Text fw={600} size="sm" lineClamp={1}>{report.showcase_title}</Text>
                <Text size="xs" c="dimmed">{dayjs(report.created_at).format('DD.MM HH:mm')}</Text>
            </div>
        </Group>
      </Table.Td>

      <Table.Td>
        <Badge color="red" variant="light" leftSection={<IconAlertTriangle size={12}/>}>
            {report.reason}
        </Badge>
      </Table.Td>

      <Table.Td>
        <Group gap="xs">
            <IconMessageReport size={16} color="gray" />
            <Text size="sm">{report.reporter_name}</Text>
        </Group>
      </Table.Td>

      <Table.Td>
        <Group gap="xs">
            {/* --- TEK BUTON: İNCELE --- */}
            <Button 
                variant="light" 
                size="xs" 
                leftSection={<IconEye size={14}/>}
                onClick={() => handleViewDetails(report)}
            >
                İncele
            </Button>
        </Group>
      </Table.Td>
    </Table.Tr>
  ));

  return (
    <Box w="100%" p={{ base: 'md', md: 'xl' }}>
        <LoadingOverlay visible={isLoading} />
        
        <Title order={2} mb="xl">Şikayet Yönetimi</Title>

        <Paper withBorder radius="md" shadow="sm" p="md">
            <Tabs value={activeTab} onChange={setActiveTab} mb="md">
                <Tabs.List>
                    <Tabs.Tab value="pending" leftSection={<IconAlertTriangle size={16}/>} color="red">
                        Bekleyenler
                    </Tabs.Tab>
                    <Tabs.Tab value="resolved" leftSection={<IconCheck size={16}/>} color="green">
                        Çözülenler
                    </Tabs.Tab>
                    <Tabs.Tab value="ignored" leftSection={<IconX size={16}/>} color="gray">
                        Reddedilenler
                    </Tabs.Tab>
                </Tabs.List>
            </Tabs>

            <Table verticalSpacing="md" striped highlightOnHover>
                <Table.Thead>
                    <Table.Tr>
                        <Table.Th>Bildirilen İçerik</Table.Th>
                        <Table.Th>Sebep</Table.Th>
                        <Table.Th>Bildiren</Table.Th>
                        <Table.Th>İşlemler</Table.Th>
                    </Table.Tr>
                </Table.Thead>
                <Table.Tbody>
                    {rows}
                    {reports?.length === 0 && (
                        <Table.Tr>
                            <Table.Td colSpan={4} align="center" c="dimmed" py="xl">
                                Bu kategoride şikayet bulunmuyor.
                            </Table.Td>
                        </Table.Tr>
                    )}
                </Table.Tbody>
            </Table>
        </Paper>

        {/* --- DETAYLI İNCELEME MODALI --- */}
        <Modal 
            opened={opened} 
            onClose={close} 
            size="xl" 
            padding={0}
            radius="md"
            title={<Text fw={700}>Şikayet Detayı</Text>}
            centered
        >
            {selectedReport && (
                <Grid gutter={0}>
                    {/* SOL: Şikayet Edilen Görsel */}
                    <Grid.Col span={{ base: 12, md: 7 }} style={{ backgroundColor: '#000', minHeight: 400, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Avatar 
                            src={selectedReport.showcase_image} 
                            style={{ width: '100%', height: '100%', maxHeight: 500, objectFit: 'contain', borderRadius: 0 }}
                        />
                    </Grid.Col>

                    {/* SAĞ: Şikayet Detayları ve Aksiyonlar */}
                    <Grid.Col span={{ base: 12, md: 5 }}>
                        <Stack h="100%" justify="space-between" gap={0}>
                            <Box p="lg">
                                <Group mb="md">
                                    <ThemeIcon color="red" size="xl" radius="md" variant="light">
                                        <IconAlertTriangle />
                                    </ThemeIcon>
                                    <div>
                                        <Text size="xs" c="dimmed" fw={700}>ŞİKAYET SEBEBİ</Text>
                                        <Text fw={700} size="lg" lh={1.2}>{selectedReport.reason}</Text>
                                    </div>
                                </Group>

                                <Divider mb="md" />

                                <Box mb="lg">
                                    <Group gap="xs" mb={5}>
                                        <IconUser size={16} color="gray" />
                                        <Text size="sm" fw={600}>Bildiren Kullanıcı</Text>
                                    </Group>
                                    <Text size="sm">{selectedReport.reporter_name}</Text>
                                    <Text size="xs" c="dimmed">Tarih: {dayjs(selectedReport.created_at).format('DD.MM.YYYY HH:mm')}</Text>
                                </Box>

                                <Box>
                                    <Group gap="xs" mb={5}>
                                        <IconFileDescription size={16} color="gray" />
                                        <Text size="sm" fw={600}>Açıklama / Not</Text>
                                    </Group>
                                    <Paper withBorder p="sm" bg="gray.0" radius="md">
                                        <Text size="sm" style={{ fontStyle: 'italic' }}>
                                            "{selectedReport.description || 'Açıklama girilmemiş.'}"
                                        </Text>
                                    </Paper>
                                </Box>
                            </Box>

                            {/* BUTONLAR */}
                            {activeTab === 'pending' && (
                                <Box p="lg" bg="gray.0" style={{ borderTop: '1px solid #e5e7eb' }}>
                                    <Text size="xs" ta="center" c="dimmed" mb="sm">Bu şikayet hakkında ne yapmak istersiniz?</Text>
                                    <Group grow>
                                        <Button 
                                            color="gray" 
                                            variant="white"
                                            leftSection={<IconX size={16}/>}
                                            onClick={() => updateStatusMutation.mutate({ id: selectedReport.id, status: 'ignored' })}
                                        >
                                            Yoksay (Reddet)
                                        </Button>
                                        <Button 
                                            color="red" 
                                            leftSection={<IconTrash size={16}/>}
                                            onClick={() => {
                                                if(confirm('İçeriği silmek istediğine emin misin?'))
                                                    deleteContentMutation.mutate({ reportId: selectedReport.id, showcaseId: selectedReport.showcase_id })
                                            }}
                                        >
                                            İçeriği Sil (Onayla)
                                        </Button>
                                    </Group>
                                </Box>
                            )}
                        </Stack>
                    </Grid.Col>
                </Grid>
            )}
        </Modal>
    </Box>
  );
}