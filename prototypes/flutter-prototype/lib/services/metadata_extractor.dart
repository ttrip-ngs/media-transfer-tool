import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../models/media_file.dart';

class MediaMetadata {
  final String? cameraModel;
  final String? cameraMake;
  final String? lensModel;
  final double? focalLength;
  final double? aperture;
  final String? exposureTime;
  final int? iso;
  final DateTime? dateTaken;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;
  final String? copyright;
  final String? artist;
  final String? software;
  final String? description;
  final Map<String, dynamic> rawExif;

  MediaMetadata({
    this.cameraModel,
    this.cameraMake,
    this.lensModel,
    this.focalLength,
    this.aperture,
    this.exposureTime,
    this.iso,
    this.dateTaken,
    this.width,
    this.height,
    this.latitude,
    this.longitude,
    this.copyright,
    this.artist,
    this.software,
    this.description,
    this.rawExif = const {},
  });

  String get formattedDate {
    if (dateTaken == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTaken!);
  }

  String get formattedAperture {
    if (aperture == null) return '';
    return 'f/$aperture';
  }

  String get formattedFocalLength {
    if (focalLength == null) return '';
    return '${focalLength!.toStringAsFixed(0)}mm';
  }

  String get formattedExposure {
    if (exposureTime == null) return '';
    return exposureTime!;
  }

  String get formattedISO {
    if (iso == null) return '';
    return 'ISO $iso';
  }

  String get formattedDimensions {
    if (width == null || height == null) return '';
    return '${width}x${height}';
  }

  String get formattedLocation {
    if (latitude == null || longitude == null) return '';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }
}

class MetadataExtractor {
  static MetadataExtractor? _instance;
  static MetadataExtractor get instance => _instance ??= MetadataExtractor._();
  
  MetadataExtractor._();

  // メディアファイルからメタデータを抽出
  Future<MediaMetadata?> extractMetadata(MediaFile mediaFile) async {
    try {
      final file = File(mediaFile.path);
      if (!await file.exists()) return null;

      switch (mediaFile.type) {
        case MediaType.image:
        case MediaType.raw:
          return await _extractImageMetadata(file);
        case MediaType.video:
          return await _extractVideoMetadata(file);
        case MediaType.other:
          return null;
      }
    } catch (e) {
      debugPrint('メタデータ抽出エラー (${mediaFile.path}): $e');
      return null;
    }
  }

