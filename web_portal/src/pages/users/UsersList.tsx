import { useState } from 'react';
import {
    Table, ScrollArea, Avatar, Group, Text, Badge, ActionIcon,
    Menu, TextInput, Select, Title, Paper, LoadingOverlay, Box, SimpleGrid, ThemeIcon, Button
} from '@mantine/core';
import {
    IconDots, IconSearch, IconTrash, IconCheck, IconBan, IconEye, IconUserCheck, IconUserX, IconUsers, IconDownload
} from '@tabler/icons-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../../services/api';
import { notifications } from '@mantine/notifications';
import UserDetailDrawer from './UserDetailDrawer'; // Drawer bileşeninin aynı klasörde olduğundan emin ol

// Backend Veri Tipi
interface User {
    id: string;
    name: string;
    email: string;
    role: 'admin' | 'freelancer' | 'client';
    is_active: boolean;
    is_verified: boolean;
    profile_picture_url?: string;
    created_at: string;
}

export default function UsersList() {
    const queryClient = useQueryClient();
    
    // State'ler
    const [search, setSearch] = useState('');
    const [roleFilter, setRoleFilter] = useState<string | null>(null);
    const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
    const [drawerOpened, setDrawerOpened] = useState(false);

    // Veri Çekme
    const { data: users, isLoading } = useQuery({
        queryKey: ['users', search, roleFilter],
        queryFn: async () => {
            const params = new URLSearchParams();
            if (search) params.append('search', search);
            if (roleFilter) params.append('role', roleFilter);
            const res = await api.get('/admin/users', { params });
            return res.data as User[];
        },
    });

    // İstatistikler (Frontend tarafında basit hesaplama)
    const totalUsers = users?.length || 0;
    const activeUsers = users?.filter(u => u.is_active).length || 0;
    const bannedUsers = users?.filter(u => !u.is_active).length || 0;

    // Detay Çekme
    const { data: userDetail, isLoading: isDetailLoading } = useQuery({
        queryKey: ['user-detail', selectedUserId],
        queryFn: () => api.get(`/admin/users/${selectedUserId}`).then(res => res.data),
        enabled: !!selectedUserId,
    });

    // Durum Değiştirme
    const toggleStatusMutation = useMutation({
        mutationFn: async ({ id, status }: { id: string; status: boolean }) => {
            await api.patch(`/admin/users/${id}/status`, null, {
                params: { is_active: status }
            });
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['users'] });
            notifications.show({ title: 'İşlem Başarılı', message: 'Kullanıcı durumu güncellendi', color: 'green' });
        },
    });

    // Tablo Satırları
    const rows = users?.map((user) => (
        <Table.Tr key={user.id}>
            <Table.Td>
                <Group gap="sm">
                    <Avatar size={40} src={user.profile_picture_url} radius={40} color="cyan">
                        {user.name?.charAt(0)}
                    </Avatar>
                    <div>
                        <Text fz="sm" fw={600}>{user.name}</Text>
                        <Text fz="xs" c="dimmed">{user.email}</Text>
                    </div>
                </Group>
            </Table.Td>

            <Table.Td>
                <Badge 
                    variant="light" 
                    color={user.role === 'admin' ? 'red' : user.role === 'client' ? 'purple' : 'cyan'} 
                    radius="sm"
                >
                    {user.role.toUpperCase()}
                </Badge>
            </Table.Td>

            <Table.Td>
                {user.is_active ? (
                    <Badge color="teal" variant="dot" size="sm">Aktif</Badge>
                ) : (
                    <Badge color="red" variant="filled" size="sm">BANLI</Badge>
                )}
            </Table.Td>

            <Table.Td>
                {user.is_verified ? (
                    <ThemeIcon color="teal" variant="light" size="sm" radius="xl">
                        <IconCheck size={12} />
                    </ThemeIcon>
                ) : (
                    <Text c="dimmed" size="xs">-</Text>
                )}
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
                                leftSection={<IconEye style={{ width: 16, height: 16 }} />}
                                onClick={() => { setSelectedUserId(user.id); setDrawerOpened(true); }}
                            >
                                Profili İncele
                            </Menu.Item>

                            <Menu.Divider />

                            {user.is_active ? (
                                <Menu.Item
                                    leftSection={<IconBan style={{ width: 16, height: 16 }} />}
                                    color="red"
                                    onClick={() => toggleStatusMutation.mutate({ id: user.id, status: false })}
                                >
                                    Hesabı Yasakla
                                </Menu.Item>
                            ) : (
                                <Menu.Item
                                    leftSection={<IconCheck style={{ width: 16, height: 16 }} />}
                                    color="green"
                                    onClick={() => toggleStatusMutation.mutate({ id: user.id, status: true })}
                                >
                                    Yasağı Kaldır
                                </Menu.Item>
                            )}
                        </Menu.Dropdown>
                    </Menu>
                </Group>
            </Table.Td>
        </Table.Tr>
    ));

    return (
        <Box w="100%" p={{ base: 'md', md: 'xl' }}>
            <LoadingOverlay visible={isLoading} />

            {/* --- ÜST BAŞLIK --- */}
            <Group justify="space-between" mb="xl">
                <div>
                    <Title order={2} fw={700}>Kullanıcı Yönetimi</Title>
                    <Text c="dimmed" size="sm">Sistemdeki tüm freelancer ve firmaları yönetin.</Text>
                </div>
                <Button leftSection={<IconDownload size={16}/>} variant="light" color="gray">
                    Excel İndir
                </Button>
            </Group>

            {/* --- ÖZET KARTLAR --- */}
            <SimpleGrid cols={{ base: 1, sm: 3 }} mb="xl">
                <Paper withBorder p="md" radius="md" shadow="sm">
                    <Group justify="space-between">
                        <Text size="xs" c="dimmed" fw={700} tt="uppercase">Toplam Kullanıcı</Text>
                        <ThemeIcon color="blue" variant="light" radius="xl"><IconUsers size={18}/></ThemeIcon>
                    </Group>
                    <Text fw={700} size="xl" mt="sm">{totalUsers}</Text>
                </Paper>
                <Paper withBorder p="md" radius="md" shadow="sm">
                    <Group justify="space-between">
                        <Text size="xs" c="dimmed" fw={700} tt="uppercase">Aktif Hesaplar</Text>
                        <ThemeIcon color="teal" variant="light" radius="xl"><IconUserCheck size={18}/></ThemeIcon>
                    </Group>
                    <Text fw={700} size="xl" mt="sm">{activeUsers}</Text>
                </Paper>
                <Paper withBorder p="md" radius="md" shadow="sm">
                    <Group justify="space-between">
                        <Text size="xs" c="dimmed" fw={700} tt="uppercase">Yasaklı Hesaplar</Text>
                        <ThemeIcon color="red" variant="light" radius="xl"><IconUserX size={18}/></ThemeIcon>
                    </Group>
                    <Text fw={700} size="xl" mt="sm">{bannedUsers}</Text>
                </Paper>
            </SimpleGrid>

            {/* --- FİLTRE VE TABLO ALANI --- */}
            <Paper withBorder radius="md" shadow="sm" p="md">
                <Group justify="space-between" mb="md">
                    <TextInput
                        placeholder="İsim veya Email ara..."
                        leftSection={<IconSearch size={16} />}
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        w={300}
                    />
                    <Select
                        placeholder="Rol Filtrele"
                        data={[
                            { value: 'freelancer', label: 'Freelancerlar' },
                            { value: 'client', label: 'Firmalar' },
                            { value: 'admin', label: 'Yöneticiler' }
                        ]}
                        clearable
                        value={roleFilter}
                        onChange={setRoleFilter}
                        w={200}
                    />
                </Group>

                <ScrollArea>
                    <Table verticalSpacing="md" striped highlightOnHover withTableBorder={false}>
                        <Table.Thead bg="gray.0">
                            <Table.Tr>
                                <Table.Th>Kullanıcı Bilgisi</Table.Th>
                                <Table.Th>Rol</Table.Th>
                                <Table.Th>Durum</Table.Th>
                                <Table.Th>Onaylı</Table.Th>
                                <Table.Th />
                            </Table.Tr>
                        </Table.Thead>
                        <Table.Tbody>{rows}</Table.Tbody>
                    </Table>
                </ScrollArea>

                {users?.length === 0 && (
                    <Text c="dimmed" ta="center" py="xl">Aranan kriterlere uygun kullanıcı bulunamadı.</Text>
                )}
            </Paper>

            {/* --- DETAY DRAWER --- */}
            <UserDetailDrawer 
                opened={drawerOpened}
                onClose={() => {
                    setDrawerOpened(false);
                    setSelectedUserId(null);
                }}
                user={userDetail}
                loading={isDetailLoading}
            />
        </Box>
    );
}