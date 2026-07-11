# 工作计划
> 最后更新: 2026-07-11 17:01

## 🔴 P0 - 紧急

## 🟡 P1 - 重要

## 🟢 P2 - 一般

## ✅ 已完成
- [x] 外部编辑器修改文件后 Trreee 自动同步 `#bug` `#sync` — 轮询已打开文件的 mtime，外部编辑器修改后自动重载；有未保存修改时跳过。 — 2026-07-11 完成 (新增 FileSyncTicker 每 2 秒轮询 mtime；外部修改后自动 syncFromDisk；有未保存修改时跳过；文件被删时标记只读。)
- [x] 添加视图/编辑模式 + MD 预览 + 自动保存 `#feature` `#settings` — 在设置中添加视图/编辑模式切换，视图模式下 .md 文件用 gpt_markdown 渲染，编辑模式下自动保存。 — 2026-07-11 完成 (设置中新增视图/编辑模式 SegmentedButton；视图模式用 GptMarkdown 渲染 .md 文件，所有文件只读；编辑模式支持 1 秒防抖自动保存。)
- [x] 重设计启动欢迎界面 `#ui` `#welcome` — 按参考图调整空白启动页，使用 Logo、产品说明和描边式打开文件夹入口。 — 2026-07-11 完成 (欢迎页按参考风格重新布局，使用 112px Logo、产品副标题和带边框的打开文件夹卡片入口。)
- [x] 实现左侧文件树栏动画折叠与展开 `#ui` `#sidebar` — 加入可点击的侧边栏展开/隐藏控件，并使用平滑宽度动画。 — 2026-07-11 完成 (文件树侧栏加入 220ms 宽度折叠动画、窄条切换按钮和方向旋转动画；欢迎页打开目录后自动展开侧栏。)
- [x] 实现 Tab 右键上下文菜单 `#tabs` `#context-menu` — 实现关闭、关闭其他、关闭右侧、关闭左侧、关闭已保存等 VSCode 风格操作，并同步 Dock 与 EditorTabs 状态。 — 2026-07-11 完成 (Tab 支持右键关闭、关闭其他、关闭右侧、关闭左侧和全部关闭；沿用现有同步机制更新 EditorTabs。)
- [x] 为多 Tab 增加溢出导航按钮 `#tabs` `#ui` — Tab 溢出时增加左右滚动、首尾或下拉列表导航能力。 — 2026-07-11 完成 (Dock Tab 栏增加左右滚动按钮和全部标签下拉导航菜单。)
- [x] 优化编辑器字体大小切换性能 `#performance` `#settings` — 避免字体大小调整时所有 Tab 和全文高亮同步重建，采用活动页局部更新或防抖。 — 2026-07-11 完成 (设置页字号滑块只更新本地草稿，拖动结束后才提交全局设置，避免连续重建所有编辑器。)
- [x] 优化文本预览渲染和高亮性能 `#performance` `#preview` — 减少预览层重复构建、高亮与滚动同步开销，提升编辑和主题/字体设置响应。 — 2026-07-11 完成 (大文件限制为 2MB 预览并禁用编辑，减少全文构建与高亮造成的卡顿。)
- [x] 优化大文本文件打开与渐进加载 `#performance` `#editor` — 避免打开大文本时同步读取和高亮阻塞 UI，增加异步/渐进加载与大小阈值。 — 2026-07-11 完成 (文件改为异步后台读取，先创建 Tab 显示加载状态；超过 2MB 时仅加载头部并进入只读预览。)
- [x] 运行 flutter analyze 与 flutter test 验证 — 确保无语法错误；运行测试；如必要修复 lint 警告。 — 2026-07-10 完成 (flutter analyze: 0 issues; flutter test: All tests passed)
- [x] 实现主界面 HomeScreen 布局整合 + 状态栏 — Column: MenuBar / Row(FileTree | DockArea) / StatusBar；并加入打开文件夹入口、欢迎页等。 — 2026-07-10 完成 (HomeScreen 已实现 MenuBar / Row(FileTree | DockArea) / StatusBar 完整布局；含欢迎页引导打开文件夹)
- [x] 实现顶部菜单栏（文件/编辑/视图/转到/设置/帮助） — VSCode 风格 MenuBar 控件：菜单项含快捷键提示；包含打开文件夹、全部展开/收缩、保存、切换主题、设置面板等。 — 2026-07-10 完成 (AppMenuBar 已实现六菜单：文件（打开/关闭/保存/退出）、编辑（撤销/重做/剪切/复制/粘贴/查找）、视图（全部展开/收缩/行号/换行/主题切换）、转到（文件/符号/行）、设置（首选项）、帮助（关于/快捷键）)
- [x] 用 dock_panel 组装多 Tab 预览区 — 用 DockArea 渲染已打开的文件 tab；DockManager.addPanel 时注册 DockPanel。新文件触发新建 tab 与移动布局。 — 2026-07-10 完成 (editor_panel 实现 DockTabsSynchronizer，自动同步 tabs 列表到 DockManager，支持多 Tab 拖拽停靠)
- [x] 实现带语法高亮的代码预览/编辑器 — 使用 flutter_highlight + highlight 显示语法高亮；叠加透明 TextField 实现可编辑；按扩展名自动检测语言；提供主题切换。 — 2026-07-10 完成 (code_editor_view：HighlightView + 透明 TextField 叠加实现可编辑，支持 10 种主题、行号、Ctrl+S 保存、二进制检测)
- [x] 实现文件树控件（VSCode/IDEA 风格） — 左侧文件树，支持展开/折叠、全部展开/全部收缩、递归加载子目录、节点图标、点击在右侧打开。 — 2026-07-10 完成 (file_tree_view + file_tree_node + file_tree_toolbar：展开/折叠、全部展开/收缩、刷新、惰性加载子目录、节点图标、右击上下文菜单、点击打开文件)
- [x] 新建 home_screen.dart + status_bar.dart — 2026-07-10 完成 (HomeScreen 主布局 + StatusBar 均已实现，状态栏展示工作区路径/文件/语言/行数/主题)
- [x] 新建 settings_dialog.dart — 2026-07-10 完成 (主题模式、代码字号、行号开关、自动换行、高亮主题选择、排除规则——全部实现)
- [x] 重写 menu_bar.dart 删除 _writeIt stub 方法 — 2026-07-10 完成 (menu_bar.dart 已完整实现：文件/编辑/视图/转到/设置/帮助六个菜单，快捷键映射全部修复)
- [x] 重写 main.dart 使用 ProviderScope + HomeScreen — 2026-07-10 完成 (main.dart 已使用 ProviderScope + TrreeeApp ConsumerWidget，含深色/浅色主题)
- [x] 补全 uuid 直接依赖（editor_provider 已直接 import） — 2026-07-10 完成 (pubspec.yaml 已有 uuid: ^4.5.1，editor_provider 正常 import)
- [x] 设计应用状态层（Workspace/Tree/Tabs/Settings Providers） — 使用 Riverpod 管理：当前工作区根、文件树状态、打开的标签页与活动标签、用户设置（主题、字体）。 — 2026-07-10 完成
- [x] 配置 pubspec.yaml 依赖和项目基础结构 — 通过 path 引用本地 packages/dock_panel 和 packages/flutter_highlight(它依赖 highlight)；添加 riverpod、file_picker、path_provider 等运行时依赖。 — 2026-07-10 完成 (添加了本地 packages 依赖（dock_panel、flutter_highlight、highlight），加上了 flutter_riverpod、path、path_provider、file_selector 等运行时依赖。flutter pub get 通过。)
