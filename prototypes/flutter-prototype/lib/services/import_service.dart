import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/media_file.dart';
import '../services/metadata_extractor.dart';
import 'package:intl/intl.dart';

enum ImportStrategy {
  copy,      // ファイルをコピー
  move,      // ファイルを移動
  reference  // 参照のみ（コピーしない）
}

enum OrganizeStrategy {
  none,       // 整理しない
  byDate,     // 日付別
  byDevice,   // デバイス別
  byType,     // ファイルタイプ別
  custom      // カスタム
}

class ImportOptions {
  final ImportStrategy importStrategy;
  final OrganizeStrategy organizeStrategy;
  final String destinationPath;
  final bool detectDuplicates;
  final bool renameFiles;
  final String fileNamePattern;
  final bool preserveOriginal;
  final bool generatePreviews;
  
  ImportOptions({
    this.importStrategy = ImportStrategy.copy,
    this.organizeStrategy = OrganizeStrategy.byDate,
    required this.destinationPath,
    this.detectDuplicates = true,
    this.renameFiles = false,
    this.fileNamePattern = '{year}-{month}-{day}_{original}',
    this.preserveOriginal = true,
    this.generatePreviews = true,
  });
}

class ImportResult {
  final int totalFiles;
  final int importedFiles;
  final int skippedFiles;
  final int failedFiles;
  final List<String> errors;
  final Map<String, String> importedPaths; // 元パス -> 新パス
  
  ImportResult({
    required this.totalFiles,
    required this.importedFiles,
    required this.skippedFiles,
    required this.failedFiles,
    required this.errors,
    required this.importedPaths,
  });
  
  bool get isSuccess => failedFiles == 0 && errors.isEmpty;
  String get summary => 'インポート完了: $importedFiles/$totalFiles ファイル（スキップ: $skippedFiles、失敗: $failedFiles）';
}

class ImportService {
  static ImportService? _instance;
  static ImportService get instance => _instance ??= ImportService._();
  
  ImportService._();
  
  final Map<String, String> _fileHashCache = {};
  bool _isCancelled = false;
  
  // インポート処理をキャンセル
  void cancelImport() {
    _isCancelled = true;
  }
  
  // メディアファイルをインポート
  Future<ImportResult> importFiles(
    List<MediaFile> files,
    ImportOptions options, {
    Function(double progress, String currentFile)? onProgress,
  }) async {
    _isCancelled = false;
    final errors = <String>[];
    final importedPaths = <String, String>{};
    int importedCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    
    // インポート先ディレクトリの準備
    final destDir = Directory(options.destinationPath);
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    
    // 重複チェック用のハッシュマップを構築
    Map<String, String>? existingHashes;
    if (options.detectDuplicates) {
      existingHashes = await _buildHashMap(destDir);
    }
    
    // ファイルをインポート
    for (int i = 0; i < files.length; i++) {
      if (_isCancelled) break;
      
      final file = files[i];
      final sourceFile = File(file.path);
      
      try {
        // 進捗通知
        onProgress?.call((i + 1) / files.length, file.name);
        
        // ファイルが存在するか確認
        if (!await sourceFile.exists()) {
          errors.add('ファイルが見つかりません: ${file.path}');
          failedCount++;
          continue;
        }
        
        // 重複チェック
        if (options.detectDuplicates && existingHashes != null) {
          final hash = await _getFileHash(sourceFile);
          if (existingHashes.containsKey(hash)) {
            debugPrint('重複ファイルをスキップ: ${file.name}');
            skippedCount++;
            continue;
          }
          existingHashes[hash] = file.path;
        }
        
        // インポート先パスを決定
        final destPath = await _determineDestinationPath(
          file,
          options,
          destDir.path,
        );
        
        // ファイルをインポート
        final destFile = File(destPath);
        await destFile.parent.create(recursive: true);
        
        switch (options.importStrategy) {
          case ImportStrategy.copy:
            await sourceFile.copy(destPath);
            break;
          case ImportStrategy.move:
            await sourceFile.rename(destPath);
            break;
          case ImportStrategy.reference:
            // 参照のみの場合は何もしない
            break;
        }
        
        importedPaths[file.path] = destPath;
        importedCount++;
        
      } catch (e) {
        errors.add('インポートエラー (${file.name}): $e');
        failedCount++;
      }
    }
    
    return ImportResult(
      totalFiles: files.length,
      importedFiles: importedCount,
      skippedFiles: skippedCount,
      failedFiles: failedCount,
      errors: errors,
      importedPaths: importedPaths,
    );
  }
  
  // ファイルのハッシュ値を取得
  Future<String> _getFileHash(File file) async {
    // キャッシュチェック
    final key = '${file.path}:${(await file.stat()).modified.millisecondsSinceEpoch}';
    if (_fileHashCache.containsKey(key)) {
      return _fileHashCache[key]!;
    }
    
    // ハッシュ計算（最初の1MBのみ使用して高速化）
    final bytes = await file.openRead(0, 1024 * 1024).fold<List<int>>(
      [],
      (previous, element) => previous..addAll(element),
    );
    
    final hash = sha256.convert(bytes).toString();
    _fileHashCache[key] = hash;
    
    return hash;
  }
  
