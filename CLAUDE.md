# CLAUDE.md

课外培训机构学员管理 App，**2026-05-13 ShipSwift 视频录屏素材源**。

## 必读

- [PRD.md](PRD.md) — 需求与范围（4 个核心模块、AI 周报 PDF 核心演示画面）
- [README.md](README.md) — 工程信息、ShipSwift Recipe 引用清单、文件结构、录屏指引、已知陷阱

## 关键约束（不要再问）

- **不跑 `xcodebuild`**——主公在 Xcode/Simulator 测试
- **不改 pbxproj**——`PBXFileSystemSynchronizedRootGroup` 自动同步 `TutorTrack/` 下所有 .swift
- **不 git commit/push**——主公自己提交
- **不引入第三方依赖**——零 SPM 是设计目标
- **每个用 SwiftData API 的文件顶部 `import SwiftData`**——BobaLoyalty 早期漏过 3 处导致编译失败
- **SourceKit「Cannot find X in scope」是误报**——索引追不上，真编译会过
- **iOS 26.4 / Swift 5 / MainActor 默认隔离**

## ShipSwift Recipe 集成方式

通过 `mcp__shipswift__getRecipe id=<recipe-id>` 拉源码，原样放 `SWPackage/SW*.swift`。组件 ID 与 SW 文件名一一对应，便于视频里现场展示「拉 Recipe → 复制 → 用上」全流程。当前已集成 ~17 个组件，详细映射见 [README.md](README.md#shipswift-recipe-引用清单)。

## AI 周报方案

**纯本地 mock 拼接**（不调任何 LLM）：

- 视频录屏看不出真假、零网络风险、不需要嵌 API Key
- 实现：`Features/WeeklyReport/WeeklyReportEngine.swift`，吃 `Student` + 本周 `AttendanceRecord`，按 `CourseType` 模板词典 + 评语关键词 + 出勤天数拼成 ≈80 字段落
- **deterministic**：同一学员同一周生成的段落完全一致（用 `Student.id` + 周次做 seed）
- **录屏感官**：生成前用 `SWThinkingIndicator` + `SWPageLoadingView` 停 1.5 秒制造 AI 感

## PDF 导出方案

**SwiftUI 原生 `ImageRenderer` + `PDFKit`**（Pro Recipe `export-share` 未解锁，本地最简实现等效）：

- 文件：`SWPackage/SWExportShare.swift`
- 支持 SwiftUI View → PDF Data → 临时文件 URL → ShareSheet 一键分享
- 零依赖、零网络
