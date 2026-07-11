import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/file_node.dart';
import '../../providers/editor_provider.dart';
import '../../providers/file_tree_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../utils/language_detector.dart';

class FileTreeNode extends ConsumerStatefulWidget {
  const FileTreeNode({super.key, required this.node, required this.depth});
  final FileNode node;
  final int depth;

  @override
  ConsumerState<FileTreeNode> createState() => _FileTreeNodeState();
}

class _FileTreeNodeState extends ConsumerState<FileTreeNode> {
  bool _hover = false;
  bool _didAutoLoad = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(expandCollapseEventProvider);
    final expandedPaths = ref.watch(expandedPathsProvider);

    final isExpanded =
        widget.node.isDirectory &&
        (widget.node.path == '/' || expandedPaths.contains(widget.node.path));

    // "全部展开"时自动加载未填充的目录子节点
    if (isExpanded &&
        widget.node.isDirectory &&
        widget.node.children.isEmpty &&
        !_didAutoLoad) {
      _didAutoLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadChildren();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          node: widget.node,
          depth: widget.depth,
          isExpanded: isExpanded,
          isHovered: _hover,
          onHoverChange: (v) => setState(() => _hover = v),
          onTap: () => _handleTap(isExpanded),
          onChevronTap: () => _handleChevronTap(isExpanded),
        ),
        if (widget.node.isDirectory && isExpanded)
          ...widget.node.children.map(
            (child) => FileTreeNode(
              key: ValueKey(
                '${child.path}#${ref.read(expandCollapseEventProvider)}',
              ),
              node: child,
              depth: widget.depth + 1,
            ),
          ),
      ],
    );
  }

  void _handleTap(bool isExpanded) {
    if (widget.node.isDirectory) {
      _toggleExpansion(isExpanded);
    } else {
      ref.read(editorTabsProvider.notifier).openFile(widget.node.path);
    }
  }

  void _handleChevronTap(bool isExpanded) {
    if (!widget.node.isDirectory) return;
    _toggleExpansion(isExpanded);
  }

  void _toggleExpansion(bool isExpanded) {
    final notifier = ref.read(expandedPathsProvider.notifier);
    if (isExpanded) {
      notifier.state = notifier.state
          .where((p) => p != widget.node.path)
          .toSet();
    } else {
      _loadChildren();
      notifier.state = {...notifier.state, widget.node.path};
    }
  }

  void _loadChildren() {
    final newChildren = ref.read(lazyChildrenProvider(widget.node.path));
    widget.node.children
      ..clear()
      ..addAll(newChildren);
    setState(() {});
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.isHovered,
    required this.onHoverChange,
    required this.onTap,
    required this.onChevronTap,
  });
  final FileNode node;
  final int depth;
  final bool isExpanded;
  final bool isHovered;
  final ValueChanged<bool> onHoverChange;
  final VoidCallback onTap;
  final VoidCallback onChevronTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indent = depth * 14.0;
    final effectiveIcon = node.isDirectory
        ? (isExpanded ? Icons.folder_open : Icons.folder_outlined)
        : LanguageDetector.iconForPath(node.path, false);
    final color = node.isDirectory
        ? const Color(0xFFDCB67A)
        : theme.colorScheme.onSurfaceVariant;
    final ctx = context;

    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onSecondaryTapDown: (d) => _showContextMenu(ctx, d),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 面板拖动或窗口恢复期间，文件树可能被临时压缩到极窄宽度。
            // 此时不能继续布局完整的“箭头 + 图标 + 文件名”行。
            if (constraints.maxWidth < 58) {
              return Container(
                height: 24,
                color: isHovered
                    ? theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      )
                    : null,
                alignment: Alignment.center,
                child: constraints.maxWidth >= 14
                    ? Icon(effectiveIcon, size: 14, color: color)
                    : const SizedBox.shrink(),
              );
            }

            // 深层目录不能让缩进吃掉图标和文本所需的全部空间。
            // 行内固定控件共占 42px，左右基础留白共占 16px。
            final maxIndent = constraints.maxWidth - 58;
            final effectiveIndent = indent.clamp(0.0, maxIndent);

            return Container(
              height: 24,
              padding: EdgeInsets.only(left: 8 + effectiveIndent, right: 8),
              color: isHovered
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    )
                  : null,
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: node.isDirectory
                        ? InkWell(
                            onTap: onChevronTap,
                            child: AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 120),
                              child: Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 4),
                  Icon(effectiveIcon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      node.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        overlay.size.width - details.globalPosition.dx,
        overlay.size.height - details.globalPosition.dy,
      ),
      items: node.isDirectory
          ? const [
              PopupMenuItem(value: 0, child: Text('新建文件')),
              PopupMenuItem(value: 1, child: Text('新建文件夹')),
              PopupMenuItem(value: 2, child: Text('在文件资源管理器中显示')),
              PopupMenuItem(value: 3, child: Text('复制路径')),
            ]
          : const [
              PopupMenuItem(value: 4, child: Text('打开')),
              PopupMenuItem(value: 5, child: Text('在文件资源管理器中显示')),
              PopupMenuItem(value: 6, child: Text('复制路径')),
            ],
    ).then((value) {
      if (!context.mounted) return;
      switch (value) {
        case 0:
          _createNewFile(context);
        case 1:
          _createNewDirectory(context);
        case 2:
        case 5:
          _revealInExplorer();
        case 3:
        case 6:
          _copyPath();
        case 4:
          break;
      }
    });
  }

  void _createNewFile(BuildContext context) {
    final dir = node.path;
    _promptForName(
      context,
      '新建文件',
      defaultName: 'untitled.txt',
      onConfirm: (name) {
        try {
          File(
            '$dir${Platform.pathSeparator}$name',
          ).createSync(recursive: true);
        } on FileSystemException {
          /* silent */
        }
      },
    );
  }

  void _createNewDirectory(BuildContext context) {
    final dir = node.path;
    _promptForName(
      context,
      '新建文件夹',
      defaultName: 'new_folder',
      onConfirm: (name) {
        try {
          Directory(
            '$dir${Platform.pathSeparator}$name',
          ).createSync(recursive: true);
        } on FileSystemException {
          /* silent */
        }
      },
    );
  }

  void _revealInExplorer() {
    try {
      Process.run('explorer', ['/select,', node.path]);
    } on ProcessException {
      /* silent */
    }
  }

  void _copyPath() {}

  void _promptForName(
    BuildContext context,
    String title, {
    required String defaultName,
    required void Function(String) onConfirm,
  }) {
    final ctrl = TextEditingController(text: defaultName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) onConfirm(v.trim());
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) onConfirm(v);
              Navigator.of(ctx).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
