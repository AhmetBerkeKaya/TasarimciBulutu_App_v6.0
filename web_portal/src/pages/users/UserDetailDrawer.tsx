import { Drawer, Avatar, Text, Group, Badge, Stack, Divider, Image, SimpleGrid } from '@mantine/core';
import { IconMail, IconPhone, IconCalendar } from '@tabler/icons-react';
import dayjs from 'dayjs';

interface UserDetailProps {
  opened: boolean;
  onClose: () => void;
  user: any; // Backend'den gelen full detay objesi
  loading: boolean;
}

export default function UserDetailDrawer({ opened, onClose, user, loading }: UserDetailProps) {
  return (
    <Drawer 
        opened={opened} 
        onClose={onClose} 
        title="Kullanıcı Profili" 
        position="right" 
        size="md"
    >
      {loading || !user ? (
        <Text>Yükleniyor...</Text>
      ) : (
        <Stack gap="md">
            {/* Profil Başlığı */}
            <Group>
                <Avatar src={user.profile_picture_url} size={80} radius={80} color="blue">
                    {user.name?.charAt(0)}
                </Avatar>
                <div>
                    <Text fw={700} size="lg">{user.name}</Text>
                    <Badge color={user.role === 'freelancer' ? 'green' : 'blue'}>{user.role}</Badge>
                </div>
            </Group>

            <Divider />

            {/* İletişim Bilgileri */}
            <Stack gap="xs">
                <Group gap="xs">
                    <IconMail size={16} color="gray" />
                    <Text size="sm">{user.email}</Text>
                </Group>
                <Group gap="xs">
                    <IconPhone size={16} color="gray" />
                    <Text size="sm">{user.phone || 'Telefon yok'}</Text>
                </Group>
                <Group gap="xs">
                    <IconCalendar size={16} color="gray" />
                    <Text size="sm">Kayıt: {dayjs(user.created_at).format('DD MMMM YYYY')}</Text>
                </Group>
            </Stack>

            <Divider label="Yetenekler" labelPosition="center" />
            
            <Group gap="xs">
                {user.skills?.length > 0 ? (
                    user.skills.map((skill: string) => (
                        <Badge key={skill} variant="outline" color="gray">{skill}</Badge>
                    ))
                ) : (
                    <Text c="dimmed" size="sm">Yetenek girilmemiş.</Text>
                )}
            </Group>

            <Divider label="Portfolyo" labelPosition="center" />

            <SimpleGrid cols={2}>
                {user.portfolio?.map((item: any, i: number) => (
                    <div key={i}>
                        <Image src={item.image} radius="sm" h={100} fit="cover" />
                        <Text size="xs" mt={2} fw={500} lineClamp={1}>{item.title}</Text>
                    </div>
                ))}
            </SimpleGrid>
            {user.portfolio?.length === 0 && <Text c="dimmed" size="sm">Portfolyo boş.</Text>}

        </Stack>
      )}
    </Drawer>
  );
}