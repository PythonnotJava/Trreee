import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/editor_tab.dart';
import '../utils/file_utils.dart';
import '../utils/language_detector.dart';

const _uuid = Uuid();

/// Safely obtain a file's mtime. Returns null when missing / unreadable.
DateTime? _fileMtime(String path) {
  try {
    return File(path).lastModifiedSync();
  } on FileSystemException {
    return null;
  }
}

// EditorTabsNotifier --------------------------------------------------------

/// Central state holder for opened editor tabs.
class EditorTabsNotifier extends StateNotifier<List<EditorTab>> {
  EditorTabsNotifier(this._ref) : super(const []);

  /// Riverpod container reference, injected via the provider factory.
  /// Used to coordinate with fileConflictsProvider.
  // ignore: prefer_final_fields
  Ref _ref;

  String? _activeId;
  String? get activeId => _activeId;

  /// Open or activate a file.
  ///
  /// If a tab for the same path already exists:
  ///   - when no local unsaved changes: re-read from disk so that
  ///     external edits are reflected immediately;
  ///   - when dirty: keep the in-memory version, only activate the tab.
  String openFile(String path) {
    final existing = state.where((t) => t.path == path).firstOrNull;
    if (existing != null) {
      _activeId = existing.id;
      // Force activeTabProvider to re-emit.
      state = [...state];
      if (!existing.dirty && !existing.loading) {
        // Asynchronously reload from disk to make sure the latest
        // version (post external edit) lands in the editor.
        syncFromDisk(existing.id);
      }
      return existing.id;
    }

    final tab = EditorTab(
      id: _uuid.v4(),
      path: path,
      title: _basename(path),
      content: '',
      languageId: LanguageDetector.detectByPath(path),
      icon: LanguageDetector.iconForPath(path, false),
      readOnly: isUnsupportedBinaryPath(path),
      loading:
          !isUnsupportedBinaryPath(path) && !LanguageDetector.isImagePath(path),
    );

    state = [...state, tab];
    _activeId = tab.id;

    if (tab.loading) {
      _loadTab(tab.id, path);
    }
    return tab.id;
  }

  Future<void> _loadTab(String tabId, String path) async {
    final result = await readTextFilePreview(path);
    final idx = state.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;
    final current = state[idx];
    state = [...state]
      ..[idx] = current.copyWith(
        content: result.content,
        loading: false,
        truncated: result.truncated,
        readOnly: result.truncated || result.error != null,
        loadError: result.error,
        clearLoadError: result.error == null,
        lastLoadedAt: _fileMtime(path) ?? DateTime.now(),
      );
  }

  void closeTab(String tabId) {
    final idx = state.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;
    final newTabs = [...state]..removeAt(idx);
    state = newTabs;
    if (_activeId == tabId) {
      if (newTabs.isEmpty) {
        _activeId = null;
      } else {
        final fallback = newTabs[idx >= newTabs.length ? idx - 1 : idx];
        _activeId = fallback.id;
      }
    }
    _removeFromConflicts(tabId);
  }

  void closeTabs(Iterable<String> ids) {
    final set = ids.toSet();
    if (set.isEmpty) return;
    final activeIndex = state.indexWhere((t) => t.id == _activeId);
    final remaining = state.where((t) => !set.contains(t.id)).toList();
    state = remaining;
    if (_activeId != null && set.contains(_activeId)) {
      if (remaining.isEmpty) {
        _activeId = null;
      } else {
        final index = activeIndex.clamp(0, remaining.length - 1);
        _activeId = remaining[index].id;
      }
    }
    for (final id in set) {
      _removeFromConflicts(id);
    }
  }

  void closeAllTabs() {
    final removed = state.map((t) => t.id).toList();
    state = const [];
    _activeId = null;
    for (final id in removed) {
      _removeFromConflicts(id);
    }
  }

  void setActive(String tabId) {
    if (state.any((t) => t.id == tabId) && _activeId != tabId) {
      _activeId = tabId;
      state = [...state];
    }
  }

  void updateContent(String tabId, String newContent) {
    final idx = state.indexWhere((t) => t.id == tabId);
    if (idx == -1 || state[idx].readOnly) return;
    final tab = state[idx];
    if (tab.content == newContent) return;
    state = [...state]..[idx] = tab.copyWith(content: newContent, dirty: true);
  }

  /// Mark the tab as saved to disk. Uses the file mtime so that
  /// the FileSyncTicker compares against the same clock source.
  void markSaved(String tabId) {
    final idx = state.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;
    final tab = state[idx];
    final mtime = _fileMtime(tab.path) ?? DateTime.now();
    state = [...state]..[idx] = tab.copyWith(dirty: false, lastLoadedAt: mtime);
  }

  Future<void> reloadFromDisk(String tabId) async {
    final idx = state.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;
    final tab = state[idx];
    state = [...state]..[idx] = tab.copyWith(loading: true);
    await _loadTab(tabId, tab.path);
    _removeFromConflicts(tabId);
  }

