import { 
  SimpleGrid, Paper, Text, Group, Title, ThemeIcon, Grid, Stack, Box, Center, Table, Avatar, Badge, Skeleton
} from '@mantine/core';
import { 
  IconUsers, IconCurrencyDollar, IconShoppingCart, IconActivity, 
  IconTrendingUp, IconTrendingDown, IconArrowUp, IconArrowDown
} from '@tabler/icons-react';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area, PieChart, Pie, Cell
} from 'recharts';
import { useQuery } from '@tanstack/react-query';
import api from '../../services/api';

export default function DashboardHome() {
  
  // 1. GERÇEK VERİYİ ÇEK
  const { data, isLoading } = useQuery({
     queryKey: ['admin-stats-real'],
     queryFn: async () => {
       const res = await api.get('/admin/stats');
       return res.data;
     }
  });

  // 2. KART VERİLERİ
  const statsCards = [
    { 
        title: 'Toplam Kullanıcı', 
        value: data?.cards.total_users?.toLocaleString() || '0', 
        change: `${data?.cards.user_growth > 0 ? '+' : ''}${data?.cards.user_growth}%`, // Gerçek veri
        trend: data?.cards.user_growth >= 0 ? 'up' : 'down', // Ok yönü
        bg: 'orange', 
        icon: IconUsers 
    },
    { 
        title: 'Toplam Hacim', 
        value: `₺${data?.cards.total_revenue?.toLocaleString() || '0'}`, 
        change: `${data?.cards.revenue_growth > 0 ? '+' : ''}${data?.cards.revenue_growth}%`, // Gerçek veri
        trend: data?.cards.revenue_growth >= 0 ? 'up' : 'down', 
        bg: 'cyan', 
        icon: IconCurrencyDollar 
    },
    { 
        title: 'Aktif Projeler', 
        value: data?.cards.active_projects || '0', 
        change: `${data?.cards.project_growth > 0 ? '+' : ''}${data?.cards.project_growth}%`, // Gerçek veri
        trend: data?.cards.project_growth >= 0 ? 'up' : 'down', 
        bg: 'green', 
        icon: IconShoppingCart 
    },
    { 
        title: 'Vitrin İçerikleri', 
        value: data?.cards.total_showcase || '0', 
        change: `${data?.cards.showcase_growth > 0 ? '+' : ''}${data?.cards.showcase_growth}%`, // Gerçek veri
        trend: data?.cards.showcase_growth >= 0 ? 'up' : 'down', 
        bg: 'indigo', 
        icon: IconActivity 
    },
  ];

  const getStatusColor = (status: string) => {
    if (status === 'open') return 'green';
    if (status === 'completed') return 'blue';
    if (status === 'cancelled') return 'red';
    return 'orange';
  };

  // Backend'den gelen 'indigo.6' gibi renkleri CSS değişkenine çevirir
  const mapColorToVar = (colorName: string) => {
      const [color, shade] = colorName.split('.');
      return `var(--mantine-color-${color}-${shade})`;
  };

  if (isLoading) {
      return (
          <Box p="md" w="100%">
              <SimpleGrid cols={4} mb="xl">
                  {[1,2,3,4].map(i => <Skeleton key={i} height={120} radius="md" />)}
              </SimpleGrid>
              <Skeleton height={400} radius="md" />
          </Box>
      )
  }

  return (
    <Box p={{ base: 'md', md: 'xl' }} w="100%" style={{ overflowX: 'hidden' }}>
      
      {/* --- 1. İSTATİSTİK KARTLARI --- */}
      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="lg" mb="xl">
        {statsCards.map((stat, index) => (
          <Paper key={index} p="lg" radius="lg" shadow="sm" withBorder style={{ borderColor: '#f1f5f9' }}>
            <Group justify="space-between" align="flex-start" mb="sm">
              <div>
                <Text size="xs" c="dimmed" fw={600} tt="uppercase" mb={4}>{stat.title}</Text>
                <Text size="xl" fw={800} style={{ fontSize: 28 }}>{stat.value}</Text>
              </div>
              <ThemeIcon size={50} radius="md" color={stat.bg} variant="filled">
                <stat.icon size={24} />
              </ThemeIcon>
            </Group>
            <Group gap={6}>
              {stat.trend === 'up' ? 
                <IconTrendingUp size={16} color="var(--mantine-color-teal-6)" /> : 
                <IconTrendingDown size={16} color="var(--mantine-color-red-6)" />
              }
              <Text size="sm" c={stat.trend === 'up' ? 'teal' : 'red'} fw={600}>
                {stat.change}
              </Text>
              <Text size="sm" c="dimmed">geçen aya göre</Text>
            </Group>
          </Paper>
        ))}
      </SimpleGrid>

      <Grid gutter="lg">
        {/* --- 2. AYLIK GELİR GRAFİĞİ (SOL BÜYÜK) --- */}
        <Grid.Col span={{ base: 12, lg: 8 }}>
          <Paper p="xl" radius="lg" shadow="sm" withBorder style={{ height: '100%', minHeight: 400 }}>
            <Group justify="space-between" mb="xl">
              <Title order={3} fw={700} c="gray.8">Finansal Genel Bakış</Title>
              <Group>
                <Group gap={6}><Box w={10} h={10} bg="blue.5" style={{borderRadius:'50%'}}/><Text size="sm" c="dimmed">Hasılat</Text></Group>
                <Group gap={6}><Box w={10} h={10} bg="cyan.5" style={{borderRadius:'50%'}}/><Text size="sm" c="dimmed">Tahmini Gider</Text></Group>
              </Group>
            </Group>
            
            <div style={{ width: '100%', height: 300, minWidth: 0 }}>
              <ResponsiveContainer width="99%" height="100%">
                <BarChart data={data?.charts.revenue || []}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                  <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{fill: '#94a3b8'}} dy={10} />
                  <YAxis axisLine={false} tickLine={false} tick={{fill: '#94a3b8'}} />
                  <Tooltip 
                    contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }} 
                    cursor={{fill: '#f1f5f9'}}
                  />
                  <Bar dataKey="Revenue" name="Hasılat" fill="#3b82f6" radius={[4, 4, 0, 0]} barSize={20} />
                  <Bar dataKey="Sales" name="Gider" fill="#06b6d4" radius={[4, 4, 0, 0]} barSize={20} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </Paper>
        </Grid.Col>

        {/* --- 3. SON PROJELER (SAĞ LİSTE) --- */}
        <Grid.Col span={{ base: 12, lg: 4 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder style={{ height: '100%' }}>
              <Group justify="space-between" mb="md">
                <Title order={4}>Son Projeler</Title>
                <Badge variant="light" color="gray">Yeni</Badge>
              </Group>
              
              <Table verticalSpacing="sm">
                <Table.Tbody>
                  {data?.recent_projects?.map((project: any) => (
                    <Table.Tr key={project.id}>
                      <Table.Td>
                        <Group gap="sm">
                          <Avatar size={32} radius="xl" color="blue">{project.initials}</Avatar>
                          <div>
                              <Text size="sm" fw={600} lineClamp={1}>{project.owner}</Text>
                              <Text size="xs" c="dimmed">{project.category}</Text>
                          </div>
                        </Group>
                      </Table.Td>
                      <Table.Td align="right">
                        <Text size="sm" fw={600}>₺{project.budget.toLocaleString()}</Text>
                        <Badge size="xs" color={getStatusColor(project.status)} variant="light">
                            {project.status}
                        </Badge>
                      </Table.Td>
                    </Table.Tr>
                  ))}
                </Table.Tbody>
              </Table>
            </Paper>
        </Grid.Col>

        {/* --- 4. KATEGORİ DAĞILIMI (ALT PASTA GRAFİK - PIECHART) --- */}
        <Grid.Col span={{ base: 12, md: 6 }}>
          <Paper p="xl" radius="lg" shadow="sm" withBorder style={{ height: '100%' }}>
            <Title order={4} mb="xl">Kategori Dağılımı</Title>
            <div style={{ width: '100%', height: 250, minWidth: 0 }}>
               <ResponsiveContainer width="99%" height="100%">
                 <PieChart>
                    <Pie
                        data={data?.charts.categories || []}
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={5}
                        dataKey="value"
                    >
                        {data?.charts.categories.map((entry: any, index: number) => (
                            <Cell key={`cell-${index}`} fill={mapColorToVar(entry.color)} />
                        ))}
                    </Pie>
                    <Tooltip />
                 </PieChart>
               </ResponsiveContainer>
            </div>
            
            <Group justify="center" mt="md" gap="xl">
                {data?.charts.categories?.map((cat: any) => (
                    <Group key={cat.name} gap={5}>
                        <Box w={8} h={8} bg={cat.color} style={{borderRadius:'50%'}} />
                        <Text size="xs" c="dimmed">{cat.name} ({cat.value})</Text>
                    </Group>
                ))}
            </Group>
          </Paper>
        </Grid.Col>

        {/* --- 5. SATIŞ ANALİTİĞİ (ALT AREA) --- */}
        <Grid.Col span={{ base: 12, md: 6 }}>
          <Paper p="xl" radius="lg" shadow="sm" withBorder style={{ height: '100%' }}>
            <Title order={4} mb="lg">Büyüme Trendi</Title>
            <div style={{ width: '100%', height: 250, minWidth: 0 }}>
              <ResponsiveContainer width="99%" height="100%">
                <AreaChart data={data?.charts.revenue || []}>
                  <defs>
                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{fill: '#94a3b8'}} dy={10}/>
                  <Tooltip contentStyle={{ borderRadius: 8, border: 'none' }} />
                  <Area type="monotone" dataKey="Revenue" stroke="#3b82f6" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </Paper>
        </Grid.Col>
      </Grid>
    </Box>
  );
}