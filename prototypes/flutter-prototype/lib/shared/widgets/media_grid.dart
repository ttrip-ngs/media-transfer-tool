import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/modern_theme.dart';

class MediaGrid extends StatefulWidget {
  final List<MediaItem> items;
  final Function(MediaItem)? onItemTap;
  final Function(List<MediaItem>)? onSelectionChanged;
  final bool multiSelectMode;
  final int crossAxisCount;

  const MediaGrid({
    Key? key,
    required this.items,
    this.onItemTap,
    this.onSelectionChanged,
    this.multiSelectMode = false,
    this.crossAxisCount = 4,
  }) : super(key: key);

  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  final Set<String> selectedIds = {};
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildToolbar(theme),
        Expanded(
          child: _buildGrid(theme),
        ),
      ],
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          if (widget.multiSelectMode && selectedIds.isNotEmpty) ...[
            Chip(
              label: Text('${selectedIds.length} 選択中'),
              onDeleted: () {
                setState(() {
                  selectedIds.clear();
                });
                widget.onSelectionChanged?.call([]);
              },
            ),
            const SizedBox(width: Spacing.md),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () {},
            tooltip: 'グリッドビュー',
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {},
            tooltip: 'リストビュー',
          ),
          const SizedBox(width: Spacing.md),
          Row(
            children: [
              const Icon(Icons.photo_size_select_small, size: 16),
              Slider(
                value: _scale,
                min: 0.5,
                max: 2.0,
                onChanged: (value) {
                  setState(() {
                    _scale = value;
                  });
                },
              ),
              const Icon(Icons.photo_size_select_large, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    final adjustedCrossAxisCount = (widget.crossAxisCount / _scale).round().clamp(2, 8);
    
    return MasonryGridView.count(
      crossAxisCount: adjustedCrossAxisCount,
      mainAxisSpacing: Spacing.sm,
      crossAxisSpacing: Spacing.sm,
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = selectedIds.contains(item.id);
        
        return _MediaTile(
          item: item,
          isSelected: isSelected,
          multiSelectMode: widget.multiSelectMode,
          onTap: () => _handleItemTap(item),
          onLongPress: () => _handleItemLongPress(item),
        ).animate().fadeIn(
          delay: Duration(milliseconds: index * 20),
          duration: AnimationDurations.fast,
        );
      },
    );
  }

  void _handleItemTap(MediaItem item) {
    if (widget.multiSelectMode) {
      setState(() {
        if (selectedIds.contains(item.id)) {
          selectedIds.remove(item.id);
        } else {
          selectedIds.add(item.id);
        }
      });
      
      final selectedItems = widget.items
          .where((item) => selectedIds.contains(item.id))
          .toList();
      widget.onSelectionChanged?.call(selectedItems);
    } else {
      widget.onItemTap?.call(item);
    }
  }

  void _handleItemLongPress(MediaItem item) {
    if (!widget.multiSelectMode) {
      setState(() {
        selectedIds.add(item.id);
      });
      
      final selectedItems = widget.items
          .where((item) => selectedIds.contains(item.id))
          .toList();
      widget.onSelectionChanged?.call(selectedItems);
    }
  }
}

class _MediaTile extends StatefulWidget {
  final MediaItem item;
  final bool isSelected;
  final bool multiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MediaTile({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.multiSelectMode,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: AnimationDurations.fast,
          curve: AnimationCurves.smooth,
          transform: Matrix4.identity()
            ..scale(isHovered ? 0.98 : 1.0),
          child: Stack(
            children: [
              _buildThumbnail(theme),
              if (widget.isSelected || isHovered)
                _buildOverlay(theme),
              if (widget.multiSelectMode || widget.isSelected)
                _buildSelectionCheckbox(theme),
              _buildMetadataBadges(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    return AspectRatio(
      aspectRatio: widget.item.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceVariant,
          border: widget.isSelected
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 3,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.isSelected ? 9 : 12),
          child: widget.item.thumbnailPath != null
              ? Image.asset(
                  widget.item.thumbnailPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(theme);
                  },
                )
              : _buildPlaceholder(theme),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          widget.item.type == MediaType.video
              ? Icons.videocam_outlined
              : Icons.image_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildOverlay(ThemeData theme) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: AnimationDurations.fast,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.isSelected ? 9 : 12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(isHovered ? 0.6 : 0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCheckbox(ThemeData theme) {
    return Positioned(
      top: Spacing.sm,
      left: Spacing.sm,
      child: AnimatedContainer(
        duration: AnimationDurations.fast,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.isSelected
              ? theme.colorScheme.primary
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: widget.isSelected
                ? theme.colorScheme.primary
                : Colors.black.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: widget.isSelected
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildMetadataBadges(ThemeData theme) {
    return Positioned(
      bottom: Spacing.sm,
      left: Spacing.sm,
      right: Spacing.sm,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.item.type == MediaType.video)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    widget.item.duration ?? '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          if (widget.item.isProcessed)
            Container(
              padding: const EdgeInsets.all(Spacing.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

enum MediaType { image, video }

class MediaItem {
  final String id;
  final String name;
  final MediaType type;
  final String? thumbnailPath;
  final DateTime? capturedAt;
  final String? duration;
  final double aspectRatio;
  final bool isProcessed;

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    this.thumbnailPath,
    this.capturedAt,
    this.duration,
    this.aspectRatio = 1.0,
    this.isProcessed = false,
  });
}