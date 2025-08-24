import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/folder_structure.dart';
import '../models/media_file.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class FolderProvider extends ChangeNotifier {
  FolderNode? _rootNode;
  final List<SmartFolder> _smartFolders = [];
  final List<Collection> _collections = [];
  String? _selectedFolderId;
  final Map<String, List<MediaFile>> _folderFiles = {};
  
  FolderNode? get rootNode => _rootNode;
  List<SmartFolder> get smartFolders => _smartFolders;
  List<Collection> get collections => _collections;
  String? get selectedFolderId => _selectedFolderId;
  
  FolderProvider() {
    _initializeDefaultStructure();
  }
  
  // デフォルトのフォルダ構造を初期化
  void _initializeDefaultStructure() {
    _rootNode = FolderNode(
      id: 'root',
      name: 'ライブラリ',
      path: '/',
      type: FolderType.standard,
      icon: Icons.photo_library,
      isExpanded: true,
    );
    
    // 基本フォルダを追加
    _rootNode!.addChild(FolderNode(
      id: 'all-photos',
      name: 'すべての写真',
      path: '/all-photos',
      type: FolderType.standard,
      icon: Icons.photo,
    ));
    
    _rootNode!.addChild(FolderNode(
      id: 'recent',
      name: '最近のインポート',
      path: '/recent',
      type: FolderType.date,
      icon: Icons.access_time,
    ));
    
    // デフォルトのスマートフォルダを作成
    _createDefaultSmartFolders();
    
    notifyListeners();
  }
  
  // デフォルトのスマートフォルダを作成
  void _createDefaultSmartFolders() {
    // 大きな画像フォルダ
    _smartFolders.add(SmartFolder(
      id: 'smart-large-images',
      name: '高解像度画像',
      filters: [
        SmartFolderFilter(
          field: 'type',
          operator: 'equals',
          value: MediaType.image,
        ),
        SmartFolderFilter(
          field: 'size',
          operator: 'greater',
          value: 5 * 1024 * 1024, // 5MB以上
          logicalOperator: 'AND',
        ),
      ],
      description: '5MB以上の画像ファイル',
      icon: Icons.high_quality,
    ));
    
    // 今週の写真
    _smartFolders.add(SmartFolder(
      id: 'smart-this-week',
      name: '今週の写真',
      filters: [
        SmartFolderFilter(
          field: 'date',
          operator: 'after',
          value: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ],
      description: '過去7日間にインポートされた写真',
      icon: Icons.calendar_today,
    ));
    
    // 動画のみ
    _smartFolders.add(SmartFolder(
      id: 'smart-videos',
      name: '動画',
      filters: [
        SmartFolderFilter(
          field: 'type',
          operator: 'equals',
          value: MediaType.video,
        ),
      ],
      description: 'すべての動画ファイル',
      icon: Icons.videocam,
    ));
    
    // RAWファイル
    _smartFolders.add(SmartFolder(
      id: 'smart-raw',
      name: 'RAWファイル',
      filters: [
        SmartFolderFilter(
          field: 'type',
          operator: 'equals',
          value: MediaType.raw,
        ),
      ],
      description: 'RAW形式の画像ファイル',
      icon: Icons.camera,
    ));
  }
  
  // フォルダを選択
  void selectFolder(String folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }
  
  // フォルダを追加
  void addFolder(FolderNode folder, String? parentId) {
    if (parentId == null) {
      _rootNode?.addChild(folder);
    } else {
      final parent = _rootNode?.findNode(parentId);
      parent?.addChild(folder);
    }
    notifyListeners();
  }
  
  // フォルダを削除
  void removeFolder(String folderId) {
    if (_rootNode != null) {
      _removeFolderRecursive(_rootNode!, folderId);
      notifyListeners();
    }
  }
  
  void _removeFolderRecursive(FolderNode node, String folderId) {
    node.removeChild(folderId);
    for (final child in node.children) {
      _removeFolderRecursive(child, folderId);
    }
  }
  
  // フォルダ名を変更
  void renameFolder(String folderId, String newName) {
    final folder = _rootNode?.findNode(folderId);
    if (folder != null) {
      final updatedFolder = folder.copyWith(name: newName);
      final parent = _findParentNode(_rootNode!, folderId);
      if (parent != null) {
        parent.removeChild(folderId);
        parent.addChild(updatedFolder);
        notifyListeners();
      }
    }
  }
  
  FolderNode? _findParentNode(FolderNode node, String childId) {
    for (final child in node.children) {
      if (child.id == childId) {
        return node;
      }
      final found = _findParentNode(child, childId);
      if (found != null) return found;
    }
    return null;
  }
  
  // フォルダの展開状態を切り替え
  void toggleFolderExpanded(String folderId) {
    final folder = _rootNode?.findNode(folderId);
    if (folder != null) {
      folder.isExpanded = !folder.isExpanded;
      notifyListeners();
    }
  }
  
  // スマートフォルダを追加
  void addSmartFolder(SmartFolder smartFolder) {
    _smartFolders.add(smartFolder);
    notifyListeners();
  }
  
  // スマートフォルダを削除
  void removeSmartFolder(String smartFolderId) {
    _smartFolders.removeWhere((folder) => folder.id == smartFolderId);
    notifyListeners();
  }
  
  // スマートフォルダを更新
  void updateSmartFolder(String smartFolderId, SmartFolder updatedFolder) {
    final index = _smartFolders.indexWhere((folder) => folder.id == smartFolderId);
    if (index != -1) {
      _smartFolders[index] = updatedFolder;
      notifyListeners();
    }
  }
  
  // コレクションを作成
  void createCollection(String name, {
    String? description,
    List<String>? initialFileIds,
    String? coverImagePath,
  }) {
    final collection = Collection(
      id: 'collection-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      fileIds: initialFileIds ?? [],
      description: description ?? '',
      coverImagePath: coverImagePath,
      icon: Icons.collections,
      createdDate: DateTime.now(),
      modifiedDate: DateTime.now(),
    );
    
    _collections.add(collection);
    notifyListeners();
  }
  
  // コレクションを削除
  void removeCollection(String collectionId) {
    _collections.removeWhere((collection) => collection.id == collectionId);
    notifyListeners();
  }
  
  // コレクションにファイルを追加
  void addFileToCollection(String collectionId, String fileId) {
    final collection = _collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => throw Exception('Collection not found'),
    );
    
    collection.addFile(fileId);
    notifyListeners();
  }
  
  // コレクションからファイルを削除
  void removeFileFromCollection(String collectionId, String fileId) {
    final collection = _collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => throw Exception('Collection not found'),
    );
    
    collection.removeFile(fileId);
    notifyListeners();
  }
  
  // コレクション名を変更
  void renameCollection(String collectionId, String newName) {
    final collection = _collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => throw Exception('Collection not found'),
    );
    
    final index = _collections.indexOf(collection);
    _collections[index] = Collection(
      id: collection.id,
      name: newName,
      fileIds: collection.fileIds,
      description: collection.description,
      coverImagePath: collection.coverImagePath,
      icon: collection.icon,
      metadata: collection.metadata,
      createdDate: collection.createdDate,
      modifiedDate: DateTime.now(),
    );
    
    notifyListeners();
  }
  
  // フォルダ内のファイルを取得
  List<MediaFile> getFolderFiles(String folderId, List<MediaFile> allFiles) {
    // スマートフォルダの場合
    final smartFolder = _smartFolders.firstWhere(
      (f) => f.id == folderId,
      orElse: () => SmartFolder(id: '', name: '', filters: []),
    );
    
    if (smartFolder.id.isNotEmpty) {
      return smartFolder.getMatchingFiles(allFiles);
    }
    
    // コレクションの場合
    final collection = _collections.firstWhere(
      (c) => c.id == folderId,
      orElse: () => Collection(id: '', name: '', fileIds: []),
    );
    
    if (collection.id.isNotEmpty) {
      return collection.getFiles(allFiles);
    }
    
    // 標準フォルダの場合
    switch (folderId) {
      case 'all-photos':
        return allFiles;
      case 'recent':
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        return allFiles.where((file) {
          return file.createdDate != null && file.createdDate!.isAfter(cutoff);
        }).toList();
      default:
        return _folderFiles[folderId] ?? [];
    }
  }
  
  // ディレクトリからフォルダ構造を構築
  Future<void> buildFolderStructureFromDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return;
    
    final rootName = path.basename(directoryPath);
    final newRoot = FolderNode(
      id: 'dir-root',
      name: rootName,
      path: directoryPath,
      type: FolderType.standard,
      icon: Icons.folder,
      isExpanded: true,
    );
    
    await _buildFolderRecursive(directory, newRoot);
    
    _rootNode = newRoot;
    notifyListeners();
  }
  
  Future<void> _buildFolderRecursive(Directory dir, FolderNode parentNode) async {
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          final folderName = path.basename(entity.path);
          
          // 隠しフォルダやシステムフォルダをスキップ
          if (folderName.startsWith('.') || folderName.startsWith('\$')) {
            continue;
          }
          
          final childNode = FolderNode(
            id: 'dir-${entity.path.hashCode}',
            name: folderName,
            path: entity.path,
            type: FolderType.standard,
            icon: Icons.folder,
          );
          
          parentNode.addChild(childNode);
          
          // 再帰的に子フォルダを処理
          await _buildFolderRecursive(entity, childNode);
        }
      }
    } catch (e) {
      debugPrint('フォルダ構築エラー: ${dir.path} - $e');
    }
  }
  
  // フォルダ構造をリセット
  void resetFolderStructure() {
    _initializeDefaultStructure();
  }
}