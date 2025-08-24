import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/design/professional_theme.dart';
import '../providers/media_provider.dart';
import '../models/media_file.dart';
import '../services/metadata_extractor.dart';
import '../screens/import_screen.dart';
import '../screens/export_screen.dart';
import '../screens/settings_screen.dart';
import 'dart:io';

class ProfessionalScreen extends StatefulWidget {
  const ProfessionalScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends State<ProfessionalScreen> {
  int selectedModule = 0; // 0: Library, 1: Import, 2: Process, 3: Export
  int viewMode = 0; // 0: Grid, 1: List, 2: Filmstrip
  double thumbnailSize = 160;
  bool showLeftPanel = true;
  bool showRightPanel = true;

  @override
  void initState() {
    super.initState();
    // 初期化時にデバイスを検出
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaProvider>().detectDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProTheme.background,
      body: Column(
        children: [
          _buildMenuBar(),
          _buildModuleSelector(),
          _buildToolbar(),
          Expanded(
            child: Row(
              children: [
                if (showLeftPanel) _buildLeftPanel(),
                Expanded(child: _buildMainView()),
                if (showRightPanel) _buildRightPanel(),
              ],
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  // メニューバー - Adobe 風
  Widget _buildMenuBar() {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(
          bottom: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: Spacing.sm),
          _buildMenu('ファイル'),
          _buildMenu('編集'),
          _buildMenu('表示'),
          _buildMenu('ライブラリ'),
          _buildMenu('現像'),
          _buildMenu('ツール'),
          _buildMenu('ウィンドウ'),
          _buildMenu('ヘルプ'),
          const Spacer(),
          // ウィンドウコントロール
          IconButton(
            icon: const Icon(Icons.minimize, size: 14),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          IconButton(
            icon: const Icon(Icons.crop_square, size: 14),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
    );
  }

  Widget _buildMenu(String title) {
    return InkWell(
      onTap: () {
        if (title == 'ツール') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: ProTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // モジュールセレクター - Lightroom Classic 風
  Widget _buildModuleSelector() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: Spacing.lg),
          _buildModuleTab('ライブラリ', 0, Icons.photo_library),
          _buildModuleTab('インポート', 1, Icons.download),
          _buildModuleTab('現像', 2, Icons.tune),
          _buildModuleTab('エクスポート', 3, Icons.upload),
          const Spacer(),
          // Identity Plate
          const Text(
            'MEDIA TRANSFER PRO',
            style: TextStyle(
              fontSize: 11,
              color: ProTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: Spacing.lg),
        ],
      ),
    );
  }

  Widget _buildModuleTab(String label, int index, IconData icon) {
    final isSelected = selectedModule == index;
    return InkWell(
      onTap: () {
        setState(() => selectedModule = index);
        if (index == 1) {
          // インポートモジュールが選択された場合
          _showImportScreen();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? ProTheme.surface : Colors.transparent,
          border: isSelected
              ? const Border(
                  bottom: BorderSide(color: ProTheme.accent, width: 2),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
            ),
            const SizedBox(width: Spacing.xs),
            Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? ProTheme.textPrimary : ProTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ツールバー
  Widget _buildToolbar() {
    final provider = context.watch<MediaProvider>();
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(
          bottom: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // インポートボタン
          _buildToolButton(Icons.add_photo_alternate, 'ファイルを追加', () {
            provider.selectFiles();
          }),
          _buildToolButton(Icons.create_new_folder, 'フォルダを追加', () {
            provider.selectFolder();
          }),
          const SizedBox(width: Spacing.md),
          Container(width: 1, height: 20, color: ProTheme.border),
          const SizedBox(width: Spacing.md),
          
          // ビューモード
          _buildViewModeButton(Icons.grid_view, 0),
          _buildViewModeButton(Icons.view_list, 1),
          _buildViewModeButton(Icons.view_carousel, 2),
          const SizedBox(width: Spacing.md),
          Container(width: 1, height: 20, color: ProTheme.border),
          const SizedBox(width: Spacing.md),
          
          // サムネイルサイズ
          const Icon(Icons.photo_size_select_small, size: 14, color: ProTheme.textSecondary),
          SizedBox(
            width: 100,
            child: Slider(
              value: thumbnailSize,
              min: 80,
              max: 300,
              onChanged: (value) => setState(() => thumbnailSize = value),
            ),
          ),
          const Icon(Icons.photo_size_select_large, size: 14, color: ProTheme.textSecondary),
          
          const Spacer(),
          
          // 選択ツール
          if (provider.selectedFiles.isNotEmpty) ...[
            Text(
              '${provider.selectedFiles.length}枚選択中',
              style: const TextStyle(fontSize: 11, color: ProTheme.textPrimary),
            ),
            const SizedBox(width: Spacing.md),
            _buildToolButton(Icons.select_all, 'すべて選択', () {
              provider.selectAll();
            }),
            _buildToolButton(Icons.clear, '選択解除', () {
              provider.clearSelection();
            }),
            _buildToolButton(Icons.delete_outline, '削除', () {
              provider.removeSelectedFiles();
            }),
            _buildToolButton(Icons.upload, 'エクスポート', () {
              _showExportScreen();
            }),
            const SizedBox(width: Spacing.md),
            Container(width: 1, height: 20, color: ProTheme.border),
            const SizedBox(width: Spacing.md),
          ],
          _buildToolButton(Icons.filter_list, 'フィルター', () {}),
          _buildToolButton(Icons.search, '検索', () {}),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tooltip, [VoidCallback? onTap]) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Icon(icon, size: 16, color: ProTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildViewModeButton(IconData icon, int mode) {
    final isSelected = viewMode == mode;
    return InkWell(
      onTap: () => setState(() => viewMode = mode),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? ProTheme.surfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
        ),
      ),
    );
  }

  // 左パネル - フォルダツリー、コレクション
  Widget _buildLeftPanel() {
    final provider = context.watch<MediaProvider>();
    
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(
          right: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // パネルヘッダー
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              border: Border(
                bottom: BorderSide(color: ProTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.folder, size: 14, color: ProTheme.textSecondary),
                SizedBox(width: Spacing.xs),
                Text(
                  'フォルダー',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: ProTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                Icon(Icons.add, size: 14, color: ProTheme.textSecondary),
              ],
            ),
          ),
          
          // フォルダリスト
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.sm),
              children: [
                // ダイナミックフォルダ
                for (var entry in provider.filesByFolder.entries)
                  _buildFolderItem(
                    entry.key,
                    entry.value.length.toString(),
                    provider.currentFolder == entry.key,
                    () => provider.setCurrentFolder(entry.key),
                  ),
                
                const Divider(height: Spacing.lg),
                _buildSectionHeader('コレクション'),
                _buildFolderItem('お気に入り', '0', false, () {}),
                _buildFolderItem('編集済み', '0', false, () {}),
                
                const Divider(height: Spacing.lg),
                _buildSectionHeader('デバイス'),
                
                // 接続されたデバイス
                for (var device in provider.connectedDevices)
                  _buildFolderItem(device, '-', false, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ProTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFolderItem(String name, String count, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ProTheme.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder,
              size: 14,
              color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? ProTheme.textPrimary : ProTheme.textSecondary,
                ),
              ),
            ),
            Text(
              count,
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

  // メインビュー
  Widget _buildMainView() {
    final provider = context.watch<MediaProvider>();
    final currentFiles = provider.getCurrentFolderFiles();
    
    return Container(
      color: ProTheme.background,
      child: Column(
        children: [
          // パンくずリスト
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: const BoxDecoration(
              color: ProTheme.surface,
              border: Border(
                bottom: BorderSide(color: ProTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.home, size: 14, color: ProTheme.textSecondary),
                const Icon(Icons.chevron_right, size: 16, color: ProTheme.textDisabled),
                Text(
                  provider.currentFolder,
                  style: const TextStyle(fontSize: 12, color: ProTheme.textPrimary),
                ),
              ],
            ),
          ),
          
          // コンテンツ
          Expanded(
            child: provider.isImporting
                ? _buildImportingState(provider)
                : currentFiles.isEmpty
                    ? _buildEmptyState()
                    : _buildMediaGrid(currentFiles),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImportingState(MediaProvider provider) {
    final progressText = provider.progress < 0.3
        ? 'ファイル情報を読み込み中...'
        : 'サムネイルを生成中...';
    final progressPercentage = (provider.progress * 100).round();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: provider.progress),
          const SizedBox(height: Spacing.lg),
          Text(
            progressText,
            style: const TextStyle(
              color: ProTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            '$progressPercentage% 完了',
            style: const TextStyle(
              color: ProTheme.textDisabled,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: ProTheme.textDisabled,
          ),
          const SizedBox(height: Spacing.lg),
          const Text(
            'メディアファイルがありません',
            style: TextStyle(
              fontSize: 16,
              color: ProTheme.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const Text(
            'ファイルまたはフォルダを追加してください',
            style: TextStyle(
              fontSize: 12,
              color: ProTheme.textDisabled,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  context.read<MediaProvider>().selectFiles();
                },
                icon: const Icon(Icons.add_photo_alternate, size: 16),
                label: const Text('ファイルを選択'),
              ),
              const SizedBox(width: Spacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<MediaProvider>().selectFolder();
                },
                icon: const Icon(Icons.create_new_folder, size: 16),
                label: const Text('フォルダを選択'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List<MediaFile> files) {
    final provider = context.watch<MediaProvider>();
    
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: thumbnailSize,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) => _buildThumbnail(files[index], provider),
    );
  }

  Widget _buildThumbnail(MediaFile file, MediaProvider provider) {
    final isSelected = provider.selectedFiles.contains(file);
    
    return InkWell(
      onTap: () {
        provider.toggleFileSelection(file);
      },
      child: Container(
        decoration: BoxDecoration(
          color: ProTheme.surface,
          border: Border.all(
            color: isSelected ? ProTheme.accent : ProTheme.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // サムネイル
            if (file.thumbnailFile != null && file.thumbnailFile!.existsSync())
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.file(
                    file.thumbnailFile!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          file.type == MediaType.video
                              ? Icons.videocam
                              : file.type == MediaType.raw
                                  ? Icons.camera
                                  : Icons.image,
                          size: 32,
                          color: ProTheme.border,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Stack(
                children: [
                  Center(
                    child: Icon(
                      file.type == MediaType.video
                          ? Icons.videocam
                          : file.type == MediaType.raw
                              ? Icons.camera
                              : Icons.image,
                      size: 32,
                      color: ProTheme.border,
                    ),
                  ),
                  // サムネイル生成中のローディング表示
                  if (provider.isImporting)
                    const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ProTheme.accent),
                        ),
                      ),
                    ),
                ],
              ),
            
            // メタデータオーバーレイ
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(Spacing.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          file.extension,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          file.formattedSize,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // 選択チェックボックス
            if (isSelected)
              Positioned(
                top: Spacing.xs,
                right: Spacing.xs,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ProTheme.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 右パネル - メタデータ、ヒストグラム
  Widget _buildRightPanel() {
    final provider = context.watch<MediaProvider>();
    final selectedFile = provider.selectedFiles.isNotEmpty
        ? provider.selectedFiles.last
        : null;
    
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(
          left: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: ListView(
        children: [
          _buildPanelSection('ヒストグラム', _buildHistogram()),
          if (selectedFile != null)
            _buildPanelSection('メタデータ', _buildMetadata(selectedFile)),
          _buildPanelSection('キーワード', _buildKeywords()),
        ],
      ),
    );
  }

  Widget _buildPanelSection(String title, Widget content) {
    return Column(
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            border: Border(
              bottom: BorderSide(color: ProTheme.border, width: 1),
            ),
          ),
          child: Row(
            children: [
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
              const Icon(Icons.expand_less, size: 16, color: ProTheme.textSecondary),
            ],
          ),
        ),
        content,
      ],
    );
  }

  Widget _buildHistogram() {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: ProTheme.background,
        border: Border.all(color: ProTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'Histogram',
          style: TextStyle(
            fontSize: 11,
            color: ProTheme.textDisabled,
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata(MediaFile file) {
    final provider = context.watch<MediaProvider>();
    final metadata = provider.getMetadata(file.id);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本情報
          _buildMetadataSection('基本情報'),
          _buildMetadataRow('ファイル名', file.name),
          _buildMetadataRow('ファイルタイプ', file.extension),
          _buildMetadataRow('サイズ', file.formattedSize),
          _buildMetadataRow('作成日時', file.formattedDate),
          
          // 撮影情報（メタデータがある場合）
          if (metadata != null) ...[
            const SizedBox(height: Spacing.md),
            _buildMetadataSection('撮影情報'),
            if (metadata.cameraMake != null || metadata.cameraModel != null)
              _buildMetadataRow('カメラ', '${metadata.cameraMake ?? ''} ${metadata.cameraModel ?? ''}'.trim()),
            if (metadata.lensModel != null)
              _buildMetadataRow('レンズ', metadata.lensModel!),
            if (metadata.formattedDimensions.isNotEmpty)
              _buildMetadataRow('解像度', metadata.formattedDimensions),
            if (metadata.formattedDate.isNotEmpty)
              _buildMetadataRow('撮影日時', metadata.formattedDate),
            
            const SizedBox(height: Spacing.md),
            _buildMetadataSection('露出設定'),
            if (metadata.formattedISO.isNotEmpty)
              _buildMetadataRow('ISO', metadata.formattedISO),
            if (metadata.formattedAperture.isNotEmpty)
              _buildMetadataRow('絞り', metadata.formattedAperture),
            if (metadata.formattedExposure.isNotEmpty)
              _buildMetadataRow('シャッター速度', metadata.formattedExposure),
            if (metadata.formattedFocalLength.isNotEmpty)
              _buildMetadataRow('焦点距離', metadata.formattedFocalLength),
            
            // 位置情報
            if (metadata.formattedLocation.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              _buildMetadataSection('位置情報'),
              _buildMetadataRow('GPS', metadata.formattedLocation),
            ],
            
            // その他の情報
            if (metadata.copyright != null || metadata.artist != null || metadata.software != null) ...[
              const SizedBox(height: Spacing.md),
              _buildMetadataSection('その他'),
              if (metadata.copyright != null)
                _buildMetadataRow('著作権', metadata.copyright!),
              if (metadata.artist != null)
                _buildMetadataRow('作者', metadata.artist!),
              if (metadata.software != null)
                _buildMetadataRow('ソフトウェア', metadata.software!),
            ],
          ] else ...[
            const SizedBox(height: Spacing.md),
            Center(
              child: Text(
                'メタデータを読み込み中...',
                style: TextStyle(
                  fontSize: 11,
                  color: ProTheme.textDisabled,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMetadataSection(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ProTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ProTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: ProTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywords() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Wrap(
        spacing: Spacing.xs,
        runSpacing: Spacing.xs,
        children: [
          _buildKeywordChip('未分類'),
        ],
      ),
    );
  }

  Widget _buildKeywordChip(String keyword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: ProTheme.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ProTheme.border),
      ),
      child: Text(
        keyword,
        style: const TextStyle(
          fontSize: 11,
          color: ProTheme.textSecondary,
        ),
      ),
    );
  }

  // ステータスバー
  Widget _buildStatusBar() {
    final provider = context.watch<MediaProvider>();
    
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(
          top: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${provider.files.length} 枚の写真',
            style: const TextStyle(fontSize: 11, color: ProTheme.textSecondary),
          ),
          const SizedBox(width: Spacing.lg),
          if (provider.selectedFiles.isNotEmpty) ...[
            Text(
              '${provider.selectedFiles.length} 枚選択中',
              style: const TextStyle(fontSize: 11, color: ProTheme.textSecondary),
            ),
            const SizedBox(width: Spacing.lg),
          ],
          Text(
            '画像: ${provider.imageCount} | 動画: ${provider.videoCount}',
            style: const TextStyle(fontSize: 11, color: ProTheme.textSecondary),
          ),
          const Spacer(),
          if (provider.isImporting) ...[
            Text(
              'インポート中... (${(provider.progress * 100).round()}%)',
              style: const TextStyle(
                fontSize: 11,
                color: ProTheme.warning,
              ),
            ),
          ] else ...[
            Text(
              '準備完了',
              style: const TextStyle(
                fontSize: 11,
                color: ProTheme.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showImportScreen() async {
    final provider = context.read<MediaProvider>();
    if (provider.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('インポートするファイルを選択してください'),
        ),
      );
      return;
    }
    
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: ProTheme.background,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: const ImportScreen(),
        ),
      ),
    );
    
    if (result != null) {
      // インポート完了後の処理
      setState(() {
        selectedModule = 0; // ライブラリモジュールに戻る
      });
    }
  }
  
  void _showExportScreen() {
    final provider = context.read<MediaProvider>();
    
    if (provider.selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('エクスポートするファイルを選択してください'),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportScreen(
          selectedFiles: provider.selectedFiles.toList(),
        ),
      ),
    );
  }
}