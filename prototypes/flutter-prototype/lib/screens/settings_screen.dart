import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/design/professional_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _defaultImportPathController = TextEditingController();
  final _defaultExportPathController = TextEditingController();
  final _thumbnailCacheSizeController = TextEditingController(text: '1000');
  
  // 一般設定
  bool _autoDetectDevices = true;
  bool _showPreviewOnImport = true;
  bool _generateThumbnailsOnImport = true;
  bool _preserveOriginalFiles = true;
  String _defaultImportNaming = 'original';
  
  // 表示設定
  String _defaultViewMode = 'grid';
  int _defaultThumbnailSize = 160;
  bool _showFileExtensions = true;
  bool _showFileDates = true;
  bool _showFileSize = false;
  String _dateFormat = 'yyyy/MM/dd';
  String _language = 'ja';
  
  // パフォーマンス設定
  int _maxThumbnailCacheSize = 1000;
  bool _enableBackgroundProcessing = true;
  int _maxConcurrentTasks = 4;
  bool _enableHardwareAcceleration = true;
  
  // セキュリティ設定
  bool _enableExifStripping = false;
  bool _enableLocationPrivacy = false;
  bool _requireConfirmationForDelete = true;
  bool _enableSecureDelete = false;
  
  // エクスポート設定
  String _defaultExportFormat = 'original';
  String _defaultExportQuality = 'high';
  bool _preserveMetadataOnExport = true;
  bool _addWatermarkByDefault = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _defaultImportPathController.dispose();
    _defaultExportPathController.dispose();
    _thumbnailCacheSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProTheme.background,
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: ProTheme.surface,
        foregroundColor: ProTheme.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ProTheme.border),
        ),
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text('デフォルトに戻す'),
          ),
          const SizedBox(width: Spacing.md),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
          const SizedBox(width: Spacing.md),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          const VerticalDivider(width: 1, color: ProTheme.border),
          Expanded(child: _buildSettingsContent()),
        ],
      ),
    );
  }
  
  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: ProTheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          _buildSidebarItem('一般', Icons.settings, 0),
          _buildSidebarItem('表示', Icons.visibility, 1),
          _buildSidebarItem('インポート', Icons.download, 2),
          _buildSidebarItem('エクスポート', Icons.upload, 3),
          _buildSidebarItem('パフォーマンス', Icons.speed, 4),
          _buildSidebarItem('セキュリティ', Icons.security, 5),
          _buildSidebarItem('詳細', Icons.tune, 6),
        ],
      ),
    );
  }
  
  int _selectedCategory = 0;
  
  Widget _buildSidebarItem(String title, IconData icon, int index) {
    final isSelected = _selectedCategory == index;
    
    return InkWell(
      onTap: () => setState(() => _selectedCategory = index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ProTheme.accent.withOpacity(0.1) : null,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: ProTheme.accent, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? ProTheme.textPrimary : ProTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryTitle(),
          const SizedBox(height: Spacing.xl),
          _buildCategoryContent(),
        ],
      ),
    );
  }
  
  Widget _buildCategoryTitle() {
    final titles = [
      '一般設定',
      '表示設定',
      'インポート設定',
      'エクスポート設定',
      'パフォーマンス設定',
      'セキュリティ設定',
      '詳細設定',
    ];
    
    return Text(
      titles[_selectedCategory],
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ProTheme.textPrimary,
      ),
    );
  }
  
  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 0: return _buildGeneralSettings();
      case 1: return _buildDisplaySettings();
      case 2: return _buildImportSettings();
      case 3: return _buildExportSettings();
      case 4: return _buildPerformanceSettings();
      case 5: return _buildSecuritySettings();
      case 6: return _buildAdvancedSettings();
      default: return const SizedBox();
    }
  }
  
  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingGroup(
          'デバイス検出',
          [
            _buildSwitchSetting(
              'デバイスを自動検出',
              '接続されたカメラやスマートフォンを自動的に検出します',
              _autoDetectDevices,
              (value) => setState(() => _autoDetectDevices = value),
            ),
          ],
        ),
        
        _buildSettingGroup(
          'デフォルトパス',
          [
            _buildPathSetting(
              'デフォルトインポート先',
              _defaultImportPathController,
              () => _selectDefaultImportPath(),
            ),
            _buildPathSetting(
              'デフォルトエクスポート先',
              _defaultExportPathController,
              () => _selectDefaultExportPath(),
            ),
          ],
        ),
        
        _buildSettingGroup(
          '言語設定',
          [
            _buildDropdownSetting(
              '表示言語',
              _language,
              const {
                'ja': '日本語',
                'en': 'English',
              },
              (value) => setState(() => _language = value),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDisplaySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingGroup(
          '表示モード',
          [
            _buildDropdownSetting(
              'デフォルト表示モード',
              _defaultViewMode,
              const {
                'grid': 'グリッド表示',
                'list': 'リスト表示',
                'filmstrip': 'フィルムストリップ',
              },
              (value) => setState(() => _defaultViewMode = value),
            ),
          ],
        ),
        
        _buildSettingGroup(
          'サムネイル',
          [
            _buildSliderSetting(
              'デフォルトサムネイルサイズ',
              _defaultThumbnailSize.toDouble(),
              80,
              300,
              (value) => setState(() => _defaultThumbnailSize = value.round()),
              '${_defaultThumbnailSize}px',
            ),
          ],
        ),
        
        _buildSettingGroup(
          'ファイル情報表示',
          [
            _buildSwitchSetting(
              'ファイル拡張子を表示',
              'ファイル名に拡張子を表示します',
              _showFileExtensions,
              (value) => setState(() => _showFileExtensions = value),
            ),
            _buildSwitchSetting(
              'ファイル日付を表示',
              'ファイルの作成日時を表示します',
              _showFileDates,
              (value) => setState(() => _showFileDates = value),
            ),
            _buildSwitchSetting(
              'ファイルサイズを表示',
              'ファイルのサイズを表示します',
              _showFileSize,
              (value) => setState(() => _showFileSize = value),
            ),
          ],
        ),
        
        _buildSettingGroup(
          '日付形式',
          [
            _buildDropdownSetting(
              '日付表示形式',
              _dateFormat,
              const {
                'yyyy/MM/dd': '2024/01/15',
                'yyyy-MM-dd': '2024-01-15',
                'dd/MM/yyyy': '15/01/2024',
                'MM/dd/yyyy': '01/15/2024',
              },
              (value) => setState(() => _dateFormat = value),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildImportSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingGroup(
          'インポート動作',
          [
            _buildSwitchSetting(
              'インポート時にプレビューを表示',
              'ファイルをインポートする前にプレビューを表示します',
              _showPreviewOnImport,
              (value) => setState(() => _showPreviewOnImport = value),
            ),
            _buildSwitchSetting(
              'インポート時にサムネイル生成',
              'ファイルインポート時に自動でサムネイルを生成します',
              _generateThumbnailsOnImport,
              (value) => setState(() => _generateThumbnailsOnImport = value),
            ),
            _buildSwitchSetting(
              'オリジナルファイルを保持',
              'インポート後もデバイス上のオリジナルファイルを残します',
              _preserveOriginalFiles,
              (value) => setState(() => _preserveOriginalFiles = value),
            ),
          ],
        ),
        
        _buildSettingGroup(
          'ファイル名設定',
          [
            _buildDropdownSetting(
              'デフォルトファイル名規則',
              _defaultImportNaming,
              const {
                'original': 'オリジナル名を保持',
                'date': '日付ベース (YYYYMMDD_HHMMSS)',
                'counter': '連番 (IMG_0001, IMG_0002...)',
                'custom': 'カスタムテンプレート',
              },
              (value) => setState(() => _defaultImportNaming = value),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildExportSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingGroup(
          'デフォルトエクスポート設定',
          [
            _buildDropdownSetting(
              'デフォルト形式',
              _defaultExportFormat,
              const {
                'original': 'オリジナル',
                'jpeg': 'JPEG',
                'png': 'PNG',
                'webp': 'WebP',
                'tiff': 'TIFF',
              },
              (value) => setState(() => _defaultExportFormat = value),
            ),
            _buildDropdownSetting(
              'デフォルト品質',
              _defaultExportQuality,
              const {
                'maximum': '最高品質',
                'high': '高品質',
                'medium': '中品質',
                'low': '低品質',
              },
              (value) => setState(() => _defaultExportQuality = value),
            ),
          ],
        ),
        
        _buildSettingGroup(
          'メタデータ',
          [
            _buildSwitchSetting(
              'エクスポート時にメタデータを保持',
              'エクスポートしたファイルにメタデータを含めます',
              _preserveMetadataOnExport,
              (value) => setState(() => _preserveMetadataOnExport = value),
            ),
          ],
        ),
        
        _buildSettingGroup(
          'ウォーターマーク',
          [
            _buildSwitchSetting(
              'デフォルトでウォーターマークを追加',
              'エクスポート時に自動でウォーターマークを追加します',
              _addWatermarkByDefault,
              (value) => setState(() => _addWatermarkByDefault = value),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPerformanceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingGroup(
          'サムネイルキャッシュ',
          [
            _buildTextFieldSetting(
              '最大キャッシュサイズ (枚数)',
              _thumbnailCacheSizeController,
              '生成されたサムネイルをキャッシュする最大数',
              TextInputType.number,
            ),
          ],
        ),
        
        _buildSettingGroup(
          'バックグラウンド処理',
          [
            _buildSwitchSetting(
              'バックグラウンド処理を有効化',
              'サムネイル生成などを背景で実行します',
              _enableBackgroundProcessing,
              (value) => setState(() => _enableBackgroundProcessing = value),
            ),
            _buildSliderSetting(
              '最大同時処理タスク数',
              _maxConcurrentTasks.toDouble(),
              1,
              8,
              (value) => setState(() => _maxConcurrentTasks = value.round()),
              '$_maxConcurrentTasks タスク',
            ),
          ],
        ),
        
        _buildSettingGroup(
          'ハードウェア最適化',
          [
            _buildSwitchSetting(
              'ハードウェアアクセラレーションを使用',
              'GPUによる処理の高速化を有効にします',
              _enableHardwareAcceleration,
              (value) => setState(() => _enableHardwareAcceleration = value),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSecuritySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingGroup(
          'プライバシー保護',
          [
            _buildSwitchSetting(
              'EXIF情報を自動削除',
              'エクスポート時にEXIF情報を自動的に削除します',
              _enableExifStripping,
              (value) => setState(() => _enableExifStripping = value),
            ),
            _buildSwitchSetting(
              '位置情報のプライバシー保護',
              'GPS座標などの位置情報を削除します',
              _enableLocationPrivacy,
              (value) => setState(() => _enableLocationPrivacy = value),
            ),
          ],
        ),
        
        _buildSettingGroup(
          'ファイル操作',
          [
            _buildSwitchSetting(
              'ファイル削除時に確認を求める',
              'ファイルを削除する前に確認ダイアログを表示します',
              _requireConfirmationForDelete,
              (value) => setState(() => _requireConfirmationForDelete = value),
            ),
            _buildSwitchSetting(
              'セキュア削除を有効化',
              'ファイルを完全に削除して復元不可能にします',
              _enableSecureDelete,
              (value) => setState(() => _enableSecureDelete = value),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingGroup(
          'デバッグ',
          [
            _buildActionSetting(
              'ログファイルを表示',
              'アプリケーションのログファイルを開きます',
              () => _showLogFiles(),
            ),
            _buildActionSetting(
              'キャッシュをクリア',
              'サムネイルキャッシュとメタデータキャッシュを削除します',
              () => _clearCache(),
            ),
            _buildActionSetting(
              'データベースを再構築',
              'メディアデータベースを再構築します',
              () => _rebuildDatabase(),
            ),
          ],
        ),
        
        _buildSettingGroup(
          'バックアップ・復元',
          [
            _buildActionSetting(
              '設定をエクスポート',
              '現在の設定をファイルに保存します',
              () => _exportSettings(),
            ),
            _buildActionSetting(
              '設定をインポート',
              '保存された設定ファイルから復元します',
              () => _importSettings(),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSettingGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ProTheme.textPrimary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...children,
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
  
  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: ProTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ProTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ProTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ProTheme.accent,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdownSetting<T>(
    String title,
    T value,
    Map<T, String> options,
    ValueChanged<T> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: ProTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ProTheme.textPrimary,
              ),
            ),
          ),
          DropdownButton<T>(
            value: value,
            onChanged: (T? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            items: options.entries.map((entry) {
              return DropdownMenuItem<T>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String displayValue,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: ProTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ProTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 12,
                  color: ProTheme.textSecondary,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: ProTheme.accent,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextFieldSetting(
    String title,
    TextEditingController controller,
    String hint,
    TextInputType keyboardType,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: ProTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ProTheme.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPathSetting(
    String title,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: ProTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ProTheme.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'フォルダを選択...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              ElevatedButton(
                onPressed: onTap,
                child: const Text('選択'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionSetting(
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: ProTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ProTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ProTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            child: const Text('実行'),
          ),
        ],
      ),
    );
  }
  
  // 設定の読み込み
  void _loadSettings() {
    // TODO: SharedPreferencesや設定ファイルから設定を読み込む
  }
  
  // 設定の保存
  void _saveSettings() {
    // TODO: 設定をSharedPreferencesや設定ファイルに保存
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('設定を保存しました'),
        backgroundColor: ProTheme.success,
      ),
    );
  }
  
  // デフォルト設定に戻す
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('すべての設定をデフォルト値に戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // すべての設定をデフォルト値に戻す
                _autoDetectDevices = true;
                _showPreviewOnImport = true;
                _generateThumbnailsOnImport = true;
                _preserveOriginalFiles = true;
                _defaultImportNaming = 'original';
                _defaultViewMode = 'grid';
                _defaultThumbnailSize = 160;
                _showFileExtensions = true;
                _showFileDates = true;
                _showFileSize = false;
                _dateFormat = 'yyyy/MM/dd';
                _language = 'ja';
                _maxThumbnailCacheSize = 1000;
                _enableBackgroundProcessing = true;
                _maxConcurrentTasks = 4;
                _enableHardwareAcceleration = true;
                _enableExifStripping = false;
                _enableLocationPrivacy = false;
                _requireConfirmationForDelete = true;
                _enableSecureDelete = false;
                _defaultExportFormat = 'original';
                _defaultExportQuality = 'high';
                _preserveMetadataOnExport = true;
                _addWatermarkByDefault = false;
                _defaultImportPathController.clear();
                _defaultExportPathController.clear();
                _thumbnailCacheSizeController.text = '1000';
              });
              Navigator.pop(context);
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectDefaultImportPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      _defaultImportPathController.text = result;
    }
  }
  
  Future<void> _selectDefaultExportPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      _defaultExportPathController.text = result;
    }
  }
  
  void _showLogFiles() {
    // TODO: ログファイルを表示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ログファイル機能は開発中です')),
    );
  }
  
  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('キャッシュクリア'),
        content: const Text('サムネイルとメタデータのキャッシュをクリアしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: キャッシュクリア処理
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('キャッシュをクリアしました')),
              );
            },
            child: const Text('クリア'),
          ),
        ],
      ),
    );
  }
  
  void _rebuildDatabase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データベース再構築'),
        content: const Text('データベースを再構築しますか？この処理には時間がかかる場合があります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: データベース再構築処理
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('データベースの再構築を開始しました')),
              );
            },
            child: const Text('再構築'),
          ),
        ],
      ),
    );
  }
  
  void _exportSettings() {
    // TODO: 設定のエクスポート処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('設定エクスポート機能は開発中です')),
    );
  }
  
  void _importSettings() {
    // TODO: 設定のインポート処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('設定インポート機能は開発中です')),
    );
  }
}