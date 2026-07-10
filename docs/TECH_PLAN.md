# Sola Player — 技术方案 Plan（v1）

> 配套 `docs/DESIGN_SPEC.md`。本文件只给**技术方案与实施计划**，暂不写业务代码。
> 目标：iOS 原生 App，功能 = 播放 / 导入 / 分组 / 波形滑动组件 / 时刻标记。

---

## 1. 技术栈与目标
| 项 | 选择 | 理由 |
|---|---|---|
| 最低系统 | **iOS 17+** | 用 `@Observable`、`.sensoryFeedback`、SwiftData、`Charts/Canvas` 新特性 |
| UI | **SwiftUI**（纯声明式） | 贴合渐变/波形/手势/触感，迭代快 |
| 状态 | **Observation（`@Observable`）** + 轻量 MV | 不引入重型 MVVM/第三方 |
| 音频 | **AVFoundation**（`AVAudioPlayer` 起步，必要时 `AVPlayer`/`AVAudioEngine`） | 播放、精确 seek、变速、后台 |
| 波形采样 | **AVAssetReader**（读 PCM → 分桶 peak/RMS） | 生成竖条高度数据 |
| 持久化 | **SwiftData**（首选）/ 备选 actor+JSON | 音频/分组/标记建模，查询方便 |
| 并发 | **Swift 6 Approachable Concurrency**（主 actor 默认，`@concurrent` 后台） | 采样/IO 不卡 UI |
| 依赖 | **零第三方**（v1） | 降低风险；如需再引 |
| 语言/工具 | Swift 5.10+/6，Xcode 16，SwiftFormat/SwiftLint（可选） | |

---

## 2. 架构分层
采用 **MV + Service**（View ↔ Observable Store ↔ Service ↔ 持久化/系统框架）：

```
┌── Views (SwiftUI) ────────────────────────────────┐
│  LibraryView · PlayerView · Sheets · Components    │
└───────────────▲───────────────────────────────────┘
                │ 绑定 @Observable
┌── Stores (@Observable, @MainActor) ───────────────┐
│  LibraryStore · PlayerStore(播放态) · MarkerStore  │
└───────────────▲───────────────────────────────────┘
                │ async 调用（协议注入）
┌── Services (protocol + 实现) ─────────────────────┐
│  AudioEngine · WaveformService · ImportService     │
│  PersistenceService · HapticService                │
└───────────────▲───────────────────────────────────┘
                │
┌── Frameworks / Storage ───────────────────────────┐
│  AVFoundation · SwiftData · FileManager(App容器)   │
└────────────────────────────────────────────────────┘
```

**关键点**
- Service 全部**面向协议**（`protocol AudioEngine {…}`），便于单测 mock（参考 `swift-protocol-di-testing`）。
- 波形提取等重活用 **actor** 承载缓存与串行化（参考 `swift-actor-persistence`）。
- Store 在 `@MainActor`，只持 UI 状态；跨线程结果 `await` 回主。

---

## 3. 模块清单与职责
1. **AudioEngine**：`load(item)` / `play` / `pause` / `seek(to:)` / `rate` / `currentTime` 发布；配置 `AVAudioSession(.playback)`、后台播放、（可选）`MPNowPlayingInfoCenter` + 远程控制。
2. **WaveformService**（actor）：`samples(for: AudioItem) async -> [Float]`；用 `AVAssetReader` 读 PCM → 分桶（目标 60–120 桶）算 peak+RMS → 归一化 → **落盘缓存**（`waveformCacheURL`），命中直接返回；参考 `content-hash-cache-pattern`（按文件内容哈希键，路径无关、自动失效）。
3. **ImportService**：`fileImporter` / 分享扩展 / URL；获取 **security-scoped bookmark**，把文件拷入 App 容器（`Application Support/Audio/`），产出 `AudioItem`；录音 v2 用 `AVAudioRecorder`。
4. **PersistenceService**：SwiftData `ModelContainer` 封装；CRUD 音频/分组/标记；筛选（分组、搜索）。
5. **MarkerStore / LibraryStore / PlayerStore**：见 §5。
6. **HapticService**：封装 `UIImpactFeedbackGenerator`（light/soft/medium）+ 频率保护 + `prepare()`；`.sensoryFeedback` 优先。

---

