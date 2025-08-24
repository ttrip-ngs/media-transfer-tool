import React, { useState } from 'react';
import {
  ChakraProvider,
  Box,
  VStack,
  HStack,
  Grid,
  GridItem,
  Heading,
  Text,
  Button,
  IconButton,
  Card,
  CardHeader,
  CardBody,
  Progress,
  Radio,
  RadioGroup,
  Checkbox,
  Stack,
  Badge,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  TableContainer,
  useToast,
  useColorMode,
  extendTheme,
  Stat,
  StatLabel,
  StatNumber,
  StatHelpText,
  StatGroup,
  Divider,
  Container,
  SimpleGrid,
  Icon,
  Center,
  Flex,
} from '@chakra-ui/react';
import {
  FiUploadCloud,
  FiFolder,
  FiImage,
  FiVideo,
  FiFile,
  FiTrash2,
  FiPlay,
  FiCloud,
  FiHardDrive,
  FiCalendar,
  FiSmartphone,
  FiSearch,
} from 'react-icons/fi';
import { motion } from 'framer-motion';
import { open } from '@tauri-apps/api/dialog';
import { invoke } from '@tauri-apps/api/tauri';

const theme = extendTheme({
  config: {
    initialColorMode: 'dark',
    useSystemColorMode: false,
  },
  colors: {
    brand: {
      50: '#e6ebff',
      100: '#b8c5ff',
      200: '#8a9eff',
      300: '#5c78ff',
      400: '#2e52ff',
      500: '#667eea',
      600: '#5a6cd8',
      700: '#4e5ac6',
      800: '#764ba2',
      900: '#5e3a82',
    },
  },
});

const MotionBox = motion(Box);

interface FileInfo {
  id: string;
  path: string;
  name: string;
  size: number;
  type: 'image' | 'video' | 'other';
}

