import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design/professional_theme.dart';
import '../providers/media_provider.dart';
import '../services/import_service.dart';
import '../models/media_file.dart';
import 'package:path/path.dart' as path;

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  ImportStrategy _importStrategy = ImportStrategy.copy;
  OrganizeStrategy _organizeStrategy = OrganizeStrategy.byDate;
  String _destinationPath = '';
  bool _detectDuplicates = true;
  bool _renameFiles = false;
  String _fileNamePattern = '{year}-{month}-{day}_{original}';
  bool _isImporting = false;
  double _importProgress = 0.0;
  String _currentFile = '';
  ImportResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
  }

  Future<void> _loadDefaultPath() async {
    final defaultPath = await ImportService.instance.getDefaultImportDirectory();
    setState(() {
      _destinationPath = defaultPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final selectedFiles = provider.selectedFiles.isNotEmpty 
        ? provider.selectedFiles 
        : provider.files;

    return Container(
      color: ProTheme.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                // 左側: インポート設定
                Container(
                  width: 350,
                  decoration: const BoxDecoration(
                    color: ProTheme.surface,
                    border: Border(
                      right: BorderSide(color: ProTheme.border, width: 1),
                    ),
                  ),
                  child: _buildSettings(),
                ),
                // 右側: プレビューとステータス
                Expanded(
                  child: _buildPreview(selectedFiles),
                ),
              ],
            ),
          ),
          _buildActionBar(selectedFiles),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(
          bottom: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.download, size: 20, color: ProTheme.accent),
          const SizedBox(width: Spacing.md),
          const Text(
            'インポート設定',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ProTheme.textPrimary,
            ),
          ),
          const Spacer(),
          if (_lastResult != null)
            Text(
              _lastResult!.summary,
              style: TextStyle(
                fontSize: 12,
                color: _lastResult!.isSuccess ? ProTheme.success : ProTheme.warning,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        _buildSectionTitle('インポート方法'),
        _buildRadioOption(
          'ファイルをコピー',
          'オリジナルファイルを残してコピーを作成',
          ImportStrategy.copy,
          _importStrategy,
          (value) => setState(() => _importStrategy = value!),
        ),
        _buildRadioOption(
          'ファイルを移動',
          'オリジナルファイルを新しい場所に移動',
          ImportStrategy.move,
          _importStrategy,
          (value) => setState(() => _importStrategy = value!),
        ),
        _buildRadioOption(
          '参照のみ',
          'ファイルをコピーせず参照情報のみ保存',
          ImportStrategy.reference,
          _importStrategy,
          (value) => setState(() => _importStrategy = value!),
        ),

        const SizedBox(height: Spacing.xl),
        _buildSectionTitle('整理方法'),
        _buildRadioOption(
          '日付別',
          '撮影日ごとにフォルダを作成',
          OrganizeStrategy.byDate,
          _organizeStrategy,
          (value) => setState(() => _organizeStrategy = value!),
        ),
        _buildRadioOption(
          'デバイス別',
          'デバイスごとにフォルダを作成',
          OrganizeStrategy.byDevice,
          _organizeStrategy,
          (value) => setState(() => _organizeStrategy = value!),
        ),
        _buildRadioOption(
          'ファイルタイプ別',
          '画像、動画、RAWごとにフォルダを作成',
          OrganizeStrategy.byType,
          _organizeStrategy,
          (value) => setState(() => _organizeStrategy = value!),
        ),
        _buildRadioOption(
          '整理しない',
          'すべてのファイルを同じフォルダに保存',
          OrganizeStrategy.none,
          _organizeStrategy,
          (value) => setState(() => _organizeStrategy = value!),
        ),

        const SizedBox(height: Spacing.xl),
        _buildSectionTitle('保存先'),
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: ProTheme.background,
            border: Border.all(color: ProTheme.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _destinationPath.isEmpty ? '保存先を選択...' : _destinationPath,
                style: const TextStyle(
                  fontSize: 12,
                  color: ProTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.sm),
              ElevatedButton.icon(
                onPressed: _selectDestination,
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('フォルダを選択'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacing.xl),
        _buildSectionTitle('オプション'),
        _buildCheckbox(
          '重複を検出',
          '同じファイルが既に存在する場合はスキップ',
          _detectDuplicates,
          (value) => setState(() => _detectDuplicates = value!),
        ),
        _buildCheckbox(
          'ファイル名を変更',
          'パターンに基づいてファイル名を変更',
          _renameFiles,
          (value) => setState(() => _renameFiles = value!),
        ),

        if (_renameFiles) ...[
          const SizedBox(height: Spacing.md),
          TextField(
            decoration: const InputDecoration(
              labelText: 'ファイル名パターン',
              hintText: '{year}-{month}-{day}_{original}',
              helperText: '使用可能: {year}, {month}, {day}, {hour}, {minute}, {second}, {original}',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(Spacing.md),
            ),
            style: const TextStyle(fontSize: 12),
            controller: TextEditingController(text: _fileNamePattern),
            onChanged: (value) => _fileNamePattern = value,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ProTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRadioOption<T>(
    String title,
    String subtitle,
    T value,
    T groupValue,
    Function(T?) onChanged,
  ) {
    return RadioListTile<T>(
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: ProTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: ProTheme.textSecondary),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCheckbox(
    String title,
    String subtitle,
    bool value,
    Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: ProTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: ProTheme.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPreview(List<MediaFile> files) {
    if (_isImporting) {
      return _buildImportProgress();
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'インポート予定: ${files.length}ファイル',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ProTheme.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          
          // ファイルリスト
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ProTheme.surface,
                border: Border.all(color: ProTheme.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(Spacing.md),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return _buildFilePreviewItem(file);
                },
              ),
            ),
          ),

          const SizedBox(height: Spacing.lg),
          _buildStorageInfo(),
        ],
      ),
    );
  }

  Widget _buildFilePreviewItem(MediaFile file) {
    final destPath = _getPreviewDestPath(file);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // サムネイル
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ProTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: file.thumbnailFile != null && file.thumbnailFile!.existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      file.thumbnailFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    file.type == MediaType.video
                        ? Icons.videocam
                        : file.type == MediaType.raw
                            ? Icons.camera
                            : Icons.image,
                    size: 20,
                    color: ProTheme.textDisabled,
                  ),
          ),
          const SizedBox(width: Spacing.md),
          
          // ファイル情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ProTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '→ $destPath',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ProTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // サイズ
          Text(
            file.formattedSize,
            style: const TextStyle(
              fontSize: 11,
              color: ProTheme.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  String _getPreviewDestPath(MediaFile file) {
    if (_destinationPath.isEmpty) return '未設定';
    
    String subPath = '';
    switch (_organizeStrategy) {
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
        subPath = file.type == MediaType.video ? '動画' : '画像';
        break;
      default:
        break;
    }
    
    final fileName = _renameFiles 
        ? _generatePreviewFileName(file)
        : path.basename(file.path);
    
    return path.join(path.basename(_destinationPath), subPath, fileName);
  }

  String _generatePreviewFileName(MediaFile file) {
    final now = file.createdDate ?? DateTime.now();
    final extension = path.extension(file.path);
    final originalName = path.basenameWithoutExtension(file.path);
    
    String fileName = _fileNamePattern;
    fileName = fileName.replaceAll('{year}', now.year.toString());
    fileName = fileName.replaceAll('{month}', now.month.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{day}', now.day.toString().padLeft(2, '0'));
    fileName = fileName.replaceAll('{original}', originalName);
    
    return fileName + extension;
  }

  Widget _buildImportProgress() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _importProgress),
            const SizedBox(height: Spacing.lg),
            Text(
              'インポート中... ${(_importProgress * 100).round()}%',
              style: const TextStyle(
                fontSize: 14,
                color: ProTheme.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              _currentFile,
              style: const TextStyle(
                fontSize: 12,
                color: ProTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacing.xl),
            OutlinedButton(
              onPressed: _cancelImport,
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfo() {
    // TODO: 実際のストレージ情報を取得
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: ProTheme.surface,
        border: Border.all(color: ProTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: const [
          Icon(Icons.storage, size: 16, color: ProTheme.textSecondary),
          SizedBox(width: Spacing.sm),
          Text(
            '空き容量: 計算中...',
            style: TextStyle(
              fontSize: 12,
              color: ProTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(List<MediaFile> files) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(
          top: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${files.length}ファイルを選択中',
            style: const TextStyle(
              fontSize: 12,
              color: ProTheme.textSecondary,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          const SizedBox(width: Spacing.md),
          ElevatedButton.icon(
            onPressed: _destinationPath.isNotEmpty && !_isImporting
                ? () => _startImport(files)
                : null,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('インポート開始'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDestination() async {
    // TODO: ディレクトリ選択ダイアログを実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('フォルダ選択機能は開発中です')),
    );
  }

  Future<void> _startImport(List<MediaFile> files) async {
    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
      _currentFile = '';
    });

    final options = ImportOptions(
      importStrategy: _importStrategy,
      organizeStrategy: _organizeStrategy,
      destinationPath: _destinationPath,
      detectDuplicates: _detectDuplicates,
      renameFiles: _renameFiles,
      fileNamePattern: _fileNamePattern,
    );

    final result = await ImportService.instance.importFiles(
      files,
      options,
      onProgress: (progress, currentFile) {
        setState(() {
          _importProgress = progress;
          _currentFile = currentFile;
        });
      },
    );

    await ImportService.instance.saveImportHistory(result);

    setState(() {
      _isImporting = false;
      _lastResult = result;
    });

    if (result.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.summary),
            backgroundColor: ProTheme.success,
          ),
        );
        Navigator.pop(context, result);
      }
    } else {
      if (mounted) {
        _showErrorDialog(result);
      }
    }
  }

  void _cancelImport() {
    ImportService.instance.cancelImport();
    setState(() {
      _isImporting = false;
    });
  }

  void _showErrorDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('インポートエラー'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.summary),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              const Text('エラー詳細:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.map((e) => Text('• $e')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}