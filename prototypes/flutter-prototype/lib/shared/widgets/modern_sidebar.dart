import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_container.dart';
import '../../core/theme/modern_theme.dart';

class ModernSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final Function()? onToggleCollapse;

  const ModernSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
  }) : super(key: key);

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = widget.isCollapsed ? 72.0 : 280.0;

    return AnimatedContainer(
      duration: AnimationDurations.normal,
      curve: AnimationCurves.smooth,
      width: width,
      child: GlassContainer(
        margin: const EdgeInsets.all(Spacing.md),
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        borderRadius: 24,
        child: Column(
          children: [
            _buildHeader(theme),
            const SizedBox(height: Spacing.xl),
            Expanded(
              child: _buildNavigationItems(theme),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? Spacing.sm : Spacing.lg,
      ),
      child: Row(
        children: [
          if (!widget.isCollapsed) ...[
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ).animate().fadeIn(duration: AnimationDurations.fast),
                  const SizedBox(width: Spacing.sm),
                  Flexible(
                    child: Text(
                      'Media Hub',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(duration: AnimationDurations.fast).slideX(),
                  ),
                ],
              ),
            ),
          ],
          if (widget.onToggleCollapse != null)
            IconButton(
              icon: Icon(
                widget.isCollapsed ? Icons.menu : Icons.menu_open,
                size: 20,
              ),
              onPressed: widget.onToggleCollapse,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(ThemeData theme) {
    final items = [
      NavigationItem(
        icon: Icons.download_outlined,
        selectedIcon: Icons.download,
        label: 'インポート',
        badge: '3',
      ),
      NavigationItem(
        icon: Icons.collections_outlined,
        selectedIcon: Icons.collections,
        label: 'ライブラリ',
      ),
      NavigationItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder,
        label: 'コレクション',
      ),
      NavigationItem(
        icon: Icons.edit_outlined,
        selectedIcon: Icons.edit,
        label: '編集',
      ),
      NavigationItem(
        icon: Icons.cloud_upload_outlined,
        selectedIcon: Icons.cloud_upload,
        label: '転送',
      ),
      NavigationItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: '設定',
      ),
    ];

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = widget.selectedIndex == index;
        
        return _buildNavigationTile(
          theme: theme,
          item: item,
          isSelected: isSelected,
          onTap: () => widget.onItemSelected(index),
        );
      },
    );
  }

  Widget _buildNavigationTile({
    required ThemeData theme,
    required NavigationItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: AnimationDurations.fast,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? Spacing.md : Spacing.lg,
              vertical: Spacing.md,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 24,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ).animate().fadeIn(duration: AnimationDurations.fast),
                  ),
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fadeIn(duration: AnimationDurations.fast),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        children: [
          if (!widget.isCollapsed)
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      'U',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ユーザー',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'user@example.com',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: AnimationDurations.fast),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? badge;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge,
  });
}