import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../models/media_file.dart';

class FileListView extends StatelessWidget {
  const FileListView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final theme = Theme.of(context);
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '選択されたファイル',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  '${provider.files.length} 個のファイル',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 400,
            child: provider.files.isEmpty
                ? Center(
                    child: Text(
                      'ファイルが選択されていません',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.files.length,
                    itemBuilder: (context, index) {
                      final file = provider.files[index];
                      return _FileListItem(file: file);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FileListItem extends StatelessWidget {
  final MediaFile file;
  
  const _FileListItem({required this.file});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<MediaProvider>();
    
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getTypeColor(file.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getTypeIcon(file.type),
          color: _getTypeColor(file.type),
        ),
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(file.formattedSize),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              _getTypeLabel(file.type),
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: _getTypeColor(file.type).withOpacity(0.2),
            padding: const EdgeInsets.all(0),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              provider.removeFile(file.id);
            },
          ),
        ],
      ),
    );
  }
  
  IconData _getTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  Color _getTypeColor(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Colors.blue;
      case MediaType.video:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  String _getTypeLabel(MediaType type) {
    switch (type) {
      case MediaType.image:
        return '画像';
      case MediaType.video:
        return '動画';
      default:
        return 'その他';
    }
  }
}