---
epic: expand-warfare-and-world
sprint: 2
title: "Counters and siege"
risk: high
phase: Verifying
stories_total: 2
stories:
  - id: S2.1
    title: "Choose a predictable counter"
    as_a: "classic RTS player"
    i_want: "armor and role differences I can understand"
    so_that: "army composition changes a fight predictably"
    risk: high
    status: in-progress
  - id: S2.2
    title: "Assault and defend with siege"
    as_a: "classic RTS player"
    i_want: "costly siege and a small useful order set"
    so_that: "breaching a defended post takes planning"
    risk: high
    status: in-progress
---

# Expand warfare and world — Sprint 2: Counters and siege

**Status:** 🟨 Verifying — controlled combat and save/replay pass; signed downloaded-build smoke remains open.

### Story 2.1 — Choose a predictable counter

**As a** classic RTS player, **I want** armor and role differences I can understand, **so that** army composition changes a fight predictably.

**Acceptance:** Existing melee and ranged roles plus one armored counter have stable, versioned attack/armor classes. Controlled encounters state which composition wins and why; a viable counter reverses an unfavorable matchup. The HUD explains armor, eligibility, damage and role without cultural stereotypes. Both factions can recruit or face the role through normal economy and age rules; save/replay reproduces outcomes.

**Risk:** high — shared combat and balance data.

### Story 2.2 — Assault and defend with siege

**As a** classic RTS player, **I want** costly siege and a small useful order set, **so that** breaching a defended post takes planning.

**Acceptance:** Screened siege can destroy a command post; unsupported siege is vulnerable to its declared counter. Projectile travel, target loss and shooter death have deterministic results and visible feedback. Attack-move, stop and hold-position are added only where controlled encounters show a need, on the same validated command path for human and AI. Garrison and formations remain out.

**Risk:** high — combat timing, command state and replay.

## Sprint QA

- **Deterministic specs:** armor/bonus table, counter reversal, projectile timing/edge cases, siege against structures, AI legal orders, save/replay and cross-platform hash.
- **Rendered smoke:** local and downloaded Restricted build show a counter and two siege assaults, with unit detail and damage feedback at normal/enlarged zoom.
- **Gate:** full Godot/Node/CI checks, no regression in the declared larger-map benchmark and independent high-risk review.

## Sprint 2 — Smoke walkthrough

Environment: the signed Restricted macOS preview; record its actual build ID and download source.

1. Start as Poblanos and recruit ranged and armored roles. → Unit cards state their tactical job, armor and counters in plain language.
2. Fight the controlled counter encounter. → Armor absorbs the declared attack class; a suitable counter reverses the result with visible feedback.
3. Send unsupported siege at a defended post. → The defender defeats it before the post falls trivially.
4. Screen a second siege approach and use available orders. → Projectiles visibly travel and the post falls through the declared attack sequence.
5. Save during an assault, quit and resume. → Combat continues consistently without a duplicate terminal event.

Record each step's result. The owner checks the downloaded build.
