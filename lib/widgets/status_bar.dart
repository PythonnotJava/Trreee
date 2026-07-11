import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/editor_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workspace_provider.dart';

/// Status bar at the bottom of the app.
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final root = ref.watch(workspaceRootProvider);
    final settings = ref.watch(settingsProvider);
    final active = ref.watch(activeTabProvider);

    final bg = theme.brightness == Brightness.dark
        ? const Color(0xFF007ACC)
        : theme.colorScheme.primary;
    final fg = theme.brightness == Brightness.dark
        ? Colors.white
        : theme.colorScheme.onPrimary;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bg),
      child: Row(
        children: [
          if (root != null && root.isNotEmpty)
            _Item(icon: Icons.folder_open, text: _compactPath(root), color: fg),
          if (root != null && root.isNotEmpty)
            const _Sep(color: Colors.white24),

          if (active != null) ...[
            _Item(
              icon: active.dirty ? Icons.edit : Icons.description,
              text: active.title,
              color: fg,
            ),
            const _Sep(color: Colors.white24),
          ],

          if (active?.languageId != null) ...[
            _Item(
              icon: Icons.code,
              text: _langDisplay(active!.languageId!),
              color: fg,
            ),
            const _Sep(color: Colors.white24),
          ],

          if (active != null) ...[
            _Item(
              icon: Icons.tag,
              text: '${_lineCount(active.content)} lines',
              color: fg,
            ),
            const _Sep(color: Colors.white24),
          ],

          const Spacer(),

          _Item(
            icon: Icons.text_fields,
            text: '${settings.codeFontSize.toStringAsFixed(0)}px',
            color: fg,
          ),
          const _Sep(color: Colors.white24),

          _Item(
            icon: _themeIcon(settings.themeMode),
            text: _themeLabel(settings.themeMode),
            color: fg,
          ),
        ],
      ),
    );
  }

  String _compactPath(String path) {
    if (path.length <= 40) return path;
    return '...${path.substring(path.length - 39)}';
  }

  int _lineCount(String content) {
    if (content.isEmpty) return 0;
    return content.split('\n').length;
  }

  String _langDisplay(String langId) {
    switch (langId) {
      case 'plaintext':
        return 'plain';
      default:
        return langId;
    }
  }

  IconData _themeIcon(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => Icons.brightness_auto,
      AppThemeMode.light => Icons.light_mode,
      AppThemeMode.dark => Icons.dark_mode,
    };
  }

  String _themeLabel(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'system',
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
    };
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
