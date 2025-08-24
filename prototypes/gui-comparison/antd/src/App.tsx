import React, { useState } from 'react';
import {
  Layout,
  Card,
  Button,
  List,
  Radio,
  Checkbox,
  Progress,
  Space,
  Typography,
  Upload,
  Table,
  Tag,
  Divider,
  Row,
  Col,
  ConfigProvider,
  theme,
  message,
  Badge,
  Statistic,
} from 'antd';
import {
  CloudUploadOutlined,
  FolderOpenOutlined,
  FileImageOutlined,
  VideoCameraOutlined,
  FileOutlined,
  DeleteOutlined,
  PlayCircleOutlined,
  CloudOutlined,
  DatabaseOutlined,
  CalendarOutlined,
  MobileOutlined,
  SearchOutlined,
  InboxOutlined,
} from '@ant-design/icons';
import { open } from '@tauri-apps/api/dialog';
import { invoke } from '@tauri-apps/api/tauri';

const { Header, Content } = Layout;
const { Title, Text } = Typography;
const { Dragger } = Upload;

interface FileInfo {
  key: string;
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

  const { darkAlgorithm } = theme;

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
          key: `${Date.now()}-${index}`,
          path,
          name: path.split(/[\\/]/).pop() || '',
          size: Math.random() * 100000000,
          type: path.match(/\.(jpg|jpeg|png|gif)$/i) ? 'image' as const : 
                path.match(/\.(mp4|mov|avi)$/i) ? 'video' as const : 'other' as const
        }));
        setFiles([...files, ...newFiles]);
        message.success(`${newFiles.length}個のファイルを追加しました`);
      }
    } catch (error) {
      console.error('Error selecting files:', error);
      message.error('ファイルの選択に失敗しました');
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
          message.success('処理が完了しました！');
          return 100;
        }
        return prev + 10;
      });
    }, 500);
  };

  const handleDelete = (key: string) => {
    setFiles(files.filter(file => file.key !== key));
    message.info('ファイルを削除しました');
  };

  const formatFileSize = (bytes: number) => {
    const sizes = ['B', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 B';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  };

  const columns = [
    {
      title: 'ファイル名',
      dataIndex: 'name',
      key: 'name',
      render: (text: string, record: FileInfo) => (
        <Space>
          {record.type === 'image' ? <FileImageOutlined style={{ color: '#1890ff' }} /> :
           record.type === 'video' ? <VideoCameraOutlined style={{ color: '#52c41a' }} /> :
           <FileOutlined />}
          {text}
        </Space>
      ),
    },
    {
      title: 'タイプ',
      dataIndex: 'type',
      key: 'type',
      render: (type: string) => (
        <Tag color={type === 'image' ? 'blue' : type === 'video' ? 'green' : 'default'}>
          {type === 'image' ? '画像' : type === 'video' ? '動画' : 'その他'}
        </Tag>
      ),
    },
    {
      title: 'サイズ',
      dataIndex: 'size',
      key: 'size',
      render: (size: number) => formatFileSize(size),
    },
    {
      title: '操作',
      key: 'action',
      render: (_: any, record: FileInfo) => (
        <Button
          type="text"
          danger
          icon={<DeleteOutlined />}
          onClick={() => handleDelete(record.key)}
        />
      ),
    },
  ];

  const uploadProps = {
    name: 'file',
    multiple: true,
    showUploadList: false,
    beforeUpload: () => false,
    onChange: () => {
      handleSelectFiles();
    },
  };

  return (
    <ConfigProvider
      theme={{
        algorithm: darkAlgorithm,
        token: {
          colorPrimary: '#667eea',
        },
      }}
    >
      <Layout style={{ minHeight: '100vh' }}>
        <Header style={{ 
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}>
          <Title level={3} style={{ color: '#fff', margin: 0 }}>
            メディア転送ツール - Ant Design版
          </Title>
          <Badge count="GUI比較デモ" style={{ backgroundColor: '#764ba2' }} />
        </Header>

        <Content style={{ padding: '24px' }}>
          <Row gutter={[16, 16]}>
            {/* ファイルアップロードエリア */}
            <Col span={24}>
              <Card>
                <Dragger {...uploadProps} style={{ padding: '20px' }}>
                  <p className="ant-upload-drag-icon">
                    <InboxOutlined style={{ fontSize: '48px', color: '#667eea' }} />
                  </p>
                  <p className="ant-upload-text">クリックまたはドラッグ＆ドロップでファイルを選択</p>
                  <p className="ant-upload-hint">
                    写真や動画ファイルを選択してください（複数選択可能）
                  </p>
                  <Button type="primary" icon={<FolderOpenOutlined />} style={{ marginTop: 16 }}>
                    ファイルを選択
                  </Button>
                </Dragger>
              </Card>
            </Col>

            {/* 統計情報 */}
            {files.length > 0 && (
              <Col span={24}>
                <Card>
                  <Row gutter={16}>
                    <Col span={8}>
                      <Statistic 
                        title="総ファイル数" 
                        value={files.length} 
                        prefix={<FileOutlined />}
                      />
                    </Col>
                    <Col span={8}>
                      <Statistic 
                        title="画像ファイル" 
                        value={files.filter(f => f.type === 'image').length} 
                        prefix={<FileImageOutlined />}
                        valueStyle={{ color: '#1890ff' }}
                      />
                    </Col>
                    <Col span={8}>
                      <Statistic 
                        title="動画ファイル" 
                        value={files.filter(f => f.type === 'video').length} 
                        prefix={<VideoCameraOutlined />}
                        valueStyle={{ color: '#52c41a' }}
                      />
                    </Col>
                  </Row>
                </Card>
              </Col>
            )}

            {/* ファイルリスト */}
            {files.length > 0 && (
              <Col xl={14} lg={24}>
                <Card title="選択されたファイル" extra={<Text type="secondary">{files.length} 個のファイル</Text>}>
                  <Table 
                    columns={columns} 
                    dataSource={files} 
                    pagination={{ pageSize: 5 }}
                    size="small"
                  />
                </Card>
              </Col>
            )}

            {/* 設定パネル */}
            {files.length > 0 && (
              <Col xl={10} lg={24}>
                <Card title="転送設定">
                  <Space direction="vertical" size="large" style={{ width: '100%' }}>
                    <div>
                      <Title level={5}>出力先</Title>
                      <Radio.Group 
                        value={destination} 
                        onChange={(e) => setDestination(e.target.value)}
                        buttonStyle="solid"
                      >
                        <Radio.Button value="local">
                          <DatabaseOutlined /> ローカルストレージ
                        </Radio.Button>
                        <Radio.Button value="cloud">
                          <CloudOutlined /> クラウドストレージ
                        </Radio.Button>
                      </Radio.Group>
                    </div>

                    <Divider />

                    <div>
                      <Title level={5}>整理ルール</Title>
                      <Space direction="vertical">
                        <Checkbox
                          checked={rules.byDate}
                          onChange={(e) => setRules({...rules, byDate: e.target.checked})}
                        >
                          <CalendarOutlined /> 日付別に整理
                        </Checkbox>
                        <Checkbox
                          checked={rules.byDevice}
                          onChange={(e) => setRules({...rules, byDevice: e.target.checked})}
                        >
                          <MobileOutlined /> デバイス別に整理
                        </Checkbox>
                        <Checkbox
                          checked={rules.detectDuplicates}
                          onChange={(e) => setRules({...rules, detectDuplicates: e.target.checked})}
                        >
                          <SearchOutlined /> 重複検出
                        </Checkbox>
                      </Space>
                    </div>

                    <Divider />

                    <Button
                      type="primary"
                      size="large"
                      icon={<PlayCircleOutlined />}
                      onClick={handleProcess}
                      loading={processing}
                      block
                    >
                      処理開始
                    </Button>

                    {processing && (
                      <Progress 
                        percent={progress} 
                        strokeColor={{
                          '0%': '#667eea',
                          '100%': '#764ba2',
                        }}
                      />
                    )}
                  </Space>
                </Card>
              </Col>
            )}
          </Row>
        </Content>
      </Layout>
    </ConfigProvider>
  );
}

export default App;