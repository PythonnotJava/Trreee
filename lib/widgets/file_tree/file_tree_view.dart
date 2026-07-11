import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/file_node.dart';
import '../../providers/file_tree_provider.dart';
import '../../providers/workspace_provider.dart';
import 'file_tree_node.dart';
import 'file_tree_toolbar.dart';

/// 完整文件树视图：根节点 + 工具栏 + 滚动内容。
class FileTreeView extends ConsumerStatefulWidget {
  const FileTreeView({super.key});

  @override
  ConsumerState<FileTreeView> createState() => _FileTreeViewState();
}

class _FileTreeViewState extends ConsumerState<FileTreeView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final root = ref.watch(workspaceRootNodeProvider);

    if (root == null) {
      return _EmptyState(onPickFolder: _pickFolder);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 工具栏
        FileTreeToolbar(root: root, scrollController: _scrollController),

        // 状态条
        _WorkspaceHeader(root: root),

        // 树
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: false,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: root.children.length,
              itemBuilder: (context, index) {
                return FileTreeNode(node: root.children[index], depth: 0);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFolder() async {
    // 这里只触发一个 setState 让父组件通过 menuBar 调用 file_selector。
    // 实际上让父组件打开目录更合适。这里给出 placeholder UI。
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPickFolder});

  final VoidCallback onPickFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('未打开工作区', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            '通过 文件 → 打开文件夹 选择一个目录',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends ConsumerWidget {
  const _WorkspaceHeader({required this.root});

  final FileNode root;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              root.path,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            tooltip: '关闭工作区',
            onPressed: () {
              ref.read(workspaceRootProvider.notifier).state = null;
              ref.read(expandedPathsProvider.notifier).state = {};
            },
            splashRadius: 12,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
