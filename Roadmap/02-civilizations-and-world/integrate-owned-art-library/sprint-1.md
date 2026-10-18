---
epic: integrate-owned-art-library
sprint: 1
title: "Source audit and export contract"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S1.1
    title: "Trace and export owned art candidates"
    as_a: "game builder"
    i_want: "reproducible owned art exports with source records"
    so_that: "selected art can safely enter production"
    risk: low
    status: done
---
# Integrate the owned art library — Sprint 1

**Status:** ✅ Shipped — source audit, export contract and verification merged in PR #42.

### Story 1.1 — Trace and export owned art candidates ✅

**Acceptance:** `scripts/export-owned-art.sh` reproduces 32 exports from tracked source copies. `node scripts/validate-art-manifest.mjs` checks hashes, dimensions, roles and the 1 MiB owned RGBA budget. Source rights and recipes are recorded in the manifest and `docs/art/owned-art-pipeline.md`.

## Sprint QA

Run the export twice and compare hashes; run the manifest validator. The ignored `references/` directory is not a build input.

## Sprint 1 — Smoke walkthrough

1. From the repo root, run `scripts/export-owned-art.sh`.
   → It reports 32 exports.
2. Run `node scripts/validate-art-manifest.mjs`.
   → It reports 62 valid textures and a measured owned texture budget.
