# Track the launch play funnel — Retrospective

## In-progress evidence · 2026-10-14

The local contract, fixture ingest, outbox reference, cohort report and dry-run publisher were built on `codex/track-launch-play-funnel`. Headless checks pass. Golden Frijoles aomx has no first event or observed reading; its enablement flag was created and checked serving off in development, preview and production. No hosted event or metric value was written.

The planned uninterrupted epic could not close because the repo still lacks the dependent Godot client, terminal solo match, and deployable authenticated service. The Node outbox is a reference for those client integrations, not a substitute for rendered game behavior. The first mature real cohort and client/reporting review remain open. Keep this retrospective open until the actual release and observed result exist.

The 2026-10-14 second code review found and verified fixes for return-rate cohort eligibility, restart first-open deduplication, impossible UTC dates, rejected-payload privacy, flag-transition eligibility, per-environment evaluation attribution, and observed zero-day counts. Live pushes were disabled because the available SDK route does not prove the bearer key's product identity. The later Godot/client and hosted-reporting review remains open.

An independent fresh checkout of commit `afdcc9b` passed offline install, 11 tests and two identical fixture runs. Its six audit rows were four test exclusions and two named rejections; the report showed no public cohort or observed baseline. Sprint 1 is ready for PR review and merge.

_Closed: <date>_
_Intent: yes | mostly | no_
<!-- Did we build what the product owner meant? One word, THEIR answer: yes, mostly or no. Required by `epic-dod` only
     when the epic's seed or README carries a numeric `intent_match:` (intent-match D17); the calibration learns from
     it. Keep the line and leave exactly one of the three words between `_Intent: ` and the closing underscore. -->
_Quote vs actual: <quote $lo–hi (basis), or "not quoted"> → <actual ≈$n> (<Δ% vs the quote's top, or "—">)_
<!-- The actual is STAMPED, never typed: `node scripts/epic-actuals.mjs --epic <slug> --write` writes actual_* into
     the README (finops S2.5); copy its numbers here. -->
_Crew (actual): <each model and its ≈$, from actual_models> · reviewers <from the PR's review records> · prose <who wrote it> — <one line: where it differed from the plan, and why>_
<!-- The models are STAMPED, never typed: `node scripts/epic-actuals.mjs --epic <slug> --write` writes actual_models
     into the README (why-as-a-story D6). Codex, agy, Devin and other outside tools are not in the transcripts; name
     them from the PR's review records. -->

## What shipped
<!-- The capability now live, by sprint, with commit/PR refs. -->

## What went well

## What we learned
<!-- Promote the durable, generalizable items to Roadmap/LEARNINGS.md (one-liner + why + date). Dedupe. -->

## Gaps / follow-ups
<!-- Smoke gaps owed to the product owner, deferred slices, known limitations. -->
