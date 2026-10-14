import fs from 'node:fs';
import path from 'node:path';

export class AuditStore {
  constructor(filename) {
    this.filename = filename;
    fs.mkdirSync(path.dirname(filename), { recursive: true });
    this.rows = fs.existsSync(filename)
      ? fs.readFileSync(filename, 'utf8').split('\n').filter(Boolean).map(line => JSON.parse(line))
      : [];
  }

  append(row) {
    // Open with append and fsync before returning a receipt. A process crash may
    // leave a truncated final line; startup deliberately fails instead of hiding it.
    const fd = fs.openSync(this.filename, 'a', 0o600);
    try {
      fs.writeSync(fd, `${JSON.stringify(row)}\n`);
      fs.fsyncSync(fd);
    } finally {
      fs.closeSync(fd);
    }
    this.rows.push(row);
    return row;
  }
}
