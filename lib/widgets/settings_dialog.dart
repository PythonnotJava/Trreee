import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../utils/highlight_loader.dart';

/// 应用首选项对话框。
///
/// 涵盖：主题模式、代码字号、行号、自动换行、highlight 主题、
/// 文件树排除规则。
class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  /// 静态入口。返回是否需要后续动作（如无需手动实现）。
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late TextEditingController _excludeController;
  late double _draftFontSize;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _draftFontSize = settings.codeFontSize;
    _excludeController = TextEditingController(
      text: settings.excludePatterns.join(', '),
    );
  }

  @override
  void dispose() {
    _excludeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AlertDialog(
      title: const Text('首选项'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(text: '外观'),
              const SizedBox(height: 8),
              _ThemeModeRow(
                value: settings.themeMode,
                onChanged: notifier.setThemeMode,
              ),
              const SizedBox(height: 16),

              _SectionTitle(text: '编辑器'),
              const SizedBox(height: 8),
              _EditorModeRow(
                value: settings.editorMode,
                onChanged: notifier.setEditorMode,
              ),
              const SizedBox(height: 16),
              _LabeledRow(
                label: '代码字号',
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: 10,
                        max: 28,
                        divisions: 18,
                        value: _draftFontSize,
                        label: _draftFontSize.toStringAsFixed(0),
                        onChanged: (value) =>
                            setState(() => _draftFontSize = value),
                        onChangeEnd: notifier.setCodeFontSize,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        _draftFontSize.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示行号'),
                value: settings.showLineNumbers,
                onChanged: (_) => notifier.toggleLineNumbers(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('自动换行'),
                value: settings.wordWrap,
                onChanged: (_) => notifier.toggleWordWrap(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('自动检测语言'),
                value: settings.autoDetectLanguage,
                onChanged: (_) => notifier.toggleAutoDetectLanguage(),
              ),
              const SizedBox(height: 8),

              _SectionTitle(text: '语法高亮主题'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: settings.highlightThemeId,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: HighlightThemes.available
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.id,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) notifier.setHighlightThemeId(id);
                },
              ),
              const SizedBox(height: 16),

              _SectionTitle(text: '文件树排除规则'),
              const SizedBox(height: 8),
              TextField(
                controller: _excludeController,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '逗号分隔, 例如: .git, build, node_modules',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final list = _excludeController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    notifier.setExcludePatterns(list);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('排除规则已更新')));
                  },
                  child: const Text('应用'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 96, child: Text(label)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EditorModeRow extends StatelessWidget {
  const _EditorModeRow({required this.value, required this.onChanged});
  final EditorMode value;
  final ValueChanged<EditorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<EditorMode>(
          segments: const [
            ButtonSegment(
              value: EditorMode.view,
              label: Text('视图模式'),
              icon: Icon(Icons.visibility, size: 16),
            ),
            ButtonSegment(
              value: EditorMode.edit,
              label: Text('编辑模式'),
              icon: Icon(Icons.edit, size: 16),
            ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (set) {
            if (set.isNotEmpty) onChanged(set.first);
          },
        ),
        const SizedBox(height: 6),
        Text(
          value == EditorMode.view
              ? '📖 Markdown 文件使用富文本预览，所有文件只读'
              : '✏️ 可直接编辑文本，修改内容会自动保存',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({required this.value, required this.onChanged});

  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppThemeMode>(
      segments: const [
        ButtonSegment(
          value: AppThemeMode.system,
          label: Text('跟随系统'),
          icon: Icon(Icons.brightness_auto, size: 16),
        ),
        ButtonSegment(
          value: AppThemeMode.light,
          label: Text('浅色'),
          icon: Icon(Icons.light_mode, size: 16),
        ),
        ButtonSegment(
          value: AppThemeMode.dark,
          label: Text('深色'),
          icon: Icon(Icons.dark_mode, size: 16),
        ),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
    );
  }
}