  /// Silent reload from disk (no loading state).
  ///
  /// Called when external editors modify the file: refresh the in-memory
  /// content and clear the dirty flag so that the editor no longer claims
  /// "unsaved changes" against a disk that already has the new content.
  Future<void> syncFromDisk(String tabId) async {
    final idx = state.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;
    final path = state[idx].path;
    final result = await readTextFilePreview(path);
    final mtime = _fileMtime(path) ?? DateTime.now();
    final current = state[idx];
    if (current.content == result.content) {
      state = [...state]
        ..[idx] = current.copyWith(lastLoadedAt: mtime, dirty: false);
      return;
    }
    state = [...state]
      ..[idx] = current.copyWith(
        content: result.content,
        lastLoadedAt: mtime,
        dirty: false,
        truncated: result.truncated,
        readOnly: current.readOnly || result.truncated || result.error != null,
        loadError: result.error,
        clearLoadError: result.error == null,
      );
  }

  /// Mark the tab as read-only with empty content when the underlying
  /// file has been removed externally.
  void markDeleted(String tabId) {
    final idx = state.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;
    final tab = state[idx];
    state = [...state]
      ..[idx] = tab.copyWith(
        content: '',
        readOnly: true,
        loadError: 'File was deleted externally',
        clearLastLoadedAt: true,
      );
  }

  /// Push the lastLoadedAt up to the current disk mtime so that the
  /// ticker stops reporting the same conflict on the next poll.
  /// Called when the user chooses "Keep local changes" in the prompt.
  void keepLocalAndAckConflict(String tabId) {
    final idx = state.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;
    final tab = state[idx];
    final mtime = _fileMtime(tab.path) ?? DateTime.now();
    state = [...state]..[idx] = tab.copyWith(lastLoadedAt: mtime);
  }

  /// Unified entry point for closing the conflict banner:
  /// advances lastLoadedAt and removes the tab from the global conflict set.
  void markConflictHandled(String tabId) {
    keepLocalAndAckConflict(tabId);
    _removeFromConflicts(tabId);
  }

  void _removeFromConflicts(String tabId) {
    final notifier = _ref.read(fileConflictsProvider.notifier);
    if (notifier.state.contains(tabId)) {
      notifier.state = {...notifier.state}..remove(tabId);
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

// Providers -----------------------------------------------------------------

final editorTabsProvider =
    StateNotifierProvider<EditorTabsNotifier, List<EditorTab>>((ref) {
  return EditorTabsNotifier(ref);
});

final activeTabProvider = Provider<EditorTab?>((ref) {
  final tabs = ref.watch(editorTabsProvider);
  final id = ref.read(editorTabsProvider.notifier).activeId;
  if (id == null) return null;
  return tabs.where((t) => t.id == id).firstOrNull;
});

/// UI-visible conflict set: tabs whose in-memory content is dirty while
/// the underlying file on disk has been modified by something else.
final fileConflictsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

// File sync polling ---------------------------------------------------------

/// Polls every 2s for external file changes and reconciles them with tabs:
///   - non-dirty tab + mtime changed -> silent reload;
///   - dirty tab + mtime changed      -> register as a conflict for UI.
final fileSyncTickerProvider = Provider<FileSyncTicker>((ref) {
  return FileSyncTicker(ref);
});

class FileSyncTicker {
  FileSyncTicker(this.ref);
  final Ref ref;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _poll();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _poll() {
    final tabs = ref.read(editorTabsProvider);
    final notifier = ref.read(editorTabsProvider.notifier);
    final cnotifier = ref.read(fileConflictsProvider.notifier);

    for (final tab in tabs) {
      if (tab.loading || tab.truncated || tab.readOnly) continue;

      try {
        final file = File(tab.path);
        if (!file.existsSync()) {
          notifier.markDeleted(tab.id);
          if (cnotifier.state.contains(tab.id)) {
            cnotifier.state = {...cnotifier.state}..remove(tab.id);
          }
          continue;
        }

        final mtime = file.lastModifiedSync();
        final lastLoaded = tab.lastLoadedAt;
        if (lastLoaded != null && !mtime.isAfter(lastLoaded)) continue;

        if (tab.dirty) {
          if (!cnotifier.state.contains(tab.id)) {
            cnotifier.state = {...cnotifier.state, tab.id};
          }
        } else {
          notifier.syncFromDisk(tab.id);
          if (cnotifier.state.contains(tab.id)) {
            cnotifier.state = {...cnotifier.state}..remove(tab.id);
          }
        }
      } on FileSystemException {
        // skip
      }
    }
  }
}

// Helpers -------------------------------------------------------------------

String _basename(String path) {
  var p = path.replaceAll('\\', '/');
  while (p.endsWith('/') && p.length > 1) {
    p = p.substring(0, p.length - 1);
  }
  final idx = p.lastIndexOf('/');
  return idx == -1 ? p : p.substring(idx + 1);
}
