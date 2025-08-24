import 'dart:io';
import 'package:intl/intl.dart';

enum MediaType { image, video, raw, other }

class MediaFile {
  final String id;
  final String path;
  final String name;
  final int size;
  final MediaType type;
  final DateTime? createdDate;
  final String? deviceName;
  File? thumbnailFile;
  
  MediaFile({
    required this.id,
    required this.path,
    required this.name,
    required this.size,
    required this.type,
    this.createdDate,
    this.deviceName,
    this.thumbnailFile,
  });
  
  static MediaType getTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'].contains(extension)) {
      return MediaType.image;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'wmv', 'm4v', 'flv'].contains(extension)) {
      return MediaType.video;
    } else if (['cr2', 'cr3', 'raw', 'nef', 'arw', 'dng', 'raf', 'orf'].contains(extension)) {
      return MediaType.raw;
    }
    return MediaType.other;
  }
  
  String get extension => path.split('.').last.toUpperCase();
  
  String get formattedDate {
    if (createdDate == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(createdDate!);
  }
  
  String get formattedSize {
    const sizes = ['B', 'KB', 'MB', 'GB'];
    if (size == 0) return '0 B';
    final i = (size > 0 ? (size.bitLength - 1) ~/ 10 : 0);
    final formattedSize = (size / (1 << (i * 10))).toStringAsFixed(2);
    return '$formattedSize ${sizes[i]}';
  }
}