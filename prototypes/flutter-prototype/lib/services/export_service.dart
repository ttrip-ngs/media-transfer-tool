import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../models/media_file.dart';

enum ExportFormat {
  original,     // オリジナル形式
  jpeg,         // JPEG
  png,          // PNG
  webp,         // WebP
  tiff,         // TIFF
}

enum ExportSize {
  original,     // オリジナルサイズ
  large,        // 2048px
  medium,       // 1200px
  small,        // 800px
  custom,       // カスタムサイズ
}

enum ExportQuality {
  maximum,      // 最高品質 (95-100%)
  high,         // 高品質 (80-95%)
  medium,       // 中品質 (60-80%)
  low,          // 低品質 (40-60%)
  custom,       // カスタム品質
}

enum WatermarkPosition {
  bottomRight,
  bottomLeft,
  topRight,
  topLeft,
  center,
}

class WatermarkSettings {
  final String? text;
  final String? imagePath;
  final WatermarkPosition position;
  final double opacity;
  final double scale;
  final Color color;
  
  WatermarkSettings({
    this.text,
    this.imagePath,
    this.position = WatermarkPosition.bottomRight,
    this.opacity = 0.5,
    this.scale = 1.0,
    this.color = const Color(0xFFFFFFFF),
  });
}

class ExportOptions {
  final ExportFormat format;
  final ExportSize size;
  final ExportQuality quality;
  final int? customWidth;
  final int? customHeight;
  final int? customQuality;
  final bool preserveMetadata;
  final bool renameFiles;
  final String? fileNameTemplate;
  final WatermarkSettings? watermark;
  final bool createSubfolders;
  final String folderStructure;
  final String destinationPath;
  
  ExportOptions({
    this.format = ExportFormat.original,
    this.size = ExportSize.original,
    this.quality = ExportQuality.high,
    this.customWidth,
    this.customHeight,
    this.customQuality,
    this.preserveMetadata = true,
    this.renameFiles = false,
    this.fileNameTemplate,
    this.watermark,
    this.createSubfolders = false,
    this.folderStructure = 'date',
    required this.destinationPath,
  });
}

class ExportResult {
  final int totalFiles;
  final int exportedFiles;
  final int skippedFiles;
  final int failedFiles;
  final List<String> errors;
  final Map<String, String> exportedPaths;
  final Duration exportTime;
  final int totalSize;
  
  ExportResult({
    required this.totalFiles,
    required this.exportedFiles,
    required this.skippedFiles,
    required this.failedFiles,
    required this.errors,
    required this.exportedPaths,
    required this.exportTime,
    required this.totalSize,
  });
  
  bool get isSuccess => failedFiles == 0 && errors.isEmpty;
  String get summary => 'エクスポート完了: $exportedFiles/$totalFiles ファイル (スキップ: $skippedFiles、失敗: $failedFiles)';
}

class ExportService {
  static ExportService? _instance;
  static ExportService get instance => _instance ??= ExportService._();
  
  ExportService._();
  
  bool _isCancelled = false;
  
  // エクスポートをキャンセル
  void cancelExport() {
    _isCancelled = true;
  }
  
  // ファイルをエクスポート
  Future<ExportResult> exportFiles(
    List<MediaFile> files,
    ExportOptions options, {
    Function(double progress, String currentFile)? onProgress,
  }) async {
    _isCancelled = false;
    final stopwatch = Stopwatch()..start();
    
    final errors = <String>[];
    final exportedPaths = <String, String>{};
    int exportedCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    int totalSize = 0;
    
    // エクスポート先ディレクトリを準備
    final destDir = Directory(options.destinationPath);
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    
    // ファイルをエクスポート
    for (int i = 0; i < files.length; i++) {
      if (_isCancelled) break;
      
      final file = files[i];
      
      try {
        // 進捗通知
        onProgress?.call((i + 1) / files.length, file.name);
        
        // エクスポート先パスを決定
        final exportPath = _determineExportPath(file, options);
        
        // ファイルをエクスポート
        final exportedFile = await _exportSingleFile(file, exportPath, options);
        
        if (exportedFile != null) {
          exportedPaths[file.path] = exportedFile.path;
          exportedCount++;
          
          // エクスポートファイルのサイズを取得
          final stat = await exportedFile.stat();
          totalSize += stat.size;
        } else {
          skippedCount++;
        }
        
      } catch (e) {
        errors.add('エクスポートエラー (${file.name}): $e');
        failedCount++;
      }
    }
    
    stopwatch.stop();
    
    return ExportResult(
      totalFiles: files.length,
      exportedFiles: exportedCount,
      skippedFiles: skippedCount,
      failedFiles: failedCount,
      errors: errors,
      exportedPaths: exportedPaths,
      exportTime: stopwatch.elapsed,
      totalSize: totalSize,
    );
  }
  
