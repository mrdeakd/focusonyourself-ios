---
name: screen-auditor
description: >
  Audits all screens in the FocusOnYourself app against the canonical screen structure rules,
  fixes every violation found, verifies the build, then pushes the validated code (single source
  of truth) into the Pencil design file via pencil.dev MCP. Dispatches parallel subagents for speed.
---

# Screen Auditor

**This is a rigid skill. Follow every phase exactly.**

## The 8-Point Checklist

Every `*Screen.swift` file must pass all 8 rules:

| # | Rule | Correct | Wrong |
|---|------|---------|-------|
| 1 | Outer wrapper | `ZStack { Color.foyBackground.ignoresSafeArea() }` | Any other structure |
| 2 | Header | `ScreenHeaderView(title:)` OR `// Screen has no header: <reason>` comment | Custom `HStack` with `Text` + `.foyNavTitle`, no comment |
| 3 | Horizontal padding token | `.padding(.horizontal, Spacing.screenHorizontal)` | `.padding(.horizontal, Spacing.xl)` or raw number |
| 4 | Scroll bottom padding | `.padding(.bottom, Spacing.screenBottom)` | Missing or different token |
| 5 | Section spacing | `VStack(spacing: Spacing.lg)` | `VStack(spacing: Spacing.xl)`, raw number, or `VStack(spacing: 0)` when content sections exist |
| 6 | ScrollView indicators | `.scrollIndicators(.hidden)` | Missing or `.scrollIndicators(.automatic)` |
| 7 | No raw private constants | All corner/spacing via `CornerRadius.*` or `Spacing.*` | `private let x: CGFloat = 18` |
| 8 | No duplicate horizontal padding | Components fill container width | Component adds `.padding(.horizontal, ...)` inside already-padded scroll context |

## Fix Patterns

For each rule violation, apply the corresponding fix:

| Rule | Before | After |
|------|--------|-------|
| 3 | `.padding(.horizontal, Spacing.xl)` | `.padding(.horizontal, Spacing.screenHorizontal)` |
| 2 | Custom `HStack { Text("Title").font(.foyNavTitle) ... }` | `ScreenHeaderView(title: "Title")` |
| 7 | `private let cardCornerRadius: CGFloat = 18` + uses | Remove `private let`, replace uses with `CornerRadius.card` (18) |
| 7 | `private let calendarCardRadius: CGFloat = 18` + uses | Remove `private let`, replace uses with `CornerRadius.card` (18) |
| 7 | `private let badgePaddingH: CGFloat = 10` + uses | Check if value matches a `Spacing.*` token; if not, add `badgeHorizontal = 10` to `DS+Spacing.swift` |
| 4 | Missing bottom padding | Add `.padding(.bottom, Spacing.screenBottom)` to scroll content VStack |
| 6 | Missing `.scrollIndicators(.hidden)` | Add it after the closing `}` of `ScrollView { }` |

**Exception screens** (rule 2 header): `WelcomeScreen`, `PaywallScreen`, and any full-bleed hero screens. These need the inline exception comment added if it's missing — do NOT add `ScreenHeaderView` to them.

---

## Phase 1 — Discover all screens

Run this to get the full list:
```bash
find FocusOnYourself/Features -name "*Screen.swift" | sort
```

Group the results into batches of 3–4 files. Create 3 batches maximum for parallel dispatch.

---

## Phase 2 — Parallel audit

Dispatch **3 Explore agents in parallel** (single message, multiple Agent tool calls). Give each agent a batch of files.

**Agent prompt template** (fill in the file list):

> Read each of these screen files and check them against the 8-point checklist below. For each screen, report a structured finding:
>
> ```
> Screen: <ScreenName>
> File: <path>
> Violations:
>   - Rule N: <what's wrong> (line ~X)
>     Current: <exact current code>
>     Expected: <exact fix>
> PASS if no violations.
> ```
>
> **The 8-point checklist:**
> 1. Outer wrapper is `ZStack { Color.foyBackground.ignoresSafeArea() }`
> 2. `ScreenHeaderView(title:)` is used — OR there's a `// Screen has no header: <reason>` comment. Exception screens that are always header-less by design: WelcomeScreen, PaywallScreen.
> 3. Horizontal padding token is `Spacing.screenHorizontal` — NOT `Spacing.xl`, NOT a raw number
> 4. Scroll content VStack has `.padding(.bottom, Spacing.screenBottom)`
> 5. Content sections are separated by `VStack(spacing: Spacing.lg)` — NOT `Spacing.xl` or a raw number
> 6. Every `ScrollView` has `.scrollIndicators(.hidden)`
> 7. No raw `private let` spacing or corner radius constants — must use `Spacing.*` or `CornerRadius.*`
> 8. No `.padding(.horizontal, ...)` added inside components that are already inside a screen-padded scroll context
>
> Files to audit:
> - <file1>
> - <file2>
> - <file3>

