import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/editor_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workspace_provider.dart';
import 'settings_dialog.dart';

class AppMenuBar extends ConsumerWidget {
  const AppMenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 32,
      color: cs.surfaceContainerLow,
      child: Row(
        children: [
          const SizedBox(width: 4),
          _menu(context, '文件', [
            _item(context, '打开文件夹…', () => _openFolder(context, ref)),
            _item(context, '关闭文件夹', () => _closeFolder(ref)),
          ]),
          _menu(context, '视图', [
            _item(context, '全部展开', () => _expandAll(ref)),
            _item(context, '全部收缩', () => _collapseAll(ref)),
            _divider(),
            _item(context, '切换行号',
                () => ref.read(settingsProvider.notifier).toggleLineNumbers()),
            _item(context, '切换自动换行',
                () => ref.read(settingsProvider.notifier).toggleWordWrap()),
            _divider(),
            _item(context, '切换主题(深/浅)', () => _cycleTheme(ref)),
          ]),
          _menu(context, '设置', [
            _item(context, '首选项…', () => SettingsDialog.show(context)),
            _item(context, '切换主题(深/浅)', () => _cycleTheme(ref)),
          ]),
          _menu(context, '帮助', [
            _item(context, '关于 Trreee', () => _showAbout(context)),
          ]),
        ],
      ),
    );
  }

  // ── helpers ──

  static PopupMenuItem<void> _item(
      BuildContext context, String label, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuItem<void>(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      height: 32,
      child: Text(label,
          style: TextStyle(fontSize: 13, color: cs.onSurface)),
    );
  }

  static PopupMenuDivider _divider() => const PopupMenuDivider(height: 1);

  Widget _menu(BuildContext context, String label,
      List<PopupMenuEntry<void>> items) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<void>(
      itemBuilder: (_) => items,
      offset: const Offset(0, 32),
      padding: EdgeInsets.zero,
      color: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(label,
            style: TextStyle(fontSize: 13, color: cs.onSurface)),
      ),
    );
  }

  // ── actions ──

  Future<void> _openFolder(BuildContext context, WidgetRef ref) async {
    try {
      final path = await getDirectoryPath(confirmButtonText: '选择文件夹');
      if (path == null) return;
      ref.read(workspaceRootProvider.notifier).state = path;
      ref.read(expandedPathsProvider.notifier).state = {path};
    } on Object catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('打开文件夹失败: $e')));
    }
  }

  void _closeFolder(WidgetRef ref) {
    ref.read(editorTabsProvider.notifier).closeAllTabs();
    ref.read(workspaceRootProvider.notifier).state = null;
    ref.read(expandedPathsProvider.notifier).state = {};
  }

  void _expandAll(WidgetRef ref) {
    ref.read(expandCollapseEventProvider.notifier).state++;
  }

  void _collapseAll(WidgetRef ref) {
    ref.read(expandedPathsProvider.notifier).state = {};
    ref.read(expandCollapseEventProvider.notifier).state++;
  }

  void _cycleTheme(WidgetRef ref) {
    final current = ref.read(settingsProvider).themeMode;
    final next = switch (current) {
      AppThemeMode.system => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.light,
      AppThemeMode.light => AppThemeMode.system,
    };
    ref.read(settingsProvider.notifier).setThemeMode(next);
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Trreee',
      applicationVersion: '1.0.0',
      applicationIcon: SizedBox(
        width: 48,
        height: 48,
        child: Image.asset('assets/logo/logo_alpha0.png'),
      ),
      applicationLegalese:
          '© 2026 Trreee — 一个使用 Flutter 实现的文件树阅读器。\n'
          'Powered by dock_panel & flutter_highlight.',
      children: const [
        SizedBox(height: 12),
        Text('特性:'),
        Text('• VSCode / IDEA 风格文件树'),
        Text('• 多 Tab + 可拖拽停靠的预览面板'),
        Text('• 基于 highlight.js 的语法高亮'),
        Text('• 可编辑 + 行号 + 多主题'),
      ],
    );
  }
}
