import 'package:flutter/foundation.dart';
import '../models/media_file.dart';
import '../services/metadata_extractor.dart';

enum SearchScope {
  fileName,     // ファイル名
  metadata,     // メタデータ
  keywords,     // キーワード
  all,          // すべて
}

enum SortCriteria {
  name,         // 名前順
  date,         // 日付順
  size,         // サイズ順
  type,         // タイプ順
}

enum SortOrder {
  ascending,    // 昇順
  descending,   // 降順
}

class SearchFilter {
  final String? fileNamePattern;
  final MediaType? mediaType;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? sizeMin;
  final int? sizeMax;
  final List<String>? extensions;
  final String? cameraModel;
  final String? keywords;
  final SortCriteria sortCriteria;
  final SortOrder sortOrder;
  
  SearchFilter({
    this.fileNamePattern,
    this.mediaType,
    this.dateFrom,
    this.dateTo,
    this.sizeMin,
    this.sizeMax,
    this.extensions,
    this.cameraModel,
    this.keywords,
    this.sortCriteria = SortCriteria.date,
    this.sortOrder = SortOrder.descending,
  });
  
  SearchFilter copyWith({
    String? fileNamePattern,
    MediaType? mediaType,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? sizeMin,
    int? sizeMax,
    List<String>? extensions,
    String? cameraModel,
    String? keywords,
    SortCriteria? sortCriteria,
    SortOrder? sortOrder,
  }) {
    return SearchFilter(
      fileNamePattern: fileNamePattern ?? this.fileNamePattern,
      mediaType: mediaType ?? this.mediaType,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sizeMin: sizeMin ?? this.sizeMin,
      sizeMax: sizeMax ?? this.sizeMax,
      extensions: extensions ?? this.extensions,
      cameraModel: cameraModel ?? this.cameraModel,
      keywords: keywords ?? this.keywords,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class SearchResult {
  final List<MediaFile> files;
  final int totalFound;
  final Duration searchTime;
  final Map<String, int> typeBreakdown;
  
  SearchResult({
    required this.files,
    required this.totalFound,
    required this.searchTime,
    required this.typeBreakdown,
  });
}

class SearchService {
  static SearchService? _instance;
  static SearchService get instance => _instance ??= SearchService._();
  
  SearchService._();
  
  final Map<String, List<String>> _searchHistory = {};
  final Map<String, SearchFilter> _savedSearches = {};
  
  // 検索を実行
  Future<SearchResult> search(
    List<MediaFile> allFiles,
    String query,
    SearchFilter filter,
    SearchScope scope,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    List<MediaFile> results = List.from(allFiles);
    
    // テキスト検索
    if (query.isNotEmpty) {
      results = await _performTextSearch(results, query, scope);
    }
    
    // フィルター適用
    results = await _applyFilters(results, filter);
    
    // ソート
    results = await _sortResults(results, filter.sortCriteria, filter.sortOrder);
    
    stopwatch.stop();
    
    // タイプ別の集計
    final typeBreakdown = _calculateTypeBreakdown(results);
    
    // 検索履歴に追加
    _addToSearchHistory(query, scope);
    
    return SearchResult(
      files: results,
      totalFound: results.length,
      searchTime: stopwatch.elapsed,
      typeBreakdown: typeBreakdown,
    );
  }
  
  // テキスト検索
  Future<List<MediaFile>> _performTextSearch(
    List<MediaFile> files,
    String query,
    SearchScope scope,
  ) async {
    final results = <MediaFile>[];
    final queryLower = query.toLowerCase();
    
    for (final file in files) {
      bool matches = false;
      
      switch (scope) {
        case SearchScope.fileName:
          matches = file.name.toLowerCase().contains(queryLower);
          break;
          
        case SearchScope.metadata:
          matches = await _searchInMetadata(file, queryLower);
          break;
          
        case SearchScope.keywords:
          matches = await _searchInKeywords(file, queryLower);
          break;
          
        case SearchScope.all:
          matches = file.name.toLowerCase().contains(queryLower) ||
                   await _searchInMetadata(file, queryLower) ||
                   await _searchInKeywords(file, queryLower);
          break;
      }
      
      if (matches) {
        results.add(file);
      }
    }
    
    return results;
  }
  
  // メタデータ内を検索
  Future<bool> _searchInMetadata(MediaFile file, String query) async {
    // TODO: 実際のメタデータ検索を実装
    // 現在は基本的なフィールドのみ検索
    final deviceName = file.deviceName?.toLowerCase() ?? '';
    final path = file.path.toLowerCase();
    
    return deviceName.contains(query) || path.contains(query);
  }
  
  // キーワード内を検索
  Future<bool> _searchInKeywords(MediaFile file, String query) async {
    // TODO: キーワード検索を実装
    return false;
  }
  
  // フィルターを適用
  Future<List<MediaFile>> _applyFilters(
    List<MediaFile> files,
    SearchFilter filter,
  ) async {
    List<MediaFile> results = files;
    
    // メディアタイプフィルター
    if (filter.mediaType != null) {
      results = results.where((f) => f.type == filter.mediaType).toList();
    }
    
    // 日付範囲フィルター
    if (filter.dateFrom != null || filter.dateTo != null) {
      results = results.where((f) {
        if (f.createdDate == null) return false;
        
        if (filter.dateFrom != null && f.createdDate!.isBefore(filter.dateFrom!)) {
          return false;
        }
        
        if (filter.dateTo != null && f.createdDate!.isAfter(filter.dateTo!)) {
          return false;
        }
        
        return true;
      }).toList();
    }
    
    // サイズ範囲フィルター
    if (filter.sizeMin != null || filter.sizeMax != null) {
      results = results.where((f) {
        if (filter.sizeMin != null && f.size < filter.sizeMin!) {
          return false;
        }
        
        if (filter.sizeMax != null && f.size > filter.sizeMax!) {
          return false;
        }
        
        return true;
      }).toList();
    }
    
    // 拡張子フィルター
    if (filter.extensions != null && filter.extensions!.isNotEmpty) {
      final allowedExtensions = filter.extensions!.map((e) => e.toLowerCase()).toSet();
      results = results.where((f) {
        final extension = f.extension.toLowerCase();
        return allowedExtensions.contains(extension);
      }).toList();
    }
    
    // ファイル名パターンフィルター
    if (filter.fileNamePattern != null && filter.fileNamePattern!.isNotEmpty) {
      final pattern = filter.fileNamePattern!.toLowerCase();
      results = results.where((f) {
        return f.name.toLowerCase().contains(pattern);
      }).toList();
    }
    
    return results;
  }
  
  // 結果をソート
  Future<List<MediaFile>> _sortResults(
    List<MediaFile> files,
    SortCriteria criteria,
    SortOrder order,
  ) async {
    final sortedFiles = List<MediaFile>.from(files);
    
    switch (criteria) {
      case SortCriteria.name:
        sortedFiles.sort((a, b) => a.name.compareTo(b.name));
        break;
        
      case SortCriteria.date:
        sortedFiles.sort((a, b) {
          final dateA = a.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateA.compareTo(dateB);
        });
        break;
        
      case SortCriteria.size:
        sortedFiles.sort((a, b) => a.size.compareTo(b.size));
        break;
        
      case SortCriteria.type:
        sortedFiles.sort((a, b) => a.type.toString().compareTo(b.type.toString()));
        break;
    }
    
    if (order == SortOrder.descending) {
      return sortedFiles.reversed.toList();
    }
    
    return sortedFiles;
  }
  
  // タイプ別集計
  Map<String, int> _calculateTypeBreakdown(List<MediaFile> files) {
    final breakdown = <String, int>{};
    
    for (final file in files) {
      final typeName = _getTypeDisplayName(file.type);
      breakdown[typeName] = (breakdown[typeName] ?? 0) + 1;
    }
    
    return breakdown;
  }
  
  String _getTypeDisplayName(MediaType type) {
    switch (type) {
      case MediaType.image:
        return '画像';
      case MediaType.video:
        return '動画';
      case MediaType.raw:
        return 'RAW';
      case MediaType.other:
        return 'その他';
    }
  }
  
  // 検索履歴に追加
  void _addToSearchHistory(String query, SearchScope scope) {
    if (query.isEmpty) return;
    
    final scopeKey = scope.toString();
    _searchHistory.putIfAbsent(scopeKey, () => []);
    
    // 重複を削除
    _searchHistory[scopeKey]!.remove(query);
    
    // 先頭に追加
    _searchHistory[scopeKey]!.insert(0, query);
    
    // 最大20件まで保持
    if (_searchHistory[scopeKey]!.length > 20) {
      _searchHistory[scopeKey] = _searchHistory[scopeKey]!.take(20).toList();
    }
  }
  
  // 検索履歴を取得
  List<String> getSearchHistory(SearchScope scope) {
    return _searchHistory[scope.toString()] ?? [];
  }
  
  // 検索履歴をクリア
  void clearSearchHistory(SearchScope scope) {
    _searchHistory.remove(scope.toString());
  }
  
  // 保存された検索を追加
  void saveSearch(String name, SearchFilter filter, String query, SearchScope scope) {
    _savedSearches[name] = filter;
    // TODO: 永続化
  }
  
  // 保存された検索を取得
  Map<String, SearchFilter> getSavedSearches() {
    return Map.from(_savedSearches);
  }
  
  // 保存された検索を削除
  void removeSavedSearch(String name) {
    _savedSearches.remove(name);
    // TODO: 永続化
  }
  
  // 類似ファイルを検索（重複検出）
  Future<List<MediaFile>> findSimilarFiles(
    MediaFile targetFile,
    List<MediaFile> allFiles, {
    bool byName = true,
    bool bySize = true,
    bool byDate = false,
    double sizeTolerance = 0.1, // 10%の誤差を許容
  }) async {
    final similar = <MediaFile>[];
    
    for (final file in allFiles) {
      if (file.id == targetFile.id) continue;
      
      bool isSimilar = false;
      
      // ファイル名での比較
      if (byName) {
        final similarity = _calculateNameSimilarity(targetFile.name, file.name);
        if (similarity > 0.8) {
          isSimilar = true;
        }
      }
      
      // サイズでの比較
      if (bySize) {
        final sizeDiff = (targetFile.size - file.size).abs() / targetFile.size;
        if (sizeDiff <= sizeTolerance) {
          isSimilar = true;
        }
      }
      
      // 日付での比較
      if (byDate && targetFile.createdDate != null && file.createdDate != null) {
        final timeDiff = targetFile.createdDate!.difference(file.createdDate!).abs();
        if (timeDiff.inMinutes <= 5) { // 5分以内
          isSimilar = true;
        }
      }
      
      if (isSimilar) {
        similar.add(file);
      }
    }
    
    return similar;
  }
  
  // ファイル名の類似度を計算
  double _calculateNameSimilarity(String name1, String name2) {
    final a = name1.toLowerCase();
    final b = name2.toLowerCase();
    
    if (a == b) return 1.0;
    
    // レーベンシュタイン距離を使用した簡易類似度計算
    final maxLen = [a.length, b.length].reduce((a, b) => a > b ? a : b);
    final distance = _levenshteinDistance(a, b);
    
    return 1.0 - (distance / maxLen);
  }
  
  // レーベンシュタイン距離
  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[a.length][b.length];
  }
}