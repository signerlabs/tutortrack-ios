# TutorTrack — Minimal PRD

> Student tracker for tutors / coaches running their own training business. Source material for the ShipSwift video walkthrough released on 2026-05-13.

## Who It's For

Coaches running their own training (one-on-one or small group) — piano teachers, English tutors, coding instructors, math coaches, art teachers, or in the open-source version: vibe-coding-adjacent skill teachers (overseas marketing, GPU rig setup, Claude Code, AI growth, SwiftUI advanced). A replacement for the off-the-shelf SaaS that's expensive, inflexible, and doesn't actually let the trainer own their student data.

## Single Role

- **Trainer side (B-side, the only side)**: manage student roster + track lessons + check attendance + export learner weekly report PDF
- Learners don't need to install an app — the trainer exports the PDF and shares it via DM / group chat directly

## 4 Core Modules

| # | Module | Functionality |
|---|------|------|
| 1 | Student Roster | Card view. Each card: name / avatar / course type (one of five preset themes, no custom courses) / sessions remaining / contact / notes |
| 2 | Lesson Tracking | Progress bar style. "X / Y sessions completed", remaining live updated; remaining ≤ 3 flags a red renewal reminder |
| 3 | Attendance Check-in | Tap "check in" during class → records date + time + optional session note (≤ 50 chars, feeds the weekly report). Backfill supported. Calendar heatmap: green = present / red = absent / gray = excused |
| 4 | Weekly Report PDF (**killer screen**) | **AI auto-writes a natural-language report**: based on the session notes recorded during check-in + attendance + course type, the engine composes a paragraph like *"Mark practiced vLLM PagedAttention tuning this week, with stable inference benchmarks but cooling solution still pending"* — not template fill-in-the-blank, but assembled prose — then renders to PDF (student name / weekly attendance / topics practiced / generated paragraph). Share via system ShareSheet to DM / group chat in one tap. **The market SaaS can only fill templates — this is the core demo screen** |

## Tech Stack

- **iOS 17+ SwiftUI**
- **Must build on ShipSwift recipes** — maximize component reuse (student card / progress bar / calendar / list / form / PDF rendering all come from existing modules)
- Local data via SwiftData (no AWS for the demo, pure local mock)

## Visual Style

- Primary: clean education-industry palette (warm ivory background + course-type color blocks: pink / blue / purple / orange / green for the five courses)
- Student cards are simple: avatar + name + course-color strip + sessions remaining
- PDF template is restrained (white background + black text + course-color thin separator), appropriate for DM / group-chat sharing

## MVP Scope

**In scope**:
- End-to-end loop: roster + lesson tracking + attendance + AI report PDF
- Complete demoable trainer-side UI
- Progress bar color-tinted by course type (a visual highlight for the video)
- **AI weekly report generation**: deterministic local template composer that assembles the per-session notes + attendance + course type into a coherent paragraph
- PDF auto-rendered + system share sheet (save to camera roll / send to chat)

**Out of scope**:
- Learner-side app (not needed), online scheduling, video instruction, payment splitting
- Multi-trainer collaboration, cross-org sync, production-grade robustness

## Engineering Goal

Source material for the 2026-05-13 video walkthrough — the model runs through a fresh generation pass on Cursor / Claude Code while the final app is demoed live. **The point is "AI can compose this + it looks like a real app + course-coded color blocks + AI-written natural-language report"** — the core demo screen is the PDF report with assembled prose (not template fill-in), so a viewing trainer thinks *"holy shit, I have to build my own"*. Production-grade robustness is not required.
