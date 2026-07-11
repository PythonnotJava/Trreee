import 'package:dock_panel/dock_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/editor_tab.dart';
import '../../providers/editor_provider.dart';
import 'code_editor_view.dart';

DockPanel buildEditorDockPanel({required EditorTab tab}) {
  return DockPanel(
    id: tab.id,
    title: tab.title,
    icon: tab.icon,
    closable: true,
    builder: (_) => CodeEditorView(tabId: tab.id),
  );
}

/// 监听 tabs 列表变化，差量同步到 DockManager。
/// 同时当 activeTab 变化时自动激活对应面板。
class DockTabsSynchronizer extends ConsumerStatefulWidget {
  const DockTabsSynchronizer({
    super.key,
    required this.child,
    required this.onOpenInMainRequested,
    required this.onActiveTabChanged,
  });

  final Widget child;
  final void Function(String tabId) onOpenInMainRequested;
  final void Function(String? tabId) onActiveTabChanged;

  @override
  ConsumerState<DockTabsSynchronizer> createState() =>
      _DockTabsSynchronizerState();
}

class _DockTabsSynchronizerState extends ConsumerState<DockTabsSynchronizer> {
  String? _lastActiveId;
  int _lastTabCount = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trySync());
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(editorTabsProvider);

    // Dock 页签的关闭按钮只会修改 DockManager。监听布局中真正被移除的
    // panel，并同步删除业务层 EditorTab，避免下次打开文件时旧页签复活。
    ref.listen<DockLayout>(dockManagerProvider, (previous, next) {
      if (previous == null) return;
      final previousIds = _collectPanelIds(previous.root).toSet();
      final nextIds = _collectPanelIds(next.root).toSet();
      final removedIds = previousIds.difference(nextIds);
      if (removedIds.isEmpty) return;

      final notifier = ref.read(editorTabsProvider.notifier);
      for (final id in removedIds) {
        notifier.closeTab(id);
      }
    });

    if (tabs.length != _lastTabCount) {
      _lastTabCount = tabs.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _trySync());
    }

    ref.listen<String?>(activeTabProvider.select((t) => t?.id), (prev, next) {
      if (next != _lastActiveId) {
        _lastActiveId = next;
        widget.onActiveTabChanged(next);
        // 延迟激活面板到 post-frame
        if (next != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _activateTab(next),
          );
        }
      }
    });

    return widget.child;
  }

  void _trySync() {
    if (!mounted) return;
    final tabs = ref.read(editorTabsProvider);
    final manager = ref.read(dockManagerProvider.notifier);
    final currentLayout = ref.read(dockManagerProvider);
    final existingIds = _collectPanelIds(currentLayout.root).toSet();

    for (final id in existingIds) {
      if (tabs.every((t) => t.id != id)) {
        manager.removePanel(id);
      }
    }

    for (final tab in tabs) {
      if (!existingIds.contains(tab.id)) {
        manager.addPanel(buildEditorDockPanel(tab: tab));
      }
    }
  }

  /// 在 DockManager 中激活指定 tabId 对应的面板。
  void _activateTab(String tabId) {
    final currentLayout = ref.read(dockManagerProvider);
    final node = currentLayout.root;
    if (node == null) return;

    // 查找该 panel 所在的 group 和 index
    final result = _findPanelLocation(node, tabId);
    if (result != null) {
      ref
          .read(dockManagerProvider.notifier)
          .setActiveIndex(result.groupId, result.index);
    }
  }

  _PanelLocation? _findPanelLocation(DockNode node, String panelId) {
    switch (node) {
      case DockGroup(:final panels, :final id):
        for (var i = 0; i < panels.length; i++) {
          if (panels[i].id == panelId) {
            return _PanelLocation(groupId: id, index: i);
          }
        }
        return null;
      case DockSplit(:final children):
        for (final child in children) {
          final found = _findPanelLocation(child, panelId);
          if (found != null) return found;
        }
        return null;
    }
  }

  Iterable<String> _collectPanelIds(dynamic node) sync* {
    if (node == null) return;
    if (node is DockGroup) {
      for (final p in node.panels) {
        yield p.id;
      }
    } else if (node is DockSplit) {
      for (final c in node.children) {
        yield* _collectPanelIds(c);
      }
    }
  }
}

class _PanelLocation {
  final String groupId;
  final int index;
  const _PanelLocation({required this.groupId, required this.index});
}
