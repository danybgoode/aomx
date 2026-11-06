---
epic: game-localization
sprint: 1
title: "Spanish and English game builds"
risk: medium
phase: Building
stories_total: 4
---

# Sprint 1 · Spanish and English game builds

**Status:** in-progress (released publicly as `public-36868ff112ac`; owner read-through of the Spanish copy remains)

## ✅ S1.1 Translatable game text

As a player, I want every screen to read in my language, so that I never meet a mix of English and Spanish. Godot auto-translate handles plain text; composed text uses `tr()`; ids use `GameText.name()`; drawn map labels and command captions are translated too.

## ✅ S1.2 Catalogs in the approved voice

As a Spanish-speaking player, I want the game to sound Mexican and clear, so that the jokes land without hiding the rules. `es.po` and `en.po` cover all 593 strings, with gender-neutral phrasing wherever a name is inserted.

## ✅ S1.3 Language choice

As a player, I want the game to start in my device language and let me switch, so that I am never stuck. A picker on the setup screen and in settings switches live, and the choice persists in `user://ui-settings.v2.json`.

## ✅ S1.4 Verified public release

As the owner, I want both public channels to carry the bilingual build from one merged commit, so that what players download matches the source. This uses the [public release runbook](../../../docs/release/public-release-runbook.md).
