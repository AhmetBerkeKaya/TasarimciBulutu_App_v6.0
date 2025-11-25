import { useState } from 'react';
import { 
  TextInput, Textarea, Button, Group, Title, Paper, ActionIcon, 
  Radio, Divider, Text, Stack, Box, Select, ThemeIcon, Grid, NumberInput
} from '@mantine/core';
import { IconPlus, IconTrash, IconCheck, IconDeviceFloppy, IconArrowLeft, IconCertificate } from '@tabler/icons-react';
import { useNavigate } from 'react-router-dom';
import api from '../../services/api';
import { notifications } from '@mantine/notifications';

// Veri Yapısı
interface Choice {
  id: number; // Geçici ID (Frontend key için)
  text: string;
  isCorrect: boolean;
}

interface Question {
  id: number; 
  text: string;
  choices: Choice[];
}

export default function CreateTest() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);

  // Test Genel Bilgileri
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [software, setSoftware] = useState<string | null>(null);
  
  // Sorular State (Başlangıçta 1 boş soru)
  const [questions, setQuestions] = useState<Question[]>([
    { 
        id: 1, 
        text: '', 
        choices: [
            { id: 1, text: '', isCorrect: true }, // Varsayılan doğru
            { id: 2, text: '', isCorrect: false },
            { id: 3, text: '', isCorrect: false },
            { id: 4, text: '', isCorrect: false }
        ] 
    }
  ]);

  // --- SORU İŞLEMLERİ ---
  const addQuestion = () => {
    const newId = questions.length + 1;
    setQuestions([
      ...questions,
      { 
        id: newId, 
        text: '', 
        choices: [
            { id: Date.now(), text: '', isCorrect: true }, 
            { id: Date.now()+1, text: '', isCorrect: false }
        ] 
      }
    ]);
    
    // Sayfayı aşağı kaydır
    setTimeout(() => window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' }), 100);
  };

  const removeQuestion = (qIndex: number) => {
    const newQ = [...questions];
    newQ.splice(qIndex, 1);
    setQuestions(newQ);
  };

  const updateQuestionText = (qIndex: number, val: string) => {
    const newQ = [...questions];
    newQ[qIndex].text = val;
    setQuestions(newQ);
  };

  // --- ŞIK İŞLEMLERİ ---
  const addChoice = (qIndex: number) => {
    const newQ = [...questions];
    newQ[qIndex].choices.push({ 
        id: Date.now(), 
        text: '', 
        isCorrect: false 
    });
    setQuestions(newQ);
  };

  const updateChoiceText = (qIndex: number, cIndex: number, val: string) => {
    const newQ = [...questions];
    newQ[qIndex].choices[cIndex].text = val;
    setQuestions(newQ);
  };

  const setCorrectChoice = (qIndex: number, cIndex: number) => {
    const newQ = [...questions];
    // O sorudaki tüm şıkların isCorrect'ini false yap
    newQ[qIndex].choices.forEach(c => c.isCorrect = false);
    // Seçileni true yap
    newQ[qIndex].choices[cIndex].isCorrect = true;
    setQuestions(newQ);
  };

  const removeChoice = (qIndex: number, cIndex: number) => {
    const newQ = [...questions];
    newQ[qIndex].choices.splice(cIndex, 1);
    setQuestions(newQ);
  };

  // --- KAYDET ---
  const handleSave = async () => {
    if (!title || !software) {
        notifications.show({ title: 'Hata', message: 'Lütfen başlık ve yazılım alanlarını doldurun.', color: 'red' });
        return;
    }

    setLoading(true);
    try {
        // Backend'in beklediği formata çevir (snake_case)
        const payload = {
            title,
            description,
            software,
            questions: questions.map(q => ({
                question_text: q.text,
                choices: q.choices.map(c => ({
                    choice_text: c.text,
                    is_correct: c.isCorrect
                }))
            }))
        };

        await api.post('/admin/skill-tests', payload);
        notifications.show({ title: 'Başarılı', message: 'Test oluşturuldu ve yayına alındı.', color: 'green' });
        navigate('/skill-tests'); // Listeye dön
        
    } catch (error) {
        console.error(error);
        notifications.show({ title: 'Hata', message: 'Kayıt sırasında bir sorun oluştu.', color: 'red' });
    } finally {
        setLoading(false);
    }
  };

  return (
    <Box w="100%" p={{ base: 'md', md: 'xl' }} style={{ maxWidth: 1000, margin: '0 auto' }}>
      
      {/* ÜST BAŞLIK */}
      <Group justify="space-between" mb="lg">
        <Group>
            <ActionIcon variant="light" color="gray" size="lg" onClick={() => navigate('/skill-tests')}>
                <IconArrowLeft size={20} />
            </ActionIcon>
            <div>
                <Title order={2} fw={700}>Yeni Test Oluştur</Title>
                <Text c="dimmed" size="sm">Soru havuzunu ve doğru cevapları belirleyin.</Text>
            </div>
        </Group>
        <Button 
            size="md" 
            leftSection={<IconDeviceFloppy size={20} />} 
            onClick={handleSave} 
            loading={loading}
            color="blue"
        >
            Testi Kaydet
        </Button>
      </Group>

      {/* 1. ADIM: TEST BİLGİLERİ */}
      <Paper withBorder p="xl" radius="md" mb="xl" shadow="sm">
        <Group mb="md">
            <ThemeIcon size="lg" radius="md" color="blue" variant="light">
                <IconCertificate size={20} />
            </ThemeIcon>
            <Text fw={600}>Test Detayları</Text>
        </Group>
        
        <Grid>
            <Grid.Col span={{ base: 12, md: 8 }}>
                <TextInput 
                    label="Test Başlığı" 
                    placeholder="Örn: Autodesk Inventor - İleri Seviye Modelleme" 
                    required 
                    size="md"
                    value={title} onChange={(e) => setTitle(e.target.value)}
                />
            </Grid.Col>
            <Grid.Col span={{ base: 12, md: 4 }}>
                <Select 
                    label="İlgili Yazılım" 
                    placeholder="Seçiniz" 
                    data={['Autodesk Inventor', 'SolidWorks', 'Revit', 'AutoCAD', 'Fusion 360', 'Catia']}
                    required 
                    size="md"
                    value={software} onChange={setSoftware}
                />
            </Grid.Col>
            <Grid.Col span={12}>
                <Textarea 
                    label="Açıklama / Talimatlar" 
                    placeholder="Bu test neleri ölçüyor? Katılımcı ne bilmeli?" 
                    minRows={3}
                    value={description} onChange={(e) => setDescription(e.target.value)}
                />
            </Grid.Col>
        </Grid>
      </Paper>

      <Divider my="xl" label="SORULAR VE CEVAPLAR" labelPosition="center" />

      {/* 2. ADIM: SORULAR LİSTESİ */}
      <Stack gap="lg">
        {questions.map((q, qIndex) => (
            <Paper key={q.id} withBorder p="lg" radius="md" shadow="sm" style={{ position: 'relative', borderLeft: '4px solid var(--mantine-color-blue-5)' }}>
                
                {/* Soru Başlığı ve Silme Butonu */}
                <Group justify="space-between" mb="sm" align="flex-start">
                    <Text fw={700} c="blue" size="lg">Soru {qIndex + 1}</Text>
                    {questions.length > 1 && (
                        <ActionIcon color="red" variant="subtle" onClick={() => removeQuestion(qIndex)}>
                            <IconTrash size={18} />
                        </ActionIcon>
                    )}
                </Group>

                {/* Soru Metni */}
                <Textarea 
                    placeholder="Soruyu buraya yazın..." 
                    mb="lg"
                    size="md"
                    minRows={2}
                    variant="filled"
                    value={q.text}
                    onChange={(e) => updateQuestionText(qIndex, e.target.value)}
                />

                {/* Şıklar */}
                <Stack gap="xs" pl={{ base: 0, md: 'lg' }}>
                    <Text size="xs" c="dimmed" fw={600} tt="uppercase">CEVAP ŞIKLARI (Doğru olanı işaretleyin)</Text>
                    
                    {q.choices.map((c, cIndex) => (
                        <Group key={c.id} wrap="nowrap">
                            <Radio 
                                checked={c.isCorrect} 
                                onChange={() => setCorrectChoice(qIndex, cIndex)}
                                size="md"
                                color="teal"
                            />
                            <TextInput 
                                placeholder={`Şık ${String.fromCharCode(65 + cIndex)}`} // A, B, C...
                                style={{ flex: 1 }}
                                value={c.text}
                                onChange={(e) => updateChoiceText(qIndex, cIndex, e.target.value)}
                                rightSection={c.isCorrect && <IconCheck size={16} color="var(--mantine-color-teal-6)" />}
                            />
                            {q.choices.length > 2 && (
                                <ActionIcon color="gray" variant="transparent" onClick={() => removeChoice(qIndex, cIndex)}>
                                    <IconTrash size={16} />
                                </ActionIcon>
                            )}
                        </Group>
                    ))}
                    
                    <Button 
                        variant="subtle" 
                        size="xs" 
                        leftSection={<IconPlus size={14} />} 
                        onClick={() => addChoice(qIndex)}
                        w="fit-content"
                        mt={5}
                        color="gray"
                    >
                        Şık Ekle
                    </Button>
                </Stack>
            </Paper>
        ))}
      </Stack>

      {/* Yeni Soru Ekle Butonu */}
      <Button 
        fullWidth 
        variant="outline" 
        size="lg" 
        leftSection={<IconPlus />} 
        onClick={addQuestion} 
        mt="xl" 
        style={{ borderStyle: 'dashed' }}
      >
        Yeni Soru Ekle
      </Button>

      <Group justify="flex-end" mt={50} mb={100}>
        <Button variant="default" size="lg" onClick={() => navigate('/skill-tests')}>İptal</Button>
        <Button size="lg" onClick={handleSave} loading={loading} leftSection={<IconDeviceFloppy />}>
            Testi Yayınla
        </Button>
      </Group>
    </Box>
  );
}