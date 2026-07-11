import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../models/app_settings.dart';
import '../../models/editor_tab.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/file_utils.dart' show isUnsupportedBinaryPath;
import '../../utils/highlight_loader.dart'
    show HighlightThemes, sharedHighlight;
import '../../utils/language_detector.dart';

class CodeEditorView extends ConsumerStatefulWidget {
  const CodeEditorView({super.key, required this.tabId});
  final String tabId;

  @override
  ConsumerState<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends ConsumerState<CodeEditorView> {
  late TextEditingController _controller;
  late ScrollController _editorSc;
  late ScrollController _highlightSc;
  late FocusNode _focusNode;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _editorSc = ScrollController();
    _highlightSc = ScrollController();
    _focusNode = FocusNode();
    _editorSc.addListener(_syncHighlightScroll);
  }

  void _syncHighlightScroll() {
    if (!_highlightSc.hasClients) return;
    _highlightSc.jumpTo(_editorSc.offset);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _editorSc.removeListener(_syncHighlightScroll);
    _controller.dispose();
    _editorSc.dispose();
    _highlightSc.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncController(String content) {
    if (_controller.text == content) return;
    _controller.value = TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(offset: content.length),
    );
  }

  void _onContentChanged(String value) {
    ref.read(editorTabsProvider.notifier).updateContent(widget.tabId, value);

    final editorMode =
        ref.read(settingsProvider.select((s) => s.editorMode));
    final tabs = ref.read(editorTabsProvider);
    final tab = tabs.where((t) => t.id == widget.tabId).firstOrNull;
    if (tab == null) return;
    if (editorMode == EditorMode.edit && !tab.readOnly) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 1), () {
        _saveToDiskSilently();
      });
    }
  }

  Future<void> _saveToDiskSilently() async {
    if (!mounted) return;
    final tabs = ref.read(editorTabsProvider);
    final tab = tabs.where((t) => t.id == widget.tabId).firstOrNull;
    if (tab == null || tab.readOnly || tab.dirty == false) return;

    final content = tab.content;
    try {
      await io.File(tab.path).writeAsString(content, flush: true);
      if (!mounted) return;
      ref.read(editorTabsProvider.notifier).markSaved(widget.tabId);
    } on io.FileSystemException {
      // silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(editorTabsProvider);
    final tab = tabs.where((t) => t.id == widget.tabId).firstOrNull;
    if (tab == null) return const Center(child: Text('标签不存在'));

    final theme = Theme.of(context);

    // 精确监听 — 仅在这些字段变化时重建编辑器，而不是整个 settings。
    final hlThemeId =
        ref.watch(settingsProvider.select((s) => s.highlightThemeId));
    final fontSize =
        ref.watch(settingsProvider.select((s) => s.codeFontSize));
    final showLines =
        ref.watch(settingsProvider.select((s) => s.showLineNumbers));
    final editorMode =
        ref.watch(settingsProvider.select((s) => s.editorMode));
    final isViewMode = editorMode == EditorMode.view;
    final isMd = tab.path.toLowerCase().endsWith('.md');

    if (LanguageDetector.isImagePath(tab.path)) {
      return _ImageView(path: tab.path);
    }

    if (tab.loading) {
      return const _LoadingView();
    }

    if (isUnsupportedBinaryPath(tab.path) || tab.loadError != null) {
      return _UnsupportedView(
        message: tab.loadError == null
            ? '此类文件不支持预览'
            : '文件读取失败：${tab.loadError}',
      );
    }

    if (isViewMode && isMd) {
      return _MarkdownPreview(content: tab.content, theme: theme);
    }

    final themeData = HighlightThemes.byId(hlThemeId);

    if (_controller.text != tab.content) {
      _syncController(tab.content);
    }

    final editor = RepaintBoundary(
      child: _EditableView(
        tab: tab,
        themeData: themeData,
        codeFontSize: fontSize,
        showLineNumbers: showLines,
        controller: _controller,
        focusNode: _focusNode,
        editorSc: _editorSc,
        highlightSc: _highlightSc,
        readOnly: isViewMode || tab.readOnly || tab.truncated,
        onChanged: _onContentChanged,
      ),
    );

    if (!tab.truncated) return editor;
    return Column(
      children: [
        const MaterialBanner(
          content: Text('文件较大，仅预览前 2 MB；为保证流畅性已禁用编辑。'),
          actions: [SizedBox.shrink()],
        ),
        Expanded(child: editor),
      ],
    );
  }
}

