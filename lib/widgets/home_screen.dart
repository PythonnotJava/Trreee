import 'package:dock_panel/dock_panel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/editor_provider.dart';
import '../providers/workspace_provider.dart';
import 'editor/editor_panel.dart';
import 'file_tree/file_tree_view.dart';
import 'menu_bar.dart';
import 'status_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const double _sidebarWidth = 280;
  bool _sidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(workspaceRootProvider, (prev, next) {
      if (next != null && (prev == null || prev.isEmpty)) {
        ref.read(fileSyncTickerProvider).start();
      } else if (next == null || next.isEmpty) {
        ref.read(fileSyncTickerProvider).stop();
      }
    });

    final tabs = ref.watch(editorTabsProvider);
    final hasTabs = tabs.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          const AppMenuBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: _sidebarVisible ? _sidebarWidth : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: const OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: _sidebarWidth,
                    maxWidth: _sidebarWidth,
                    child: SizedBox(
                      width: _sidebarWidth,
                      child: _FileTreePane(),
                    ),
                  ),
                ),
                _SidebarToggle(
                  expanded: _sidebarVisible,
                  onPressed: () =>
                      setState(() => _sidebarVisible = !_sidebarVisible),
                ),
                Expanded(
                  child: hasTabs
                      ? const _DockedEditorArea()
                      : _WelcomeView(
                          onOpenFolder: () => _pickFolder(context)),
                ),
              ],
            ),
          ),
          const StatusBar(),
        ],
      ),
    );
  }

  Future<void> _pickFolder(BuildContext context) async {
    try {
      final path = await getDirectoryPath(confirmButtonText: '选择文件夹');
      if (path == null) return;
      ref.read(workspaceRootProvider.notifier).state = path;
      ref.read(expandedPathsProvider.notifier).state = {path};
      if (!_sidebarVisible) {
        setState(() => _sidebarVisible = true);
      }
    } on Object catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('打开文件夹失败: $e')));
    }
  }
}

/// Dock 区域 — 单独 `build` 只监听 `Theme.of(context).brightness`，
/// 不挂在 `ConsumerState` 的 builder 下，避免主题切换时整棵 dock 树重建。
class _DockedEditorArea extends StatelessWidget {
  const _DockedEditorArea();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return DockTabsSynchronizer(
      onOpenInMainRequested: (_) {},
      onActiveTabChanged: (_) {},
      child: DockTheme(
        data: isLight ? DockThemeData.light : const DockThemeData(),
        child: const DockArea(),
      ),
    );
  }
}

class _FileTreePane extends StatelessWidget {
  const _FileTreePane();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right:
              BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
      ),
      child: const FileTreeView(),
    );
  }
}

class _SidebarToggle extends StatefulWidget {
  const _SidebarToggle({required this.expanded, required this.onPressed});
  final bool expanded;
  final VoidCallback onPressed;

  @override
  State<_SidebarToggle> createState() => _SidebarToggleState();
}

class _SidebarToggleState extends State<_SidebarToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          child: SizedBox(
            width: 12,
            child: Center(
              child: AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: const Duration(milliseconds: 140),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 12,
                  height: 54,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(6)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4),
                    ],
                  ),
                  child: AnimatedRotation(
                    turns: widget.expanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.chevron_left,
                        size: 14,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.onOpenFolder});
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline.withValues(alpha: 0.34);

    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo/logo_alpha0.png',
                  width: 112, height: 112,
                  filterQuality: FilterQuality.high),
              const SizedBox(height: 18),
              Text('Trreee',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w300,
                          letterSpacing: 1.8)),
              const SizedBox(height: 8),
              Text('File Tree Reader & Editor',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      letterSpacing: 0.3)),
              const SizedBox(height: 34),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenFolder,
                  borderRadius: BorderRadius.circular(8),
                  child: Ink(
                    width: 376,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                        border: Border.all(color: outline),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.folder_open_outlined,
                            size: 26,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('打开文件夹',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text('选择一个项目目录',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: theme
                                              .colorScheme.outline)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: theme.colorScheme.outline),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