  // 単一ファイルをエクスポート
  Future<File?> _exportSingleFile(
    MediaFile sourceFile,
    String exportPath,
    ExportOptions options,
  ) async {
    final sourceFileHandle = File(sourceFile.path);
    if (!await sourceFileHandle.exists()) {
      throw Exception('ソースファイルが見つかりません: ${sourceFile.path}');
    }
    
    // エクスポートファイルを作成
    final exportFile = File(exportPath);
    await exportFile.parent.create(recursive: true);
    
    // 画像ファイルの場合、リサイズや形式変換を適用
    if (sourceFile.type == MediaType.image || sourceFile.type == MediaType.raw) {
      return await _processImageFile(sourceFileHandle, exportFile, options);
    } else {
      // 動画やその他のファイルはコピーのみ
      await sourceFileHandle.copy(exportPath);
      return exportFile;
    }
  }
  
  // 画像ファイルを処理
  Future<File?> _processImageFile(
    File sourceFile,
    File exportFile,
    ExportOptions options,
  ) async {
    try {
      // 画像を読み込み
      final bytes = await sourceFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        // デコードに失敗した場合はオリジナルをコピー
        await sourceFile.copy(exportFile.path);
        return exportFile;
      }
      
      // リサイズを適用
      image = await _resizeImage(image, options);
      
      // ウォーターマークを適用
      if (options.watermark != null) {
        image = await _applyWatermark(image, options.watermark!);
      }
      
      // 指定形式でエンコード
      final exportBytes = await _encodeImage(image, options);
      
      if (exportBytes != null) {
        await exportFile.writeAsBytes(exportBytes);
        return exportFile;
      }
      
    } catch (e) {
      debugPrint('画像処理エラー: $e');
      // エラーの場合はオリジナルをコピー
      try {
        await sourceFile.copy(exportFile.path);
        return exportFile;
      } catch (e) {
        debugPrint('ファイルコピーエラー: $e');
      }
    }
    
