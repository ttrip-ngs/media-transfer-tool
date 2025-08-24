import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../shared/widgets/glass_container.dart';
import '../shared/widgets/modern_sidebar.dart';
import '../shared/widgets/media_grid.dart';
import '../core/theme/modern_theme.dart';

class ModernImportScreen extends StatefulWidget {
  const ModernImportScreen({Key? key}) : super(key: key);

  @override
  State<ModernImportScreen> createState() => _ModernImportScreenState();
}

class _ModernImportScreenState extends State<ModernImportScreen> {
  int selectedNavIndex = 0;
  bool isSidebarCollapsed = false;
  List<MediaItem> mediaItems = [];
  String selectedSource = 'local';

  @override
  void initState() {
    super.initState();
    _loadSampleMedia();
  }

  void _loadSampleMedia() {
    mediaItems = List.generate(20, (index) {
      final isVideo = index % 3 == 0;
      return MediaItem(
        id: 'media_$index',
        name: isVideo ? 'Video_$index.mp4' : 'IMG_$index.jpg',
        type: isVideo ? MediaType.video : MediaType.image,
        aspectRatio: isVideo ? 16 / 9 : (index % 2 == 0 ? 1.0 : 3 / 4),
        duration: isVideo ? '${index + 1}:${(index * 7 % 60).toString().padLeft(2, '0')}' : null,
        isProcessed: index % 4 == 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Row(
        children: [
          ModernSidebar(
            selectedIndex: selectedNavIndex,
            onItemSelected: (index) {
              setState(() {
                selectedNavIndex = index;
              });
            },
            isCollapsed: isSidebarCollapsed,
            onToggleCollapse: () {
              setState(() {
                isSidebarCollapsed = !isSidebarCollapsed;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    children: [
                      if (selectedNavIndex == 0) _buildSourcePanel(),
                      Expanded(
                        child: _buildMainContent(),
                      ),
                      _buildDetailsPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    
    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(0, Spacing.md, Spacing.md, Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 24,
      child: Row(
        children: [
          Text(
            'メディアインポート',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideX(),
          const SizedBox(width: Spacing.xl),
          Expanded(
            child: _buildSearchBar(),
          ),
          const SizedBox(width: Spacing.xl),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'メディアを検索...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        _ActionButton(
          icon: Icons.filter_list,
          label: 'フィルタ',
          onPressed: () {},
        ),
        const SizedBox(width: Spacing.sm),
        _ActionButton(
          icon: Icons.sort,
          label: '並び替え',
          onPressed: () {},
        ),
        const SizedBox(width: Spacing.sm),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download),
          label: const Text('インポート開始'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSourcePanel() {
    final theme = Theme.of(context);
    
    return GlassContainer(
      width: 280,
      margin: const EdgeInsets.fromLTRB(0, 0, Spacing.md, Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ソース',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          _buildSourceTile(
            icon: Icons.folder,
            title: 'ローカルフォルダ',
            subtitle: 'コンピュータ内のファイル',
            id: 'local',
          ),
          _buildSourceTile(
            icon: Icons.phone_iphone,
            title: 'iPhone',
            subtitle: '接続中',
            id: 'iphone',
            isConnected: true,
          ),
          _buildSourceTile(
            icon: Icons.sd_card,
            title: 'SDカード',
            subtitle: 'Canon EOS R5',
            id: 'sdcard',
            isConnected: true,
          ),
          _buildSourceTile(
            icon: Icons.photo_camera,
            title: 'カメラ',
            subtitle: '未接続',
            id: 'camera',
            isConnected: false,
          ),
          const Divider(height: Spacing.xl),
          Text(
            'クラウド',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          _buildSourceTile(
            icon: Icons.cloud,
            title: 'Google Photos',
            subtitle: 'user@gmail.com',
            id: 'google',
          ),
          _buildSourceTile(
            icon: Icons.cloud_queue,
            title: 'Dropbox',
            subtitle: '未接続',
            id: 'dropbox',
            isConnected: false,
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildSourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String id,
    bool isConnected = true,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedSource == id;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSource = id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isConnected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(0, 0, Spacing.md, Spacing.md),
      padding: const EdgeInsets.all(Spacing.md),
      borderRadius: 24,
      child: MediaGrid(
        items: mediaItems,
        multiSelectMode: true,
        onSelectionChanged: (items) {
          print('Selected ${items.length} items');
        },
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildDetailsPanel() {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: AnimationDurations.normal,
      width: 320,
      child: GlassContainer(
        margin: const EdgeInsets.fromLTRB(0, 0, Spacing.md, Spacing.md),
        padding: const EdgeInsets.all(Spacing.lg),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '詳細',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {},
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            _buildDetailItem('ファイル名', 'IMG_2024_001.jpg'),
            _buildDetailItem('サイズ', '4.2 MB'),
            _buildDetailItem('解像度', '4000 x 3000'),
            _buildDetailItem('撮影日時', '2024/01/13 14:30'),
            _buildDetailItem('カメラ', 'Canon EOS R5'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('メタデータを編集'),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: theme.colorScheme.onSurface.withOpacity(0.2),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
      ),
    );
  }
}