# Design: Pencil Design File Sync — Phase 5 of screen-auditor

**Date:** 2026-05-15
**Status:** Approved

## Context

The `screen-auditor` skill audits all `*Screen.swift` files against a canonical screen structure, fixes
violations, and verifies the build. After a validated code change, the Pencil design file
(`FocusOnYourselfDesign.pen`) can drift from what the code actually does. Code is the source of truth;
the design file should reflect it.

This spec adds **Phase 5** to the `screen-auditor` skill: after a clean build, automatically sync the
Pencil design file so it matches the validated Swift code.

---

## What gets synced

Full design system — all four token categories:

| Category | Swift source | Pencil target |
|---|---|---|
| Colors | `DS+Colors.swift` | Pencil variables (fill / stroke colors) |
| Spacing | `DS+Spacing.swift` | Pencil variables + screen node padding/gap |
| Corner radius | `DS+CornerRadius.swift` | Pencil variables + node cornerRadius |
| Typography | `DS+Typography.swift` | Pencil variables (fontSize, fontWeight, fontFamily) |

---

## Phase 5 design (Approach C: variables + targeted structural sync)

Phase 5 runs only if Phase 4 (build) succeeds. It has three parts.

### Part 1 — Design token variable sync

1. Read the four Swift token files and extract all token name → value pairs into a flat dict:
   ```
   { "foyNavy": "#1E3A5F", "screenHorizontal": 28, "card": 12, "foyBody": 15, ... }
   ```
2. Call `get_variables()` on the open Pencil file to get current variable values.
3. Diff Swift dict vs Pencil variables — identify every entry where values differ.
4. Call `set_variables()` with only the changed entries.
5. Report: `N variables updated, M already in sync`.

If Pencil variable names don't match Swift token names exactly, use the mapping table in the skill to
translate (e.g. `CornerRadius.card` → Pencil variable `card` or `cornerRadius-card`).

### Part 2 — Structural layout sync

Targets screen-level layout properties that the auditor validates:
- Horizontal padding: `Spacing.screenHorizontal` = 28
- Bottom padding: `Spacing.screenBottom` = 48
- Section gap: `Spacing.lg` = 24

Steps:
1. Call `search_all_unique_properties(parents=["*Screen*"], properties=["padding", "gap", "cornerRadius"])`
   to discover what values are currently set on screen nodes in Pencil.
2. For each discovered value that doesn't match the expected token value, call
   `replace_all_matching_properties()` to bulk-replace across all screen nodes in one pass.
3. No per-node ID mapping is needed — the search-and-replace approach is resilient to node reorganisation.
4. Report: `K nodes updated across N screens`.

### Part 3 — Visual verification

Take screenshots of three representative screens to confirm changes look correct:
- `HomeScreen` (main tab, custom header, carousel)
- `InsightsScreen` (data-heavy, stat cards)
- `HistoryScreen` (calendar cards)

Call `get_screenshot(nodeId)` for each. Include the screenshots in the final audit report.
If a screenshot shows an obvious layout regression, flag it and ask the user to review before moving on.

---

## Final report (extended)

```
Screen audit complete.
  Screens checked: N
  Violations found: M
  Fixes applied: K
  Build: ✅ clean

Pencil sync:
  Variables updated: N  (or: already in sync)
  Layout nodes corrected: K across N screens
  Screenshots: [HomeScreen ✅] [InsightsScreen ✅] [HistoryScreen ✅]
```

---

## Constraints and edge cases

- **Phase 5 only runs after a clean build.** If the build fails, skip sync and report the error.
- **Variables that don't exist in Pencil** — if a Swift token has no matching Pencil variable, log it as
  `⚠ unmapped: <token-name>` in the report. Do not create new variables automatically.
- **Dark-mode variants** — Swift colors have light/dark variants; Pencil likely uses a single light value.
  Only sync the light-mode hex value unless instructed otherwise.
- **Font names** — Pencil uses the font family name string (e.g. `"Inter"`); Swift uses a custom Font enum.
  The skill must map font token → `{ fontFamily: "Inter", fontWeight: N, fontSize: N }` explicitly.
- **`replace_all_matching_properties` blast radius** — only apply structural replacements within screen
  parent nodes (not the Design System component library frame) to avoid corrupting reusable components.

---

## Files to modify

| File | Change |
|---|---|
| `.claude/skills/screen-auditor/SKILL.md` | Add Phase 5 section after Phase 4 |

No new files needed. The Pencil MCP server handles all design file writes.
