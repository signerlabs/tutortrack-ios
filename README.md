# TutorTrack

> 课外培训机构学员管理 App。**2026-05-13 ShipSwift 视频录屏素材源**——展示「AI 一句话拼出 17 个生产级 SwiftUI 组件 + AI 自动写人话周报 PDF 的真 App」。

需求文档见 [PRD.md](PRD.md)。

---

## 工程信息

| 项 | 值 |
|---|---|
| Bundle ID | `com.signerlabs.TutorTrack` |
| Team ID | `5GS4D3667R` |
| iOS Deployment Target | 26.4 |
| Swift | 5.0（MainActor 默认隔离） |
| Xcode 工程组织 | `PBXFileSystemSynchronizedRootGroup`（新增 .swift 文件**无需改 pbxproj**，自动同步进 build target） |
| 后端 | 无（纯本地 SwiftData mock，无 AWS） |
| 第三方依赖 | 无（零 SPM/CocoaPods） |

---

## 单端架构

老师端单 App，4-Tab 主框架：

```
TutorTrackApp (TutorTrackApp.swift)
└─ ContentView → SWRootTabView 派生 RootTabView
    ├─ 学员    StudentsHomeView   (Features/Students/)
    ├─ 课时    LessonsHomeView    (Features/Lessons/)
    ├─ 出勤    AttendanceHomeView (Features/Attendance/)
    └─ 周报    WeeklyReportHomeView (Features/WeeklyReport/)
```

PRD 明确"老师端 B 端唯一端，家长不需要装 App"，所以不需要角色选择器。

---

## ShipSwift Recipe 引用清单

所有 Recipe 源码原样放在 `TutorTrack/SWPackage/`，文件名前缀统一 `SW`，方便录屏时一眼识别"这部分是 ShipSwift 提供的"。

| Recipe ID | 文件 | 使用位置 |
|---|---|---|
| `component-root-tab-view` | `SWRootTabView.swift` | 4-tab 主框架模板（学员/课时/出勤/周报） |
| `component-kpi-card` | `SWKPICard.swift` | 课时跟踪 Tab：本月总课时 / 待续费学员等汇总卡片 |
| `component-image-thumbnail` | `SWImageThumbnail.swift` | 学员卡头像（SF Symbol fallback） |
| `component-status-badge` | `SWStatusBadge.swift` | 课程类型彩色徽章（钢琴/英语/编程/数学/美术） |
| `component-add-sheet` | `SWAddSheet.swift` | 新增学员 / 录入签到评语的 bottom sheet |
| `component-search-bar` | `SWSearchBar.swift` | 学员列表 / 课时列表搜索栏 |
| `component-stepper` | `SWStepper.swift` | 课时跟踪：续费 +N 节 / 单节调整 |
| `chart-activity-heatmap` | `SWActivityHeatmap.swift` | 出勤日历视图（绿/红/灰 三色） |
| `component-alert` | `SWAlert.swift` | 全局 toast：签到成功 / 续费成功 / PDF 已生成 |
| `component-tab-button` | `SWTabButton.swift` | 签到状态切换 chip（出勤 / 缺勤 / 请假） |
| `component-bullet-point-text` | `SWBulletPointText.swift` | 签到历史评语列表，按课程色显示色条 |
| `component-markdown-text` | `SWMarkdownText.swift` | AI 周报段落渲染（LLM 风格） |
| `component-thinking-indicator` | `SWThinkingIndicator.swift` | "AI 思考中" 三点动画（生成周报时） |
| `component-loading` | `SWLoading.swift` | 整页生成中遮罩（按枚举页注册） |
| `component-gradient-divider` | `SWGradientDivider.swift` | PDF 内排版课程色细线 |
| `animation-shimmer` | `SWShimmer.swift` | "生成周报"按钮 shimmer 高光（CTA 强引导） |
| **本地实现** | `SWExportShare.swift` | SwiftUI View → PDF → ShareSheet（Pro Recipe `export-share` 未解锁，原生 `ImageRenderer` + `PDFKit` 等效实现） |

**组件 ID 全链路一致**：拉 Recipe 用 `mcp__shipswift__getRecipe` + ID。视频里可现场展示「`mcp__shipswift__getRecipe id=chart-activity-heatmap` → 复制源码 → 用上」的完整流程。

---

## 视觉系统

### 课程色板（`Assets.xcassets/Colors/`）

| Color Set | 用途 | 浅色 hex | 深色 hex |
|---|---|---|---|
| `CoursePink` 钢琴粉 | 钢琴课程 / 进度条 / PDF 标识线 | `#F5A2C8` | `#C26B95` |
| `CourseBlue` 英语蓝 | 英语课程 | `#5BA8E5` | `#3978B0` |
| `CoursePurple` 编程紫 | 编程课程 | `#9B7EE0` | `#6F4FB3` |
| `CourseOrange` 数学橙 | 数学课程 | `#F2A057` | `#C0742F` |
| `CourseGreen` 美术绿 | 美术课程 | `#7BC474` | `#4F9648` |
| `WarmIvory` 米白底 | 整体背景 | `#FAF6EE` | `#1F1E1A` |

### 头像方案

学员头像不嵌图片，统一用 **SF Symbol**（`person.fill` / `music.note` / `book.fill` / `function` / `paintbrush.fill` / `chevron.left.forwardslash.chevron.right`）+ 课程色背景，省去图床且演示稳定。

---

## 录屏指引

### 建议演示顺序

