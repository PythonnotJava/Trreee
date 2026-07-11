import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

List<FileSystemEntity> listEntities(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return const [];
  final entries = dir.listSync(followLinks: false);
  entries.sort((a, b) {
    final aIsDir = a is Directory;
    final bIsDir = b is Directory;
    if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
    return p
        .basename(a.path)
        .toLowerCase()
        .compareTo(p.basename(b.path).toLowerCase());
  });
  return entries;
}

class TextFileLoadResult {
  const TextFileLoadResult({
    required this.content,
    required this.truncated,
    this.error,
  });

  final String content;
  final bool truncated;
  final String? error;
}

/// 异步读取文本，避免文件 IO 阻塞 UI。
/// 大于 [previewBytes] 的文件只读取头部并以只读预览形式展示。
Future<TextFileLoadResult> readTextFilePreview(
  String path, {
  int previewBytes = 2 * 1024 * 1024,
}) async {
  try {
    final file = File(path);
    final size = await file.length();
    final truncated = size > previewBytes;
    final bytes = <int>[];

    await for (final chunk in file.openRead(
      0,
      truncated ? previewBytes : null,
    )) {
      bytes.addAll(chunk);
    }

    return TextFileLoadResult(
      content: _decodeUtf8(bytes),
      truncated: truncated,
    );
  } on FileSystemException catch (e) {
    return TextFileLoadResult(content: '', truncated: false, error: e.message);
  }
}

/// 保留给轻量同步场景使用。
String? readFileSafely(String path, {int maxBytes = 5 * 1024 * 1024}) {
  try {
    final file = File(path);
    final size = file.statSync().size;
    if (size > maxBytes) return null;
    return _decodeUtf8(file.readAsBytesSync());
  } on FileSystemException {
    return null;
  }
}

String _decodeUtf8(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

bool isUnsupportedBinaryPath(String path) {
  final name = p.basename(path).toLowerCase();
  final dot = name.lastIndexOf('.');
  if (dot == -1) return false;
  final ext = name.substring(dot + 1);
  const unsupported = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'exe',
    'dll',
    'so',
    'dylib',
    'bin',
    'o',
    'a',
    'lib',
    'zip',
    'tar',
    'gz',
    'bz2',
    'xz',
    '7z',
    'rar',
    'mp3',
    'wav',
    'ogg',
    'flac',
    'aac',
    'wma',
    'mp4',
    'mov',
    'avi',
    'mkv',
    'wmv',
    'flv',
    'webm',
    'ttf',
    'otf',
    'woff',
    'woff2',
    'class',
    'jar',
    'war',
    'ear',
    'pyc',
    'pyo',
    'wasm',
    'epub',
    'mobi',
    'db',
    'sqlite',
    'sqlite3',
    'ico',
    'icns',
    'psd',
    'ai',
    'sketch',
    'iso',
    'img',
    'dmg',
    'vmdk',
  };
  return unsupported.contains(ext);
}

Future<void> writeFileSafely(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content, flush: true);
}

bool shouldExclude(String name, Iterable<String> patterns) {
  final lower = name.toLowerCase();
  for (final pat in patterns) {
    final lp = pat.toLowerCase();
    if (lower == lp) return true;
    if (lp.startsWith('.') && lower.endsWith(lp)) return true;
  }
  return false;
}

List<String> collectAllDirectoryPaths(
  String rootPath,
  Iterable<String> excludes,
) {
  final result = <String>[rootPath];
  try {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return result;
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (!shouldExclude(name, excludes)) {
          result.addAll(collectAllDirectoryPaths(entity.path, excludes));
        }
      }
    }
  } on FileSystemException {
    // inaccessible — skip
  }
  return result;
}

bool entityExists(String path) {
  return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
}
