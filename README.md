<div align="center">

### ⭐ Built with [**ShipSwift**](https://github.com/signerlabs/ShipSwift) — the open-source Swift recipe library for vibe-coding iOS apps

**If this demo is useful to you, please [give ShipSwift a ⭐ on GitHub](https://github.com/signerlabs/ShipSwift).**
*Stars on the main repo are what keep this whole library moving.*

[![Star ShipSwift on GitHub](https://img.shields.io/github/stars/signerlabs/ShipSwift?style=for-the-badge&logo=github&label=Star%20ShipSwift&color=FFD700)](https://github.com/signerlabs/ShipSwift)

</div>

---

# TutorTrack

> A student tracker for tutors / coaches running their own training business — vibe-coded in a few hours with [ShipSwift](https://github.com/signerlabs/ShipSwift).
> Source material for the ShipSwift video walkthrough released on 2026-05-13.

Single iOS app for trainers/coaches. 4 modules — student roster, lesson tracking, attendance check-in, **AI-generated learner weekly report PDF** (the killer demo screen). 17 production-grade SwiftUI components pulled directly from ShipSwift recipes. Zero third-party dependencies, local SwiftData only — clone & run.

The five built-in course themes are tailored for the vibe coding audience: Overseas Marketing / GPU Rig Setup / Claude Code / AI Growth / SwiftUI Advanced.

---

## Project Info

| Field | Value |
|---|---|
| Bundle ID | `com.signerlabs.TutorTrack` |
| Team ID | `5GS4D3667R` |
| iOS Deployment Target | 26.4 |
| Swift | 5.0 (MainActor isolation by default) |
| Xcode project layout | `PBXFileSystemSynchronizedRootGroup` — new `.swift` files auto-sync into the build target |
| Backend | None (pure local SwiftData mock, no AWS) |
| Third-party deps | None (zero SPM / CocoaPods) |

---

## Single-Side Architecture

Trainer-side only. 4-tab main frame:

```
TutorTrackApp (TutorTrackApp.swift)
└─ ContentView → RootTabView (derived from SWRootTabView)
    ├─ Students   StudentsHomeView      (Features/Students/)
    ├─ Lessons    LessonsHomeView       (Features/Lessons/)
    ├─ Attendance AttendanceHomeView    (Features/Attendance/)
    └─ Report     WeeklyReportHomeView  (Features/WeeklyReport/)
```

The original PRD scopes this to a one-sided trainer B-side app — learners don't need their own app, the trainer just exports the weekly report PDF and sends it via DM / group chat.

---

## ShipSwift Recipes Used (17)

All recipe source code lives in `TutorTrack/SWPackage/` with the `SW` filename prefix.

| Recipe ID | File | Used For |
|---|---|---|
| `component-root-tab-view` | `SWRootTabView.swift` | 4-tab main frame (Students / Lessons / Attendance / Report) |
| `component-kpi-card` | `SWKPICard.swift` | Lessons tab — monthly totals / students near renewal etc. |
| `component-image-thumbnail` | `SWImageThumbnail.swift` | Student card avatar (SF Symbol fallback) |
| `component-status-badge` | `SWStatusBadge.swift` | Course type colored badge (one of five themes) |
| `component-add-sheet` | `SWAddSheet.swift` | Add student / log session note bottom sheet |
| `component-search-bar` | `SWSearchBar.swift` | Student list / lesson list search |
| `component-stepper` | `SWStepper.swift` | Lesson tracking — renew +N sessions / adjust |
| `chart-activity-heatmap` | `SWActivityHeatmap.swift` | Attendance calendar (green / red / gray three-color heatmap) |
| `component-alert` | `SWAlert.swift` | Global toast — check-in OK / renew OK / PDF generated |
| `component-tab-button` | `SWTabButton.swift` | Check-in status chips (present / absent / excused) |
| `component-bullet-point-text` | `SWBulletPointText.swift` | Check-in note list, color-tinted by course |
| `component-markdown-text` | `SWMarkdownText.swift` | Render the AI report paragraph (LLM-style output) |
| `component-thinking-indicator` | `SWThinkingIndicator.swift` | Three-dot animation while "AI is generating" |
| `component-loading` | `SWLoading.swift` | Full-page generating overlay, registered per page enum |
| `component-gradient-divider` | `SWGradientDivider.swift` | PDF layout — course-tinted thin separator |
| `animation-shimmer` | `SWShimmer.swift` | Shimmer highlight on the "Generate Report" CTA button |
| **local impl** | `SWExportShare.swift` | SwiftUI View → PDF → ShareSheet (Pro recipe `export-share` unlocked separately; here we use a `ImageRenderer` + `PDFKit` equivalent built locally) |

**Consistent recipe IDs across the stack**: pull a recipe via `mcp__shipswift__getRecipe` + ID. The video shows the `getRecipe id=chart-activity-heatmap → copy source → use it` flow live.

---

## Visual System

### Course Color Palette (`Assets.xcassets/Colors/`)

| Color Set | Course | Light hex | Dark hex |
|---|---|---|---|
| `CoursePink` | Overseas Marketing | `#F5A2C8` | `#C26B95` |
| `CourseBlue` | GPU Rig Setup | `#5BA8E5` | `#3978B0` |
| `CoursePurple` | Claude Code | `#9B7EE0` | `#6F4FB3` |
| `CourseOrange` | AI Growth | `#F2A057` | `#C0742F` |
| `CourseGreen` | SwiftUI Advanced | `#7BC474` | `#4F9648` |
| `WarmIvory` | App background | `#FAF6EE` | `#1F1E1A` |

### Avatar Strategy

Student avatars use **SF Symbols** (`globe.americas.fill` / `cpu.fill` / `terminal.fill` / `chart.line.uptrend.xyaxis` / `swift` etc.) plus a course-colored background — no image hosting required, demo stays stable.

---

## AI Weekly Report

This is the killer demo screen — the user picks a student and a week, taps "Generate", sees a 1.5s "AI thinking" animation, then gets an ~80-character natural-language paragraph rendered as Markdown, plus a one-click PDF export to the system share sheet.

**Implementation**: the "AI" is a fully local deterministic LCG-seeded template composer in `WeeklyReportEngine.swift` — it pulls keywords from `CourseType.practiceKeywords` and `CourseType.evaluationKeywords`, mixes them with the actual attendance records, and produces a paragraph that reads like a real LLM wrote it.

**Why local mock instead of a real LLM**:
- Zero network for demo recording — no flaky API calls during video capture
- No API keys to embed
- Deterministic output: the same student + same week always produces the same paragraph, so you can re-record the same scene
- The visual loading animation (`SWThinkingIndicator` + `SWPageLoadingView` for 1.5s) sells the "AI is thinking" impression on camera

---

## Getting Started

```bash
git clone https://github.com/signerlabs/tutortrack-ios.git
cd tutortrack-ios
open TutorTrack.xcodeproj
```

In Xcode:

1. Select iPhone 17 Pro Simulator (or any iOS 26.4+ device)
2. `Cmd+R` to run
3. First launch auto-seeds 5 mock students (one per course type) with 2 weeks of randomized attendance + session notes — so any student you pick has data to demo the weekly report against

No API keys required. No accounts. Pure local SwiftData mock.

---

## Video Demo Order

1. **Students tab** (5 student cards × 5 course colors — instant "this looks like a real app" effect)
2. **Student detail** (course-tinted progress bar, "renew" red badge when ≤3 sessions left, session-note bullet list)
3. **Add student** (`SWAddSheet` bottom sheet + course-type `SWStatusBadge` picker)
4. **Lessons tab** (`SWKPICard` summary + `SWStepper` one-tap +10 renew + `SWAlert` toast)
5. **Attendance tab** (**core wow-moment #1**: `SWActivityHeatmap` three-color heatmap + `SWTabButton` status switch)
6. **Check-in + note** (tap check-in → `SWAddSheet` note input → success toast)
7. **Report tab** (**core wow-moment #2**: pick student → tap shimmering "Generate" button → 1.5s `SWPageLoadingView` + `SWThinkingIndicator` → ~80-char AI paragraph → `SWMarkdownText` render → tap export → PDF → ShareSheet pops to system share)

---

## File Structure

```
TutorTrack/
├── TutorTrackApp.swift                # @main + ModelContainer + .swAlert() + MockSeed
├── ContentView.swift                  # Root = RootTabView
├── App/
│   └── RootTabView.swift              # 4-tab container (based on SWRootTabView)
├── Features/
│   ├── Students/
│   │   ├── StudentsHomeView.swift     # Student list + search + add
│   │   ├── StudentCard.swift          # Single student card
│   │   ├── StudentDetailView.swift    # Student detail (progress + history)
│   │   └── AddStudentSheet.swift      # Add student sheet
│   ├── Lessons/
│   │   └── LessonsHomeView.swift      # Lesson tracking (KPI cards + renewal list)
│   ├── Attendance/
│   │   ├── AttendanceHomeView.swift   # Attendance overview (heatmap + today's students)
│   │   └── CheckInSheet.swift         # Check-in + note sheet
│   └── WeeklyReport/
│       ├── WeeklyReportHomeView.swift # Report entry (student picker + generate)
│       ├── WeeklyReportPreviewView.swift # Report content preview + ShareLink
│       ├── WeeklyReportEngine.swift   # Local deterministic mock-AI engine
│       └── WeeklyReportPDFView.swift  # PDF rendering view (fed to ImageRenderer)
├── Models/
│   ├── Student.swift                  # @Model
│   ├── AttendanceRecord.swift         # @Model
│   ├── CourseType.swift               # enum (5 courses + color / icon / template dict)
│   ├── AttendanceStatus.swift         # enum (present / absent / excused)
│   └── MockSeed.swift                 # 5 students + 2 weeks of attendance
├── Shared/
│   └── Date+Week.swift                # Current-week range + week index
├── SWPackage/                         # 17 ShipSwift recipes, verbatim
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

## Engineering Constraints

- **No `xcodebuild`** — build via Xcode / Simulator
- **No `pbxproj` edits** — `PBXFileSystemSynchronizedRootGroup` auto-syncs the entire `TutorTrack/` directory
- **No third-party dependencies** — zero SPM / CocoaPods is a design goal
- **Every file using SwiftData APIs must `import SwiftData`** — easy to forget, breaks the build
- **Every file using `.modelContainer(for:inMemory:)` modifier needs `import SwiftData`** — SwiftUI does NOT re-export this modifier
- **SourceKit "Cannot find X in scope" warnings are often false positives** after bulk file additions — real compilation passes
- **AI weekly report is a pure local mock** — `WeeklyReportEngine` uses a deterministic LCG seed to compose a template-based paragraph. The "AI" in the demo refers to the fact that *the output reads like an AI wrote it*, not that an LLM was called.

---

## Built with Claude Code + ShipSwift

This entire app was vibe-coded in a few hours using [Claude Code](https://claude.com/claude-code) + ShipSwift recipes. The 17 recipes were pulled in verbatim via the ShipSwift MCP server, and the surrounding business logic was generated through natural-language collaboration with the model.

- ShipSwift main repo: [signerlabs/ShipSwift](https://github.com/signerlabs/ShipSwift)
- Try a recipe yourself: `mcp__shipswift__searchRecipes` or browse the recipe gallery

---

## License

MIT — see [LICENSE](LICENSE).