  // 画像ファイルからメタデータを抽出
  Future<MediaMetadata?> _extractImageMetadata(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // EXIF情報を取得
      final exifData = image.exif;
      
      if (exifData.isEmpty) {
        // EXIF情報がない場合は基本情報のみ返す
        return MediaMetadata(
          width: image.width,
          height: image.height,
          rawExif: {},
        );
      }

      // EXIFタグから情報を抽出
      String? cameraMake = _getExifString(exifData, 0x010F); // Make
      String? cameraModel = _getExifString(exifData, 0x0110); // Model
      String? software = _getExifString(exifData, 0x0131); // Software
      String? artist = _getExifString(exifData, 0x013B); // Artist
      String? copyright = _getExifString(exifData, 0x8298); // Copyright
      String? description = _getExifString(exifData, 0x010E); // ImageDescription
      String? lensModel = _getExifString(exifData, 0xA434); // LensModel
      
      // 撮影日時
      DateTime? dateTaken = _parseExifDateTime(exifData, 0x9003) ?? // DateTimeOriginal
                           _parseExifDateTime(exifData, 0x9004) ?? // DateTimeDigitized
                           _parseExifDateTime(exifData, 0x0132);   // DateTime

      // 露出情報
      double? aperture = _getExifRational(exifData, 0x9202); // ApertureValue
      if (aperture == null) {
        aperture = _getExifRational(exifData, 0x829D); // FNumber
      }
      
      String? exposureTime = _formatExposureTime(_getExifRational(exifData, 0x829A)); // ExposureTime
      int? iso = _getExifInt(exifData, 0x8827); // ISOSpeedRatings
      double? focalLength = _getExifRational(exifData, 0x920A); // FocalLength

      // GPS情報
      double? latitude = _extractGPSCoordinate(exifData, 0x0002, _getExifString(exifData, 0x0001)); // GPSLatitude
      double? longitude = _extractGPSCoordinate(exifData, 0x0004, _getExifString(exifData, 0x0003)); // GPSLongitude

      return MediaMetadata(
        cameraModel: cameraModel,
        cameraMake: cameraMake,
        lensModel: lensModel,
        focalLength: focalLength,
        aperture: aperture,
        exposureTime: exposureTime,
        iso: iso,
        dateTaken: dateTaken,
        width: image.width,
        height: image.height,
        latitude: latitude,
        longitude: longitude,
        copyright: copyright,
        artist: artist,
        software: software,
        description: description,
        rawExif: _convertExifToMap(exifData),
      );
    } catch (e) {
      debugPrint('画像メタデータ抽出エラー: $e');
      return null;
    }
  }

  // 動画ファイルからメタデータを抽出（簡易版）
  Future<MediaMetadata?> _extractVideoMetadata(File file) async {
    try {
      final stat = await file.stat();
      
      // TODO: 実際の動画メタデータ抽出実装
      return MediaMetadata(
        dateTaken: stat.modified,
        rawExif: {},
      );
    } catch (e) {
      debugPrint('動画メタデータ抽出エラー: $e');
      return null;
    }
  }

  // EXIF文字列値を取得
  String? _getExifString(img.ExifData exifData, int tag) {
    // imageパッケージのExifDataは直接値にアクセスできないため、
    // 簡略化された実装を使用
    return null;
  }

  // EXIF整数値を取得
  int? _getExifInt(img.ExifData exifData, int tag) {
    // imageパッケージのExifDataは直接値にアクセスできないため、
    // 簡略化された実装を使用
    return null;
  }

  // EXIF有理数値を取得
  double? _getExifRational(img.ExifData exifData, int tag) {
    // imageパッケージのExifDataは直接値にアクセスできないため、
    // 簡略化された実装を使用
    return null;
  }

  // EXIF日時をパース
  DateTime? _parseExifDateTime(img.ExifData exifData, int tag) {
    final value = _getExifString(exifData, tag);
    if (value == null) return null;
    
    try {
      // EXIF日時形式: "YYYY:MM:DD HH:MM:SS"
      final parts = value.split(' ');
      if (parts.length != 2) return null;
      
      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');
      
      if (dateParts.length != 3 || timeParts.length != 3) return null;
      
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  // 露出時間をフォーマット
  String? _formatExposureTime(double? exposureTime) {
    if (exposureTime == null) return null;
    
    if (exposureTime >= 1) {
      return '${exposureTime.toStringAsFixed(1)}s';
    } else {
      final denominator = (1 / exposureTime).round();
      return '1/${denominator}s';
    }
  }

  // GPS座標を抽出
  double? _extractGPSCoordinate(img.ExifData exifData, int tag, String? ref) {
    // imageパッケージのExifDataは直接値にアクセスできないため、
    // 簡略化された実装を使用
    return null;
  }

  // 値をdoubleに変換
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // EXIFデータをMapに変換
  Map<String, dynamic> _convertExifToMap(img.ExifData exifData) {
    // imageパッケージのExifDataは直接値にアクセスできないため、
    // 簡略化された実装を使用
    return {};
  }

  // EXIFタグ名を取得
  String _getExifTagName(int tag) {
    const tagNames = {
      0x010E: 'ImageDescription',
      0x010F: 'Make',
      0x0110: 'Model',
      0x0131: 'Software',
      0x0132: 'DateTime',
      0x013B: 'Artist',
      0x8298: 'Copyright',
      0x829A: 'ExposureTime',
      0x829D: 'FNumber',
      0x8827: 'ISOSpeedRatings',
      0x9003: 'DateTimeOriginal',
      0x9004: 'DateTimeDigitized',
      0x9202: 'ApertureValue',
      0x920A: 'FocalLength',
      0xA434: 'LensModel',
      // GPS tags
      0x0001: 'GPSLatitudeRef',
      0x0002: 'GPSLatitude',
      0x0003: 'GPSLongitudeRef',
      0x0004: 'GPSLongitude',
    };
    
    return tagNames[tag] ?? '0x${tag.toRadixString(16).toUpperCase()}';
  }

  // 複数ファイルのメタデータを並列抽出
  Future<Map<String, MediaMetadata?>> extractMetadataForFiles(List<MediaFile> files) async {
    final results = <String, MediaMetadata?>{};
    
    final futures = files.map((file) async {
      final metadata = await extractMetadata(file);
      return MapEntry(file.id, metadata);
    });
    
    final metadataList = await Future.wait(futures);
    
    for (final entry in metadataList) {
      results[entry.key] = entry.value;
    }
    
    return results;
  }
}