import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';

/// 全局设置状态。
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void setThemeMode(AppThemeMode mode) =>
      state = state.copyWith(themeMode: mode);

  void setCodeFontSize(double size) =>
      state = state.copyWith(codeFontSize: size.clamp(10.0, 28.0));

  void toggleLineNumbers() =>
      state = state.copyWith(showLineNumbers: !state.showLineNumbers);

  void toggleWordWrap() => state = state.copyWith(wordWrap: !state.wordWrap);

  void toggleAutoDetectLanguage() =>
      state = state.copyWith(autoDetectLanguage: !state.autoDetectLanguage);

  void setHighlightThemeId(String id) =>
      state = state.copyWith(highlightThemeId: id);

  void setExcludePatterns(List<String> patterns) =>
      state = state.copyWith(excludePatterns: patterns);

  void setEditorMode(EditorMode mode) =>
      state = state.copyWith(editorMode: mode);

  void toggleEditorMode() {
    final next = state.editorMode == EditorMode.view
        ? EditorMode.edit
        : EditorMode.view;
    state = state.copyWith(editorMode: next);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
