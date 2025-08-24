import React, { useState, Fragment } from 'react';
import { Transition } from '@headlessui/react';
import {
  CloudArrowUpIcon,
  FolderOpenIcon,
  PhotoIcon,
  VideoCameraIcon,
  DocumentIcon,
  TrashIcon,
  PlayIcon,
  CloudIcon,
  ServerIcon,
  CalendarDaysIcon,
  DevicePhoneMobileIcon,
  MagnifyingGlassIcon,
  CheckCircleIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';
import { open } from '@tauri-apps/api/dialog';
import { invoke } from '@tauri-apps/api/tauri';

interface FileInfo {
  id: string;
  path: string;
  name: string;
  size: number;
  type: 'image' | 'video' | 'other';
}

interface Notification {
  id: string;
  message: string;
  type: 'success' | 'error';
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
  const [notifications, setNotifications] = useState<Notification[]>([]);

  const addNotification = (message: string, type: 'success' | 'error') => {
    const id = Date.now().toString();
    setNotifications(prev => [...prev, { id, message, type }]);
    setTimeout(() => {
      setNotifications(prev => prev.filter(n => n.id !== id));
    }, 3000);
  };

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
        addNotification(`${newFiles.length}個のファイルを追加しました`, 'success');
      }
    } catch (error) {
      console.error('Error selecting files:', error);
      addNotification('ファイルの選択に失敗しました', 'error');
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
          addNotification('処理が完了しました！', 'success');
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
        return <PhotoIcon className="w-5 h-5 text-blue-500" />;
      case 'video':
        return <VideoCameraIcon className="w-5 h-5 text-green-500" />;
      default:
        return <DocumentIcon className="w-5 h-5 text-gray-500" />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100">
      {/* Header */}
      <header className="bg-gradient-primary px-6 py-4">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <h1 className="text-2xl font-bold text-white">
            メディア転送ツール - Tailwind CSS版
          </h1>
          <span className="bg-purple-700 text-white px-3 py-1 rounded-full text-sm">
            GUI比較デモ
          </span>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        {/* Upload Area */}
        <div className="bg-gray-800 rounded-lg p-8 text-center mb-6 border-2 border-dashed border-gray-700 hover:border-primary-500 transition-colors">
          <CloudArrowUpIcon className="w-16 h-16 mx-auto mb-4 text-primary-500" />
          <h2 className="text-xl font-semibold mb-2">ファイルを選択</h2>
          <p className="text-gray-400 mb-4">
            写真や動画ファイルを選択してください
          </p>
          <button
            onClick={handleSelectFiles}
            className="inline-flex items-center px-6 py-3 bg-primary-600 hover:bg-primary-700 text-white font-medium rounded-lg transition-colors"
          >
            <FolderOpenIcon className="w-5 h-5 mr-2" />
            ファイルを選択
          </button>
        </div>

        {/* Statistics */}
        {files.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="bg-gray-800 p-6 rounded-lg">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">総ファイル数</p>
                  <p className="text-2xl font-bold">{files.length}</p>
                </div>
                <DocumentIcon className="w-8 h-8 text-gray-600" />
              </div>
            </div>
            <div className="bg-gray-800 p-6 rounded-lg">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">画像ファイル</p>
                  <p className="text-2xl font-bold text-blue-500">
                    {files.filter(f => f.type === 'image').length}
                  </p>
                </div>
                <PhotoIcon className="w-8 h-8 text-blue-600" />
              </div>
            </div>
            <div className="bg-gray-800 p-6 rounded-lg">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">動画ファイル</p>
                  <p className="text-2xl font-bold text-green-500">
                    {files.filter(f => f.type === 'video').length}
                  </p>
                </div>
                <VideoCameraIcon className="w-8 h-8 text-green-600" />
              </div>
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* File List */}
          {files.length > 0 && (
            <div className="lg:col-span-2">
              <div className="bg-gray-800 rounded-lg overflow-hidden">
                <div className="px-6 py-4 border-b border-gray-700">
                  <h3 className="text-lg font-semibold">選択されたファイル</h3>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-gray-700">
                        <th className="text-left px-6 py-3 text-sm font-medium text-gray-400">
                          ファイル名
                        </th>
                        <th className="text-left px-6 py-3 text-sm font-medium text-gray-400">
                          タイプ
                        </th>
                        <th className="text-left px-6 py-3 text-sm font-medium text-gray-400">
                          サイズ
                        </th>
                        <th className="text-left px-6 py-3 text-sm font-medium text-gray-400">
                          操作
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {files.map(file => (
                        <tr key={file.id} className="border-b border-gray-700 hover:bg-gray-750">
                          <td className="px-6 py-4">
                            <div className="flex items-center">
                              {getFileIcon(file.type)}
                              <span className="ml-2 text-sm">{file.name}</span>
                            </div>
                          </td>
                          <td className="px-6 py-4">
                            <span className={`inline-flex px-2 py-1 text-xs rounded-full ${
                              file.type === 'image' ? 'bg-blue-900 text-blue-200' :
                              file.type === 'video' ? 'bg-green-900 text-green-200' :
                              'bg-gray-700 text-gray-300'
                            }`}>
                              {file.type === 'image' ? '画像' :
                               file.type === 'video' ? '動画' : 'その他'}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-sm text-gray-400">
                            {formatFileSize(file.size)}
                          </td>
                          <td className="px-6 py-4">
                            <button
                              onClick={() => handleDelete(file.id)}
                              className="text-red-500 hover:text-red-400"
                            >
                              <TrashIcon className="w-5 h-5" />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* Settings Panel */}
          {files.length > 0 && (
            <div className="lg:col-span-1">
              <div className="bg-gray-800 rounded-lg p-6">
                <h3 className="text-lg font-semibold mb-6">転送設定</h3>
                
                {/* Destination */}
                <div className="mb-6">
                  <h4 className="text-sm font-medium text-gray-400 mb-3">出力先</h4>
                  <div className="space-y-2">
                    <label className="flex items-center p-3 bg-gray-700 rounded-lg cursor-pointer hover:bg-gray-650">
                      <input
                        type="radio"
                        name="destination"
                        value="local"
                        checked={destination === 'local'}
                        onChange={(e) => setDestination(e.target.value)}
                        className="text-primary-600 focus:ring-primary-500"
                      />
                      <ServerIcon className="w-5 h-5 ml-3 mr-2" />
                      <span>ローカルストレージ</span>
                    </label>
                    <label className="flex items-center p-3 bg-gray-700 rounded-lg cursor-pointer hover:bg-gray-650">
                      <input
                        type="radio"
                        name="destination"
                        value="cloud"
                        checked={destination === 'cloud'}
                        onChange={(e) => setDestination(e.target.value)}
                        className="text-primary-600 focus:ring-primary-500"
                      />
                      <CloudIcon className="w-5 h-5 ml-3 mr-2" />
                      <span>クラウドストレージ</span>
                    </label>
                  </div>
                </div>

                {/* Rules */}
                <div className="mb-6">
                  <h4 className="text-sm font-medium text-gray-400 mb-3">整理ルール</h4>
                  <div className="space-y-2">
                    <label className="flex items-center p-3 bg-gray-700 rounded-lg cursor-pointer hover:bg-gray-650">
                      <input
                        type="checkbox"
                        checked={rules.byDate}
                        onChange={(e) => setRules({...rules, byDate: e.target.checked})}
                        className="text-primary-600 focus:ring-primary-500 rounded"
                      />
                      <CalendarDaysIcon className="w-5 h-5 ml-3 mr-2" />
                      <span>日付別に整理</span>
                    </label>
                    <label className="flex items-center p-3 bg-gray-700 rounded-lg cursor-pointer hover:bg-gray-650">
                      <input
                        type="checkbox"
                        checked={rules.byDevice}
                        onChange={(e) => setRules({...rules, byDevice: e.target.checked})}
                        className="text-primary-600 focus:ring-primary-500 rounded"
                      />
                      <DevicePhoneMobileIcon className="w-5 h-5 ml-3 mr-2" />
                      <span>デバイス別に整理</span>
                    </label>
                    <label className="flex items-center p-3 bg-gray-700 rounded-lg cursor-pointer hover:bg-gray-650">
                      <input
                        type="checkbox"
                        checked={rules.detectDuplicates}
                        onChange={(e) => setRules({...rules, detectDuplicates: e.target.checked})}
                        className="text-primary-600 focus:ring-primary-500 rounded"
                      />
                      <MagnifyingGlassIcon className="w-5 h-5 ml-3 mr-2" />
                      <span>重複検出</span>
                    </label>
                  </div>
                </div>

                {/* Process Button */}
                <button
                  onClick={handleProcess}
                  disabled={processing}
                  className="w-full flex items-center justify-center px-6 py-3 bg-primary-600 hover:bg-primary-700 disabled:bg-gray-700 disabled:cursor-not-allowed text-white font-medium rounded-lg transition-colors"
                >
                  {processing ? (
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                  ) : (
                    <>
                      <PlayIcon className="w-5 h-5 mr-2" />
                      処理開始
                    </>
                  )}
                </button>

                {/* Progress Bar */}
                {processing && (
                  <div className="mt-4">
                    <div className="bg-gray-700 rounded-full h-2 overflow-hidden">
                      <div
                        className="bg-gradient-primary h-full transition-all duration-500"
                        style={{ width: `${progress}%` }}
                      ></div>
                    </div>
                    <p className="text-center text-sm text-gray-400 mt-2">
                      {progress}%
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Notifications */}
      <div className="fixed bottom-4 right-4 space-y-2">
        {notifications.map(notification => (
          <Transition
            key={notification.id}
            show={true}
            enter="transform ease-out duration-300 transition"
            enterFrom="translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
            enterTo="translate-y-0 opacity-100 sm:translate-x-0"
            leave="transition ease-in duration-100"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
          >
            <div className={`flex items-center p-4 rounded-lg shadow-lg ${
              notification.type === 'success' ? 'bg-green-800' : 'bg-red-800'
            }`}>
              {notification.type === 'success' ? (
                <CheckCircleIcon className="w-5 h-5 mr-2" />
              ) : (
                <XMarkIcon className="w-5 h-5 mr-2" />
              )}
              <span className="text-sm">{notification.message}</span>
            </div>
          </Transition>
        ))}
      </div>
    </div>
  );
}

export default App;