    return null;
  }
  
  // 画像をリサイズ
  Future<img.Image> _resizeImage(img.Image image, ExportOptions options) async {
    if (options.size == ExportSize.original) {
      return image;
    }
    
    int? targetWidth;
    int? targetHeight;
    
    switch (options.size) {
      case ExportSize.large:
        targetWidth = 2048;
        break;
      case ExportSize.medium:
        targetWidth = 1200;
        break;
      case ExportSize.small:
        targetWidth = 800;
        break;
      case ExportSize.custom:
        targetWidth = options.customWidth;
        targetHeight = options.customHeight;
        break;
      case ExportSize.original:
        return image;
    }
    
    // アスペクト比を維持してリサイズ
    if (targetWidth != null || targetHeight != null) {
      return img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic,
      );
    }
    
    return image;
  }
  
  // ウォーターマークを適用
  Future<img.Image> _applyWatermark(img.Image image, WatermarkSettings watermark) async {
    // テキストウォーターマークの場合
    if (watermark.text != null && watermark.text!.isNotEmpty) {
      return _applyTextWatermark(image, watermark);
    }
    
    // 画像ウォーターマークの場合
    if (watermark.imagePath != null) {
      return await _applyImageWatermark(image, watermark);
    }
    
    return image;
  }
  
  // テキストウォーターマークを適用
  img.Image _applyTextWatermark(img.Image image, WatermarkSettings watermark) {
    // TODO: テキスト描画機能の実装
    // 現在はプレースホルダー
    debugPrint('テキストウォーターマーク適用: ${watermark.text}');
    return image;
  }
  
  // 画像ウォーターマークを適用
  Future<img.Image> _applyImageWatermark(img.Image image, WatermarkSettings watermark) async {
    try {
      final watermarkFile = File(watermark.imagePath!);
      if (await watermarkFile.exists()) {
        final watermarkBytes = await watermarkFile.readAsBytes();
        final watermarkImage = img.decodeImage(watermarkBytes);
        
        if (watermarkImage != null) {
          // ウォーターマークをリサイズ
          final scaledWatermark = img.copyResize(
            watermarkImage,
            width: (watermarkImage.width * watermark.scale).round(),
            height: (watermarkImage.height * watermark.scale).round(),
          );
          
          // 位置を計算
          final position = _calculateWatermarkPosition(
            image,
            scaledWatermark,
            watermark.position,
          );
          
          // 合成
          return img.compositeImage(
            image,
            scaledWatermark,
            dstX: position.$1,
            dstY: position.$2,
          );
        }
      }
    } catch (e) {
      debugPrint('画像ウォーターマークエラー: $e');
    }
    
    return image;
  }
  
  // ウォーターマークの位置を計算
  (int, int) _calculateWatermarkPosition(
    img.Image baseImage,
    img.Image watermarkImage,
    WatermarkPosition position,
  ) {
    const padding = 20;
    
    switch (position) {
      case WatermarkPosition.bottomRight:
        return (
          baseImage.width - watermarkImage.width - padding,
          baseImage.height - watermarkImage.height - padding,
        );
      case WatermarkPosition.bottomLeft:
        return (
          padding,
          baseImage.height - watermarkImage.height - padding,
        );
      case WatermarkPosition.topRight:
        return (
          baseImage.width - watermarkImage.width - padding,
          padding,
        );
      case WatermarkPosition.topLeft:
        return (padding, padding);
      case WatermarkPosition.center:
        return (
          (baseImage.width - watermarkImage.width) ~/ 2,
          (baseImage.height - watermarkImage.height) ~/ 2,
        );
    }
  }
  
  // 画像をエンコード
  Future<List<int>?> _encodeImage(img.Image image, ExportOptions options) async {
    int quality = _getQualityValue(options);
    
    switch (options.format) {
      case ExportFormat.jpeg:
        return img.encodeJpg(image, quality: quality);
      case ExportFormat.png:
        return img.encodePng(image);
      case ExportFormat.webp:
        // WebPは現在サポートされていない可能性があります
        return img.encodeJpg(image, quality: quality);
      case ExportFormat.tiff:
        return img.encodeTiff(image);
      case ExportFormat.original:
        return img.encodeJpg(image, quality: quality);
    }
  }
  
  // 品質値を取得
  int _getQualityValue(ExportOptions options) {
    switch (options.quality) {
      case ExportQuality.maximum:
        return 95;
      case ExportQuality.high:
        return 85;
      case ExportQuality.medium:
        return 70;
      case ExportQuality.low:
        return 50;
      case ExportQuality.custom:
        return options.customQuality ?? 85;
    }
  }
  
  // エクスポート先パスを決定
  String _determineExportPath(MediaFile file, ExportOptions options) {
    String subPath = '';
    
    // サブフォルダ構造を作成
    if (options.createSubfolders) {
      switch (options.folderStructure) {
        case 'date':
          if (file.createdDate != null) {
            final year = file.createdDate!.year.toString();
            final month = file.createdDate!.month.toString().padLeft(2, '0');
            subPath = path.join(year, '$year-$month');
          }
          break;
        case 'type':
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
        case 'size':
          subPath = _getSizeCategory(file.size);
          break;
      }
    }
    
    // ファイル名を決定
    String fileName;
    if (options.renameFiles && options.fileNameTemplate != null) {
      fileName = _generateExportFileName(file, options.fileNameTemplate!);
    } else {
      fileName = path.basenameWithoutExtension(file.path);
    }
    
    // 拡張子を決定
    String extension;
    switch (options.format) {
      case ExportFormat.jpeg:
        extension = '.jpg';
        break;
      case ExportFormat.png:
        extension = '.png';
        break;
      case ExportFormat.webp:
        extension = '.webp';
        break;
      case ExportFormat.tiff:
        extension = '.tiff';
        break;
      case ExportFormat.original:
        extension = path.extension(file.path);
        break;
    }
    
    return path.join(options.destinationPath, subPath, '$fileName$extension');
  }
  
  // ファイル名を生成
  String _generateExportFileName(MediaFile file, String template) {
    final now = DateTime.now();
    final createDate = file.createdDate ?? now;
    final originalName = path.basenameWithoutExtension(file.path);
    
    String fileName = template;
    fileName = fileName.replaceAll('{year}', createDate.year.toString());
    fileName = fileName.replaceAll('{month}', createDate.month.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{day}', createDate.day.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{hour}', createDate.hour.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{minute}', createDate.minute.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{second}', createDate.second.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{original}', originalName);
    fileName = fileName.replaceAll('{counter}', '001');
    
    return fileName;
  }
  
  // サイズカテゴリを取得
  String _getSizeCategory(int sizeInBytes) {
    final sizeInMB = sizeInBytes / (1024 * 1024);
    
    if (sizeInMB < 1) {
      return '小サイズ';
    } else if (sizeInMB < 5) {
      return '中サイズ';
    } else {
      return '大サイズ';
    }
  }
  
  // エクスポート履歴を保存
  Future<void> saveExportHistory(ExportResult result, ExportOptions options) async {
    // TODO: エクスポート履歴の永続化
    debugPrint('エクスポート履歴を保存: ${result.summary}');
  }
  
  // エクスポートプリセットを保存
  Future<void> saveExportPreset(String name, ExportOptions options) async {
    // TODO: エクスポートプリセットの永続化
    debugPrint('エクスポートプリセットを保存: $name');
  }
}