## 4. 数据模型（SwiftData 示意）★ 分组=独立播放列表，引用而非移动
```
@Model AudioItem {                 // 永远属于"默认列表(Master)"
  id: UUID
  title: String
  bookmark: Data            // security-scoped bookmark（可靠定位原文件）
  localCopyURL: URL?        // App 容器内副本（可选）
  duration: TimeInterval
  createdAt: Date
  masterOrder: Int          // 默认列表内的顺序（导入序/可自定义）
  memberships: [Membership] // 多对多：所属各分组（cascade delete）
  markers: [Marker]         // cascade delete
  waveformCacheURL: URL?
  paletteKey: String?
}
@Model Group {                     // 命名播放列表
  id: UUID
  name: String
  colorKey: String?
  chipOrder: Int            // 分组之间(chips)的顺序
  createdAt: Date
  memberships: [Membership] // cascade delete（删组只删成员关系，不删音频）
}
@Model Membership {                // 关系表，携带"组内自定义顺序"
  id: UUID
  group: Group
  item: AudioItem
  orderInGroup: Int         // 组内拖拽排序写回此字段
  addedAt: Date
}
@Model Marker { id: UUID; time: TimeInterval; title: String; note: String; createdAt: Date; owner: AudioItem }
```
- **互不干扰**：导入只写 `AudioItem`（进默认列表）；分组操作只增删 `Membership`；删分组 = 删 `Group`+其 `Membership`，`AudioItem` 不动；取消分组 = 删单条 `Membership`。
- **自定义排序**：默认列表用 `masterOrder`；每个分组用各自 `Membership.orderInGroup` → 天然支持每组独立顺序。
- 多归属：一个 `AudioItem` 可有多条 `Membership`（可选加唯一约束改成一曲一组，见设计规范 §8）。
- 波形缓存：紧凑二进制落 `Caches/Waveforms/<hash>.waff`，可重建，不进 iCloud。
- 原始音频：默认拷贝进容器（离线可靠）；大文件可选仅存 bookmark。

---

## 5. 状态管理（Store）
- **LibraryStore**：
  - 作用域：`scope: PlaybackScope = .master | .group(id)`；`items(in: scope)` 返回排序后的曲目（master 按 `masterOrder`；group 按 `orderInGroup`）。
  - 导入：`import()` → 仅进默认列表。
  - 分组：`createGroup / renameGroup / setColor / deleteGroup / reorderGroups(.onMove)`。
  - 成员：`addToGroups(items, groups) / removeFromGroup(item, group)`（=取消分组）。
  - 排序：`reorder(in: scope, from:to:)` → 写回 `masterOrder` 或 `orderInGroup`。
- **PlayerStore**：
  - **队列来源**：`queueScope: PlaybackScope` + `queue: [AudioItem]`（进入播放时由 LibraryStore 按当前作用域**快照生成**）；`currentIndex`；`next/prev` **只在 queue 内循环**。
  - **队列快照固定**：`queue` 是播放开始时的不可变快照，**不订阅**分组/成员的后续变化。分组被删、队列内音频被取消分组 → `queue` 不变，切歌照旧在快照内进行。仅"切换作用域/重新播放某列表"时重建 `queue`。
  - 例外：队列内音频被**彻底删除** → 从 `queue` 移除该曲（正在播则跳快照下一首）；用 SwiftData 删除通知或播放前存在性校验处理。
  - `sourceName: String`（"默认列表"/分组名）→ 播放页顶栏显示（取快照时的名字）。
  - 播放态：`current` / `isPlaying` / `progress` / `isScrubbing` / `samples` / `paletteKey`；桥接 AudioEngine 时间发布（periodicObserver → 主 actor）。scrub 中冻结自走，`onEnded` 提交 seek。
- **MarkerStore**：`markers(for:)` / `addMarker(at:)` / `rename` / `delete` / `export`。

---

## 6. 核心组件实现要点
### 6.1 WaveformScrubber（性能关键）
- 用 **`Canvas`**（或 `Path` + `.drawingGroup()`）绘制竖条，避免 60+ 个 `View` 的开销。
- head/played 用不同填充；旗标与药丸作 overlay；圆柄 knob 作 overlay。
- 手势见设计规范 §5.3；`headIndex` 变化驱动 `.sensoryFeedback`。
- `accessibilityRepresentation { Slider(...) }`。

### 6.2 GradientBackground
- `LinearGradient` + `paletteKey`；换曲/换主题 `.animation(.easeInOut(0.9))`。

### 6.3 TransportControls / GroupChips / TrackRow / ImportCard
- 按设计规范尺寸；微型按钮用透明 `contentShape` 扩大命中区到 44pt。

---

## 7. 系统能力 / 配置
- **Capabilities**：Background Modes → Audio。
- **Info.plist**：支持的音频 UTType（导入用）。
- **AVAudioSession**：`.playback`；处理中断/路由变化（耳机拔出暂停）。
- **v1.x（不在 v1）**：录音(`NSMicrophoneUsageDescription`+`AVAudioRecorder`)、Now Playing/锁屏(`MPRemoteCommandCenter`+`MPNowPlayingInfoCenter`)、Share Extension、iCloud(CloudKit/`ModelConfiguration`)、标记导出、循环/变速/A-B。

---

