export const gameVersion = 'godot-4.7.2-skirmish-12';
export const currentContentVersion = 'la-roma-world-6';
export const wonderContentVersions = ['la-roma-wonder-1', 'narvarte-wonder-1', 'copilco-wonder-1', 'la-roma-medium-wonder-1', 'la-roma-large-wonder-1'];
export const legacyWonderContentVersions = wonderContentVersions.filter(content => content !== 'la-roma-medium-wonder-1');
export const legacyGameVersion = 'godot-4.7.2-skirmish-7';
export const legacyContentVersion = 'la-roma-world-5';
export const pilotGameVersion = gameVersion;
export const pilotContentVersion = currentContentVersion;
export const objectiveVersions = [legacyGameVersion, gameVersion];
export const campaignVersions = [
  { game: legacyGameVersion, content: legacyContentVersion },
  { game: gameVersion, content: currentContentVersion }
];
export const supportedVersions = [
  { game: 'godot-4.7.2-skirmish-1', content: 'original-skirmish-map-1' },
  { game: 'godot-4.7.2-skirmish-1', content: 'la-roma-prototype-1' },
  { game: 'godot-4.7.2-skirmish-2', content: 'la-roma-strategy-2' },
  { game: 'godot-4.7.2-skirmish-3', content: 'la-roma-warfare-3' },
  { game: 'godot-4.7.2-skirmish-4', content: 'la-roma-opponent-4' },
  { game: 'godot-4.7.2-skirmish-5', content: legacyContentVersion },
  { game: 'godot-4.7.2-skirmish-6', content: legacyContentVersion },
  { game: legacyGameVersion, content: legacyContentVersion },
  ...legacyWonderContentVersions.map(content => ({ game: legacyGameVersion, content })),
  { game: gameVersion, content: currentContentVersion },
  ...wonderContentVersions.map(content => ({ game: gameVersion, content })),
];
