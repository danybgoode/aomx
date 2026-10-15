# Ways of Working

This is the working agreement for Battle for La Roma at its planning stage. Update it when the game stack, deployment, and review tools are chosen.

## Roles and the unit of work

The product owner sets direction and approves product bets. The agent drafts and implements small, reviewable slices. A story should describe a player or operator outcome and observable acceptance checks.

## The cadence

Capture idea → refine scope → approve a bet → build a slice → verify behavior → review → merge → record the result. A merged document is not a shipped game feature. This repo currently uses `master`; no deployment rail exists yet.

## Epic-mode builds

Before code, record the intended player outcome, scope, key decisions, acceptance checks, and verification method in the epic README and sprint file. Keep each sprint small enough to review and test. Use a separate branch for substantial changes. The `refine` skill scaffolds approved work.

## Betting & appetite

Use a session-sized appetite when refining work:

| Size | Planning commitment |
| --- | --- |
| S | One bounded builder session. |
| M | Several connected slices needing an architecture decision and review. |
| L | A larger epic that must be re-evaluated between waves. |

The owner approves scope and what it displaces. A raw backlog seed is not funded work. Record approved bets with the `refine` skill before scaffolding an epic.

## Review & merge

Review code, game behavior, and measurements against the approved acceptance checks. Use a second reviewer for changes that affect player data, security, payments, or the integrity of North Star reporting. Verify the working tree and tests before merge. A merge to `master` does not imply a deployment until a deploy process is established.

## Escalate, don't guess

Ask the product owner when a decision changes core game rules, audience, cultural portrayal, privacy, spending, deployment, or the agreed North Star. Document the decision where future work will find it. Routine implementation details can be resolved by the builder.

## Permissions

Agents may inspect and edit this repo, prepare branches and pull requests, and run local checks for authorized work. Do not expose credentials or commit local environment files. Obtain the owner's decision before an unapproved external release, spending commitment, or production data change.

## Definitions of Done

- **Story:** The observable behavior works, its acceptance checks pass, and relevant docs reflect the result.
- **Epic:** Its stories are complete, the outcome has been checked in a real build, and the result and learnings are recorded.
- **Measurement:** Events are sent with stable player identity, deduplicated and checked against a known play path; derived readings match the agreed North Star definition.

## Automated QA

The local funnel prototype uses Node 24: run `npm ci`, `npm test`, `npm run funnel:fixtures`, and `npm run funnel:report`. Its [event contract and audit walkthrough](../docs/launch-funnel-contract.md) explain the output. The Godot 4.7.2 RTS prototype has [run and headless check commands](../game/README.md); its rendered worker, gathering and construction paths were checked locally. There is no terminal match or release build; add export and hosted smoke commands when those exist.

## Documentation map

`Roadmap/README.md` is the product poster. `00-strategy/` holds agreed strategy and assumptions. `00-ideas/seeds/` holds raw ideas; `BUILD-ORDER.md` is generated from source status. Epic and sprint documents will record funded work. `LEARNINGS.md` holds only findings relevant to this project.

## Conventions

Use English for planning and technical documentation. The game's copy and localization policy will be chosen with the first playable slice. Keep cultural references legible to players who do not know the jokes. Use the actual `master` branch name in commands until the repository changes it.

## Tooling

The project scoped skills live in `.agents/skills/`. Golden Frijoles is linked as product `aomx`; `npx -y @golden-frijoles/cli@1.5.1 status` checks the remote connection. Local keys live in ignored `.env.local`. The kit can generate the build-order board and push the roadmap; use the matching skill instructions for the installed version.
