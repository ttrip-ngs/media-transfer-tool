import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../core/design/professional_theme.dart';
import '../services/export_service.dart';
import '../models/media_file.dart';
import '../providers/media_provider.dart';

class ExportScreen extends StatefulWidget {
  final List<MediaFile> selectedFiles;
  
  const ExportScreen({
    Key? key,
    required this.selectedFiles,
  }) : super(key: key);

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _destinationController = TextEditingController();
  final _filenameTemplateController = TextEditingController(text: '{original}');
  final _watermarkTextController = TextEditingController();
  final _watermarkImageController = TextEditingController();
  
  ExportFormat _format = ExportFormat.original;
  ExportSize _size = ExportSize.original;
  ExportQuality _quality = ExportQuality.high;
  int? _customWidth;
  int? _customHeight;
  int _customQuality = 85;
  bool _preserveMetadata = true;
  bool _renameFiles = false;
  bool _createSubfolders = false;
  String _folderStructure = 'none';
  
  // ウォーターマーク設定
  bool _enableWatermark = false;
  String _watermarkType = 'text'; // 'text' or 'image'
  WatermarkPosition _watermarkPosition = WatermarkPosition.bottomRight;
  double _watermarkOpacity = 0.5;
  double _watermarkScale = 1.0;
  Color _watermarkColor = Colors.white;
  
  // エクスポート進行状況
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _currentFile = '';
  
