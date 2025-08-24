import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/media_file.dart';
import '../services/thumbnail_generator.dart';
import '../services/metadata_extractor.dart';
import '../services/database_service.dart';
import 'dart:math';
import 'dart:io';
import 'package:path/path.dart' as path;

enum ProcessingStatus { idle, processing, completed, error }

class MediaProvider extends ChangeNotifier {
  final List<MediaFile> _files = [];
  final List<MediaFile> _selectedFiles = [];
  final Map<String, List<MediaFile>> _filesByFolder = {};
  final Map<String, MediaMetadata?> _metadataCache = {};
  final List<String> _connectedDevices = [];
  ProcessingStatus _status = ProcessingStatus.idle;
  double _progress = 0.0;
  String _destination = 'local';
  String _currentFolder = 'すべての写真';
  bool _organizeByDate = true;
  bool _organizeByDevice = false;
  bool _detectDuplicates = true;
  bool _isImporting = false;
  bool _isInitialized = false;
  
  MediaProvider() {
    _initializeDatabase();
  }
  
  List<MediaFile> get files => _files;
  List<MediaFile> get selectedFiles => _selectedFiles;
  Map<String, List<MediaFile>> get filesByFolder => _filesByFolder;
  Map<String, MediaMetadata?> get metadataCache => _metadataCache;
  List<String> get connectedDevices => _connectedDevices;
  ProcessingStatus get status => _status;
  double get progress => _progress;
  String get destination => _destination;
  String get currentFolder => _currentFolder;
  bool get organizeByDate => _organizeByDate;
  bool get organizeByDevice => _organizeByDevice;
  bool get detectDuplicates => _detectDuplicates;
  bool get isImporting => _isImporting;
  
  MediaMetadata? getMetadata(String fileId) => _metadataCache[fileId];
  bool get isInitialized => _isInitialized;
  
  int get totalFiles => _files.length;
  int get imageCount => _files.where((f) => f.type == MediaType.image).length;
  int get videoCount => _files.where((f) => f.type == MediaType.video).length;
  
  Future<void> _initializeDatabase() async {
    try {
      await DatabaseService.instance.database;
      await _loadFilesFromDatabase();
      _isInitialized = true;
      notifyListeners();
      debugPrint('データベース初期化完了');
    } catch (e) {
      debugPrint('データベース初期化エラー: $e');
    }
  }
  
  Future<void> _loadFilesFromDatabase() async {
    try {
      final dbFiles = await DatabaseService.instance.getAllMediaFiles();
      _files.clear();
      _files.addAll(dbFiles);
      
      // メタデータをキャッシュに読み込み
      for (final file in dbFiles) {
        final metadata = await DatabaseService.instance.getMediaMetadata(file.id);
        if (metadata != null) {
          _metadataCache[file.id] = metadata;
        }
      }
      
      _organizeFilesByFolder();
      notifyListeners();
      debugPrint('データベースから${_files.length}件のファイルを読み込みました');
    } catch (e) {
      debugPrint('データベースからのファイル読み込みエラー: $e');
    }
  }
  
  Future<void> refreshFromDatabase() async {
    await _loadFilesFromDatabase();
  }
  
