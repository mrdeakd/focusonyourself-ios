---
name: feature-spec
description: >
  Use when starting work on any new feature for the FocusOnYourself app — autonomously
  researches competitor apps, trending ideas, and user pain points to surface 4–6 feature
  opportunities, presents them for the user to select, then writes an exhaustive spec,
  generates Pencil design mockups, and creates all OpenSpec artifacts (proposal, design,
  specs, tasks) without requiring any manual commands. User is only asked questions that
  genuinely require their input.
---

# Feature Specification

**This is a rigid skill. Follow every phase in order. Do not skip phases.**

**User interaction points:** Phase 3 (feature selection + constraints), Phase 6 (Q&A),
Phase 8 (design approval). Everything else runs automatically with no user prompts.

## Overview

1. Read existing app — build exclusion list
2. Dispatch 3 parallel discovery subagents (trends, pain points, design innovations)
3. Present 4–6 feature ideas → **user picks one** + gives constraints
4. Dispatch 3 parallel deep-dive subagents on the chosen feature
5. Read app to determine placement autonomously
6. **User Q&A** — resolve contested decisions (10–18 questions, batched 3–4 at a time)
7. Write exhaustive spec in `specification/`
8. Generate 2–3 Pencil design mockups → **user approves one design**
9. Create all OpenSpec artifacts automatically (proposal → design → specs → tasks)

---

## Phase 1 — App Inventory

Read the existing feature set before researching so you never propose something already built.

Run in parallel:
```bash
find FocusOnYourself/Features -name "*Screen.swift" | sort
find FocusOnYourself/Features -name "*ViewModel.swift" | sort
cat FocusOnYourself/App/Container+App.swift
```

Summarise: current tabs, screens, services, and data models. This becomes the "already built" exclusion list for discovery.

---

## Phase 2 — Parallel Discovery Research

Dispatch **3 subagents in a single message** with no feature topic — they search broadly:

### Discovery Agent A — Trending Features in Wellness Apps

> Search the web for the most impactful new features added to top wellness, mindfulness, mood tracking, and habit apps in 2024–2025. Look at Headspace, Calm, Reflectly, Daylio, Streaks, Fabulous, Balance, Apple Health, Bearable, Moodflow, and any new entrants. For each notable feature: name it, describe what it does from a user perspective, explain why it gained traction, and note which app(s) offer it. Also look at app update notes on App Store and recent Product Hunt launches in the wellness space. Return 8–12 distinct feature ideas with a sentence on why each matters.

### Discovery Agent B — User Pain Points & Feature Requests

> Search Reddit (r/selfimprovement, r/Meditation, r/moodtracking, r/habittracking), App Store reviews of top wellness apps, and any user research forums for the most frequently requested features or voiced frustrations in wellness / mood / mindfulness apps. Also check ProductHunt comments and Twitter/X discussions. Identify the top 8–10 pain points or missing features users talk about, with the most-cited ones ranked first. Quote real user language where possible.

### Discovery Agent C — Emerging Patterns & Design Innovations

> Search for emerging UX and design patterns in mobile wellness apps (2023–2025). Look for articles on UX Collective, Smashing Magazine, Prototypr, and design blogs. Also look at iOS 17/18 features (StandBy, Live Activities, interactive widgets, journaling API, Mental Wellness framework) that wellness apps are starting to leverage. Identify 6–8 patterns or platform capabilities that are innovative and underused, with a sentence on why each is compelling.

**Wait for all 3 agents to return before proceeding.**

---

## Phase 3 — Synthesise & Present Feature Ideas (User Interaction #1)

Cross-reference findings against the Phase 1 exclusion list. Remove anything already built. Then:

1. Identify the top **5–6 distinct feature opportunities** — prioritise ideas appearing in multiple agents' findings or solving high-frequency pain points.
2. For each idea write: **Name**, **one-sentence description**, **why now**, **Complexity** (Low/Med/High), **Impact** (Low/Med/High).

Print the shortlist in a clear numbered format, then ask the user:

