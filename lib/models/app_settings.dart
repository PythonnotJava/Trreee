import 'package:flutter/material.dart';

/// 主题模式。
enum AppThemeMode { system, light, dark }

/// 编辑器模式。
enum EditorMode { view, edit }

/// 用户设置。
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.codeFontSize = 14.0,
    this.showLineNumbers = true,
    this.wordWrap = false,
    this.autoDetectLanguage = true,
    this.highlightThemeId = 'atom-one-dark',
    this.excludePatterns = const [
      '.git',
      '.dart_tool',
      'build',
      '.idea',
      '.gradle',
      'node_modules',
      '.metadata',
      '.pub-cache',
    ],
    this.editorMode = EditorMode.view,
  });

  final AppThemeMode themeMode;
  final double codeFontSize;
  final bool showLineNumbers;
  final bool wordWrap;
  final bool autoDetectLanguage;

  /// 当前使用的 highlight 主题 id。
  final String highlightThemeId;

  /// 在加载文件树时跳过的目录/文件名。
  final List<String> excludePatterns;

  /// 全局编辑器模式：view（预览模式）或 edit（编辑模式）。
  final EditorMode editorMode;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    double? codeFontSize,
    bool? showLineNumbers,
    bool? wordWrap,
    bool? autoDetectLanguage,
    String? highlightThemeId,
    List<String>? excludePatterns,
    EditorMode? editorMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      codeFontSize: codeFontSize ?? this.codeFontSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wordWrap: wordWrap ?? this.wordWrap,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      highlightThemeId: highlightThemeId ?? this.highlightThemeId,
      excludePatterns: excludePatterns ?? this.excludePatterns,
      editorMode: editorMode ?? this.editorMode,
    );
  }

  ThemeMode get materialThemeMode => switch (themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
