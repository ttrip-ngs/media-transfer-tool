import React, { useState } from 'react';
import './App.css';

const { ipcRenderer } = window.require('electron');

interface FileInfo {
  name: string;
  size: number;
  path: string;
  type: string;
  modified: Date;
}

function App() {
  const [files, setFiles] = useState<FileInfo[]>([]);
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [destination, setDestination] = useState('local');
  const [rules, setRules] = useState({
    dateFolder: true,
    deviceFolder: false,
    duplicateCheck: true
  });

  const selectFiles = async () => {
    try {
      const selectedFiles = await ipcRenderer.invoke('select-files');
      setFiles(selectedFiles);
    } catch (error) {
      console.error('ファイル選択エラー:', error);
    }
  };

  const processFiles = async () => {
    setProcessing(true);
    setProgress(0);

    try {
      for (let i = 0; i < files.length; i++) {
        await ipcRenderer.invoke('process-file', files[i].path);
        setProgress(((i + 1) / files.length) * 100);
      }
      alert('処理が完了しました！');
    } catch (error) {
      console.error('処理エラー:', error);
      alert('処理中にエラーが発生しました。');
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

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    // ドラッグ&ドロップ機能は実装簡略化
    alert('ドラッグ&ドロップ機能は開発中です。「ファイルを選択」ボタンをご利用ください。');
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>📱 Media Transfer Tool - Electron</h1>
        <p>写真・動画ファイルを効率的に整理・転送</p>
      </header>

      <main className="app-main">
        <div className="file-selection-area" onDragOver={handleDragOver} onDrop={handleDrop}>
          <div className="drop-zone">
            <div className="drop-zone-content">
              <div className="drop-icon">📂</div>
              <p>ファイルをドラッグ&ドロップするか、下のボタンをクリック</p>
              <button onClick={selectFiles} className="select-button">
                📁 ファイルを選択
              </button>
            </div>
          </div>
          
          <div className="file-count">
            {files.length > 0 ? (
              <span className="count-badge">{files.length} 件のファイル</span>
            ) : (
              <span className="count-empty">ファイルが選択されていません</span>
            )}
          </div>
        </div>

        <div className="content-grid">
          <div className="file-list-section">
            {files.length > 0 && (
              <div className="file-list">
                <h3>📋 選択されたファイル</h3>
                <div className="file-items">
                  {files.map((file, index) => (
                    <div key={index} className="file-item">
                      <div className="file-type-icon">
                        {['mp4', 'mov', 'avi', 'mkv', 'wmv'].includes(file.type) ? '🎬' : '📸'}
                      </div>
                      <div className="file-details">
                        <div className="file-name">{file.name}</div>
                        <div className="file-meta">
                          <span className="file-size">{formatFileSize(file.size)}</span>
                          <span className="file-type">{file.type.toUpperCase()}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          <div className="settings-section">
            <div className="settings-group">
              <h3>🎯 出力先設定</h3>
              <div className="radio-group">
                <label className="radio-item">
                  <input
                    type="radio"
                    name="destination"
                    value="local"
                    checked={destination === 'local'}
                    onChange={(e) => setDestination(e.target.value)}
                  />
                  <span className="radio-label">💻 ローカルストレージ</span>
                </label>
                <label className="radio-item">
                  <input
                    type="radio"
                    name="destination"
                    value="dropbox"
                    checked={destination === 'dropbox'}
                    onChange={(e) => setDestination(e.target.value)}
                  />
                  <span className="radio-label">☁️ Dropbox</span>
                </label>
                <label className="radio-item">
                  <input
                    type="radio"
                    name="destination"
                    value="onedrive"
                    checked={destination === 'onedrive'}
                    onChange={(e) => setDestination(e.target.value)}
                  />
                  <span className="radio-label">☁️ OneDrive</span>
                </label>
                <label className="radio-item">
                  <input
                    type="radio"
                    name="destination"
                    value="s3"
                    checked={destination === 's3'}
                    onChange={(e) => setDestination(e.target.value)}
                  />
                  <span className="radio-label">🪣 Amazon S3</span>
                </label>
              </div>
            </div>

            <div className="settings-group">
              <h3>⚙️ 整理ルール</h3>
              <div className="checkbox-group">
                <label className="checkbox-item">
                  <input
                    type="checkbox"
                    checked={rules.dateFolder}
                    onChange={(e) => setRules({...rules, dateFolder: e.target.checked})}
                  />
                  <span className="checkbox-label">📅 日付別フォルダ作成</span>
                </label>
                <label className="checkbox-item">
                  <input
                    type="checkbox"
                    checked={rules.deviceFolder}
                    onChange={(e) => setRules({...rules, deviceFolder: e.target.checked})}
                  />
                  <span className="checkbox-label">📱 デバイス別フォルダ作成</span>
                </label>
                <label className="checkbox-item">
                  <input
                    type="checkbox"
                    checked={rules.duplicateCheck}
                    onChange={(e) => setRules({...rules, duplicateCheck: e.target.checked})}
                  />
                  <span className="checkbox-label">🔍 重複ファイル検出</span>
                </label>
              </div>
            </div>
          </div>
        </div>

        {files.length > 0 && (
          <div className="action-section">
            <div className="process-controls">
              <button 
                onClick={processFiles} 
                disabled={processing}
                className="process-button"
              >
                {processing ? '⏳ 処理中...' : '🚀 処理を開始'}
              </button>
              
              {processing && (
                <div className="progress-container">
                  <div className="progress-bar">
                    <div 
                      className="progress-fill" 
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                  <span className="progress-text">{Math.round(progress)}% 完了</span>
                </div>
              )}
            </div>
          </div>
        )}
      </main>

      <footer className="app-footer">
        <p>⚡ Powered by Electron + React + Node.js</p>
      </footer>
    </div>
  );
}

export default App;