```
AskUserQuestion — batch 1 of 2:
  Q1: "Which of these features would you like to spec out?"
      Options: [each idea + "None of these — I have my own idea"]
  Q2: "What are your constraints or non-negotiables?" (scope / PRO vs free / timeline)
```

```
AskUserQuestion — batch 2 of 2:
  Q1: "Any reference apps or design inspiration you have in mind?"
  Q2: "Should this feature be free, PRO-only, or partially gated?"
```

Record all answers. These anchor Phase 4.

---

## Phase 4 — Deep-Dive Research on Selected Feature

Dispatch **3 more subagents in a single message**, focused on the chosen feature:

### Research Agent D — Competitor Implementation Analysis

> Search the web for how wellness, mindfulness, mood tracking, and habit apps implement [selected feature]. Find 5–7 real examples from Headspace, Calm, Reflectly, Daylio, Streaks, Apple Health, Fabulous, Balance, or similar. For each: describe the approach taken, key UX decisions, what works well, and notable gaps. Be concrete — describe exactly what the user sees and does, step by step.

### Research Agent E — UX Patterns & Mobile Best Practices

> Search for iOS UX design patterns and best practices for [selected feature]. Look for recent articles (2023+), Apple HIG guidance, App Store top-performer patterns, and relevant WWDC sessions. Identify 4–6 proven patterns and 2–3 anti-patterns to avoid. Name each pattern and explain specifically why it works for this type of feature.

### Research Agent F — Technical & iOS-Specific Considerations

> Search for iOS/SwiftUI implementation approaches for [selected feature]. Note relevant frameworks, system APIs, or libraries. Flag known complexity, performance considerations, or Apple platform limitations. Check Apple documentation, privacy requirements (HealthKit, notifications, journaling API, etc.), and widget/complication support. Report what is straightforward vs. what needs careful planning.

**Wait for all 3 agents to return before proceeding.**

Synthesise findings into three sections: what similar apps do (D), UX patterns and anti-patterns (E), technical notes (F).

---

## Phase 5 — App Placement Analysis (No User Input)

**Decide placement autonomously — never ask the user where things should live.**

Read each affected screen file to understand current layout structure, existing interactive elements, and file line counts (400-line limit). Then form explicit placement decisions for:
- **Check-in flow changes:** Which file, position, interaction pattern
- **New screen sections:** Which existing screen, where in scroll order
- **Navigation entry point:** Which tab, from which screen

State decisions in 2–3 bullets before Phase 6. Only escalate to Q&A if two equally valid options exist and the choice is a genuine product call (not a UX call).

---

## Phase 6 — Open Questions & User Q&A (User Interaction #2)

From the deep-dive synthesis, identify all contested decisions, edge cases, and unknowns. Generate 10–18 questions covering:

