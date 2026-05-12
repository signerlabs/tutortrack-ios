# CLAUDE.md

Student tracker for solo tutors / coaches, source material for the [ShipSwift](https://github.com/signerlabs/ShipSwift) video walkthrough released on 2026-05-13.

## Read First

- [PRD.md](PRD.md) — Scope and requirements (4 core modules, AI weekly report PDF as the killer demo screen)
- [README.md](README.md) — Project info, ShipSwift recipe inventory (17 recipes), file layout, demo recording notes, known pitfalls

## Engineering Constraints

- **No `xcodebuild`** — build via Xcode / Simulator
- **No `pbxproj` edits** — `PBXFileSystemSynchronizedRootGroup` auto-syncs every `.swift` file under `TutorTrack/`
- **No third-party dependencies** — zero SPM / CocoaPods is a design goal
- **Every file using SwiftData APIs must `import SwiftData`** at the top — easy to miss, breaks the build
- **Every file using `.modelContainer(for:inMemory:)` modifier needs `import SwiftData`** — SwiftUI does NOT re-export this modifier
- **SourceKit "Cannot find X in scope" warnings are often false positives** after bulk file additions — real compilation passes
- **iOS 26.4 / Swift 5 / MainActor isolation by default**

## ShipSwift Recipe Integration

Pull recipes via `mcp__shipswift__getRecipe id=<recipe-id>` and drop the source verbatim into `SWPackage/SW*.swift`. File names map 1:1 to recipe IDs. 17 recipes are integrated — see the [README](README.md#shipswift-recipes-used-17) for the full table.

## AI Weekly Report

**Pure local mock composer** — no LLM calls:

- The video records on-device, so the demo cannot depend on flaky network or API keys
- Implementation: `Features/WeeklyReport/WeeklyReportEngine.swift` consumes `Student` + this week's `AttendanceRecord` set, draws from `CourseType.practiceKeywords` and `evaluationKeywords`, and composes a ~80-character Markdown-style paragraph
- **Deterministic**: same student + same week always produces the same paragraph (seeded LCG using `Student.id` + ISO week index)
- **On-screen feel**: a 1.5s `SWThinkingIndicator` + `SWPageLoadingView` sells the "AI is thinking" impression before the composed paragraph appears

## PDF Export

**SwiftUI `ImageRenderer` + `PDFKit`** (the Pro recipe `export-share` is licensed separately; this project uses a local minimal equivalent in `SWPackage/SWExportShare.swift`):

- SwiftUI View → PDF Data → temp file URL → system share sheet
- Zero dependencies, zero network
