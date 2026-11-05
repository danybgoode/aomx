export const gameVersion = 'godot-4.7.2-skirmish-7';
export const currentContentVersion = 'la-roma-world-5';
export const wonderContentVersions = ['la-roma-wonder-1', 'narvarte-wonder-1', 'copilco-wonder-1', 'la-roma-large-wonder-1'];
// The Restricted multiplayer pilot is ahead of master. Keep its current
// telemetry contract accepted while the solo release uses the master version.
export const pilotGameVersion = 'godot-4.7.2-skirmish-12';
export const pilotContentVersion = 'la-roma-world-6';
export const objectiveVersions = [gameVersion, pilotGameVersion];
export const campaignVersions = [
  { game: gameVersion, content: currentContentVersion },
  { game: pilotGameVersion, content: pilotContentVersion }
];
export const supportedVersions = [
  { game: 'godot-4.7.2-skirmish-1', content: 'original-skirmish-map-1' },
  { game: 'godot-4.7.2-skirmish-1', content: 'la-roma-prototype-1' },
  { game: 'godot-4.7.2-skirmish-2', content: 'la-roma-strategy-2' },
  { game: 'godot-4.7.2-skirmish-3', content: 'la-roma-warfare-3' },
  { game: 'godot-4.7.2-skirmish-4', content: 'la-roma-opponent-4' },
  { game: 'godot-4.7.2-skirmish-5', content: currentContentVersion },
  { game: 'godot-4.7.2-skirmish-6', content: currentContentVersion },
  { game: gameVersion, content: currentContentVersion },
  ...wonderContentVersions.map(content => ({ game: gameVersion, content })),
  { game: pilotGameVersion, content: pilotContentVersion },
  { game: pilotGameVersion, content: 'la-roma-wonder-1' }
];
