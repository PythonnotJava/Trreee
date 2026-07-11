import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/file_node.dart';
import '../utils/file_utils.dart';
import 'settings_provider.dart';
import 'workspace_provider.dart';

/// 加载目录子节点的辅助函数（同步）。
/// 不抛错；目录读取失败时返回空数组。
List<FileNode> _loadChildren(String path, Iterable<String> excludes) {
  try {
    final entities = listEntities(path);
    return entities
        .where((e) => !shouldExclude(_basename(e.path), excludes))
        .map((e) {
          final isDir = e is Directory;
          return FileNode(
            path: e.path,
            name: _basename(e.path),
            isDirectory: isDir,
          );
        })
        .toList();
  } on FileSystemException {
    return [];
  }
}

String _basename(String path) {
  var p = path.replaceAll('\\', '/');
  while (p.endsWith('/') && p.length > 1) {
    p = p.substring(0, p.length - 1);
  }
  final idx = p.lastIndexOf('/');
  return idx == -1 ? p : p.substring(idx + 1);
}

/// 当前工作区的根节点。
///
/// 每次 workspace 变化或 excludePatterns 变化时重新加载。
final workspaceRootNodeProvider = Provider<FileNode?>((ref) {
  final root = ref.watch(workspaceRootProvider);
  if (root == null || root.isEmpty) return null;
  if (!Directory(root).existsSync()) return null;

  final excludes = ref.watch(settingsProvider).excludePatterns;
  final children = _loadChildren(root, excludes);
  return FileNode(
    path: root,
    name: _basename(root),
    isDirectory: true,
    children: children,
    isExpanded: true,
  );
});

/// 给定路径，惰性加载其直接子节点。
///
/// 不会缓存，由调用方决定如何把 children 写回到节点。
final lazyChildrenProvider = Provider.family<List<FileNode>, String>((
  ref,
  path,
) {
  final excludes = ref.watch(settingsProvider).excludePatterns;
  return _loadChildren(path, excludes);
});

/// 异步刷新整个工作区（用于 F5 之类的快捷键）。
final refreshTreeProvider = StateProvider<int>((ref) => 0);
