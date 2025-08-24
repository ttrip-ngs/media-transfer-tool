import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design/professional_theme.dart';
import '../models/folder_structure.dart';
import '../providers/folder_provider.dart';

class FolderTreeView extends StatelessWidget {
  final Function(String folderId)? onFolderSelected;
  final bool showSmartFolders;
  final bool showCollections;
  
  const FolderTreeView({
    Key? key,
    this.onFolderSelected,
    this.showSmartFolders = true,
    this.showCollections = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    
    return Container(
      color: ProTheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        children: [
          // メインライブラリ
          if (folderProvider.rootNode != null)
            _buildFolderNode(context, folderProvider.rootNode!, 0),
          
          // スマートフォルダセクション
          if (showSmartFolders && folderProvider.smartFolders.isNotEmpty) ...[
            const Divider(height: 1),
            _buildSectionHeader('スマートフォルダ', Icons.auto_awesome),
            ...folderProvider.smartFolders.map(
              (folder) => _buildSmartFolderItem(context, folder),
            ),
          ],
          
          // コレクションセクション
          if (showCollections) ...[
            const Divider(height: 1),
            _buildSectionHeader(
              'コレクション',
              Icons.collections,
              onAdd: () => _showCreateCollectionDialog(context),
            ),
            if (folderProvider.collections.isEmpty)
              _buildEmptyMessage('コレクションがありません')
            else
              ...folderProvider.collections.map(
                (collection) => _buildCollectionItem(context, collection),
              ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onAdd}) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: ProTheme.textSecondary),
          const SizedBox(width: Spacing.xs),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ProTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              child: const Icon(Icons.add, size: 14, color: ProTheme.textSecondary),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFolderNode(BuildContext context, FolderNode node, int depth) {
    final folderProvider = context.watch<FolderProvider>();
    final isSelected = folderProvider.selectedFolderId == node.id;
    final hasChildren = node.children.isNotEmpty;
    
    return Column(
      children: [
        InkWell(
          onTap: () {
            folderProvider.selectFolder(node.id);
            onFolderSelected?.call(node.id);
          },
          child: Container(
            height: 28,
            padding: EdgeInsets.only(
              left: Spacing.md + (depth * Spacing.lg),
              right: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? ProTheme.accent.withOpacity(0.15)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                // 展開/折りたたみアイコン
                if (hasChildren)
                  InkWell(
                    onTap: () => folderProvider.toggleFolderExpanded(node.id),
                    child: Icon(
                      node.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: ProTheme.textSecondary,
                    ),
                  )
                else
                  const SizedBox(width: 16),
                
                const SizedBox(width: Spacing.xs),
                
                // フォルダアイコン
                Icon(
                  node.icon ?? (node.isExpanded ? Icons.folder_open : Icons.folder),
                  size: 14,
                  color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
                ),
                
                const SizedBox(width: Spacing.xs),
                
                // フォルダ名
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? ProTheme.textPrimary : ProTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // ファイル数
                if (node.fileCount > 0)
                  Text(
                    node.fileCount.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: ProTheme.textDisabled,
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // 子ノード
        if (node.isExpanded && hasChildren)
          ...node.children.map(
            (child) => _buildFolderNode(context, child, depth + 1),
          ),
      ],
    );
  }
  
  Widget _buildSmartFolderItem(BuildContext context, SmartFolder folder) {
    final folderProvider = context.watch<FolderProvider>();
    final isSelected = folderProvider.selectedFolderId == folder.id;
    
    return InkWell(
      onTap: () {
        folderProvider.selectFolder(folder.id);
        onFolderSelected?.call(folder.id);
      },
      onLongPress: () => _showSmartFolderOptions(context, folder),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? ProTheme.accent.withOpacity(0.15)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              folder.icon ?? Icons.auto_awesome,
              size: 14,
              color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                folder.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? ProTheme.textPrimary : ProTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (folder.fileCount > 0)
              Text(
                folder.fileCount.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  color: ProTheme.textDisabled,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCollectionItem(BuildContext context, Collection collection) {
    final folderProvider = context.watch<FolderProvider>();
    final isSelected = folderProvider.selectedFolderId == collection.id;
    
    return InkWell(
      onTap: () {
        folderProvider.selectFolder(collection.id);
        onFolderSelected?.call(collection.id);
      },
      onLongPress: () => _showCollectionOptions(context, collection),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? ProTheme.accent.withOpacity(0.15)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              collection.icon ?? Icons.collections,
              size: 14,
              color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                collection.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? ProTheme.textPrimary : ProTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              collection.fileIds.length.toString(),
              style: const TextStyle(
                fontSize: 11,
                color: ProTheme.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 11,
            color: ProTheme.textDisabled,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
  
  void _showCreateCollectionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいコレクション'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'コレクション名',
                hintText: '例: お気に入りの写真',
              ),
              autofocus: true,
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（オプション）',
                hintText: '例: 2024年の旅行写真',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                context.read<FolderProvider>().createCollection(
                  nameController.text,
                  description: descriptionController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }
  
  void _showSmartFolderOptions(BuildContext context, SmartFolder folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ProTheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              folder.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ProTheme.textPrimary,
              ),
            ),
            if (folder.description.isNotEmpty) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                folder.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: ProTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            ListTile(
              leading: const Icon(Icons.edit, size: 20),
              title: const Text('編集'),
              onTap: () {
                Navigator.pop(context);
                // TODO: スマートフォルダ編集ダイアログを表示
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, size: 20, color: ProTheme.error),
              title: const Text('削除', style: TextStyle(color: ProTheme.error)),
              onTap: () {
                Navigator.pop(context);
                context.read<FolderProvider>().removeSmartFolder(folder.id);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCollectionOptions(BuildContext context, Collection collection) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ProTheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              collection.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ProTheme.textPrimary,
              ),
            ),
            Text(
              '${collection.fileIds.length}個のアイテム',
              style: const TextStyle(
                fontSize: 12,
                color: ProTheme.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            ListTile(
              leading: const Icon(Icons.edit, size: 20),
              title: const Text('名前を変更'),
              onTap: () {
                Navigator.pop(context);
                _showRenameCollectionDialog(context, collection);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, size: 20, color: ProTheme.error),
              title: const Text('削除', style: TextStyle(color: ProTheme.error)),
              onTap: () {
                Navigator.pop(context);
                context.read<FolderProvider>().removeCollection(collection.id);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showRenameCollectionDialog(BuildContext context, Collection collection) {
    final controller = TextEditingController(text: collection.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コレクション名を変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新しい名前',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<FolderProvider>().renameCollection(
                  collection.id,
                  controller.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('変更'),
          ),
        ],
      ),
    );
  }
}