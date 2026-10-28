---
title: "Prepare a release candidate"
slug: prepare-release-candidate
status: raw
area: "09"
type: feature
appetite: null
underwritten_by: null
risk: low
epic: null
build_order: 23
updated: 2026-10-21
intent_ask: proxy
hypothesis: "Players will need a reliable way to install, learn, play, return and report problems before a wider release."
persona: "A new player installing and learning Battle for La Roma."
grounded: false
grounded_reason: "No distribution build, crash data or measured launch cohort exists yet."
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

# Idea — Prepare a release candidate

After the chosen full-game content and platform gates in the [build path](../../full-game-build-path.md), refine a source-commit-traceable release candidate with signed/versioned builds, onboarding, settings, localization/accessibility, performance, crash/support process, license and attribution register and production telemetry. This follows—not replaces—the earlier measured private-alpha work. Record which native desktop, Web and mobile targets are actually verified on devices. Set go/no-go from observed play, quality and legal evidence. The provisional 15% later-day completion goal has no baseline until the first eligible cohort matures; a merge to `master` is not a deployment.

The owner placed [cross-platform proof #22](../../09-platform-and-measurement/prove-cross-platform-play/README.md) ahead of this bet. Use its [QA ledger](../../../docs/platform/prove-cross-platform-qa.md) for the supported platform matrix; an export or headless launch alone is not a release-candidate support claim.
