import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/file_node.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../utils/file_utils.dart';

class FileTreeToolbar extends ConsumerWidget {
  const FileTreeToolbar({
    super.key,
    required this.root,
    required this.scrollController,
  });

  final FileNode root;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.4 : 0.6,
        ),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_special_outlined,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '资源管理器',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _ToolbarButton(
            icon: Icons.unfold_more,
            tooltip: '全部展开',
            onPressed: () => _expandAll(ref),
          ),
          _ToolbarButton(
            icon: Icons.unfold_less,
            tooltip: '全部收缩',
            onPressed: () => _collapseAll(ref),
          ),
          _ToolbarButton(
            icon: Icons.refresh,
            tooltip: '刷新',
            onPressed: () {
              ref.read(expandCollapseEventProvider.notifier).state++;
            },
          ),
        ],
      ),
    );
  }

  void _expandAll(WidgetRef ref) {
    final rootPath = ref.read(workspaceRootProvider);
    if (rootPath == null || rootPath.isEmpty) return;
    final excludes = ref.read(settingsProvider).excludePatterns;
    final all = collectAllDirectoryPaths(rootPath, excludes);
    ref.read(expandedPathsProvider.notifier).state = all.toSet();
    ref.read(expandCollapseEventProvider.notifier).state++;
  }

  void _collapseAll(WidgetRef ref) {
    ref.read(expandedPathsProvider.notifier).state = {};
    ref.read(expandCollapseEventProvider.notifier).state++;
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 14,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 26, height: 28),
    );
  }
}
