import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';

const gameFile = name => new URL(`../../game/${name}`, import.meta.url);
const simulationHash = createHash('sha256')
  .update(readFileSync(gameFile('skirmish.gd')))
  .update(readFileSync(gameFile('rules_content.gd'))).digest('hex');
const contentHash = createHash('sha256')
  .update(readFileSync(gameFile('content/skirmish.v1.json'))).digest('hex');

export const SkirmishVersions = {
  protocol: 1,
  game: 'godot-4.7.2-skirmish-5',
  content: 'la-roma-world-5',
  commandSchema: 3,
  stateSchema: 5,
  simulationHash,
  contentHash,
  public() { return { protocol_version: this.protocol, game_version: this.game,
    content_version: this.content, command_schema_version: this.commandSchema,
    state_schema_version: this.stateSchema, simulation_hash: this.simulationHash,
    content_hash: this.contentHash }; },
  matches(value) { const expected = this.public(); return Object.keys(expected).every(key => value[key] === expected[key]); }
};
