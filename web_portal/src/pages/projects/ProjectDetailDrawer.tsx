import { Drawer, Text, Group, Badge, Stack, Divider, ThemeIcon, Paper, Avatar, Grid, Box, Skeleton } from '@mantine/core';
import { IconCalendar, IconCoin, IconUser, IconBriefcase, IconCheck, IconClock } from '@tabler/icons-react';
import dayjs from 'dayjs';

interface ProjectDetailProps {
  opened: boolean;
  onClose: () => void;
  project: any;
  loading: boolean;
}

export default function ProjectDetailDrawer({ opened, onClose, project, loading }: ProjectDetailProps) {
  
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'open': return 'green';
      case 'completed': return 'blue';
      case 'cancelled': return 'red';
      default: return 'gray';
    }
  };

  // --- YÜKLENİYOR DURUMU (SKELETON) ---
  const LoadingView = () => (
    <Stack gap="md">
        <Skeleton height={30} width="50%" radius="xl" />
        <Skeleton height={40} width="80%" />
        <Skeleton height={100} />
        <Grid>
            <Grid.Col span={6}><Skeleton height={80} /></Grid.Col>
            <Grid.Col span={6}><Skeleton height={80} /></Grid.Col>
        </Grid>
    </Stack>
  );

  return (
    <Drawer 
        opened={opened} 
        onClose={onClose} 
        title={<Text fw={700} size="lg">Proje Detayları</Text>} 
        position="right" 
        size="lg" // Daha geniş alan
        padding="xl"
    >
      {loading || !project ? (
        <LoadingView />
      ) : (
        <Stack gap="lg">
             
             {/* --- BAŞLIK VE DURUM --- */}
             <Group justify="space-between" align="flex-start">
                <Box style={{ flex: 1 }}>
                    <Badge size="lg" variant="light" color="blue" mb={5} leftSection={<IconBriefcase size={14}/>}>
                        {project.category}
                    </Badge>
                    <Text size="xl" fw={800} lh={1.2} style={{ fontSize: 24 }}>
                        {project.title}
                    </Text>
                </Box>
                <Badge 
                    color={getStatusColor(project.status)} 
                    size="lg" 
                    variant="filled"
                    leftSection={project.status === 'open' ? <IconCheck size={14}/> : <IconClock size={14}/>}
                >
                    {project.status.toUpperCase()}
                </Badge>
             </Group>

             <Text size="xs" c="dimmed">
                Oluşturulma: {dayjs(project.created_at).format('DD MMMM YYYY - HH:mm')}
             </Text>

             <Divider />
             
             {/* --- AÇIKLAMA --- */}
             <Box>
                <Text fw={600} size="sm" mb="xs" c="dimmed">PROJE AÇIKLAMASI</Text>
                <Paper withBorder p="md" bg="gray.0" radius="md">
                    <Text size="sm" style={{ lineHeight: 1.6, whiteSpace: 'pre-wrap' }}>
                        {project.description}
                    </Text>
                </Paper>
             </Box>

             {/* --- BİLGİ KARTLARI (GRID) --- */}
             <Grid>
                <Grid.Col span={6}>
                    <Paper withBorder p="md" radius="md">
                        <Group gap="xs" mb={5}>
                            <ThemeIcon variant="light" color="green"><IconCoin size={18}/></ThemeIcon>
                            <Text size="xs" c="dimmed" fw={700}>BÜTÇE ARALIĞI</Text>
                        </Group>
                        <Text fw={700} size="lg" c="green.8">
                            {project.budget_min?.toLocaleString()} - {project.budget_max?.toLocaleString()} ₺
                        </Text>
                    </Paper>
                </Grid.Col>
                <Grid.Col span={6}>
                    <Paper withBorder p="md" radius="md">
                        <Group gap="xs" mb={5}>
                            <ThemeIcon variant="light" color="red"><IconCalendar size={18}/></ThemeIcon>
                            <Text size="xs" c="dimmed" fw={700}>SON TARİH</Text>
                        </Group>
                        <Text fw={700} size="lg">
                            {project.deadline ? dayjs(project.deadline).format('DD.MM.YYYY') : 'Belirsiz'}
                        </Text>
                    </Paper>
                </Grid.Col>
             </Grid>

             {/* --- PROJE SAHİBİ --- */}
             <Box>
                <Text fw={600} size="sm" mb="xs" c="dimmed">PROJE SAHİBİ</Text>
                <Paper withBorder p="md" radius="md" shadow="xs">
                    <Group>
                        <Avatar size="md" radius="xl" color="blue" src={null} alt={project.owner?.name}>
                            {project.owner?.name?.charAt(0)}
                        </Avatar>
                        <div>
                            <Text size="sm" fw={700}>{project.owner?.name || 'Gizli Kullanıcı'}</Text>
                            <Text size="xs" c="dimmed">{project.owner?.email}</Text>
                        </div>
                        <Badge ml="auto" variant="outline" color="gray">İşveren</Badge>
                    </Group>
                </Paper>
             </Box>
             
             <Divider />

             {/* --- YETENEKLER --- */}
             <Box>
                 <Text fw={600} size="sm" mb="xs" c="dimmed">GEREKEN YETENEKLER</Text>
                 <Group gap="xs">
                     {project.required_skills?.length > 0 ? (
                         project.required_skills.map((s: string) => (
                             <Badge key={s} variant="outline" color="dark" size="lg">{s}</Badge>
                         ))
                     ) : (
                         <Text size="sm" c="dimmed" fs="italic">Özel yetenek belirtilmemiş.</Text>
                     )}
                 </Group>
             </Box>
        </Stack>
      )}
    </Drawer>
  );
}