Wait for all 3 agents to return before proceeding to Phase 3.

---

## Phase 3 — Aggregate and fix

1. Collect all violation reports from the 3 agents into one list.
2. Print a summary: `N screens checked, M violations found across K screens.`
3. Fix violations in this order:
   - **Token mismatches first** (rule 3, 7) — safe, token-only swaps
   - **Missing modifiers** (rule 4, 6) — additive, low risk
   - **Structural changes** (rule 2, 5) — modify layout structure
4. For rule 2 violations: replace the custom `HStack` header with `ScreenHeaderView`. Preserve any trailing content (e.g. a PRO badge) using `ScreenHeaderView`'s trailing ViewBuilder parameter.
5. For rule 7: when removing a `private let`, also replace every use of that constant with the token.
6. After all edits: run `swiftlint --fix && swiftlint` from the project root. Fix any lint errors before proceeding.

---

## Phase 4 — Verify build

Run:
```bash
xcodebuild -project FocusOnYourself.xcodeproj -scheme FocusOnYourself \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30
```

If the build fails, read the error, fix it, and re-run until clean.

---

## Phase 5 — Sync to Pencil design file

**Code is the single source of truth.** This phase pushes validated code values into the design
file — never the reverse. If the design file is missing, broken, or out of date, that is fine:
the design can always be regenerated from the code.

**Only runs if Phase 4 build succeeded.** Skips silently if the build failed.

Open the design file: `mcp__pencil__open_document("FocusOnYourselfDesign.pen")`

### Part 1 — Design token variable sync

1. Read the four Swift token files and extract all token name → value pairs:
   - `FocusOnYourself/DesignSystem/DS+Colors.swift` → color hex values (light-mode only)
   - `FocusOnYourself/DesignSystem/DS+Spacing.swift` → spacing numbers
   - `FocusOnYourself/DesignSystem/DS+CornerRadius.swift` → corner radius numbers
   - `FocusOnYourself/DesignSystem/DS+Typography.swift` → font size / weight / family

2. Call `mcp__pencil__get_variables()` to read current Pencil variable values.

3. Diff Swift tokens vs Pencil variables. Build a list of mismatches:
   `{ tokenName: { swift: expectedValue, pencil: currentValue } }`
   **Swift value always wins.** Never update code to match Pencil.

4. Call `mcp__pencil__set_variables()` with only the mismatched entries to update them.

5. Log: `Variables synced: N updated, M already in sync.`
   If a Swift token has no matching Pencil variable, log `⚠ unmapped: <token-name>` — do not create variables.

**Color mapping note:** Swift colors have light/dark variants. Only sync the light-mode hex. Use `Color(light: X, dark: Y)` → take X.

### Part 2 — Structural layout sync

Targets screen-level padding, gap, and corner radius that the auditor validates.

Expected values from code (these are authoritative):
- Horizontal padding: `Spacing.screenHorizontal` = 28
- Bottom padding: `Spacing.screenBottom` = 48
- Section gap: `Spacing.lg` = 24

Steps:
1. Call `mcp__pencil__search_all_unique_properties(parents=["*Screen*"], properties=["padding", "gap", "cornerRadius"])` to find all current values across screen nodes.
2. For any value that doesn't match the expected token, call `mcp__pencil__replace_all_matching_properties()` to bulk-update across all screen nodes.
3. Limit replacements to screen parent nodes only — do NOT touch the Design System component library frame.
4. Log: `Layout nodes corrected: K across N screens.`

### Part 3 — Visual verification

Take screenshots of three representative screens to confirm changes look correct:

```
mcp__pencil__get_screenshot(nodeId: <HomeScreen node ID>)
mcp__pencil__get_screenshot(nodeId: <InsightsScreen node ID>)
mcp__pencil__get_screenshot(nodeId: <HistoryScreen node ID>)
```

Find node IDs with `mcp__pencil__batch_get(patterns=["HomeScreen", "InsightsScreen", "HistoryScreen"])`.

Include screenshots in the final report. If a screenshot shows an obvious layout regression, flag it and ask the user to review before finishing.

---

## Final report

Print:
```
Screen audit complete.
  Screens checked: N
  Violations found: M
  Fixes applied: K
  Build: ✅ clean / ❌ errors remaining

Screens with changes:
  - ScreenName: [list of rules fixed]
  ...

Screens with exceptions documented:
  - WelcomeScreen: no header (full-bleed hero)
  - PaywallScreen: no header (custom paywall layout)
  ...

Design file sync:
  Variables updated: N  (or: already in sync)
  Layout nodes corrected: K across N screens
  Unmapped tokens: [list or none]
  Screenshots: [HomeScreen ✅] [InsightsScreen ✅] [HistoryScreen ✅]
```
