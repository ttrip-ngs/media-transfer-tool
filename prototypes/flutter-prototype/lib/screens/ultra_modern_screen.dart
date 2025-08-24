import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design/ultra_modern_theme.dart';

class UltraModernScreen extends StatefulWidget {
  const UltraModernScreen({Key? key}) : super(key: key);

  @override
  State<UltraModernScreen> createState() => _UltraModernScreenState();
}

class _UltraModernScreenState extends State<UltraModernScreen> {
  int selectedIndex = 0;
  bool showCommandPalette = false;
  final FocusNode searchFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UltraModernTheme.neutral950,
      body: Stack(
        children: [
          Row(
            children: [
              // Arc Browser風のサイドバー
              _buildMinimalSidebar(),
              
              // メインコンテンツ
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // コマンドパレット（Linear/Raycast風）
          if (showCommandPalette) _buildCommandPalette(),
        ],
      ),
    );
  }

  Widget _buildMinimalSidebar() {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: UltraModernTheme.neutral900,
        border: Border(
          right: BorderSide(
            color: UltraModernTheme.neutral800,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: Space.lg),
          
          // ロゴ
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: Space.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  UltraModernTheme.blue,
                  UltraModernTheme.violet,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          // ナビゲーションアイコン
          _buildNavIcon(Icons.inbox_rounded, 0, 'Inbox'),
          _buildNavIcon(Icons.folder_outlined, 1, 'Files'),
          _buildNavIcon(Icons.image_outlined, 2, 'Media'),
          _buildNavIcon(Icons.cloud_outlined, 3, 'Cloud'),
          
          const Spacer(),
          
          // 設定
          _buildNavIcon(Icons.settings_outlined, 4, 'Settings'),
          
          // プロフィール
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: UltraModernTheme.neutral700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'A',
                style: TextStyle(
                  color: UltraModernTheme.neutral200,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, String tooltip) {
    final isSelected = selectedIndex == index;
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      textStyle: TextStyle(
        color: UltraModernTheme.neutral100,
        fontSize: 12,
      ),
      decoration: BoxDecoration(
        color: UltraModernTheme.neutral800,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => setState(() => selectedIndex = index),
        child: Container(
          width: 60,
          height: 48,
          child: Stack(
            children: [
              // 選択インジケーター
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 12,
                  bottom: 12,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: UltraModernTheme.blue,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              
              // アイコン
              Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? UltraModernTheme.neutral100
                      : UltraModernTheme.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: UltraModernTheme.neutral800,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 検索バー（Vercel風）
          Expanded(
            child: Container(
              height: 32,
              child: TextField(
                focusNode: searchFocus,
                style: TextStyle(
                  color: UltraModernTheme.neutral100,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search or jump to... (Cmd+K)',
                  hintStyle: TextStyle(
                    color: UltraModernTheme.neutral600,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: UltraModernTheme.neutral500,
                  ),
                  filled: true,
                  fillColor: UltraModernTheme.neutral900,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: UltraModernTheme.blue,
                      width: 1.5,
                    ),
                  ),
                ),
                onTap: () {
                  setState(() => showCommandPalette = true);
                },
              ),
            ),
          ),
          
          const SizedBox(width: Space.xl),
          
          // アクションボタン（Notion風）
          _buildActionButton(Icons.add, 'New'),
          const SizedBox(width: Space.md),
          _buildActionButton(Icons.file_upload_outlined, 'Import'),
          const SizedBox(width: Space.md),
          _buildActionButton(Icons.sync, 'Sync'),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: UltraModernTheme.neutral300,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー（Vercel風）
          Text(
            'Media Library',
            style: TextStyle(
              color: UltraModernTheme.neutral100,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            '1,234 items • 45.6 GB',
            style: TextStyle(
              color: UltraModernTheme.neutral500,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: Space.xxl),
          
          // フィルターバー（Linear風）
          Row(
            children: [
              _buildFilterChip('All', true),
              const SizedBox(width: Space.md),
              _buildFilterChip('Images', false),
              const SizedBox(width: Space.md),
              _buildFilterChip('Videos', false),
              const SizedBox(width: Space.md),
              _buildFilterChip('Documents', false),
              const Spacer(),
              // ビュー切り替え
              Container(
                decoration: BoxDecoration(
                  color: UltraModernTheme.neutral900,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: UltraModernTheme.neutral800,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildViewButton(Icons.grid_view, true),
                    _buildViewButton(Icons.view_list, false),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: Space.xl),
          
          // コンテンツグリッド
          Expanded(
            child: _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? UltraModernTheme.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? UltraModernTheme.blue : UltraModernTheme.neutral800,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? UltraModernTheme.blue : UltraModernTheme.neutral400,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildViewButton(IconData icon, bool isActive) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? UltraModernTheme.neutral800 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? UltraModernTheme.neutral200 : UltraModernTheme.neutral500,
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: Space.lg,
        mainAxisSpacing: Space.lg,
        childAspectRatio: 1,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        return _buildGridItem(index);
      },
    );
  }

  Widget _buildGridItem(int index) {
    return Container(
      decoration: BoxDecoration(
        color: UltraModernTheme.neutral900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: UltraModernTheme.neutral800,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // サムネイル領域
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: UltraModernTheme.neutral800,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Icon(
                  index % 3 == 0 ? Icons.play_circle_outline : Icons.image,
                  size: 32,
                  color: UltraModernTheme.neutral700,
                ),
              ),
            ),
          ),
          
          // ホバー時のオーバーレイ
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                hoverColor: UltraModernTheme.blue.withOpacity(0.05),
                child: Container(
                  padding: const EdgeInsets.all(Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'File_${index + 1}.${index % 3 == 0 ? 'mp4' : 'jpg'}',
                        style: TextStyle(
                          color: UltraModernTheme.neutral200,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(index + 1) * 2.3} MB',
                        style: TextStyle(
                          color: UltraModernTheme.neutral500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 選択チェックボックス
          Positioned(
            top: Space.md,
            left: Space.md,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: UltraModernTheme.neutral900,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: UltraModernTheme.neutral600,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandPalette() {
    return GestureDetector(
      onTap: () => setState(() => showCommandPalette = false),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            width: 600,
            height: 400,
            decoration: BoxDecoration(
              color: UltraModernTheme.neutral900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: UltraModernTheme.neutral800,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                // 検索入力
                Container(
                  padding: const EdgeInsets.all(Space.xl),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: UltraModernTheme.neutral800,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TextField(
                    autofocus: true,
                    style: TextStyle(
                      color: UltraModernTheme.neutral100,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a command or search...',
                      hintStyle: TextStyle(
                        color: UltraModernTheme.neutral600,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.terminal,
                        color: UltraModernTheme.neutral500,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                
                // コマンドリスト
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(Space.md),
                    children: [
                      _buildCommandItem(Icons.file_upload, 'Import Media', 'Cmd+I'),
                      _buildCommandItem(Icons.create_new_folder, 'New Collection', 'Cmd+N'),
                      _buildCommandItem(Icons.cloud_sync, 'Sync with Cloud', 'Cmd+S'),
                      _buildCommandItem(Icons.search, 'Search Files', 'Cmd+F'),
                      _buildCommandItem(Icons.settings, 'Settings', 'Cmd+,'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommandItem(IconData icon, String title, String shortcut) {
    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => showCommandPalette = false);
          },
          borderRadius: BorderRadius.circular(6),
          hoverColor: UltraModernTheme.neutral800,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.lg,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: UltraModernTheme.neutral400,
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: UltraModernTheme.neutral200,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.sm,
                  ),
                  decoration: BoxDecoration(
                    color: UltraModernTheme.neutral800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shortcut,
                    style: TextStyle(
                      color: UltraModernTheme.neutral500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchFocus.dispose();
    super.dispose();
  }
}