  Future<void> selectFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif',
                            'mp4', 'mov', 'avi', 'mkv', 'wmv', 'm4v', 'flv',
                            'cr2', 'cr3', 'raw', 'nef', 'arw', 'dng'],
      );
      
      if (result != null) {
        await _importFiles(result.files);
      }
    } catch (e) {
      debugPrint('ファイル選択エラー: $e');
    }
  }
  
  Future<void> selectFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        await _importFromDirectory(selectedDirectory);
      }
    } catch (e) {
      debugPrint('フォルダ選択エラー: $e');
    }
  }
  
  Future<void> _importFiles(List<PlatformFile> platformFiles) async {
    _isImporting = true;
    _progress = 0.0;
    notifyListeners();
    
    final newFiles = <MediaFile>[];
    final totalFiles = platformFiles.length;
    
    // ファイル情報を収集
    for (int i = 0; i < platformFiles.length; i++) {
      final file = platformFiles[i];
      if (file.path != null) {
        final fileInfo = File(file.path!);
        final stat = await fileInfo.stat();
        
        final mediaFile = MediaFile(
          id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString(),
          path: file.path!,
          name: file.name,
          size: file.size,
          type: MediaFile.getTypeFromPath(file.path!),
          createdDate: stat.modified,
          deviceName: 'ローカルデバイス',
        );
        
        newFiles.add(mediaFile);
      }
      
      // ファイル情報収集進捗を更新（30%まで）
      _progress = (i + 1) / totalFiles * 0.3;
      notifyListeners();
    }
    
    _files.addAll(newFiles);
    
    // データベースに保存
    try {
      await DatabaseService.instance.insertMediaFiles(newFiles);
      debugPrint('${newFiles.length}件のファイルをデータベースに保存しました');
    } catch (e) {
      debugPrint('データベース保存エラー: $e');
    }
    
    _organizeFolders();
    
    // サムネイルを並列生成
    await _generateThumbnailsInBackground(newFiles);
    
    _isImporting = false;
    _progress = 1.0;
    notifyListeners();
  }
  
  Future<void> _generateThumbnailsInBackground(List<MediaFile> files) async {
    final thumbnailGenerator = ThumbnailGenerator.instance;
    final metadataExtractor = MetadataExtractor.instance;
    
    for (int i = 0; i < files.length; i++) {
      if (!_isImporting) break; // キャンセルされた場合
      
      final file = files[i];
      try {
        // サムネイル生成
        final thumbnailFile = await thumbnailGenerator.generateThumbnail(file);
        
        // MediaFileオブジェクトを更新
        final index = _files.indexWhere((f) => f.id == file.id);
        if (index >= 0) {
          _files[index].thumbnailFile = thumbnailFile;
        }
        
        // メタデータ抽出
        final metadata = await metadataExtractor.extractMetadata(file);
        _metadataCache[file.id] = metadata;
        
        // メタデータをデータベースに保存
        if (metadata != null) {
          try {
            await DatabaseService.instance.insertMediaFile(file, metadata);
          } catch (e) {
            debugPrint('メタデータ保存エラー: $e');
          }
        }
        
        // サムネイル生成進捗を更新（30%〜100%）
        _progress = 0.3 + (i + 1) / files.length * 0.7;
        notifyListeners();
        
        // CPU負荷を軽減
        if (i % 3 == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        debugPrint('サムネイル/メタデータ処理エラー: ${file.path} - $e');
      }
    }
  }
  
  Future<void> _importFromDirectory(String directoryPath) async {
    _isImporting = true;
    _progress = 0.0;
    notifyListeners();
    
    final directory = Directory(directoryPath);
    final supportedExtensions = [
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif',
      'mp4', 'mov', 'avi', 'mkv', 'wmv', 'm4v', 'flv',
      'cr2', 'cr3', 'raw', 'nef', 'arw', 'dng'
    ];
    
    // ファイル一覧を取得
    final allFiles = <File>[];
    await for (var entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase().replaceAll('.', '');
        if (supportedExtensions.contains(extension)) {
          allFiles.add(entity);
        }
      }
    }
    
    final totalFiles = allFiles.length;
    final newFiles = <MediaFile>[];
    
    // ファイル情報を収集
    for (int i = 0; i < allFiles.length; i++) {
      final entity = allFiles[i];
      final stat = await entity.stat();
      
      final mediaFile = MediaFile(
        id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString(),
        path: entity.path,
        name: path.basename(entity.path),
        size: stat.size,
        type: MediaFile.getTypeFromPath(entity.path),
        createdDate: stat.modified,
        deviceName: 'ローカルデバイス',
      );
      
      newFiles.add(mediaFile);
      
      // ファイル情報収集進捗を更新（30%まで）
      _progress = (i + 1) / totalFiles * 0.3;
      notifyListeners();
    }
    
    _files.addAll(newFiles);
    _organizeFolders();
    
    // サムネイルを並列生成
    await _generateThumbnailsInBackground(newFiles);
    
    _isImporting = false;
    _progress = 1.0;
    notifyListeners();
  }
  
  void _organizeFolders() {
    _filesByFolder.clear();
    _filesByFolder['すべての写真'] = List.from(_files);
    
    // 年別に整理
    for (var file in _files) {
      if (file.createdDate != null) {
        final year = '${file.createdDate!.year}年';
        _filesByFolder.putIfAbsent(year, () => []).add(file);
      }
    }
    
    // 最近のインポート
    final now = DateTime.now();
    final recentFiles = _files.where((file) {
      if (file.createdDate != null) {
        return now.difference(file.createdDate!).inDays <= 7;
      }
      return false;
    }).toList();
    if (recentFiles.isNotEmpty) {
      _filesByFolder['最近のインポート'] = recentFiles;
    }
  }
  
  void toggleFileSelection(MediaFile file) {
    if (_selectedFiles.contains(file)) {
      _selectedFiles.remove(file);
    } else {
      _selectedFiles.add(file);
    }
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedFiles.clear();
    notifyListeners();
  }
  
  void selectAll() {
    _selectedFiles.clear();
    _selectedFiles.addAll(_files);
    notifyListeners();
  }
  
  Future<void> removeFile(String id) async {
    // データベースから削除
    try {
      await DatabaseService.instance.deleteMediaFile(id);
    } catch (e) {
      debugPrint('データベース削除エラー: $e');
    }
    
    _files.removeWhere((file) => file.id == id);
    _selectedFiles.removeWhere((file) => file.id == id);
    _metadataCache.remove(id);
    _organizeFolders();
    notifyListeners();
  }
  
  Future<void> removeSelectedFiles() async {
    final idsToDelete = _selectedFiles.map((f) => f.id).toList();
    
    // データベースから削除
    try {
      await DatabaseService.instance.deleteMediaFiles(idsToDelete);
    } catch (e) {
      debugPrint('データベース一括削除エラー: $e');
    }
    
    for (var file in _selectedFiles) {
      _files.removeWhere((f) => f.id == file.id);
      _metadataCache.remove(file.id);
    }
    _selectedFiles.clear();
    _organizeFolders();
    notifyListeners();
  }
  
  void clearFiles() {
    _files.clear();
    _selectedFiles.clear();
    _filesByFolder.clear();
    _metadataCache.clear();
    _progress = 0.0;
    _status = ProcessingStatus.idle;
    notifyListeners();
  }
  
  void setCurrentFolder(String folder) {
    _currentFolder = folder;
    notifyListeners();
  }
  
  List<MediaFile> getCurrentFolderFiles() {
    return _filesByFolder[_currentFolder] ?? [];
  }
  
  Future<void> detectDevices() async {
    _connectedDevices.clear();
    _connectedDevices.add('ローカルデバイス');
    
    // Windows向けのドライブ検出
    if (Platform.isWindows) {
      try {
        // WMICでリムーバブルドライブを検出
        final driveInfo = await Process.run('wmic', [
          'logicaldisk', 'where', 'drivetype=2', 'get', 'deviceid,volumename'
        ]).timeout(const Duration(seconds: 3));
        
        final output = driveInfo.stdout.toString();
        final lines = output.split('\n');
        
        for (var line in lines) {
          final deviceId = RegExp(r'([A-Z]:)').firstMatch(line);
          if (deviceId != null) {
            final drive = deviceId.group(1)!;
            try {
              if (await Directory('$drive\\').exists()) {
                _connectedDevices.add('リムーバブルドライブ ($drive)');
              }
            } catch (e) {
              debugPrint('ドライブ $drive へのアクセスエラー: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('デバイス検出エラー: $e');
        // フォールバック: 基本的なドライブをチェック
        for (var letter in ['D', 'E', 'F', 'G', 'H']) {
          try {
            final drive = '$letter:\\';
            if (await Directory(drive).exists()) {
              _connectedDevices.add('ドライブ $letter:');
            }
          } catch (e) {
            // ドライブにアクセスできない場合は無視
          }
        }
      }
    }
    
    // その他のプラットフォーム
    if (Platform.isMacOS) {
      try {
        final volumesDir = Directory('/Volumes');
        if (await volumesDir.exists()) {
          await for (var entity in volumesDir.list()) {
            if (entity is Directory) {
              final name = path.basename(entity.path);
              if (name != '.') {
                _connectedDevices.add('ボリューム: $name');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('macOSデバイス検出エラー: $e');
      }
    }
    
    notifyListeners();
  }
  
  void setDestination(String destination) {
    _destination = destination;
    notifyListeners();
  }
  
  void setOrganizeByDate(bool value) {
    _organizeByDate = value;
    notifyListeners();
  }
  
  void setOrganizeByDevice(bool value) {
    _organizeByDevice = value;
    notifyListeners();
  }
  
  void setDetectDuplicates(bool value) {
    _detectDuplicates = value;
    notifyListeners();
  }
  
  Future<void> processFiles() async {
    _status = ProcessingStatus.processing;
    _progress = 0.0;
    notifyListeners();
    
    // シミュレーション
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      _progress = i / 100;
      notifyListeners();
    }
    
    _status = ProcessingStatus.completed;
    notifyListeners();
  }
}