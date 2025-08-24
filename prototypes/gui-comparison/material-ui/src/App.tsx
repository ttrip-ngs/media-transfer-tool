import React, { useState } from 'react';
import {
  ThemeProvider,
  createTheme,
  CssBaseline,
  Box,
  AppBar,
  Toolbar,
  Typography,
  Container,
  Grid,
  Card,
  CardContent,
  Button,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  ListItemSecondary,
  FormControl,
  FormLabel,
  RadioGroup,
  FormControlLabel,
  Radio,
  Checkbox,
  LinearProgress,
  Chip,
  IconButton,
  Paper,
  Fab,
  Alert,
  Snackbar,
} from '@mui/material';
import {
  CloudUpload,
  FolderOpen,
  InsertDriveFile,
  Image,
  Movie,
  Delete,
  PlayArrow,
  CloudQueue,
  Storage,
  CalendarMonth,
  Devices,
  FindInPage,
} from '@mui/icons-material';
import { open } from '@tauri-apps/api/dialog';
import { invoke } from '@tauri-apps/api/tauri';

const darkTheme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#667eea',
    },
    secondary: {
      main: '#764ba2',
    },
  },
});

interface FileInfo {
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
  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState('');

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
        const newFiles = selected.map(path => ({
          path,
          name: path.split(/[\\/]/).pop() || '',
          size: Math.random() * 100000000,
          type: path.match(/\.(jpg|jpeg|png|gif)$/i) ? 'image' as const : 
                path.match(/\.(mp4|mov|avi)$/i) ? 'video' as const : 'other' as const
        }));
        setFiles([...files, ...newFiles]);
        showSnackbar(`${newFiles.length}個のファイルを追加しました`);
      }
    } catch (error) {
      console.error('Error selecting files:', error);
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
          showSnackbar('処理が完了しました！');
          return 100;
        }
        return prev + 10;
      });
    }, 500);
  };

  const showSnackbar = (message: string) => {
    setSnackbarMessage(message);
    setSnackbarOpen(true);
  };

  const getFileIcon = (type: string) => {
    switch (type) {
      case 'image':
        return <Image color="primary" />;
      case 'video':
        return <Movie color="secondary" />;
      default:
        return <InsertDriveFile />;
    }
  };

  const formatFileSize = (bytes: number) => {
    const sizes = ['B', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 B';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  };

  return (
    <ThemeProvider theme={darkTheme}>
      <CssBaseline />
      <Box sx={{ flexGrow: 1 }}>
        <AppBar position="static" elevation={0} sx={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
          <Toolbar>
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              メディア転送ツール - Material-UI版
            </Typography>
            <Chip label="GUI比較デモ" color="secondary" />
          </Toolbar>
        </AppBar>

        <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
          <Grid container spacing={3}>
            {/* ファイル選択エリア */}
            <Grid item xs={12}>
              <Paper elevation={3} sx={{ p: 3, textAlign: 'center' }}>
                <CloudUpload sx={{ fontSize: 60, color: 'primary.main', mb: 2 }} />
                <Typography variant="h5" gutterBottom>
                  ファイルを選択
                </Typography>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  写真や動画ファイルを選択してください
                </Typography>
                <Button
                  variant="contained"
                  startIcon={<FolderOpen />}
                  onClick={handleSelectFiles}
                  size="large"
                  sx={{ mt: 2 }}
                >
                  ファイルを選択
                </Button>
              </Paper>
            </Grid>

            {/* ファイルリスト */}
            {files.length > 0 && (
              <Grid item xs={12} md={7}>
                <Card>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      選択されたファイル ({files.length})
                    </Typography>
                    <List>
                      {files.map((file, index) => (
                        <ListItem
                          key={index}
                          secondaryAction={
                            <IconButton edge="end" aria-label="delete">
                              <Delete />
                            </IconButton>
                          }
                        >
                          <ListItemIcon>
                            {getFileIcon(file.type)}
                          </ListItemIcon>
                          <ListItemText
                            primary={file.name}
                            secondary={formatFileSize(file.size)}
                          />
                        </ListItem>
                      ))}
                    </List>
                  </CardContent>
                </Card>
              </Grid>
            )}

            {/* 設定パネル */}
            {files.length > 0 && (
              <Grid item xs={12} md={5}>
                <Card>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      転送設定
                    </Typography>
                    
                    <FormControl component="fieldset" sx={{ mt: 2, mb: 3 }}>
                      <FormLabel component="legend">出力先</FormLabel>
                      <RadioGroup
                        value={destination}
                        onChange={(e) => setDestination(e.target.value)}
                      >
                        <FormControlLabel 
                          value="local" 
                          control={<Radio />} 
                          label={
                            <Box sx={{ display: 'flex', alignItems: 'center' }}>
                              <Storage sx={{ mr: 1 }} />
                              ローカルストレージ
                            </Box>
                          } 
                        />
                        <FormControlLabel 
                          value="cloud" 
                          control={<Radio />} 
                          label={
                            <Box sx={{ display: 'flex', alignItems: 'center' }}>
                              <CloudQueue sx={{ mr: 1 }} />
                              クラウドストレージ
                            </Box>
                          } 
                        />
                      </RadioGroup>
                    </FormControl>

                    <FormControl component="fieldset">
                      <FormLabel component="legend">整理ルール</FormLabel>
                      <FormControlLabel
                        control={
                          <Checkbox
                            checked={rules.byDate}
                            onChange={(e) => setRules({...rules, byDate: e.target.checked})}
                          />
                        }
                        label={
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <CalendarMonth sx={{ mr: 1 }} />
                            日付別に整理
                          </Box>
                        }
                      />
                      <FormControlLabel
                        control={
                          <Checkbox
                            checked={rules.byDevice}
                            onChange={(e) => setRules({...rules, byDevice: e.target.checked})}
                          />
                        }
                        label={
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Devices sx={{ mr: 1 }} />
                            デバイス別に整理
                          </Box>
                        }
                      />
                      <FormControlLabel
                        control={
                          <Checkbox
                            checked={rules.detectDuplicates}
                            onChange={(e) => setRules({...rules, detectDuplicates: e.target.checked})}
                          />
                        }
                        label={
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <FindInPage sx={{ mr: 1 }} />
                            重複検出
                          </Box>
                        }
                      />
                    </FormControl>
                  </CardContent>
                </Card>
              </Grid>
            )}

            {/* 処理実行エリア */}
            {files.length > 0 && (
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Fab
                    variant="extended"
                    color="primary"
                    onClick={handleProcess}
                    disabled={processing}
                  >
                    <PlayArrow sx={{ mr: 1 }} />
                    処理開始
                  </Fab>
                  {processing && (
                    <Box sx={{ flex: 1 }}>
                      <LinearProgress variant="determinate" value={progress} />
                      <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                        処理中... {progress}%
                      </Typography>
                    </Box>
                  )}
                </Box>
              </Grid>
            )}
          </Grid>
        </Container>

        <Snackbar
          open={snackbarOpen}
          autoHideDuration={3000}
          onClose={() => setSnackbarOpen(false)}
        >
          <Alert severity="success" sx={{ width: '100%' }}>
            {snackbarMessage}
          </Alert>
        </Snackbar>
      </Box>
    </ThemeProvider>
  );
}

export default App;