- **UX decisions** the research revealed are handled differently across apps
- **Edge cases** (empty state, error state, first-time user, returning user)
- **Scope boundaries** (what's in vs. out for this version)
- **Free vs. PRO** gating
- **iCloud sync** (cross-device vs. local only)
- **Widget impact** (MoodWidget / StreakWidget changes?)
- **Notifications** (does this feature need local notifications?)
- **Design decisions** (if UI-impacting): layout, data density, navigation pattern
- **Success metric** (what does "working well" look like?)

Ask in batches of 3–4 via `AskUserQuestion`. Wait for answers before the next batch. Record every Q&A pair verbatim.

---

## Phase 7 — Write the Specification

Create `specification/<feature-name-kebab-case>.md` using this exact template:

```markdown
# [Feature Name] Specification

**Status:** Draft  
**Created:** [YYYY-MM-DD]  
**Feature:** [one-sentence description]

---

## Discovery Context

**How this was identified:** [trend / user pain point / platform opportunity — cite source]  
**Complexity estimate:** [Low / Medium / High]  
**Impact estimate:** [Low / Medium / High]

---

## Problem Statement

[What user problem does this solve, in concrete terms?]

---

## Research Findings

### What Similar Apps Do
[5–7 examples from Research Agent D]

### UX Patterns & Best Practices
[4–6 proven patterns from Research Agent E]

### Anti-Patterns to Avoid
[2–3 patterns that fail for this type of feature]

### Technical Considerations
[Key findings from Research Agent F]

---

## User Stories

- As a [user type], I want [action], so that [outcome].
[List 6–12 user stories]

---

## Functional Requirements

### Must Have (launch blocker)
- [ ] requirement

### Should Have (high value, not blocking)
- [ ] requirement

### Could Have (nice-to-have)
- [ ] requirement

### Won't Have (explicitly out of scope this version)
- requirement (reason)

---

## Non-Functional Requirements

| Concern | Requirement |
|---------|-------------|
| Performance | |
| Accessibility | VoiceOver labels, Dynamic Type, 44pt tap targets |
| Offline | |
| iCloud sync | |
| Widget impact | |
| Privacy | |
| Notifications | |

---

## Design Requirements

[Only if UI-impacting. Skip if purely logic/backend.]

**Affected screens:** [list]  
**New screens needed:** [list or "none"]  
**Navigation entry point:** [where user accesses this feature]  
**Key design constraints:**
- `Color.foyBackground` on all new screens
- `Spacing.screenHorizontal` (28pt) horizontal padding
- `CornerRadius.*` tokens, never raw values
- Typography via `.font(.foy*)` tokens

**Animation/transition:** [describe or "standard NavigationStack push"]

---

## Resolved Open Questions

| # | Question | Answer | Decision |
|---|----------|--------|----------|
| 1 | [question] | [answer] | [decision] |
[One row per Q&A pair]

---

## Design Options

[Only if UI-impacting mockups were created in Phase 8.]

| Option | Name | Rationale |
|--------|------|-----------|
| A | [name] | [one sentence] |
| B | [name] | [one sentence] |
| C | [name] | [one sentence] |

**Pencil location:** `FocusOnYourselfDesign.pen` → `🎨 PROTOTYPE: [Feature Name]`  
**Approved option:** ⏳ Pending

---

## Implementation Notes

- Services to create or modify:
- Models to extend:
- Widget sync changes in `WidgetDataProvider.swift`:
- Factory DI registrations in `Container+App.swift`:
- Navigation routes to add:

---

## Acceptance Criteria

- [ ] [concrete, testable — observable behavior, not code detail]
[List 6–12 AC items]

---

## Status

| Phase | Status |
|-------|--------|
| Discovery research | ✅ Complete |
| Feature selected | ✅ [feature name] |
| Deep-dive research | ✅ Complete |
| User Q&A | ✅ Complete |
| Specification | ✅ Draft |
| Design mockups | [⏳ / ✅ 3 options in Pencil / ⏳ Skipped] |
| Design approved | ⏳ Pending |
| OpenSpec change | ⏳ Pending |
| Implementation | ⏳ Not started |
```

After writing the file, print the full path and confirm it exists.

---

## Phase 8 — Pencil Design Mockups + Design Approval (User Interaction #3)

**Skip this entire phase if the feature has no UI impact.**

If UI-impacting, generate mockups automatically (no need to ask — always generate for UI features). Then ask the user which option they approve.

**Step 1 — Open the design file**
```
mcp__pencil__open_document("FocusOnYourselfDesign.pen")
mcp__pencil__get_editor_state()
mcp__pencil__find_empty_space_on_canvas()
```

**Step 2 — Create the Prototype frame group**

Use `mcp__pencil__batch_design()` to create a parent frame named exactly:
```
🎨 PROTOTYPE: [Feature Name]
```

Inside it, create 3 sub-frames at iPhone dimensions (393 × 852):
- `Option A — [Approach Name]`
- `Option B — [Approach Name]`
- `Option C — [Approach Name]`

Space them 60px apart horizontally. Each frame uses design system values (foyBackground, foyNavy, foyOrange, foyCard) and includes a visible `Option X — [Name]` label with a one-sentence rationale.

**Step 3 — Design each option**

Each option must be a genuinely different direction. Vary layout structure, information density, and navigation pattern.

**Step 4 — Screenshot and ask for approval**

Take a screenshot of each option:
```
mcp__pencil__get_screenshot(nodeId: <Option A frame ID>)
mcp__pencil__get_screenshot(nodeId: <Option B frame ID>)
mcp__pencil__get_screenshot(nodeId: <Option C frame ID>)
```

Show all 3 screenshots, then ask:

```
AskUserQuestion:
  Question: "Which design option do you want to go with?"
  Options: ["Option A — [name]", "Option B — [name]", "Option C — [name]"]
```

**Step 5 — Record approval**

Update the spec file's "Approved option" and "Design approved" status fields to reflect the chosen option.

**Prototype Layer Rule:** Frames stay in the `🎨 PROTOTYPE:` group until explicitly approved above. Do NOT modify existing production screen frames. When approved: note the choice in the spec; physical move to production screen frame happens during implementation, not here.

---

## Phase 9 — OpenSpec Artifact Creation (Fully Automatic)

**No user input needed in this phase. Run all steps without pausing.**

### Step 9.1 — Create the change

Derive a kebab-case change name from the feature name (e.g., "Daily Gratitude Journal" → `daily-gratitude-journal`).

```bash
openspec new change "<kebab-name>"
openspec status --change "<kebab-name>"
```

### Step 9.2 — Proposal artifact

```bash
openspec instructions proposal --change "<kebab-name>" --json
```

Write `proposal.md` with:
- **Why**: 1–2 sentences on the problem and why now
- **What Changes**: concrete list of new capabilities, model changes, UI changes
- **Capabilities**: list each capability as a new `specs/<name>/spec.md` entry (derive capability names from the feature's logical parts — e.g., `factor-check-in`, `factor-insights`, `healthkit-integration`)
- **Impact**: affected files, services, APIs

### Step 9.3 — Design artifact

```bash
openspec instructions design --change "<kebab-name>" --json
```

Write `design.md` covering:
- **Context**: current codebase state relevant to this feature
- **Goals / Non-Goals**: what this design achieves and explicitly excludes
- **Decisions**: 4–6 key technical decisions with rationale and alternatives considered
- **Risks / Trade-offs**: known limitations with mitigations
- **Migration Plan**: how existing data / users are unaffected
- **Open Questions**: any unresolved technical unknowns (usually none after Phase 6)

### Step 9.4 — Spec artifacts

```bash
openspec instructions specs --change "<kebab-name>" --json
```

Create one `specs/<capability>/spec.md` per capability listed in the proposal. Each spec file uses:
- `## ADDED Requirements` sections
- `### Requirement: <name>` — SHALL/MUST normative language
- `#### Scenario: <name>` — WHEN/THEN format (exactly 4 hashtags, minimum one per requirement)

### Step 9.5 — Tasks artifact

```bash
openspec instructions tasks --change "<kebab-name>" --json
```

Write `tasks.md` breaking down implementation into checkboxed tasks (`- [ ] N.N description`), grouped by concern (Data Model, Services, UI Components, etc.). Order by dependency. Each task completable in one coding session. Final group is always "Build & Verification" with a build command and manual test steps.

### Step 9.6 — Verify completion

```bash
openspec status --change "<kebab-name>"
```

Confirm all 4 artifacts show `[x]` or `done`.

---

## Final Report

```
Feature specification complete.

  Feature: [name]
  Discovered via: [trend / pain point / platform opportunity]
  Spec file: specification/[kebab-name].md
  Research: 6 subagents (3 discovery + 3 deep-dive)
  Open questions resolved: N

Design:
  Approved option: [Option X — name]
  Pencil: FocusOnYourselfDesign.pen → 🎨 PROTOTYPE: [Feature Name]

OpenSpec change: openspec/changes/[kebab-name]/
  [x] proposal.md
  [x] design.md
  [x] specs/ ([N] capability specs, [M] scenarios)
  [x] tasks.md ([N] tasks across [M] groups)

Other ideas discovered (available for next /feature-spec):
  - [idea 2]: [one sentence]
  - [idea 3]: [one sentence]
  - [idea 4]: [one sentence]

Ready to implement:
  Run /opsx:apply to start working through the task list.
```