1. **学员 Tab**（5 张学员卡 × 5 种课程色，第一眼"哎这是真 App"）
2. **学员详情**（进度条按课程色 tint、剩余 ≤3 节标红、签到历史 SWBulletPointText 列表）
3. **新增学员**（SWAddSheet bottom sheet 弹出 + 课程类型 SWStatusBadge 选择）
4. **课时 Tab**（SWKPICard 汇总 + SWStepper 一键 +10 节续费 + SWAlert toast）
5. **出勤 Tab**（**核心炸场 1**：SWActivityHeatmap 三色热力图 + SWTabButton 切签到状态）
6. **签到 + 评语**（点签到 → SWAddSheet 录评语 → SWAlert success toast）
7. **周报 Tab**（**核心炸场 2**：选学员 → 点 SWShimmer 高亮的「生成周报」按钮 → SWPageLoadingView 1.5 秒 + SWThinkingIndicator 三点动画 → 出 80 字 AI 段落 → SWMarkdownText 渲染 → 点导出 → PDF → ShareSheet 弹起到微信家长群）

### 视频核心炸场点（按价值排序）

1. **AI 周报 PDF**：1.5 秒 thinking → 80 字人话段落 → ShareSheet 发家长群（**杀手画面**）
2. **出勤热力图**：三色 GitHub 风格 grid，过去 2 周一眼可视化
3. **学员卡 5 种课程色**：第一眼信息密度
4. **进度条课程色 tint + 剩余 3 节标红**：业务感

### 录屏前 checklist

- [ ] 在 Xcode `Cmd+Shift+K` 清缓存 + `Cmd+B` 验证编译
- [ ] Simulator 选 iPhone 17 Pro
- [ ] 状态栏时间锁定（`xcrun simctl status_bar ... override --time 9:41`）
- [ ] 第一次启动会自动 seed 5 个 mock 学员（每课程类型一名，每人带过去 2 周随机出勤 + 评语）

---

## 文件结构

```
TutorTrack/
├── TutorTrackApp.swift                # @main + ModelContainer + .swAlert() + MockSeed
├── ContentView.swift                  # 根视图 = RootTabView
├── App/
│   └── RootTabView.swift              # 4-Tab 容器（基于 SWRootTabView 模板）
├── Features/
│   ├── Students/
│   │   ├── StudentsHomeView.swift     # 学员列表 + 搜索 + 新增
│   │   ├── StudentCard.swift          # 单张学员卡
│   │   ├── StudentDetailView.swift    # 学员详情（进度条 + 签到历史）
│   │   └── AddStudentSheet.swift      # 新增学员 sheet
│   ├── Lessons/
│   │   └── LessonsHomeView.swift      # 课时跟踪（KPI 卡 + 续费列表）
│   ├── Attendance/
│   │   ├── AttendanceHomeView.swift   # 出勤总览（热力图 + 今日学员）
│   │   └── CheckInSheet.swift         # 签到 + 录评语 sheet
│   └── WeeklyReport/
│       ├── WeeklyReportHomeView.swift # 周报生成入口（学员选择器 + 生成按钮）
│       ├── WeeklyReportPreviewView.swift # 周报内容预览 + ShareLink
│       ├── WeeklyReportEngine.swift   # mock AI 拼接引擎（deterministic）
│       └── WeeklyReportPDFView.swift  # PDF 渲染 View（喂给 ImageRenderer）
├── Models/
│   ├── Student.swift                  # @Model
│   ├── AttendanceRecord.swift         # @Model
│   ├── CourseType.swift               # enum（5 种课程，附 color / icon / 模板词典）
│   ├── AttendanceStatus.swift         # enum（present / absent / excused）
│   └── MockSeed.swift                 # 5 学员 + 过去 2 周出勤
├── Shared/
│   └── Date+Week.swift                # 本周区间 + 周次计算
├── SWPackage/                         # 17 个 ShipSwift Recipe 原样源码
│   └── SW*.swift
└── Assets.xcassets/
    └── Colors/
        ├── CoursePink.colorset
        ├── CourseBlue.colorset
        ├── CoursePurple.colorset
        ├── CourseOrange.colorset
        ├── CourseGreen.colorset
        └── WarmIvory.colorset
```

---

## 已知陷阱（AI 接手须知）

1. **SourceKit 误报**：批量新增 .swift 文件后，IDE 会持续报「Cannot find X in scope」一段时间。`PBXFileSystemSynchronizedRootGroup` 索引追不上跨文件类型解析的已知问题——**真编译会过**，不要因此乱改代码
2. **每个用 SwiftData API 的文件必须 `import SwiftData`**（BobaLoyalty 早期漏过 3 处导致主公手动报编译错才发现）
3. **不要跑 `xcodebuild`**——主公在 Xcode/Simulator 里测试
4. **不要修 pbxproj**——`PBXFileSystemSynchronizedRootGroup` 自动同步整个 `TutorTrack/` 目录
5. **不要 git commit/push**——主公自己提交
6. **不要引入第三方依赖**——零 SPM/CocoaPods 是设计目标
7. **AI 周报是纯 mock**——`WeeklyReportEngine` 用 deterministic seed 拼接，不调任何 LLM，主公视频里说"AI 写人话周报"指的是「拼出来像真 AI 写的」的演示效果

---

## 与 ShipSwift 的关系

本 demo 是 ShipSwift Recipe 库的**典型客户场景**：

- 一个老师想做"我自己的"学员管理 App，**不愿被 SaaS 锁住**
- 用 Cursor / Claude Code + ShipSwift MCP，**4 小时拼出 17 个生产级组件 + 一个能演示的真 App**
- 视频脚本目标受众：**培训机构老师**——让他们看完想"卧槽我也能做"
