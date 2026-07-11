import 'package:flutter/material.dart';

/// 一个已打开的文件标签。
class EditorTab {
  EditorTab({
    required this.id,
    required this.path,
    required this.title,
    required this.content,
    this.dirty = false,
    this.languageId,
    this.icon,
    this.readOnly = false,
    this.loading = false,
    this.truncated = false,
    this.loadError,
    this.lastLoadedAt,
  });

  final String id;
  final String path;
  final String title;
  final String content;
  final bool dirty;
  final String? languageId;
  final IconData? icon;
  final bool readOnly;

  /// 文件是否仍在后台读取。
  final bool loading;

  /// 是否只加载了大文件的前一部分。
  final bool truncated;

  /// 读取失败信息。
  final String? loadError;

  /// 最后一次从磁盘加载内容的时间。
  /// 用于检测外部编辑器所做的修改。
  final DateTime? lastLoadedAt;

  EditorTab copyWith({
    String? content,
    bool? dirty,
    bool? readOnly,
    bool? loading,
    bool? truncated,
    String? loadError,
    bool clearLoadError = false,
    DateTime? lastLoadedAt,
    bool clearLastLoadedAt = false,
  }) {
    return EditorTab(
      id: id,
      path: path,
      title: title,
      content: content ?? this.content,
      dirty: dirty ?? this.dirty,
      languageId: languageId,
      icon: icon,
      readOnly: readOnly ?? this.readOnly,
      loading: loading ?? this.loading,
      truncated: truncated ?? this.truncated,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      lastLoadedAt: clearLastLoadedAt
          ? null
          : (lastLoadedAt ?? this.lastLoadedAt),
    );
  }
}
