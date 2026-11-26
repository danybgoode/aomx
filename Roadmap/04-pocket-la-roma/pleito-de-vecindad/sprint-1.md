---
epic: pleito-de-vecindad
sprint: 1
title: "The run"
stories_total: 4
---

# Pleito de Vecindad: the auto-battler · Sprint 1: The run

**Status:** ⬜ Planned

## Stories

### S1.1 A deterministic street fight

As a player, I watch a fight I can trust and replay. `game/pocket/pleito/battle.gd` is a fixed-tick integer simulation covering targeting, movement, range and canon abilities (stun, splash, heal, back-line jump, aura). Traits and the round's event apply to both sides the same way. Done when headless tests and a cross-platform hash test pass.

### S1.2 Tianguis, bench, merges and board

As a player, I build my crew with one thumb. The shop's odds depend on the age, re-rolls cost 1 Varo, three copies merge into ★★ and ★★★, the board cap grows each round, and selling refunds the cost. A traits panel shows the plain rule for each trait. Everything works with taps; drag is optional.

### S1.3 The street economy

As a player, money is the strategy. Income is a base plus a win bonus, plus the Tanda (1 per 5 Varos saved, max 2), the Contadora's quincena, and the Mirreyes' tarjetazo on wins, minus rent of 0/1/2/3 by age. Events like Quincena (+3) and Subió la renta change it. An income breakdown shows after every round. The Depósito (10 lives) ends the run.

### S1.4 Six rounds and a boss

As a player, a run is a story: 6 rounds across the four ages, rival boards named from the canon, and El Desarrollador as the boss with a unique ability. It has win and lose screens, barks, hit feedback and 1× / 2× speed. A full run takes 6–8 minutes and counts as a completed match.
