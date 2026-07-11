import 'package:flutter/material.dart';

/// 根据文件名/扩展名推断 highlight.js 的 language id。
class LanguageDetector {
  static const Map<String, String> _extMap = {
    'dart': 'dart',
    'js': 'javascript',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'jsx': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'html': 'xml',
    'htm': 'xml',
    'vue': 'xml',
    'svelte': 'xml',
    'css': 'css',
    'scss': 'scss',
    'sass': 'scss',
    'less': 'less',
    'py': 'python',
    'pyx': 'python',
    'java': 'java',
    'kt': 'kotlin',
    'kts': 'kotlin',
    'swift': 'swift',
    'go': 'go',
    'rs': 'rust',
    'rb': 'ruby',
    'php': 'php',
    'cs': 'cs',
    'cpp': 'cpp',
    'cc': 'cpp',
    'cxx': 'cpp',
    'c': 'c',
    'h': 'c',
    'hpp': 'cpp',
    'm': 'objectivec',
    'mm': 'objectivec',
    'sh': 'bash',
    'bash': 'bash',
    'zsh': 'bash',
    'ps1': 'powershell',
    'bat': 'dos',
    'cmd': 'dos',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'toml': 'ini',
    'ini': 'ini',
    'xml': 'xml',
    'csv': 'plaintext',
    'md': 'markdown',
    'markdown': 'markdown',
    'tex': 'latex',
    'sql': 'sql',
    'lua': 'lua',
    'pl': 'perl',
    'r': 'r',
    'dockerfile': 'dockerfile',
  };

  static String? detectByPath(String path) {
    final lower = path.toLowerCase();
    final name = _basename(lower);
    if (name == 'dockerfile') return 'dockerfile';
    if (name == 'makefile') return 'makefile';
    if (name == 'cmakelists.txt') return 'cmake';
    if (name == '.gitignore') return 'plaintext';
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return null;
    return _extMap[name.substring(dot + 1)];
  }

  static IconData iconForPath(String path, bool isDirectory) {
    if (isDirectory) return Icons.folder_outlined;
    final name = _basename(path.toLowerCase());
    if (name.startsWith('.')) return Icons.visibility_off_outlined;
    final dot = name.lastIndexOf('.');
    if (dot == -1) return Icons.insert_drive_file_outlined;
    final ext = name.substring(dot + 1);
    return switch (ext) {
      'dart' => Icons.code,
      'js' || 'ts' || 'jsx' || 'tsx' => Icons.javascript,
      'py' => Icons.code,
      'java' || 'kt' => Icons.coffee,
      'json' => Icons.data_object,
      'yaml' || 'yml' || 'toml' || 'ini' => Icons.settings,
      'md' || 'markdown' => Icons.description,
      'png' ||
      'jpg' ||
      'jpeg' ||
      'gif' ||
      'svg' ||
      'webp' => Icons.image_outlined,
      'mp3' || 'wav' || 'ogg' || 'flac' => Icons.audiotrack_outlined,
      'mp4' || 'mov' || 'avi' || 'mkv' => Icons.movie_outlined,
      'zip' || 'tar' || 'gz' || 'rar' || '7z' => Icons.archive_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  /// 判断是否为可预览的图片文件。
  static bool isImagePath(String path) {
    final name = _basename(path.toLowerCase());
    final dot = name.lastIndexOf('.');
    if (dot == -1) return false;
    const exts = {'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'bmp', 'ico'};
    return exts.contains(name.substring(dot + 1));
  }

  static String _basename(String path) {
    var p = path.replaceAll('\\', '/');
    while (p.endsWith('/') && p.length > 1) {
      p = p.substring(0, p.length - 1);
    }
    final idx = p.lastIndexOf('/');
    return idx == -1 ? p : p.substring(idx + 1);
  }
}
