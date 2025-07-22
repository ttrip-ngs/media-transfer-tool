import { useState } from 'react';
import { invoke } from '@tauri-apps/api/tauri';
import { open } from '@tauri-apps/api/dialog';
import './App.css';

interface FileInfo {
  name: string;
  size: number;
  path: string;
  type: string;
}

function App() {
  const [files, setFiles] = useState<FileInfo[]>([]);
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState(0);

  const selectFiles = async () => {
    try {
      const selected = await open({
        multiple: true,
        filters: [
          {
            name: 'Media Files',
            extensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi', 'mkv']
          }
        ]
      });

      if (selected) {
        const fileArray = Array.isArray(selected) ? selected : [selected];
        const fileInfos = await Promise.all(
          fileArray.map(async (path) => {
            const stats = await invoke('get_file_info', { path }) as { size: number };
            return {
              name: path.split('/').pop() || path.split('\\').pop() || 'unknown',
              size: stats.size,
              path,
              type: path.split('.').pop() || 'unknown'
            };
          })
        );
        setFiles(fileInfos);
      }
    } catch (error) {
      console.error('Error selecting files:', error);
    }
  };

  const processFiles = async () => {
    setProcessing(true);
    setProgress(0);

    try {
      for (let i = 0; i < files.length; i++) {
        await invoke('process_file', { path: files[i].path });
        setProgress(((i + 1) / files.length) * 100);
        await new Promise(resolve => setTimeout(resolve, 500)); // シミュレーション
      }
    } catch (error) {
      console.error('Error processing files:', error);
    } finally {
      setProcessing(false);
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>📷 Media Transfer Tool - Tauri</h1>
        <p>写真・動画ファイルを整理・転送するツール</p>
      </header>

      <main className="app-main">
        <div className="file-selection">
          <button onClick={selectFiles} className="select-button">
            📁 ファイルを選択
          </button>
          <p className="file-count">
            {files.length > 0 ? `${files.length} 件のファイルが選択されています` : 'ファイルが選択されていません'}
          </p>
        </div>

        {files.length > 0 && (
          <div className="file-list">
            <h3>選択されたファイル</h3>
            <div className="file-items">
              {files.map((file, index) => (
                <div key={index} className="file-item">
                  <div className="file-icon">
                    {file.type === 'mp4' || file.type === 'mov' || file.type === 'avi' ? '🎬' : '📷'}
                  </div>
                  <div className="file-info">
                    <div className="file-name">{file.name}</div>
                    <div className="file-details">
                      {formatFileSize(file.size)} • {file.type.toUpperCase()}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="processing-section">
          <div className="destination-selection">
            <h3>出力先設定</h3>
            <div className="destination-options">
              <label>
                <input type="radio" name="destination" value="local" defaultChecked />
                💾 ローカルストレージ
              </label>
              <label>
                <input type="radio" name="destination" value="dropbox" />
                ☁️ Dropbox
              </label>
              <label>
                <input type="radio" name="destination" value="onedrive" />
                ☁️ OneDrive
              </label>
            </div>
          </div>

          <div className="organization-rules">
            <h3>整理ルール</h3>
            <div className="rule-options">
              <label>
                <input type="checkbox" defaultChecked />
                📅 日付別フォルダ作成
              </label>
              <label>
                <input type="checkbox" />
                📱 デバイス別フォルダ作成
              </label>
              <label>
                <input type="checkbox" defaultChecked />
                🔍 重複ファイル検出
              </label>
            </div>
          </div>

          {files.length > 0 && (
            <div className="process-controls">
              <button 
                onClick={processFiles} 
                disabled={processing}
                className="process-button"
              >
                {processing ? '処理中...' : '🚀 処理を開始'}
              </button>
              
              {processing && (
                <div className="progress-bar">
                  <div 
                    className="progress-fill" 
                    style={{ width: `${progress}%` }}
                  />
                  <span className="progress-text">{Math.round(progress)}%</span>
                </div>
              )}
            </div>
          )}
        </div>
      </main>

      <footer className="app-footer">
        <p>⚡ Powered by Tauri + React + Rust</p>
      </footer>
    </div>
  );
}

export default App;