  @override
  void dispose() {
    _destinationController.dispose();
    _filenameTemplateController.dispose();
    _watermarkTextController.dispose();
    _watermarkImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProTheme.background,
      appBar: AppBar(
        title: Text('エクスポート (${widget.selectedFiles.length}ファイル)'),
        backgroundColor: ProTheme.surface,
        foregroundColor: ProTheme.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ProTheme.border),
        ),
      ),
      body: _isExporting ? _buildExportProgress() : _buildExportSettings(),
      bottomNavigationBar: _isExporting ? null : _buildActionButtons(),
    );
  }
  
  Widget _buildExportProgress() {
    return Container(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.upload,
            size: 80,
            color: ProTheme.accent,
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'エクスポート中...',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: ProTheme.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          LinearProgressIndicator(
            value: _exportProgress,
            backgroundColor: ProTheme.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(ProTheme.accent),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            '${(_exportProgress * 100).toInt()}% 完了',
            style: const TextStyle(
              fontSize: 16,
              color: ProTheme.textSecondary,
            ),
          ),
          if (_currentFile.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              '処理中: $_currentFile',
              style: const TextStyle(
                fontSize: 12,
                color: ProTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Spacing.xl),
          OutlinedButton(
            onPressed: () {
              ExportService.instance.cancelExport();
              setState(() {
                _isExporting = false;
                _exportProgress = 0.0;
                _currentFile = '';
              });
            },
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExportSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDestinationSection(),
          const SizedBox(height: Spacing.xl),
          _buildFormatSection(),
          const SizedBox(height: Spacing.xl),
          _buildSizeSection(),
          const SizedBox(height: Spacing.xl),
          _buildQualitySection(),
          const SizedBox(height: Spacing.xl),
          _buildFileNamingSection(),
          const SizedBox(height: Spacing.xl),
          _buildOrganizationSection(),
          const SizedBox(height: Spacing.xl),
          _buildWatermarkSection(),
          const SizedBox(height: Spacing.xl),
          _buildMetadataSection(),
        ],
      ),
    );
  }
  
  Widget _buildDestinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('エクスポート先'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  hintText: 'フォルダを選択してください',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(width: Spacing.md),
            ElevatedButton.icon(
              onPressed: _selectDestination,
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('選択'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('フォーマット'),
        Wrap(
          spacing: Spacing.md,
          children: ExportFormat.values.map((format) {
            return ChoiceChip(
              label: Text(_getFormatLabel(format)),
              selected: _format == format,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _format = format);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('サイズ'),
        Wrap(
          spacing: Spacing.md,
          runSpacing: Spacing.sm,
          children: ExportSize.values.map((size) {
            return ChoiceChip(
              label: Text(_getSizeLabel(size)),
              selected: _size == size,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _size = size);
                }
              },
            );
          }).toList(),
        ),
        if (_size == ExportSize.custom) ...[
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '幅 (px)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _customWidth = int.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '高さ (px)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _customHeight = int.tryParse(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('品質'),
        Wrap(
          spacing: Spacing.md,
          children: ExportQuality.values.map((quality) {
            return ChoiceChip(
              label: Text(_getQualityLabel(quality)),
              selected: _quality == quality,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _quality = quality);
                }
              },
            );
          }).toList(),
        ),
        if (_quality == ExportQuality.custom) ...[
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              const Text('品質: '),
              Expanded(
                child: Slider(
                  value: _customQuality.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 18,
                  label: '$_customQuality%',
                  onChanged: (value) {
                    setState(() => _customQuality = value.toInt());
                  },
                ),
              ),
              Text('$_customQuality%'),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildFileNamingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ファイル名'),
        Row(
          children: [
            Checkbox(
              value: _renameFiles,
              onChanged: (value) {
                setState(() => _renameFiles = value ?? false);
              },
            ),
            const Text('ファイル名を変更する'),
          ],
        ),
        if (_renameFiles) ...[
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _filenameTemplateController,
            decoration: const InputDecoration(
              labelText: 'ファイル名テンプレート',
              hintText: '{original}, {year}-{month}-{day}_{counter}',
              border: OutlineInputBorder(),
              helperText: '使用可能: {original}, {year}, {month}, {day}, {hour}, {minute}, {second}, {counter}',
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildOrganizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('フォルダ構成'),
        Row(
          children: [
            Checkbox(
              value: _createSubfolders,
              onChanged: (value) {
                setState(() => _createSubfolders = value ?? false);
              },
            ),
            const Text('サブフォルダを作成'),
          ],
        ),
        if (_createSubfolders) ...[
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<String>(
            value: _folderStructure,
            decoration: const InputDecoration(
              labelText: 'フォルダ構成',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('なし')),
              DropdownMenuItem(value: 'date', child: Text('日付別')),
              DropdownMenuItem(value: 'type', child: Text('ファイル種別')),
              DropdownMenuItem(value: 'size', child: Text('サイズ別')),
            ],
            onChanged: (value) {
              setState(() => _folderStructure = value ?? 'none');
            },
          ),
        ],
      ],
    );
  }
  
  Widget _buildWatermarkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ウォーターマーク'),
        Row(
          children: [
            Checkbox(
              value: _enableWatermark,
              onChanged: (value) {
                setState(() => _enableWatermark = value ?? false);
              },
            ),
            const Text('ウォーターマークを追加'),
          ],
        ),
        if (_enableWatermark) ...[
          const SizedBox(height: Spacing.md),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'text', label: Text('テキスト')),
              ButtonSegment(value: 'image', label: Text('画像')),
            ],
            selected: {_watermarkType},
            onSelectionChanged: (Set<String> selection) {
              setState(() => _watermarkType = selection.first);
            },
          ),
          const SizedBox(height: Spacing.md),
          if (_watermarkType == 'text')
            TextField(
              controller: _watermarkTextController,
              decoration: const InputDecoration(
                labelText: 'ウォーターマークテキスト',
                border: OutlineInputBorder(),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _watermarkImageController,
                    decoration: const InputDecoration(
                      labelText: '画像ファイル',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                ElevatedButton(
                  onPressed: _selectWatermarkImage,
                  child: const Text('選択'),
                ),
              ],
            ),
          const SizedBox(height: Spacing.md),
          _buildWatermarkSettings(),
        ],
      ],
    );
  }
  
  Widget _buildWatermarkSettings() {
    return Column(
      children: [
        // 位置設定
        DropdownButtonFormField<WatermarkPosition>(
          value: _watermarkPosition,
          decoration: const InputDecoration(
            labelText: '位置',
            border: OutlineInputBorder(),
          ),
          items: WatermarkPosition.values.map((position) {
            return DropdownMenuItem(
              value: position,
              child: Text(_getPositionLabel(position)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _watermarkPosition = value);
            }
          },
        ),
        const SizedBox(height: Spacing.md),
        // 透明度設定
        Row(
          children: [
            const Text('透明度: '),
            Expanded(
              child: Slider(
                value: _watermarkOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(_watermarkOpacity * 100).toInt()}%',
                onChanged: (value) {
                  setState(() => _watermarkOpacity = value);
                },
              ),
            ),
            Text('${(_watermarkOpacity * 100).toInt()}%'),
          ],
        ),
        // スケール設定
        Row(
          children: [
            const Text('サイズ: '),
            Expanded(
              child: Slider(
                value: _watermarkScale,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                label: '${(_watermarkScale * 100).toInt()}%',
                onChanged: (value) {
                  setState(() => _watermarkScale = value);
                },
              ),
            ),
            Text('${(_watermarkScale * 100).toInt()}%'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('メタデータ'),
        Row(
          children: [
            Checkbox(
              value: _preserveMetadata,
              onChanged: (value) {
                setState(() => _preserveMetadata = value ?? true);
              },
            ),
            const Text('メタデータを保持'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ProTheme.textPrimary,
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(top: BorderSide(color: ProTheme.border)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _canExport ? _startExport : null,
            icon: const Icon(Icons.upload, size: 16),
            label: const Text('エクスポート開始'),
          ),
        ],
      ),
    );
  }
  
  bool get _canExport {
    return _destinationController.text.isNotEmpty && widget.selectedFiles.isNotEmpty;
  }
  
  Future<void> _selectDestination() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _destinationController.text = result;
      });
    }
  }
  
  Future<void> _selectWatermarkImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _watermarkImageController.text = result.files.first.path!;
      });
    }
  }
  
  Future<void> _startExport() async {
    if (!_canExport) return;
    
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _currentFile = '';
    });
    
    final options = ExportOptions(
      format: _format,
      size: _size,
      quality: _quality,
      customWidth: _customWidth,
      customHeight: _customHeight,
      customQuality: _customQuality,
      preserveMetadata: _preserveMetadata,
      renameFiles: _renameFiles,
      fileNameTemplate: _renameFiles ? _filenameTemplateController.text : null,
      watermark: _enableWatermark ? WatermarkSettings(
        text: _watermarkType == 'text' ? _watermarkTextController.text : null,
        imagePath: _watermarkType == 'image' ? _watermarkImageController.text : null,
        position: _watermarkPosition,
        opacity: _watermarkOpacity,
        scale: _watermarkScale,
        color: _watermarkColor,
      ) : null,
      createSubfolders: _createSubfolders,
      folderStructure: _folderStructure,
      destinationPath: _destinationController.text,
    );
    
    try {
      final result = await ExportService.instance.exportFiles(
        widget.selectedFiles,
        options,
        onProgress: (progress, currentFile) {
          setState(() {
            _exportProgress = progress;
            _currentFile = currentFile;
          });
        },
      );
      
      setState(() {
        _isExporting = false;
      });
      
      if (mounted) {
        _showExportResult(result);
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _exportProgress = 0.0;
        _currentFile = '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートエラー: $e'),
            backgroundColor: ProTheme.error,
          ),
        );
      }
    }
  }
  
  void _showExportResult(ExportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.isSuccess ? 'エクスポート完了' : 'エクスポート結果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.summary),
            const SizedBox(height: Spacing.md),
            Text('処理時間: ${result.exportTime.inSeconds}秒'),
            Text('合計サイズ: ${_formatFileSize(result.totalSize)}'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              const Text('エラー:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.map((error) => Text('• $error', style: const TextStyle(fontSize: 12))),
            ],
          ],
        ),
        actions: [
          if (result.isSuccess)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('完了'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
        ],
      ),
    );
  }
  
  String _getFormatLabel(ExportFormat format) {
    switch (format) {
      case ExportFormat.original: return 'オリジナル';
      case ExportFormat.jpeg: return 'JPEG';
      case ExportFormat.png: return 'PNG';
      case ExportFormat.webp: return 'WebP';
      case ExportFormat.tiff: return 'TIFF';
    }
  }
  
  String _getSizeLabel(ExportSize size) {
    switch (size) {
      case ExportSize.original: return 'オリジナル';
      case ExportSize.large: return '大 (2048px)';
      case ExportSize.medium: return '中 (1200px)';
      case ExportSize.small: return '小 (800px)';
      case ExportSize.custom: return 'カスタム';
    }
  }
  
  String _getQualityLabel(ExportQuality quality) {
    switch (quality) {
      case ExportQuality.maximum: return '最高';
      case ExportQuality.high: return '高';
      case ExportQuality.medium: return '中';
      case ExportQuality.low: return '低';
      case ExportQuality.custom: return 'カスタム';
    }
  }
  
  String _getPositionLabel(WatermarkPosition position) {
    switch (position) {
      case WatermarkPosition.topLeft: return '左上';
      case WatermarkPosition.topRight: return '右上';
      case WatermarkPosition.bottomLeft: return '左下';
      case WatermarkPosition.bottomRight: return '右下';
      case WatermarkPosition.center: return '中央';
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}