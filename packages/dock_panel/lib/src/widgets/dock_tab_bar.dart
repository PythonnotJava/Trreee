import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/dock_manager.dart';
import '../theme/dock_theme.dart';

/// Tab bar for a [DockGroup]. Tabs are draggable and support intra-group
/// reordering via DragTarget on each tab.
class DockTabBar extends ConsumerStatefulWidget {
  const DockTabBar({super.key, required this.group});

  final DockGroup group;

  @override
  ConsumerState<DockTabBar> createState() => _DockTabBarState();
}

class _DockTabBarState extends ConsumerState<DockTabBar> {
  final ScrollController _tabsController = ScrollController();

  @override
  void dispose() {
    _tabsController.dispose();
    super.dispose();
  }

  void _scrollTabs(double delta) {
    if (!_tabsController.hasClients) return;
    final target = (_tabsController.offset + delta).clamp(
      0.0,
      _tabsController.position.maxScrollExtent,
    );
    _tabsController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  int? _insertionIndex;

  Future<void> _showTabMenu(
    BuildContext context,
    Offset position,
    DockGroup group,
    int index,
  ) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem(value: 'close', child: Text('关闭')),
        PopupMenuItem(value: 'others', child: Text('关闭其他')),
        PopupMenuItem(value: 'right', child: Text('关闭右侧')),
        PopupMenuItem(value: 'left', child: Text('关闭左侧')),
        PopupMenuItem(value: 'all', child: Text('全部关闭')),
      ],
    );
    if (selected == null) return;
    final ids = switch (selected) {
      'close' => [group.panels[index].id],
      'others' => [
        for (var i = 0; i < group.panels.length; i++)
          if (i != index) group.panels[i].id,
      ],
      'right' => [
        for (var i = index + 1; i < group.panels.length; i++)
          group.panels[i].id,
      ],
      'left' => [for (var i = 0; i < index; i++) group.panels[i].id],
      'all' => group.panels.map((p) => p.id).toList(),
      _ => <String>[],
    };
    final manager = ref.read(dockManagerProvider.notifier);
    for (final id in ids) {
      manager.removePanel(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = DockTheme.of(context);
    final group = widget.group;

    return Container(
      height: theme.tabHeight,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: theme.tabBarColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _tabsController,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  itemCount: group.panels.length,
                  itemBuilder: (context, index) {
                    final panel = group.panels[index];
                    final isActive = index == group.activeIndex;
                    return _ReorderableDockTab(
                      panel: panel,
                      groupId: group.id,
                      index: index,
                      panels: group.panels,
                      isActive: isActive,
                      insertionIndex: _insertionIndex,
                      onTap: () {
                        ref
                            .read(dockManagerProvider.notifier)
                            .setActiveIndex(group.id, index);
                      },
                      onContextMenu: (position) =>
                          _showTabMenu(context, position, group, index),
                      onClose: panel.closable
                          ? () {
                              ref
                                  .read(dockManagerProvider.notifier)
                                  .removePanel(panel.id);
                            }
                          : null,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(dockManagerProvider.notifier)
                            .reorderPanel(group.id, oldIndex, newIndex);
                        setState(() => _insertionIndex = null);
                      },
                      onInsertionIndexChanged: (idx) {
                        setState(() => _insertionIndex = idx);
                      },
                      onDragLeave: () {
                        setState(() => _insertionIndex = null);
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: Icon(Icons.chevron_left, size: 17, color: theme.tabTextColor),
                  tooltip: '',
                  onPressed: () => _scrollTabs(-220),
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: Icon(Icons.chevron_right, size: 17, color: theme.tabTextColor),
                  tooltip: '',
                  onPressed: () => _scrollTabs(220),
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: PopupMenuButton<String>(
                  tooltip: '',
                  icon: Icon(Icons.arrow_drop_down, size: 18, color: theme.tabTextColor),
                  padding: EdgeInsets.zero,
                  onSelected: (panelId) {
                    final index = group.panels.indexWhere((p) => p.id == panelId);
                    if (index >= 0) {
                      ref.read(dockManagerProvider.notifier).setActiveIndex(group.id, index);
                    }
                  },
                  itemBuilder: (_) => group.panels
                      .map((p) => PopupMenuItem(value: p.id, child: Text(p.title)))
                      .toList(),
                ),
              ),
              if (group.activePanel != null)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: Icon(Icons.fullscreen, size: 16, color: theme.tabTextColor),
                    onPressed: () {
                      ref.read(dockManagerProvider.notifier).toggleMaximize(group.activePanel!.id);
                    },
                    tooltip: '',
                    splashRadius: 12,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),
              const SizedBox(width: 4),
            ],
          );
        },
      ),
    );
  }
}