  // ディレクトリ内のファイルハッシュマップを構築
  Future<Map<String, String>> _buildHashMap(Directory dir) async {
    final hashMap = <String, String>{};
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          final hash = await _getFileHash(entity);
          hashMap[hash] = entity.path;
        } catch (e) {
          debugPrint('ハッシュ計算エラー: ${entity.path}');
        }
      }
    }
    
    return hashMap;
  }
  
  // インポート先のパスを決定
  Future<String> _determineDestinationPath(
    MediaFile file,
    ImportOptions options,
    String baseDestPath,
  ) async {
    String subPath = '';
    
    // 整理戦略に基づいてサブディレクトリを決定
    switch (options.organizeStrategy) {
      case OrganizeStrategy.none:
        subPath = '';
        break;
        
      case OrganizeStrategy.byDate:
        if (file.createdDate != null) {
          final year = file.createdDate!.year.toString();
          final month = file.createdDate!.month.toString().padLeft(2, '0');
          final day = file.createdDate!.day.toString().padLeft(2, '0');
          subPath = path.join(year, '$year-$month-$day');
        }
        break;
        
      case OrganizeStrategy.byDevice:
        subPath = file.deviceName ?? 'Unknown';
        break;
        
      case OrganizeStrategy.byType:
        switch (file.type) {
          case MediaType.image:
            subPath = '画像';
            break;
          case MediaType.video:
            subPath = '動画';
            break;
          case MediaType.raw:
            subPath = 'RAW';
            break;
          case MediaType.other:
            subPath = 'その他';
            break;
        }
        break;
        
      case OrganizeStrategy.custom:
        // カスタム整理（将来の実装用）
        subPath = '';
        break;
    }
    
    // ファイル名を決定
    String fileName;
    if (options.renameFiles) {
      fileName = _generateFileName(file, options.fileNamePattern);
    } else {
      fileName = path.basename(file.path);
    }
    
    // 最終パスを構築
    return path.join(baseDestPath, subPath, fileName);
  }
  
  // パターンに基づいてファイル名を生成
  String _generateFileName(MediaFile file, String pattern) {
    final now = file.createdDate ?? DateTime.now();
    final extension = path.extension(file.path);
    final originalName = path.basenameWithoutExtension(file.path);
    
    String fileName = pattern;
    fileName = fileName.replaceAll('{year}', now.year.toString());
    fileName = fileName.replaceAll('{month}', now.month.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{day}', now.day.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{hour}', now.hour.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{minute}', now.minute.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{second}', now.second.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{original}', originalName);
    fileName = fileName.replaceAll('{type}', file.type.toString().split('.').last);
    
    // カウンターを追加（重複回避）
    if (fileName.contains('{counter}')) {
      fileName = fileName.replaceAll('{counter}', '001');
    }
    
    return fileName + extension;
  }
  
  // デフォルトのインポート先ディレクトリを取得
  Future<String> getDefaultImportDirectory() async {
    if (Platform.isWindows) {
      // Windowsの場合はピクチャフォルダを使用
      final picturesPath = Platform.environment['USERPROFILE'];
      if (picturesPath != null) {
        return path.join(picturesPath, 'Pictures', 'MediaTransfer');
      }
    } else if (Platform.isMacOS) {
      // macOSの場合はピクチャフォルダを使用
      final home = Platform.environment['HOME'];
      if (home != null) {
        return path.join(home, 'Pictures', 'MediaTransfer');
      }
    }
    
    // フォールバック: アプリケーションドキュメントディレクトリ
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'MediaTransfer', 'Imports');
  }
  
  // インポート履歴を保存
  Future<void> saveImportHistory(ImportResult result) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final historyFile = File(path.join(appDir.path, 'MediaTransfer', 'import_history.json'));
      
      if (!await historyFile.parent.exists()) {
        await historyFile.parent.create(recursive: true);
      }
      
      final timestamp = DateTime.now().toIso8601String();
      final entry = {
        'timestamp': timestamp,
        'totalFiles': result.totalFiles,
        'importedFiles': result.importedFiles,
        'skippedFiles': result.skippedFiles,
        'failedFiles': result.failedFiles,
        'errors': result.errors,
      };
      
      // 既存の履歴を読み込み
      List<dynamic> history = [];
      if (await historyFile.exists()) {
        final content = await historyFile.readAsString();
        if (content.isNotEmpty) {
          history = List.from(content.split('\n').where((line) => line.isNotEmpty).map((line) => line));
        }
      }
      
      // 新しいエントリを追加
      history.add(entry.toString());
      
      // 最新100件のみ保持
      if (history.length > 100) {
        history = history.sublist(history.length - 100);
      }
      
      // 保存
      await historyFile.writeAsString(history.join('\n'));
    } catch (e) {
      debugPrint('インポート履歴の保存エラー: $e');
    }
  }
}