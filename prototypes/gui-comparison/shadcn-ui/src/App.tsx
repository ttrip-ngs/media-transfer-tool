import React, { useState } from 'react';
import { Button } from './components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './components/ui/card';
import { Checkbox } from './components/ui/checkbox';
import { Label } from './components/ui/label';
import { Progress } from './components/ui/progress';
import { RadioGroup, RadioGroupItem } from './components/ui/radio-group';
import { Badge } from './components/ui/badge';
import { useToast } from './components/ui/use-toast';
import { Toaster } from './components/ui/toaster';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from './components/ui/table';
import {
  CloudUpload,
  FolderOpen,
  Image,
  Video,
  File,
  Trash2,
  Play,
  Cloud,
  HardDrive,
  Calendar,
  Smartphone,
  Search,
} from 'lucide-react';
import { open } from '@tauri-apps/api/dialog';
import { invoke } from '@tauri-apps/api/tauri';
import { cn } from './lib/utils';

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
  const { toast } = useToast();

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
          title: "ファイル追加完了",
          description: `${newFiles.length}個のファイルを追加しました`,
        });
      }
    } catch (error) {
      console.error('Error selecting files:', error);
      toast({
        title: "エラー",
        description: "ファイルの選択に失敗しました",
        variant: "destructive",
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
            title: "処理完了",
            description: "すべてのファイルの転送が完了しました！",
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
        return <Image className="w-4 h-4" />;
      case 'video':
        return <Video className="w-4 h-4" />;
      default:
        return <File className="w-4 h-4" />;
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <Toaster />
      
      {/* Header */}
      <header className="bg-gradient-to-r from-purple-600 to-pink-600 text-white">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold">
            メディア転送ツール - shadcn/ui版
          </h1>
          <Badge variant="secondary">GUI比較デモ</Badge>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="grid gap-6">
          {/* Upload Area */}
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12">
              <CloudUpload className="w-16 h-16 text-muted-foreground mb-4" />
              <h2 className="text-xl font-semibold mb-2">ファイルを選択</h2>
              <p className="text-muted-foreground mb-4">
                写真や動画ファイルを選択してください
              </p>
              <Button onClick={handleSelectFiles} size="lg">
                <FolderOpen className="mr-2 h-4 w-4" />
                ファイルを選択
              </Button>
            </CardContent>
          </Card>

          {/* Statistics */}
          {files.length > 0 && (
            <div className="grid gap-4 md:grid-cols-3">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    総ファイル数
                  </CardTitle>
                  <File className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{files.length}</div>
                  <p className="text-xs text-muted-foreground">
                    選択済み
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    画像ファイル
                  </CardTitle>
                  <Image className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-blue-600">
                    {files.filter(f => f.type === 'image').length}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    JPG, PNG等
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    動画ファイル
                  </CardTitle>
                  <Video className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-green-600">
                    {files.filter(f => f.type === 'video').length}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    MP4, MOV等
                  </p>
                </CardContent>
              </Card>
            </div>
          )}

          <div className="grid gap-6 lg:grid-cols-3">
            {/* File List */}
            {files.length > 0 && (
              <div className="lg:col-span-2">
                <Card>
                  <CardHeader>
                    <CardTitle>選択されたファイル</CardTitle>
                    <CardDescription>
                      {files.length} 個のファイルが選択されています
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>ファイル名</TableHead>
                          <TableHead>タイプ</TableHead>
                          <TableHead>サイズ</TableHead>
                          <TableHead className="w-[50px]"></TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {files.map(file => (
                          <TableRow key={file.id}>
                            <TableCell>
                              <div className="flex items-center gap-2">
                                {getFileIcon(file.type)}
                                <span className="truncate max-w-[200px]">
                                  {file.name}
                                </span>
                              </div>
                            </TableCell>
                            <TableCell>
                              <Badge variant={
                                file.type === 'image' ? 'default' :
                                file.type === 'video' ? 'secondary' : 'outline'
                              }>
                                {file.type === 'image' ? '画像' :
                                 file.type === 'video' ? '動画' : 'その他'}
                              </Badge>
                            </TableCell>
                            <TableCell className="text-muted-foreground">
                              {formatFileSize(file.size)}
                            </TableCell>
                            <TableCell>
                              <Button
                                variant="ghost"
                                size="icon"
                                onClick={() => handleDelete(file.id)}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </CardContent>
                </Card>
              </div>
            )}

            {/* Settings Panel */}
            {files.length > 0 && (
              <div>
                <Card>
                  <CardHeader>
                    <CardTitle>転送設定</CardTitle>
                    <CardDescription>
                      ファイルの転送先と整理方法を設定してください
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-6">
                    {/* Destination */}
                    <div className="space-y-3">
                      <Label>出力先</Label>
                      <RadioGroup value={destination} onValueChange={setDestination}>
                        <div className="flex items-center space-x-2">
                          <RadioGroupItem value="local" id="local" />
                          <Label htmlFor="local" className="flex items-center cursor-pointer">
                            <HardDrive className="mr-2 h-4 w-4" />
                            ローカルストレージ
                          </Label>
                        </div>
                        <div className="flex items-center space-x-2">
                          <RadioGroupItem value="cloud" id="cloud" />
                          <Label htmlFor="cloud" className="flex items-center cursor-pointer">
                            <Cloud className="mr-2 h-4 w-4" />
                            クラウドストレージ
                          </Label>
                        </div>
                      </RadioGroup>
                    </div>

                    {/* Rules */}
                    <div className="space-y-3">
                      <Label>整理ルール</Label>
                      <div className="space-y-2">
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id="byDate"
                            checked={rules.byDate}
                            onCheckedChange={(checked) => 
                              setRules({...rules, byDate: checked as boolean})
                            }
                          />
                          <Label
                            htmlFor="byDate"
                            className="flex items-center cursor-pointer"
                          >
                            <Calendar className="mr-2 h-4 w-4" />
                            日付別に整理
                          </Label>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id="byDevice"
                            checked={rules.byDevice}
                            onCheckedChange={(checked) => 
                              setRules({...rules, byDevice: checked as boolean})
                            }
                          />
                          <Label
                            htmlFor="byDevice"
                            className="flex items-center cursor-pointer"
                          >
                            <Smartphone className="mr-2 h-4 w-4" />
                            デバイス別に整理
                          </Label>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id="detectDuplicates"
                            checked={rules.detectDuplicates}
                            onCheckedChange={(checked) => 
                              setRules({...rules, detectDuplicates: checked as boolean})
                            }
                          />
                          <Label
                            htmlFor="detectDuplicates"
                            className="flex items-center cursor-pointer"
                          >
                            <Search className="mr-2 h-4 w-4" />
                            重複検出
                          </Label>
                        </div>
                      </div>
                    </div>

                    {/* Process Button */}
                    <Button
                      className="w-full"
                      size="lg"
                      onClick={handleProcess}
                      disabled={processing}
                    >
                      {processing ? (
                        <div className="flex items-center">
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                          処理中...
                        </div>
                      ) : (
                        <>
                          <Play className="mr-2 h-4 w-4" />
                          処理開始
                        </>
                      )}
                    </Button>

                    {/* Progress */}
                    {processing && (
                      <div className="space-y-2">
                        <Progress value={progress} className="w-full" />
                        <p className="text-sm text-center text-muted-foreground">
                          {progress}%
                        </p>
                      </div>
                    )}
                  </CardContent>
                </Card>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

export default App;