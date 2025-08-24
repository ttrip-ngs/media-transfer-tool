import 'package:flutter/material.dart';
import '../core/design/professional_theme.dart';
import '../services/search_service.dart';
import '../models/media_file.dart';

class SearchPanel extends StatefulWidget {
  final Function(String query, SearchFilter filter, SearchScope scope)? onSearch;
  final Function()? onClear;
  
  const SearchPanel({
    Key? key,
    this.onSearch,
    this.onClear,
  }) : super(key: key);

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final _searchController = TextEditingController();
  final _fileNameController = TextEditingController();
  final _cameraController = TextEditingController();
  final _keywordsController = TextEditingController();
  
  SearchScope _searchScope = SearchScope.all;
  MediaType? _selectedMediaType;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _sizeMin;
  int? _sizeMax;
  List<String> _selectedExtensions = [];
  SortCriteria _sortCriteria = SortCriteria.date;
  SortOrder _sortOrder = SortOrder.descending;
  bool _showAdvancedFilters = false;
  
  final List<String> _commonExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic',
    'mp4', 'mov', 'avi', 'mkv', 'wmv',
    'cr2', 'cr3', 'raw', 'nef', 'arw', 'dng'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(
          bottom: BorderSide(color: ProTheme.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchHeader(),
          const SizedBox(height: Spacing.md),
          _buildSearchBar(),
          const SizedBox(height: Spacing.md),
          _buildQuickFilters(),
          if (_showAdvancedFilters) ...[
            const SizedBox(height: Spacing.lg),
            _buildAdvancedFilters(),
          ],
          const SizedBox(height: Spacing.md),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildSearchHeader() {
    return Row(
      children: [
        const Icon(Icons.search, size: 20, color: ProTheme.accent),
        const SizedBox(width: Spacing.sm),
        const Text(
          '検索・フィルター',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ProTheme.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showAdvancedFilters = !_showAdvancedFilters;
            });
          },
          icon: Icon(
            _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
            size: 16,
          ),
          label: Text(_showAdvancedFilters ? '簡易表示' : '詳細フィルター'),
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '写真やファイルを検索...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        DropdownButton<SearchScope>(
          value: _searchScope,
          onChanged: (scope) {
            if (scope != null) {
              setState(() {
                _searchScope = scope;
              });
            }
          },
          items: const [
            DropdownMenuItem(
              value: SearchScope.all,
              child: Text('すべて'),
            ),
            DropdownMenuItem(
              value: SearchScope.fileName,
              child: Text('ファイル名'),
            ),
            DropdownMenuItem(
              value: SearchScope.metadata,
              child: Text('メタデータ'),
            ),
            DropdownMenuItem(
              value: SearchScope.keywords,
              child: Text('キーワード'),
            ),
          ],
          style: const TextStyle(fontSize: 12, color: ProTheme.textPrimary),
        ),
      ],
    );
  }
  
  Widget _buildQuickFilters() {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        _buildMediaTypeChip('すべて', null),
        _buildMediaTypeChip('画像', MediaType.image),
        _buildMediaTypeChip('動画', MediaType.video),
        _buildMediaTypeChip('RAW', MediaType.raw),
        const SizedBox(width: Spacing.md),
        _buildSortDropdown(),
      ],
    );
  }
  
  Widget _buildMediaTypeChip(String label, MediaType? type) {
    final isSelected = _selectedMediaType == type;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMediaType = selected ? type : null;
        });
        _performSearch();
      },
      backgroundColor: ProTheme.surfaceLight,
      selectedColor: ProTheme.accent.withOpacity(0.2),
      checkmarkColor: ProTheme.accent,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
      ),
    );
  }
  
  Widget _buildSortDropdown() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('並び順: ', style: TextStyle(fontSize: 12, color: ProTheme.textSecondary)),
        DropdownButton<SortCriteria>(
          value: _sortCriteria,
          onChanged: (criteria) {
            if (criteria != null) {
              setState(() {
                _sortCriteria = criteria;
              });
              _performSearch();
            }
          },
          items: const [
            DropdownMenuItem(value: SortCriteria.date, child: Text('日付')),
            DropdownMenuItem(value: SortCriteria.name, child: Text('名前')),
            DropdownMenuItem(value: SortCriteria.size, child: Text('サイズ')),
            DropdownMenuItem(value: SortCriteria.type, child: Text('種類')),
          ],
          style: const TextStyle(fontSize: 12, color: ProTheme.textPrimary),
          underline: const SizedBox(),
        ),
        IconButton(
          icon: Icon(
            _sortOrder == SortOrder.ascending
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            size: 16,
          ),
          onPressed: () {
            setState(() {
              _sortOrder = _sortOrder == SortOrder.ascending
                  ? SortOrder.descending
                  : SortOrder.ascending;
            });
            _performSearch();
          },
          tooltip: _sortOrder == SortOrder.ascending ? '昇順' : '降順',
        ),
      ],
    );
  }
  
  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '詳細フィルター',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ProTheme.textPrimary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        
        // ファイル名パターン
        TextField(
          controller: _fileNameController,
          decoration: const InputDecoration(
            labelText: 'ファイル名パターン',
            hintText: '例: IMG_, DSC_, etc.',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (_) => _performSearch(),
        ),
        
        const SizedBox(height: Spacing.md),
        
        // 日付範囲
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                '開始日',
                _dateFrom,
                (date) => setState(() => _dateFrom = date),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _buildDateField(
                '終了日',
                _dateTo,
                (date) => setState(() => _dateTo = date),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: Spacing.md),
        
        // サイズ範囲
        Row(
          children: [
            Expanded(
              child: _buildSizeField(
                '最小サイズ (MB)',
                _sizeMin,
                (size) => setState(() => _sizeMin = size),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _buildSizeField(
                '最大サイズ (MB)',
                _sizeMax,
                (size) => setState(() => _sizeMax = size),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: Spacing.md),
        
        // ファイル拡張子
        const Text(
          'ファイル形式',
          style: TextStyle(fontSize: 12, color: ProTheme.textSecondary),
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: _commonExtensions.map((ext) {
            final isSelected = _selectedExtensions.contains(ext);
            return FilterChip(
              label: Text(ext.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedExtensions.add(ext);
                  } else {
                    _selectedExtensions.remove(ext);
                  }
                });
                _performSearch();
              },
              backgroundColor: ProTheme.surfaceLight,
              selectedColor: ProTheme.accent.withOpacity(0.2),
              checkmarkColor: ProTheme.accent,
              labelStyle: TextStyle(
                fontSize: 10,
                color: isSelected ? ProTheme.accent : ProTheme.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
          _performSearch();
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    onChanged(null);
                    _performSearch();
                  },
                )
              : const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          value != null
              ? '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
              : '',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
  
  Widget _buildSizeField(
    String label,
    int? value,
    Function(int?) onChanged,
  ) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
      ),
      style: const TextStyle(fontSize: 12),
      keyboardType: TextInputType.number,
      controller: TextEditingController(
        text: value != null ? (value / (1024 * 1024)).toStringAsFixed(1) : '',
      ),
      onChanged: (text) {
        final mb = double.tryParse(text);
        onChanged(mb != null ? (mb * 1024 * 1024).round() : null);
        _performSearch();
      },
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _performSearch,
          icon: const Icon(Icons.search, size: 16),
          label: const Text('検索'),
        ),
        const SizedBox(width: Spacing.md),
        OutlinedButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear_all, size: 16),
          label: const Text('クリア'),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _showSaveSearchDialog,
          icon: const Icon(Icons.bookmark, size: 16),
          label: const Text('検索を保存'),
        ),
      ],
    );
  }
  
  void _performSearch() {
    final filter = SearchFilter(
      fileNamePattern: _fileNameController.text.isEmpty ? null : _fileNameController.text,
      mediaType: _selectedMediaType,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      sizeMin: _sizeMin,
      sizeMax: _sizeMax,
      extensions: _selectedExtensions.isEmpty ? null : _selectedExtensions,
      cameraModel: _cameraController.text.isEmpty ? null : _cameraController.text,
      keywords: _keywordsController.text.isEmpty ? null : _keywordsController.text,
      sortCriteria: _sortCriteria,
      sortOrder: _sortOrder,
    );
    
    widget.onSearch?.call(_searchController.text, filter, _searchScope);
  }
  
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _fileNameController.clear();
      _cameraController.clear();
      _keywordsController.clear();
      _selectedMediaType = null;
      _dateFrom = null;
      _dateTo = null;
      _sizeMin = null;
      _sizeMax = null;
      _selectedExtensions.clear();
      _sortCriteria = SortCriteria.date;
      _sortOrder = SortOrder.descending;
      _searchScope = SearchScope.all;
    });
    
    widget.onClear?.call();
  }
  
  void _showSaveSearchDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('検索を保存'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '検索名',
            hintText: '例: 今月の高解像度画像',
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
              if (nameController.text.isNotEmpty) {
                final filter = SearchFilter(
                  fileNamePattern: _fileNameController.text.isEmpty ? null : _fileNameController.text,
                  mediaType: _selectedMediaType,
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                  sizeMin: _sizeMin,
                  sizeMax: _sizeMax,
                  extensions: _selectedExtensions.isEmpty ? null : _selectedExtensions,
                  sortCriteria: _sortCriteria,
                  sortOrder: _sortOrder,
                );
                
                SearchService.instance.saveSearch(
                  nameController.text,
                  filter,
                  _searchController.text,
                  _searchScope,
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('検索を保存しました')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}