function App() {
  const [files, setFiles] = useState<FileInfo[]>([]);
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [destination, setDestination] = useState('local');
  const [rules, setRules] = useState({
    byDate: true,
    byDevice: false,
    detectDuplicates: true,
  });
  const toast = useToast();

  const handleSelectFiles = async () => {
    try {
      const selected = await open({
        multiple: true,
        filters: [{
          name: 'Media Files',
          extensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi']
        }]
      });
      
      if (selected && Array.isArray(selected)) {
        const newFiles = selected.map((path, index) => ({
          id: `${Date.now()}-${index}`,
          path,
          name: path.split(/[\\/]/).pop() || '',
          size: Math.random() * 100000000,
          type: path.match(/\.(jpg|jpeg|png|gif)$/i) ? 'image' as const : 
                path.match(/\.(mp4|mov|avi)$/i) ? 'video' as const : 'other' as const
        }));
        setFiles([...files, ...newFiles]);
        toast({
          title: 'ファイル追加完了',
          description: `${newFiles.length}個のファイルを追加しました`,
          status: 'success',
          duration: 3000,
          isClosable: true,
        });
      }
    } catch (error) {
      console.error('Error selecting files:', error);
      toast({
        title: 'エラー',
        description: 'ファイルの選択に失敗しました',
        status: 'error',
        duration: 3000,
        isClosable: true,
      });
    }
  };

  const handleProcess = async () => {
    setProcessing(true);
    setProgress(0);
    
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setProcessing(false);
          toast({
            title: '処理完了',
            description: 'すべてのファイルの転送が完了しました！',
            status: 'success',
            duration: 3000,
            isClosable: true,
          });
          return 100;
        }
        return prev + 10;
      });
    }, 500);
  };

  const handleDelete = (id: string) => {
    setFiles(files.filter(file => file.id !== id));
  };

  const formatFileSize = (bytes: number) => {
    const sizes = ['B', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 B';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  };

  const getFileIcon = (type: string) => {
    switch (type) {
      case 'image':
        return FiImage;
      case 'video':
        return FiVideo;
      default:
        return FiFile;
    }
  };

  const getFileColor = (type: string) => {
    switch (type) {
      case 'image':
        return 'blue.400';
      case 'video':
        return 'green.400';
      default:
        return 'gray.400';
    }
  };

  return (
    <ChakraProvider theme={theme}>
      <Box minH="100vh" bg="gray.900">
        {/* ヘッダー */}
        <Box
          bgGradient="linear(to-r, brand.500, brand.800)"
          px={8}
          py={4}
        >
          <Flex justify="space-between" align="center">
            <Heading size="lg" color="white">
              メディア転送ツール - Chakra UI版
            </Heading>
            <Badge colorScheme="purple" fontSize="md" px={3} py={1}>
              GUI比較デモ
            </Badge>
          </Flex>
        </Box>

        <Container maxW="container.xl" py={8}>
          <VStack spacing={6} align="stretch">
            {/* ファイルアップロードエリア */}
            <MotionBox
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
            >
              <Card>
                <CardBody>
                  <Center py={12}>
                    <VStack spacing={4}>
                      <Icon as={FiUploadCloud} boxSize={16} color="brand.500" />
                      <Heading size="md">ファイルを選択</Heading>
                      <Text color="gray.500">
                        写真や動画ファイルを選択してください
                      </Text>
                      <Button
                        leftIcon={<FiFolder />}
                        colorScheme="brand"
                        size="lg"
                        onClick={handleSelectFiles}
                      >
                        ファイルを選択
                      </Button>
                    </VStack>
                  </Center>
                </CardBody>
              </Card>
            </MotionBox>

            {/* 統計情報 */}
            {files.length > 0 && (
              <MotionBox
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.1 }}
              >
                <StatGroup>
                  <Card flex="1">
                    <CardBody>
                      <Stat>
                        <StatLabel>総ファイル数</StatLabel>
                        <StatNumber>{files.length}</StatNumber>
                        <StatHelpText>選択済み</StatHelpText>
                      </Stat>
                    </CardBody>
                  </Card>
                  <Card flex="1">
                    <CardBody>
                      <Stat>
                        <StatLabel>画像ファイル</StatLabel>
                        <StatNumber color="blue.400">
                          {files.filter(f => f.type === 'image').length}
                        </StatNumber>
                        <StatHelpText>JPG, PNG等</StatHelpText>
                      </Stat>
                    </CardBody>
                  </Card>
                  <Card flex="1">
                    <CardBody>
                      <Stat>
                        <StatLabel>動画ファイル</StatLabel>
                        <StatNumber color="green.400">
                          {files.filter(f => f.type === 'video').length}
                        </StatNumber>
                        <StatHelpText>MP4, MOV等</StatHelpText>
                      </Stat>
                    </CardBody>
                  </Card>
                </StatGroup>
              </MotionBox>
            )}

            <Grid templateColumns={{ base: '1fr', lg: 'repeat(3, 1fr)' }} gap={6}>
              {/* ファイルリスト */}
              {files.length > 0 && (
                <GridItem colSpan={{ base: 1, lg: 2 }}>
                  <MotionBox
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.5, delay: 0.2 }}
                  >
                    <Card h="full">
                      <CardHeader>
                        <Heading size="md">選択されたファイル</Heading>
                      </CardHeader>
                      <CardBody>
                        <TableContainer>
                          <Table variant="simple">
                            <Thead>
                              <Tr>
                                <Th>ファイル名</Th>
                                <Th>タイプ</Th>
                                <Th>サイズ</Th>
                                <Th width="50px"></Th>
                              </Tr>
                            </Thead>
                            <Tbody>
                              {files.map((file) => (
                                <Tr key={file.id}>
                                  <Td>
                                    <HStack>
                                      <Icon 
                                        as={getFileIcon(file.type)} 
                                        color={getFileColor(file.type)}
                                      />
                                      <Text>{file.name}</Text>
                                    </HStack>
                                  </Td>
                                  <Td>
                                    <Badge colorScheme={
                                      file.type === 'image' ? 'blue' : 
                                      file.type === 'video' ? 'green' : 'gray'
                                    }>
                                      {file.type === 'image' ? '画像' : 
                                       file.type === 'video' ? '動画' : 'その他'}
                                    </Badge>
                                  </Td>
                                  <Td>{formatFileSize(file.size)}</Td>
                                  <Td>
                                    <IconButton
                                      aria-label="削除"
                                      icon={<FiTrash2 />}
                                      size="sm"
                                      variant="ghost"
                                      colorScheme="red"
                                      onClick={() => handleDelete(file.id)}
                                    />
                                  </Td>
                                </Tr>
                              ))}
                            </Tbody>
                          </Table>
                        </TableContainer>
                      </CardBody>
                    </Card>
                  </MotionBox>
                </GridItem>
              )}

              {/* 設定パネル */}
              {files.length > 0 && (
                <GridItem>
                  <MotionBox
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.5, delay: 0.3 }}
                  >
                    <Card h="full">
                      <CardHeader>
                        <Heading size="md">転送設定</Heading>
                      </CardHeader>
                      <CardBody>
                        <VStack spacing={6} align="stretch">
                          <Box>
                            <Text fontWeight="bold" mb={3}>出力先</Text>
                            <RadioGroup value={destination} onChange={setDestination}>
                              <Stack>
                                <Radio value="local" colorScheme="brand">
                                  <HStack>
                                    <Icon as={FiHardDrive} />
                                    <Text>ローカルストレージ</Text>
                                  </HStack>
                                </Radio>
                                <Radio value="cloud" colorScheme="brand">
                                  <HStack>
                                    <Icon as={FiCloud} />
                                    <Text>クラウドストレージ</Text>
                                  </HStack>
                                </Radio>
                              </Stack>
                            </RadioGroup>
                          </Box>

                          <Divider />

                          <Box>
                            <Text fontWeight="bold" mb={3}>整理ルール</Text>
                            <Stack>
                              <Checkbox
                                isChecked={rules.byDate}
                                onChange={(e) => setRules({...rules, byDate: e.target.checked})}
                                colorScheme="brand"
                              >
                                <HStack>
                                  <Icon as={FiCalendar} />
                                  <Text>日付別に整理</Text>
                                </HStack>
                              </Checkbox>
                              <Checkbox
                                isChecked={rules.byDevice}
                                onChange={(e) => setRules({...rules, byDevice: e.target.checked})}
                                colorScheme="brand"
                              >
                                <HStack>
                                  <Icon as={FiSmartphone} />
                                  <Text>デバイス別に整理</Text>
                                </HStack>
                              </Checkbox>
                              <Checkbox
                                isChecked={rules.detectDuplicates}
                                onChange={(e) => setRules({...rules, detectDuplicates: e.target.checked})}
                                colorScheme="brand"
                              >
                                <HStack>
                                  <Icon as={FiSearch} />
                                  <Text>重複検出</Text>
                                </HStack>
                              </Checkbox>
                            </Stack>
                          </Box>

                          <Divider />

                          <Box>
                            <Button
                              leftIcon={<FiPlay />}
                              colorScheme="brand"
                              size="lg"
                              width="full"
                              onClick={handleProcess}
                              isLoading={processing}
                              loadingText="処理中..."
                            >
                              処理開始
                            </Button>
                            {processing && (
                              <Box mt={4}>
                                <Progress 
                                  value={progress} 
                                  colorScheme="brand"
                                  hasStripe
                                  isAnimated
                                />
                                <Text textAlign="center" mt={2} fontSize="sm">
                                  {progress}%
                                </Text>
                              </Box>
                            )}
                          </Box>
                        </VStack>
                      </CardBody>
                    </Card>
                  </MotionBox>
                </GridItem>
              )}
            </Grid>
          </VStack>
        </Container>
      </Box>
    </ChakraProvider>
  );
}

export default App;