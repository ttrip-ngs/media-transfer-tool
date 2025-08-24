import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/media_file.dart';
import 'package:crypto/crypto.dart';

class ThumbnailGenerator {
  static const int thumbnailSize = 300;
  static const double thumbnailQuality = 0.8;
  
  static ThumbnailGenerator? _instance;
  static ThumbnailGenerator get instance => _instance ??= ThumbnailGenerator._();
  
  ThumbnailGenerator._();
  
  Directory? _cacheDirectory;
  
  // キャッシュディレクトリを初期化
  Future<void> _initializeCacheDirectory() async {
    if (_cacheDirectory != null) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory(path.join(appDir.path, 'MediaTransfer', 'thumbnails'));
      
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('サムネイルキャッシュディレクトリの初期化エラー: $e');
      // フォールバック: テンポラリディレクトリを使用
      final tempDir = await getTemporaryDirectory();
      _cacheDirectory = Directory(path.join(tempDir.path, 'MediaTransfer_thumbnails'));
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
    }
  }
  
  // ファイルのハッシュ値を生成してキャッシュキーとする
  String _generateCacheKey(String filePath, int modificationTime) {
    final key = '$filePath:$modificationTime';
    return sha256.convert(key.codeUnits).toString();
  }
  
  // メディアファイルのサムネイルを生成
  Future<File?> generateThumbnail(MediaFile mediaFile) async {
    try {
      await _initializeCacheDirectory();
      
      final file = File(mediaFile.path);
      if (!await file.exists()) return null;
      
      final stat = await file.stat();
      final cacheKey = _generateCacheKey(mediaFile.path, stat.modified.millisecondsSinceEpoch);
      final cacheFile = File(path.join(_cacheDirectory!.path, '$cacheKey.jpg'));
      
      // キャッシュが存在する場合は返す
      if (await cacheFile.exists()) {
        return cacheFile;
      }
      
      // メディアタイプに応じてサムネイルを生成
      File? thumbnailFile;
      switch (mediaFile.type) {
        case MediaType.image:
        case MediaType.raw:
          thumbnailFile = await _generateImageThumbnail(file, cacheFile);
          break;
        case MediaType.video:
          thumbnailFile = await _generateVideoThumbnail(file, cacheFile);
          break;
        case MediaType.other:
          return null;
      }
      
      return thumbnailFile;
    } catch (e) {
      debugPrint('サムネイル生成エラー (${mediaFile.path}): $e');
      return null;
    }
  }
  
  // 画像ファイルのサムネイルを生成
  Future<File?> _generateImageThumbnail(File sourceFile, File cacheFile) async {
    try {
      // 画像を読み込む
      final bytes = await sourceFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('画像デコードに失敗: ${sourceFile.path}');
        return null;
      }
      
      // サムネイルサイズにリサイズ（アスペクト比を維持）
      final thumbnail = img.copyResize(
        image,
        width: image.width > image.height ? thumbnailSize : null,
        height: image.height >= image.width ? thumbnailSize : null,
        interpolation: img.Interpolation.cubic,
      );
      
      // JPEGとして保存
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: (thumbnailQuality * 100).round());
      await cacheFile.writeAsBytes(thumbnailBytes);
      
      return cacheFile;
    } catch (e) {
      debugPrint('画像サムネイル生成エラー: $e');
      return null;
    }
  }
  
  // 動画ファイルのサムネイルを生成（プレースホルダー版）
  Future<File?> _generateVideoThumbnail(File sourceFile, File cacheFile) async {
    try {
      // TODO: 実際の動画フレーム抽出機能の実装
      // 現在はプレースホルダー画像を生成
      final placeholderImage = img.Image(width: thumbnailSize, height: thumbnailSize);
      img.fill(placeholderImage, color: img.ColorRgba8(40, 40, 40, 255));
      
      // 動画アイコンを描画
      _drawVideoIcon(placeholderImage);
      
      final thumbnailBytes = img.encodeJpg(placeholderImage, quality: (thumbnailQuality * 100).round());
      await cacheFile.writeAsBytes(thumbnailBytes);
      
      return cacheFile;
    } catch (e) {
      debugPrint('動画サムネイル生成エラー: $e');
      return null;
    }
  }
  
  // 動画アイコンを描画
  void _drawVideoIcon(img.Image image) {
    final center = thumbnailSize ~/ 2;
    final iconSize = 60;
    
    // 再生ボタンの三角形を描画
    final trianglePoints = [
      [center - iconSize ~/ 3, center - iconSize ~/ 2],
      [center - iconSize ~/ 3, center + iconSize ~/ 2],
      [center + iconSize ~/ 2, center],
    ];
    
    // 簡単な三角形描画
    for (int y = center - iconSize ~/ 2; y < center + iconSize ~/ 2; y++) {
      for (int x = center - iconSize ~/ 3; x < center + iconSize ~/ 2; x++) {
        if (_isPointInTriangle(x, y, trianglePoints)) {
          if (x >= 0 && y >= 0 && x < image.width && y < image.height) {
            image.setPixel(x, y, img.ColorRgba8(255, 255, 255, 200));
          }
        }
      }
    }
  }
  
  // 点が三角形内にあるかチェック
  bool _isPointInTriangle(int px, int py, List<List<int>> triangle) {
    final x1 = triangle[0][0].toDouble();
    final y1 = triangle[0][1].toDouble();
    final x2 = triangle[1][0].toDouble();
    final y2 = triangle[1][1].toDouble();
    final x3 = triangle[2][0].toDouble();
    final y3 = triangle[2][1].toDouble();
    final x = px.toDouble();
    final y = py.toDouble();
    
    final denominator = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3);
    if (denominator == 0) return false;
    
    final a = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denominator;
    final b = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denominator;
    final c = 1 - a - b;
    
    return a >= 0 && b >= 0 && c >= 0;
  }
  
  // 複数のファイルのサムネイルを並列生成
  Future<Map<String, File?>> generateThumbnails(List<MediaFile> mediaFiles) async {
    final results = <String, File?>{};
    
    // 並列処理でパフォーマンス向上
    final futures = mediaFiles.map((file) async {
      final thumbnail = await generateThumbnail(file);
      return MapEntry(file.id, thumbnail);
    });
    
    final thumbnails = await Future.wait(futures);
    
    for (final entry in thumbnails) {
      results[entry.key] = entry.value;
    }
    
    return results;
  }
  
  // 特定のサムネイルを削除
  Future<void> deleteThumbnail(String filePath, int modificationTime) async {
    try {
      await _initializeCacheDirectory();
      
      final cacheKey = _generateCacheKey(filePath, modificationTime);
      final cacheFile = File(path.join(_cacheDirectory!.path, '$cacheKey.jpg'));
      
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
    } catch (e) {
      debugPrint('サムネイル削除エラー: $e');
    }
  }
  
  // キャッシュディレクトリをクリア
  Future<void> clearCache() async {
    try {
      await _initializeCacheDirectory();
      
      if (await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('キャッシュクリアエラー: $e');
    }
  }
  
  // キャッシュサイズを取得
  Future<int> getCacheSize() async {
    try {
      await _initializeCacheDirectory();
      
      int totalSize = 0;
      await for (final file in _cacheDirectory!.list(recursive: true)) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('キャッシュサイズ取得エラー: $e');
      return 0;
    }
  }
  
  // 古いキャッシュファイルを削除（30日以上古いもの）
  Future<void> cleanOldCache() async {
    try {
      await _initializeCacheDirectory();
      
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      
      await for (final file in _cacheDirectory!.list()) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.accessed.isBefore(cutoff)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('古いキャッシュ削除エラー: $e');
    }
  }
}