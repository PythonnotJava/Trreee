import 'dart:io';

/// 一个文件树节点。
///
/// 用 `children` 表示子节点（目录才有）。
/// `isExpanded` 是 UI 状态，与文件系统的内容无关。
class FileNode {
  FileNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    List<FileNode>? children,
    this.isExpanded = false,
    this.isLoading = false,
    this.errorMessage,
  }) : children = children ?? [];

  /// 文件/目录的完整绝对路径。
  final String path;

  /// 显示名（不含路径）。
  final String name;

  /// 是否为目录。
  final bool isDirectory;

  /// 子节点。仅目录使用；叶节点为空。
  final List<FileNode> children;

  /// UI 状态：是否在树中展开。
  final bool isExpanded;

  /// UI 状态：是否正在异步加载子节点。
  final bool isLoading;

  /// 如果加载失败，记录错误信息。
  final String? errorMessage;

  FileNode copyWith({
    List<FileNode>? children,
    bool? isExpanded,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FileNode(
      path: path,
      name: name,
      isDirectory: isDirectory,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// 通过路径快速查找一个 FileNode。
  ///
  /// 只搜索当前节点下的子树。
  FileNode? findByPath(String target) {
    if (path == target) return this;
    if (!isDirectory) return null;
    for (final child in children) {
      final found = child.findByPath(target);
      if (found != null) return found;
    }
    return null;
  }

  /// 递归收集所有目录路径（用于 "全部展开"）。
  List<String> collectDirectoryPaths() {
    final result = <String>[];
    if (!isDirectory) return result;
    result.add(path);
    for (final child in children) {
      result.addAll(child.collectDirectoryPaths());
    }
    return result;
  }

  /// 当前节点的所有子目录数量。
  int get directoryCount => children.where((c) => c.isDirectory).length;
}

/// 同步读取目录的辅助函数。
FileNode buildNodeFromFileSystem(FileSystemEntity entity) {
  final isDir = entity is Directory;
  return FileNode(
    path: entity.path,
    name: _basename(entity.path),
    isDirectory: isDir,
  );
}

String _basename(String path) {
  var p = path.replaceAll('\\', '/');
  while (p.endsWith('/') && p.length > 1) {
    p = p.substring(0, p.length - 1);
  }
  final idx = p.lastIndexOf('/');
  return idx == -1 ? p : p.substring(idx + 1);
}