// ── Markdown 富文本预览 ──

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({required this.content, required this.theme});
  final String content;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: GptMarkdown(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      ),
    );
  }
}

// ── 加载与不支持预览 ──

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('正在加载文件…'),
        ],
      ),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  const _UnsupportedView({this.message = '此类文件不支持预览'});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = resolveBackgroundColor(theme, null);
    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_outlined, size: 48,
                color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(message,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

// ── 图片预览 ──

class _ImageView extends StatelessWidget {
  const _ImageView({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = resolveBackgroundColor(theme, null);
    final file = io.File(path);
    if (!file.existsSync()) return Center(child: Text('文件不存在: $path'));
    return Container(
      color: bg,
      child: InteractiveViewer(
        minScale: 0.1,
        maxScale: 10,
        child: Center(
          child: Image.file(file, fit: BoxFit.contain,
              errorBuilder: (_, err, s) =>
                  const Center(child: Text('无法加载图片'))),
        ),
      ),
    );
  }
}

// ── 可编辑视图 ──

class _EditableView extends StatefulWidget {
  const _EditableView({
    required this.tab,
    required this.themeData,
    required this.codeFontSize,
    required this.showLineNumbers,
    required this.controller,
    required this.focusNode,
    required this.editorSc,
    required this.highlightSc,
    required this.readOnly,
    required this.onChanged,
  });
  final EditorTab tab;
  final dynamic themeData;
  final double codeFontSize;
  final bool showLineNumbers;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController editorSc;
  final ScrollController highlightSc;
  final bool readOnly;
  final ValueChanged<String> onChanged;

  @override
  State<_EditableView> createState() => _EditableViewState();
}

class _EditableViewState extends State<_EditableView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final fontSize = widget.codeFontSize;
    const lineHeight = 1.5;
    final lineCount = '\n'.allMatches(widget.controller.text).length + 1;
    final gutterWidth = widget.showLineNumbers
        ? ((lineCount.toString().length * fontSize * 0.6) + 12)
        : 0.0;
    final editorTextStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: lineHeight,
      color: Colors.transparent,
    );

    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      child: Container(
        color: bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: widget.highlightSc,
                  physics: const NeverScrollableScrollPhysics(),
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: HighlightView(
                        widget.controller.text.isEmpty
                            ? ' '
                            : widget.controller.text,
                        language: widget.tab.languageId,
                        theme: widget.themeData,
                        backgroundColor: bg,
                        padding: EdgeInsets.zero,
                        highlighter: sharedHighlight,
                        showLineNumbers: widget.showLineNumbers,
                        textStyle: editorTextStyle.copyWith(color: null),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(scrollbars: false),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    readOnly: widget.readOnly,
                    controller: widget.controller,
                    scrollController: widget.editorSc,
                    maxLines: null,
                    expands: true,
                    style: editorTextStyle,
                    strutStyle: StrutStyle(
                      fontFamily: 'monospace',
                      fontSize: fontSize,
                      height: lineHeight,
                      forceStrutHeight: true,
                    ),
                    cursorHeight: fontSize * lineHeight,
                    cursorColor: theme.colorScheme.primary,
                    cursorWidth: 2,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(left: gutterWidth),
                    ),
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 公共背景色工具 ──

Color resolveBackgroundColor(ThemeData theme, dynamic hljsTheme) {
  if (hljsTheme != null) {
    try {
      final root = hljsTheme['root'] as Map?;
      if (root != null && root['backgroundColor'] is String) {
        return _parseHex(root['backgroundColor'] as String);
      }
    } catch (_) {}
  }
  return theme.brightness == Brightness.dark
      ? const Color(0xFF1E1E1E)
      : const Color(0xFFFAFAFA);
}

Color _parseHex(String hex) {
  var h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 3) h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
  final value = int.parse(h, radix: 16);
  if (h.length == 6) return Color(value | 0xFF000000);
  return Color(value);
}
