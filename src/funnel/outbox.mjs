import fs from 'node:fs';
import path from 'node:path';
import { randomUUID } from 'node:crypto';

function save(filename, state) {
  fs.mkdirSync(path.dirname(filename), { recursive: true });
  const temp = `${filename}.${process.pid}.tmp`;
  fs.writeFileSync(temp, JSON.stringify(state, null, 2), { mode: 0o600 });
  const fd = fs.openSync(temp, 'r');
  try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  fs.renameSync(temp, filename);
  const dir = fs.openSync(path.dirname(filename), 'r');
  try { fs.fsyncSync(dir); } finally { fs.closeSync(dir); }
}

export class Outbox {
  constructor(filename, { now = () => new Date(), gameVersion = 'prototype-0', contentVersion = 'original-0', testAccount = true } = {}) {
    this.filename = filename;
    this.now = now;
    this.gameVersion = gameVersion;
    this.contentVersion = contentVersion;
    this.testAccount = testAccount;
    this.state = fs.existsSync(filename) ? JSON.parse(fs.readFileSync(filename, 'utf8')) : { player_id: randomUUID(), next_sequence: 1, events: [] };
    if (!fs.existsSync(filename)) save(filename, this.state);
  }

  queue(type, { matchId = null, mode = 'solo', faction = 'neutral', bot = false, result = null, newSession = false } = {}) {
    if (type === 'game_opened' && !newSession && this.state.events.some(x => x.event.type === 'game_opened')) {
      return this.state.events.find(x => x.event.type === 'game_opened').event;
    }
    if (type !== 'game_opened' && this.state.events.some(x => x.event.type === type && x.event.match_id === matchId)) return this.state.events.find(x => x.event.type === type && x.event.match_id === matchId).event;
    const event = { schema_version: 1, type, event_id: randomUUID(), player_id: this.state.player_id,
      claimed_at: this.now().toISOString(), local_sequence: this.state.next_sequence, game_version: this.gameVersion,
      content_version: this.contentVersion, mode, faction, test_account: this.testAccount, bot };
    if (matchId) event.match_id = matchId;
    if (result) event.result = result;
    this.state.events.push({ event, status: 'pending', receipt: null });
    this.state.next_sequence++;
    save(this.filename, this.state);
    return event;
  }

  get status() {
    return this.state.events.map(x => ({ event_id: x.event.event_id, type: x.event.type, status: x.status,
      message: x.status === 'pending' ? 'Saved on this device. Pending sync.' : x.status === 'accepted' ?
        x.receipt?.status === 'excluded' ? 'Synced test or excluded session. This play was not counted.' : 'Synced and accepted.' :
        x.receipt?.reason === 'clock_ahead' ? 'Needs attention: check your device clock. Your result is saved here; contact support if it persists.' :
          `Needs attention: ${x.receipt?.reason ?? 'sync error'}. Your result is saved here; contact support.`, receipt: x.receipt }));
  }

  async sync(send) {
    for (const item of this.state.events) {
      if (item.status === 'accepted' || item.status === 'needs_attention') continue;
      let receipt;
      try { receipt = await send(item.event); } catch { break; }
      if (!receipt || receipt.event_id !== item.event.event_id) break;
      item.receipt = receipt;
      item.status = receipt.status === 'accepted' || receipt.status === 'excluded' ? 'accepted' : 'needs_attention';
      save(this.filename, this.state);
      if (item.status === 'needs_attention') break;
    }
    return this.status;
  }
}
