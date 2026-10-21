---
title: "Audit gameplay fidelity against a pinned RTS reference"
slug: audit-gameplay-fidelity
status: raw
area: "01"
type: spike
appetite: null
underwritten_by: null
risk: low
epic: null
build_order: 17
updated: 2026-10-21
intent_ask: proxy
hypothesis: "A pinned behavioral comparison may expose the largest gameplay gaps before broad content work consumes the budget."
persona: "The product owner deciding which RTS mechanics and exceptions to build next."
grounded: false
grounded_reason: "This is a design/engineering decision artifact rather than a direct measured retention bet."
target_metric: null
target_from: null
target_to: null
read_date: null
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
intent_match: null
---

# Idea — Audit gameplay fidelity against a pinned RTS reference

The owner chose Age of Empires II: Definitive Edition as the fidelity reference; the **specific edition build/patch and exception policy still need a decision**. Timebox a source-and-test audit of the current four-resource, four-age game against independently described behavioral scenarios for gathering, construction, tech prerequisites, combat/counters/siege, pathing, fog, AI, map setup, save/replay and match outcomes. Classify each as verified, partial, planned or absent with exact repo evidence and reproducible scenarios. Separate rules fidelity from original Mexico City fiction, UI and assets. End with a written decision and ordered follow-on stories in existing core-play epics or new seeds, rather than implementing mechanics in this spike.

The [GDD](../../../docs/design/GDD.md) and [full-game build path](../../full-game-build-path.md) state the aspiration; neither proves parity. Do not use proprietary assets, code or data. Record proposed exception decisions for Terrenos, local objectives and neighborhood modifiers for the owner before making them competitive rules. See the [coverage review](../art-world-coverage-2026-10-21.md).
