import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import '../models/media_file.dart';
import '../models/folder_structure.dart';
import '../services/metadata_extractor.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  
  DatabaseService._();
  
  Database? _database;
  final Completer<Database> _dbCompleter = Completer<Database>();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!_dbCompleter.isCompleted) {
      _database = await _initDatabase();
      _dbCompleter.complete(_database);
    }
    return _dbCompleter.future;
  }
  
  Future<Database> _initDatabase() async {
    // FFI初期化 (デスクトップアプリ用)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    final dbPath = await _getDatabasePath();
    
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }
  
  Future<String> _getDatabasePath() async {
    // アプリケーションデータディレクトリにデータベースを作成
    final documentsDir = Directory.current.path;
    final dbDir = Directory(path.join(documentsDir, '.media_transfer_data'));
    
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    
    return path.join(dbDir.path, 'media_transfer.db');
  }
  
  Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // メディアファイルテーブル
      await txn.execute('''
        CREATE TABLE media_files (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          path TEXT NOT NULL UNIQUE,
          size INTEGER NOT NULL,
          type TEXT NOT NULL,
          extension TEXT NOT NULL,
          hash TEXT,
          device_name TEXT,
          import_date INTEGER,
          created_date INTEGER,
          modified_date INTEGER,
          is_favorite INTEGER DEFAULT 0,
          rating INTEGER DEFAULT 0,
          keywords TEXT,
          notes TEXT,
          folder_id TEXT,
          FOREIGN KEY (folder_id) REFERENCES folders (id)
        )
      ''');
      
      // メタデータテーブル
      await txn.execute('''
        CREATE TABLE media_metadata (
          file_id TEXT PRIMARY KEY,
          camera_make TEXT,
          camera_model TEXT,
          lens_model TEXT,
          focal_length REAL,
          aperture REAL,
          exposure_time TEXT,
          iso INTEGER,
          flash_used INTEGER,
          orientation INTEGER,
          width INTEGER,
          height INTEGER,
          color_space TEXT,
          gps_latitude REAL,
          gps_longitude REAL,
          gps_altitude REAL,
          gps_timestamp INTEGER,
          FOREIGN KEY (file_id) REFERENCES media_files (id) ON DELETE CASCADE
        )
      ''');
      
      // フォルダテーブル
      await txn.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          path TEXT,
          parent_id TEXT,
          type TEXT NOT NULL DEFAULT 'regular',
          icon TEXT,
          description TEXT,
          created_date INTEGER NOT NULL,
          FOREIGN KEY (parent_id) REFERENCES folders (id)
        )
      ''');
      
      // スマートフォルダテーブル
      await txn.execute('''
        CREATE TABLE smart_folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          filters TEXT NOT NULL,
          created_date INTEGER NOT NULL,
          updated_date INTEGER NOT NULL
        )
      ''');
      
      // コレクションテーブル
      await txn.execute('''
        CREATE TABLE collections (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          created_date INTEGER NOT NULL,
          updated_date INTEGER NOT NULL
        )
      ''');
      
      // コレクション-ファイル関連テーブル
      await txn.execute('''
        CREATE TABLE collection_files (
          collection_id TEXT NOT NULL,
          file_id TEXT NOT NULL,
          added_date INTEGER NOT NULL,
          PRIMARY KEY (collection_id, file_id),
          FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE,
          FOREIGN KEY (file_id) REFERENCES media_files (id) ON DELETE CASCADE
        )
      ''');
      
      // サムネイルキャッシュテーブル
      await txn.execute('''
        CREATE TABLE thumbnail_cache (
          file_id TEXT PRIMARY KEY,
          thumbnail_path TEXT NOT NULL,
          created_date INTEGER NOT NULL,
          file_size INTEGER NOT NULL,
          FOREIGN KEY (file_id) REFERENCES media_files (id) ON DELETE CASCADE
        )
      ''');
      
      // インポート履歴テーブル
      await txn.execute('''
        CREATE TABLE import_history (
          id TEXT PRIMARY KEY,
          source_path TEXT NOT NULL,
          destination_path TEXT NOT NULL,
          import_date INTEGER NOT NULL,
          file_count INTEGER NOT NULL,
          total_size INTEGER NOT NULL,
          status TEXT NOT NULL,
          notes TEXT
        )
      ''');
      
      // エクスポート履歴テーブル
      await txn.execute('''
        CREATE TABLE export_history (
          id TEXT PRIMARY KEY,
          destination_path TEXT NOT NULL,
          export_date INTEGER NOT NULL,
          file_count INTEGER NOT NULL,
          total_size INTEGER NOT NULL,
          format TEXT NOT NULL,
          quality TEXT NOT NULL,
          status TEXT NOT NULL,
          notes TEXT
        )
      ''');
      
      // インデックス作成
      await txn.execute('CREATE INDEX idx_media_files_path ON media_files (path)');
      await txn.execute('CREATE INDEX idx_media_files_type ON media_files (type)');
      await txn.execute('CREATE INDEX idx_media_files_created_date ON media_files (created_date)');
      await txn.execute('CREATE INDEX idx_media_files_import_date ON media_files (import_date)');
      await txn.execute('CREATE INDEX idx_media_files_folder_id ON media_files (folder_id)');
      await txn.execute('CREATE INDEX idx_media_files_hash ON media_files (hash)');
      await txn.execute('CREATE INDEX idx_folders_parent_id ON folders (parent_id)');
      await txn.execute('CREATE INDEX idx_metadata_camera_model ON media_metadata (camera_model)');
    });
    
    debugPrint('データベーステーブル作成完了');
  }
  
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // 将来のバージョンアップ時に使用
    debugPrint('データベース更新: $oldVersion -> $newVersion');
  }
  
  // メディアファイル操作
  Future<void> insertMediaFile(MediaFile file, [MediaMetadata? metadata]) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'media_files',
        {
          'id': file.id,
          'name': file.name,
          'path': file.path,
          'size': file.size,
          'type': file.type.toString().split('.').last,
          'extension': file.extension,
          'hash': file.hash,
          'device_name': file.deviceName,
          'import_date': file.importDate?.millisecondsSinceEpoch,
          'created_date': file.createdDate?.millisecondsSinceEpoch,
          'modified_date': file.modifiedDate?.millisecondsSinceEpoch,
          'is_favorite': file.isFavorite ? 1 : 0,
          'rating': file.rating,
          'keywords': file.keywords.join(','),
          'notes': file.notes,
          'folder_id': file.folderId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // メタデータがある場合は挿入
      if (metadata != null) {
        await txn.insert(
          'media_metadata',
          {
            'file_id': file.id,
            'camera_make': metadata.cameraMake,
            'camera_model': metadata.cameraModel,
            'lens_model': metadata.lensModel,
            'focal_length': metadata.focalLength,
            'aperture': metadata.aperture,
            'exposure_time': metadata.exposureTime,
            'iso': metadata.iso,
            'flash_used': metadata.flashUsed ? 1 : 0,
            'orientation': metadata.orientation,
            'width': metadata.width,
            'height': metadata.height,
            'color_space': metadata.colorSpace,
            'gps_latitude': metadata.gpsLatitude,
            'gps_longitude': metadata.gpsLongitude,
            'gps_altitude': metadata.gpsAltitude,
            'gps_timestamp': metadata.gpsTimestamp?.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
  
  Future<void> insertMediaFiles(List<MediaFile> files, [Map<String, MediaMetadata>? metadataMap]) async {
    final db = await database;
    final batch = db.batch();
    
    for (final file in files) {
      batch.insert(
        'media_files',
        {
          'id': file.id,
          'name': file.name,
          'path': file.path,
          'size': file.size,
          'type': file.type.toString().split('.').last,
          'extension': file.extension,
          'hash': file.hash,
          'device_name': file.deviceName,
          'import_date': file.importDate?.millisecondsSinceEpoch,
          'created_date': file.createdDate?.millisecondsSinceEpoch,
          'modified_date': file.modifiedDate?.millisecondsSinceEpoch,
          'is_favorite': file.isFavorite ? 1 : 0,
          'rating': file.rating,
          'keywords': file.keywords.join(','),
          'notes': file.notes,
          'folder_id': file.folderId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // メタデータがある場合は挿入
      final metadata = metadataMap?[file.id];
      if (metadata != null) {
        batch.insert(
          'media_metadata',
          {
            'file_id': file.id,
            'camera_make': metadata.cameraMake,
            'camera_model': metadata.cameraModel,
            'lens_model': metadata.lensModel,
            'focal_length': metadata.focalLength,
            'aperture': metadata.aperture,
            'exposure_time': metadata.exposureTime,
            'iso': metadata.iso,
            'flash_used': metadata.flashUsed ? 1 : 0,
            'orientation': metadata.orientation,
            'width': metadata.width,
            'height': metadata.height,
            'color_space': metadata.colorSpace,
            'gps_latitude': metadata.gpsLatitude,
            'gps_longitude': metadata.gpsLongitude,
            'gps_altitude': metadata.gpsAltitude,
            'gps_timestamp': metadata.gpsTimestamp?.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    
    await batch.commit(noResult: true);
  }
  
  Future<List<MediaFile>> getAllMediaFiles() async {
    final db = await database;
    final results = await db.query(
      'media_files',
      orderBy: 'created_date DESC',
    );
    
    return results.map(_mapRowToMediaFile).toList();
  }
  
  Future<MediaFile?> getMediaFileById(String id) async {
    final db = await database;
    final results = await db.query(
      'media_files',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return _mapRowToMediaFile(results.first);
  }
  
  Future<List<MediaFile>> getMediaFilesByFolder(String folderId) async {
    final db = await database;
    final results = await db.query(
      'media_files',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'created_date DESC',
    );
    
    return results.map(_mapRowToMediaFile).toList();
  }
  
  Future<List<MediaFile>> searchMediaFiles({
    String? query,
    MediaType? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? sizeMin,
    int? sizeMax,
    List<String>? extensions,
    String? cameraModel,
    int? ratingMin,
    bool? favoritesOnly,
  }) async {
    final db = await database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    if (query != null && query.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR keywords LIKE ? OR notes LIKE ?)');
      final likeQuery = '%$query%';
      whereArgs.addAll([likeQuery, likeQuery, likeQuery]);
    }
    
    if (type != null) {
      whereConditions.add('type = ?');
      whereArgs.add(type.toString().split('.').last);
    }
    
    if (dateFrom != null) {
      whereConditions.add('created_date >= ?');
      whereArgs.add(dateFrom.millisecondsSinceEpoch);
    }
    
    if (dateTo != null) {
      whereConditions.add('created_date <= ?');
      whereArgs.add(dateTo.millisecondsSinceEpoch);
    }
    
    if (sizeMin != null) {
      whereConditions.add('size >= ?');
      whereArgs.add(sizeMin);
    }
    
    if (sizeMax != null) {
      whereConditions.add('size <= ?');
      whereArgs.add(sizeMax);
    }
    
    if (extensions != null && extensions.isNotEmpty) {
      final extensionPlaceholders = extensions.map((_) => '?').join(',');
      whereConditions.add('extension IN ($extensionPlaceholders)');
      whereArgs.addAll(extensions);
    }
    
    if (ratingMin != null) {
      whereConditions.add('rating >= ?');
      whereArgs.add(ratingMin);
    }
    
    if (favoritesOnly == true) {
      whereConditions.add('is_favorite = 1');
    }
    
    String sql = 'SELECT * FROM media_files';
    if (cameraModel != null) {
      sql = '''
        SELECT mf.* FROM media_files mf
        JOIN media_metadata mm ON mf.id = mm.file_id
      ''';
      whereConditions.add('mm.camera_model LIKE ?');
      whereArgs.add('%$cameraModel%');
    }
    
    if (whereConditions.isNotEmpty) {
      sql += ' WHERE ${whereConditions.join(' AND ')}';
    }
    
    sql += ' ORDER BY created_date DESC';
    
    final results = await db.rawQuery(sql, whereArgs);
    return results.map(_mapRowToMediaFile).toList();
  }
  
  Future<void> updateMediaFile(MediaFile file) async {
    final db = await database;
    await db.update(
      'media_files',
      {
        'name': file.name,
        'is_favorite': file.isFavorite ? 1 : 0,
        'rating': file.rating,
        'keywords': file.keywords.join(','),
        'notes': file.notes,
        'folder_id': file.folderId,
      },
      where: 'id = ?',
      whereArgs: [file.id],
    );
  }
  
  Future<void> deleteMediaFile(String id) async {
    final db = await database;
    await db.delete(
      'media_files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> deleteMediaFiles(List<String> ids) async {
    if (ids.isEmpty) return;
    
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete(
      'media_files',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
  
  // メタデータ操作
  Future<MediaMetadata?> getMediaMetadata(String fileId) async {
    final db = await database;
    final results = await db.query(
      'media_metadata',
      where: 'file_id = ?',
      whereArgs: [fileId],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return _mapRowToMetadata(results.first);
  }
  
  // フォルダ操作
  Future<void> insertFolder(FolderNode folder) async {
    final db = await database;
    await db.insert(
      'folders',
      {
        'id': folder.id,
        'name': folder.name,
        'path': folder.path,
        'parent_id': folder.parentId,
        'type': 'regular',
        'icon': folder.icon?.codePoint.toString(),
        'description': folder.description,
        'created_date': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<FolderNode>> getAllFolders() async {
    final db = await database;
    final results = await db.query(
      'folders',
      orderBy: 'name ASC',
    );
    
    return results.map(_mapRowToFolder).toList();
  }
  
  // コレクション操作
  Future<void> insertCollection(Collection collection) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'collections',
      {
        'id': collection.id,
        'name': collection.name,
        'description': collection.description,
        'created_date': now,
        'updated_date': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> addFileToCollection(String collectionId, String fileId) async {
    final db = await database;
    await db.insert(
      'collection_files',
      {
        'collection_id': collectionId,
        'file_id': fileId,
        'added_date': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // 統計情報
  Future<Map<String, int>> getFileStatistics() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM media_files');
    final total = totalResult.first['count'] as int;
    
    final typeResults = await db.rawQuery('''
      SELECT type, COUNT(*) as count 
      FROM media_files 
      GROUP BY type
    ''');
    
    final stats = <String, int>{'total': total};
    for (final row in typeResults) {
      stats[row['type'] as String] = row['count'] as int;
    }
    
    return stats;
  }
  
  Future<int> getTotalFileSize() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(size) as total_size FROM media_files');
    return result.first['total_size'] as int? ?? 0;
  }
  
  // ユーティリティメソッド
  MediaFile _mapRowToMediaFile(Map<String, dynamic> row) {
    return MediaFile(
      id: row['id'] as String,
      name: row['name'] as String,
      path: row['path'] as String,
      size: row['size'] as int,
      type: MediaType.values.firstWhere(
        (e) => e.toString().split('.').last == row['type'],
        orElse: () => MediaType.other,
      ),
      extension: row['extension'] as String,
      hash: row['hash'] as String?,
      deviceName: row['device_name'] as String?,
      importDate: row['import_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['import_date'] as int)
          : null,
      createdDate: row['created_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['created_date'] as int)
          : null,
      modifiedDate: row['modified_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['modified_date'] as int)
          : null,
      isFavorite: (row['is_favorite'] as int) == 1,
      rating: row['rating'] as int,
      keywords: (row['keywords'] as String? ?? '').split(',').where((k) => k.isNotEmpty).toList(),
      notes: row['notes'] as String?,
      folderId: row['folder_id'] as String?,
    );
  }
  
  MediaMetadata _mapRowToMetadata(Map<String, dynamic> row) {
    return MediaMetadata(
      cameraMake: row['camera_make'] as String?,
      cameraModel: row['camera_model'] as String?,
      lensModel: row['lens_model'] as String?,
      focalLength: row['focal_length'] as double?,
      aperture: row['aperture'] as double?,
      exposureTime: row['exposure_time'] as String?,
      iso: row['iso'] as int?,
      flashUsed: (row['flash_used'] as int?) == 1,
      orientation: row['orientation'] as int?,
      width: row['width'] as int?,
      height: row['height'] as int?,
      colorSpace: row['color_space'] as String?,
      gpsLatitude: row['gps_latitude'] as double?,
      gpsLongitude: row['gps_longitude'] as double?,
      gpsAltitude: row['gps_altitude'] as double?,
      gpsTimestamp: row['gps_timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['gps_timestamp'] as int)
          : null,
    );
  }
  
  FolderNode _mapRowToFolder(Map<String, dynamic> row) {
    return FolderNode(
      id: row['id'] as String,
      name: row['name'] as String,
      path: row['path'] as String?,
      parentId: row['parent_id'] as String?,
      icon: row['icon'] != null 
          ? IconData(int.parse(row['icon'] as String), fontFamily: 'MaterialIcons')
          : null,
      description: row['description'] as String? ?? '',
    );
  }
  
  // データベースクリーンアップ
  Future<void> cleanup() async {
    final db = await database;
    
    // 存在しないファイルを削除
    final files = await db.query('media_files', columns: ['id', 'path']);
    final batch = db.batch();
    
    for (final file in files) {
      final filePath = file['path'] as String;
      if (!await File(filePath).exists()) {
        batch.delete('media_files', where: 'id = ?', whereArgs: [file['id']]);
      }
    }
    
    await batch.commit(noResult: true);
    
    // VACUUM実行（データベース最適化）
    await db.execute('VACUUM');
    
    debugPrint('データベースクリーンアップ完了');
  }
  
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}