/// A single tab wrapped with DragTarget for intra-group reorder detection.
class _ReorderableDockTab extends StatefulWidget {
  const _ReorderableDockTab({
    required this.panel,
    required this.groupId,
    required this.index,
    required this.panels,
    required this.isActive,
    required this.insertionIndex,
    required this.onTap,
    required this.onContextMenu,
    required this.onReorder,
    required this.onInsertionIndexChanged,
    required this.onDragLeave,
    this.onClose,
  });

  final DockPanel panel;
  final String groupId;
  final int index;
  final List<DockPanel> panels;
  final bool isActive;
  final int? insertionIndex;
  final VoidCallback onTap;
  final ValueChanged<Offset> onContextMenu;
  final VoidCallback? onClose;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onInsertionIndexChanged;
  final VoidCallback onDragLeave;

  @override
  State<_ReorderableDockTab> createState() => _ReorderableDockTabState();
}

class _ReorderableDockTabState extends State<_ReorderableDockTab> {
  bool _isDragging = false;

  int _computeInsertionIndex(Offset globalPosition, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final local = renderBox.globalToLocal(globalPosition);
    final halfWidth = renderBox.size.width / 2;
    return local.dx < halfWidth ? widget.index : widget.index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = DockTheme.of(context);
    final isActive = widget.isActive;
    final showInsertionBefore = widget.insertionIndex == widget.index && !_isDragging;
    final showInsertionAfter = widget.insertionIndex == widget.index + 1 && !_isDragging;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showInsertionBefore)
          Container(width: 2, height: theme.tabHeight, color: theme.activeTabColor),
        DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != widget.index,
          onAcceptWithDetails: (details) {
            widget.onReorder(details.data, widget.index);
          },
          onMove: (details) {
            final idx = _computeInsertionIndex(details.offset, context);
            widget.onInsertionIndexChanged(idx);
          },
          onLeave: (_) => widget.onDragLeave(),
          builder: (context, candidateData, rejectedData) {
            return LongPressDraggable<int>(
              data: widget.index,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.tabBarColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.panel.title,
                    style: TextStyle(fontSize: 12, color: theme.tabTextColor),
                  ),
                ),
              ),
              onDragStarted: () => setState(() => _isDragging = true),
              onDragEnd: (_) {
                setState(() => _isDragging = false);
                widget.onDragLeave();
              },
              child: GestureDetector(
                onTap: widget.onTap,
                onSecondaryTapDown: (d) => widget.onContextMenu(d.globalPosition),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  constraints: const BoxConstraints(minWidth: 80),
                  decoration: BoxDecoration(
                    color: isActive ? theme.activeTabColor : null,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? theme.activeTabColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.panel.icon != null) ...[
                        Icon(widget.panel.icon, size: 14, color: theme.tabTextColor),
                        const SizedBox(width: 4),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          widget.panel.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.tabTextColor,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (widget.onClose != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: widget.onClose,
                          borderRadius: BorderRadius.circular(3),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close, size: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (showInsertionAfter)
          Container(width: 2, height: theme.tabHeight, color: theme.activeTabColor),
      ],
    );
  }
}
