import 'package:flutter/foundation.dart';
import '../models/media_file.dart';

enum FolderType {
  standard,      // 通常のフォルダ
  smart,         // スマートフォルダ（動的フィルタ）
  collection,    // コレクション（手動選択）
  device,        // デバイス
  date,          // 日付ベース
}

class FolderNode {
  final String id;
  final String name;
  final String path;
  final FolderType type;
  final IconData? icon;
  final List<FolderNode> children;
  final Map<String, dynamic> metadata;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  int fileCount;
  bool isExpanded;
  bool isSelected;
  
  FolderNode({
    required this.id,
    required this.name,
    required this.path,
    this.type = FolderType.standard,
    this.icon,
    List<FolderNode>? children,
    Map<String, dynamic>? metadata,
    this.createdDate,
    this.modifiedDate,
    this.fileCount = 0,
    this.isExpanded = false,
    this.isSelected = false,
  }) : children = children ?? [],
       metadata = metadata ?? {};
  
  // 子フォルダを追加
  void addChild(FolderNode child) {
    children.add(child);
  }
  
  // 子フォルダを削除
  void removeChild(String childId) {
    children.removeWhere((node) => node.id == childId);
  }
  
  // 再帰的にフォルダを検索
  FolderNode? findNode(String nodeId) {
    if (id == nodeId) return this;
    
    for (final child in children) {
      final found = child.findNode(nodeId);
      if (found != null) return found;
    }
    
    return null;
  }
  
  // フォルダツリーをフラット化
  List<FolderNode> flatten() {
    final result = <FolderNode>[this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }
  
  // ファイル数を再帰的に計算
  int getTotalFileCount() {
    int total = fileCount;
    for (final child in children) {
      total += child.getTotalFileCount();
    }
    return total;
  }
  
  FolderNode copyWith({
    String? id,
    String? name,
    String? path,
    FolderType? type,
    IconData? icon,
    List<FolderNode>? children,
    Map<String, dynamic>? metadata,
    DateTime? createdDate,
    DateTime? modifiedDate,
    int? fileCount,
    bool? isExpanded,
    bool? isSelected,
  }) {
    return FolderNode(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      children: children ?? List.from(this.children),
      metadata: metadata ?? Map.from(this.metadata),
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      fileCount: fileCount ?? this.fileCount,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// スマートフォルダのフィルタ条件
class SmartFolderFilter {
  final String field;          // フィルタ対象フィールド
  final String operator;        // 演算子（equals, contains, greater, less, etc.）
  final dynamic value;          // 比較値
  final String? logicalOperator; // AND/OR（複数条件の場合）
  
  SmartFolderFilter({
    required this.field,
    required this.operator,
    required this.value,
    this.logicalOperator,
  });
  
  // フィルタ条件を評価
  bool evaluate(MediaFile file) {
    switch (field) {
      case 'type':
        return _evaluateType(file);
      case 'size':
        return _evaluateSize(file);
      case 'date':
        return _evaluateDate(file);
      case 'name':
        return _evaluateName(file);
      case 'extension':
        return _evaluateExtension(file);
      default:
        return false;
    }
  }
  
  bool _evaluateType(MediaFile file) {
    if (operator == 'equals') {
      return file.type.toString() == value.toString();
    }
    return false;
  }
  
  bool _evaluateSize(MediaFile file) {
    final fileSize = file.size;
    final compareSize = value is int ? value : int.tryParse(value.toString()) ?? 0;
    
    switch (operator) {
      case 'greater':
        return fileSize > compareSize;
      case 'less':
        return fileSize < compareSize;
      case 'equals':
        return fileSize == compareSize;
      default:
        return false;
    }
  }
  
  bool _evaluateDate(MediaFile file) {
    if (file.createdDate == null) return false;
    
    final fileDate = file.createdDate!;
    final compareDate = value is DateTime ? value : DateTime.tryParse(value.toString());
    
    if (compareDate == null) return false;
    
    switch (operator) {
      case 'after':
        return fileDate.isAfter(compareDate);
      case 'before':
        return fileDate.isBefore(compareDate);
      case 'equals':
        return fileDate.year == compareDate.year &&
               fileDate.month == compareDate.month &&
               fileDate.day == compareDate.day;
      default:
        return false;
    }
  }
  
  bool _evaluateName(MediaFile file) {
    final fileName = file.name.toLowerCase();
    final compareValue = value.toString().toLowerCase();
    
    switch (operator) {
      case 'contains':
        return fileName.contains(compareValue);
      case 'equals':
        return fileName == compareValue;
      case 'starts':
        return fileName.startsWith(compareValue);
      case 'ends':
        return fileName.endsWith(compareValue);
      default:
        return false;
    }
  }
  
  bool _evaluateExtension(MediaFile file) {
    final fileExt = file.extension.toLowerCase();
    final compareExt = value.toString().toLowerCase();
    
    if (operator == 'equals') {
      return fileExt == compareExt;
    }
    return false;
  }
}

// スマートフォルダ
class SmartFolder extends FolderNode {
  final List<SmartFolderFilter> filters;
  final String description;
  
  SmartFolder({
    required String id,
    required String name,
    required this.filters,
    this.description = '',
    IconData? icon,
    Map<String, dynamic>? metadata,
  }) : super(
    id: id,
    name: name,
    path: '',
    type: FolderType.smart,
    icon: icon,
    metadata: metadata,
  );
  
  // フィルタに基づいてファイルを評価
  bool matchesFile(MediaFile file) {
    if (filters.isEmpty) return true;
    
    bool result = filters.first.evaluate(file);
    
    for (int i = 1; i < filters.length; i++) {
      final filter = filters[i];
      final matches = filter.evaluate(file);
      
      if (filter.logicalOperator == 'AND') {
        result = result && matches;
      } else if (filter.logicalOperator == 'OR') {
        result = result || matches;
      }
    }
    
    return result;
  }
  
  // フィルタに基づいてファイルリストを取得
  List<MediaFile> getMatchingFiles(List<MediaFile> allFiles) {
    return allFiles.where((file) => matchesFile(file)).toList();
  }
}

// コレクション（手動で選択したファイルグループ）
class Collection extends FolderNode {
  final List<String> fileIds;
  final String description;
  final String? coverImagePath;
  
  Collection({
    required String id,
    required String name,
    required this.fileIds,
    this.description = '',
    this.coverImagePath,
    IconData? icon,
    Map<String, dynamic>? metadata,
    DateTime? createdDate,
    DateTime? modifiedDate,
  }) : super(
    id: id,
    name: name,
    path: '',
    type: FolderType.collection,
    icon: icon,
    metadata: metadata,
    createdDate: createdDate,
    modifiedDate: modifiedDate,
    fileCount: fileIds.length,
  );
  
  // ファイルを追加
  void addFile(String fileId) {
    if (!fileIds.contains(fileId)) {
      fileIds.add(fileId);
      fileCount = fileIds.length;
    }
  }
  
  // ファイルを削除
  void removeFile(String fileId) {
    fileIds.remove(fileId);
    fileCount = fileIds.length;
  }
  
  // ファイルが含まれているか確認
  bool containsFile(String fileId) {
    return fileIds.contains(fileId);
  }
  
  // コレクション内のファイルを取得
  List<MediaFile> getFiles(List<MediaFile> allFiles) {
    return allFiles.where((file) => fileIds.contains(file.id)).toList();
  }
}