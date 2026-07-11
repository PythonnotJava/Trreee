import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前打开的工作区根目录。
///
/// 为空字符串或 null 时表示"未打开工作区"——文件树显示空状态。
final workspaceRootProvider = StateProvider<String?>((ref) => null);

/// 文件树节点展开状态：以路径作为 key。
final expandedPathsProvider = StateProvider<Set<String>>((ref) => <String>{});

/// "全部展开/全部收缩" 触发的全局事件。
/// 通过一个单调递增的计数器实现，让子组件在变化时强制重建。
final expandCollapseEventProvider = StateProvider<int>((ref) => 0);
