import 'package:flutter_highlight/themes/atom_one_dark.dart';
import 'package:flutter_highlight/themes/atom_one_light.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/github_dark.dart';
import 'package:flutter_highlight/themes/monokai.dart';
import 'package:flutter_highlight/themes/night_owl.dart';
import 'package:flutter_highlight/themes/nord.dart';
import 'package:flutter_highlight/themes/tomorrow_night_blue.dart';
import 'package:flutter_highlight/themes/tomorrow_night_bright.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/highlight_core.dart' show Highlight, HljsTheme;
import 'package:highlight/languages/_all.dart' as langs;

/// 全局共享的 Highlight 实例，首次访问时注册全部 ~180 种语言。
Highlight? _highlightInstance;
Highlight get sharedHighlight {
  if (_highlightInstance != null) return _highlightInstance!;
  final hl = Highlight();
  langs.registerAllLanguages(hl);
  _highlightInstance = hl;
  return hl;
}

/// 内置主题集合。
class HighlightThemes {
  HighlightThemes._();

  static const List<({String id, String label})> available = [
    (id: 'atom-one-dark', label: 'Atom One Dark'),
    (id: 'atom-one-light', label: 'Atom One Light'),
    (id: 'github', label: 'GitHub Light'),
    (id: 'github-dark', label: 'GitHub Dark'),
    (id: 'monokai', label: 'Monokai'),
    (id: 'vs2015', label: 'Visual Studio Dark'),
    (id: 'night-owl', label: 'Night Owl'),
    (id: 'tomorrow-night-blue', label: 'Tomorrow Night Blue'),
    (id: 'tomorrow-night-bright', label: 'Tomorrow Night Bright'),
    (id: 'nord', label: 'Nord'),
  ];

  static HljsTheme byId(String id) {
    switch (id) {
      case 'atom-one-light':
        return atomOneLightTheme;
      case 'github':
        return githubTheme;
      case 'github-dark':
        return githubDarkTheme;
      case 'monokai':
        return monokaiTheme;
      case 'vs2015':
        return vs2015Theme;
      case 'night-owl':
        return nightOwlTheme;
      case 'tomorrow-night-blue':
        return tomorrowNightBlueTheme;
      case 'tomorrow-night-bright':
        return tomorrowNightBrightTheme;
      case 'nord':
        return nordTheme;
      case 'atom-one-dark':
      default:
        return atomOneDarkTheme;
    }
  }
}
