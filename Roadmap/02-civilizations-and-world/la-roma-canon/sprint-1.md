---
epic: la-roma-canon
sprint: 1
title: "The canon file and its voice"
stories_total: 3
---

# The La Roma canon: archetypes, traits, events and voice · Sprint 1: The canon file and its voice

**Status:** ⬜ Planned

## Stories

### S1.1 One canon content model

As a builder of any mode, I read archetypes, traits, events, ages and rivals from `game/content/canon.v1.json` through `game/canon.gd`, so the lore can't fork. It starts with 12 archetypes: Foráneo, Bicitaxista, Repartidor, Ciclista, Godín, Contadora, Asambleísta, Barista, Taquero, Mirrey, Influencer and Broker. Each gets a class, faction affinity, role, RTS role, pocket base stats, ability ids and unlock age. It also holds 9 traits (5 classes, 4 factions), at least 12 city events with per-mode effects, 4 ages with a rent curve, at least 24 rival names, and two bosses (El Casero, El Desarrollador). Done when a Godot test and a Node check reject broken references, and the review prototype's numbers are carried over as the starting balance.

### S1.2 Barks and copy in the approved voice

As a player, every archetype sounds like someone I've met in the city: at least two lines each for select, order, ability and defeat, plus trait, event and age copy, in es-MX and EN. The glossary goes in `docs/brand/voice.md` with the satire rule spelled out. The owner's read-through is the gate for public use (D3). Barks are text first (D10).

### S1.3 Readable without the joke

As a player who doesn't know Mexico, every archetype, trait and event also has a plain one-line rule next to the joke, so I can play without decoding a reference. Done when the i18n catalogs cover both lines and a test fails if any displayed rule has no plain line.