## 8. 目录结构（提案）
```
SolaPlayer/
├─ App/            (App entry, ModelContainer, Theme)
├─ Models/         (AudioItem, Group, Marker)
├─ Stores/         (LibraryStore, PlayerStore, MarkerStore)
├─ Services/       (AudioEngine, WaveformService, ImportService,
│                   PersistenceService, HapticService  + Protocols/)
├─ Features/
│   ├─ Library/    (LibraryView, TrackRow, GroupChips, ImportCard)
│   ├─ Player/     (PlayerView, WaveformScrubber, TransportControls,
│   │              GradientBackground, TimeCode)
│   └─ Markers/    (MarkerListView, MarkerRow)
├─ DesignSystem/   (Colors/Palette, Typography, Materials, Haptics)
└─ Resources/      (Assets, Localizable)
Tests/             (WaveformTests, MarkerTests, ImportTests, Stores)
```

---

## 9. 里程碑（建议顺序，每步可独立验证）
| 阶段 | 内容 | 产出 / 验收 |
|---|---|---|
| **M0 脚手架** | Xcode 工程、目录、DesignSystem token、诊断页(内置 commit SHA+版本) | 可跑空壳，About 显示构建标识 |
| **M1 导入+音库+分组+持久化** | ImportService + SwiftData(AudioItem/Group/Membership) + LibraryView + 作用域 chips + 新建/编辑/删除分组 + 加入/取消分组 + 组内 `.onMove` 自定义排序 | 导入进默认列表；建分组、加入/取消分组、组内拖拽排序均生效且互不干扰；持久化 |
| **M2 播放+作用域队列+波形滑动** | AudioEngine + PlayerStore(queueScope/queue/next-prev) + PlayerView(顶栏显示当前列表名) + WaveformScrubber（先占位采样） | 选默认列表/分组进入播放，只在该范围切歌；顶栏显示来源名；拖动+震动+方向可用 |
| **M3 波形提取** | WaveformService（AVAssetReader + 缓存） | 真实响度竖条，二次进入秒开 |
| **M4 标记** | MarkerStore + 打点 + 旗标 + 标记列表 Sheet（跳转/命名/删除） | 任意时刻打点、可管理、可跳转 |
| **M5 设置+打磨** | SettingsView(主题配色选择，写 UserDefaults/AppStorage + 单曲 paletteKey 覆盖)、动效、空/错/加载态、可访问性、深浅色 | 可在设置切主题；视觉/交互达设计规范 |
| **M6 后台播放** | AVAudioSession 中断/路由处理、基础后台播放 | 锁屏息屏继续播放，通过真机验证清单 |

> **v1 不做**（列 v1.x backlog）：录音、Now Playing/锁屏控件、标记导出、iCloud、循环/变速/A-B 循环。
> 交付顺序遵循"竖切"：每个 M 都是可运行、可点的增量。

---

## 10. 测试策略
- **单元**：波形分桶/归一化（给定 PCM → 期望桶数与范围）、标记增删/排序、筛选逻辑、时间↔进度换算。
- **协议 mock**：AudioEngine/ImportService/Persistence 注入假实现，Store 逻辑可测（`swift-protocol-di-testing`）。
- **快照/手动**：波形/播放页视觉；真机验证震动与拖动手感（模拟器无 haptic）。
- **真机验证清单**（配合用户规则：手动安装无法自测时）：诊断页显示的 commit 与所发一致；后台播放；拖动震动；标记持久化。

---

## 11. 风险与对策
| 风险 | 对策 |
|---|---|
| 大文件波形提取慢/占内存 | 后台流式读取、分桶下采样、落盘缓存、显示骨架条 |
| 微型 transport 误触/命中难 | 透明扩大命中区 ≥44pt |
| 浅色渐变底白字对比不足 | 文字阴影 + 底部渐隐压暗（设计规范 §2.6）|
| security-scoped 文件失效 | 导入即拷贝进容器为主，bookmark 为辅 |
| 模拟器无 haptic 难验证 | 真机验证 + 视觉脉冲兜底 |
| SwiftData 迁移 | 模型加版本、早期少改结构 |

---

## 12. 开工前确认状态 — 全部闭环 ✅
- ✅ 分组多归属（可多归属）；下一首=队列快照固定（§5）。
- ✅ 主题：用户在设置里选（`@AppStorage` 全局 + 单曲 `paletteKey` 覆盖）。
- ✅ v1 范围：不含 录音 / Now Playing 锁屏 / 标记导出 / iCloud / 循环 / 变速 / A-B。
- ✅ **Transport 布局 = B 精修2（湖水青·内联文字控件）**；定稿原型 `prototype/player.html`。
- ✅ **播放页「分组」按钮**：复用音库的「加入分组」Sheet 组件（`GroupPickerSheet`，多选 add/remove membership，含新建分组），按钮显示所属分组数角标。

> 决策已全部闭环，可进入 **M0 脚手架**。按 §9 逐里程碑实现，每步走特性分支 → PR（遵循仓库 PR 流程）。
