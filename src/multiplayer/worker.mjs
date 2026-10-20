import { spawn } from 'node:child_process';
import net from 'node:net';
import { once } from 'node:events';

const READY = 'AOMX_MATCH:ready';

async function unusedPort() {
  const server = net.createServer();
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const port = server.address().port;
  await new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  return port;
}

export class GodotMatchWorker {
  constructor({ godotBin, gamePath, spawnProcess = spawn } = {}) {
    if (!godotBin || !gamePath) throw new Error('godotBin and gamePath are required');
    this.godotBin = godotBin;
    this.gamePath = gamePath;
    this.spawnProcess = spawnProcess;
    this.pending = [];
    this.buffer = '';
    this.closed = false;
  }

  async start() {
    const port = await unusedPort();
    this.child = this.spawnProcess(this.godotBin,
      ['--headless', '--path', this.gamePath, '--script', 'res://multiplayer_worker.gd'],
      { env: { ...process.env, AOMX_WORKER_PORT: String(port) }, stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    const ready = new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('worker_start_timeout')), 5000);
      this.child.stdout.on('data', data => {
        stdout += data;
        if (stdout.includes(READY)) { clearTimeout(timeout); resolve(); }
        if (stdout.length > 16384) stdout = stdout.slice(-4096);
      });
      this.child.stderr.on('data', data => { stderr = (stderr + data).slice(-4096); });
      this.child.once('exit', code => {
        clearTimeout(timeout);
        this.closed = true;
        const error = new Error(`worker_exit_${code}: ${stderr.replaceAll(/invite[_ -]?code\s*[:=]\s*\S+/gi, 'invite_code=[redacted]')}`);
        for (const pending of this.pending.splice(0)) pending.reject(error);
        reject(error);
      });
    });
    await ready;
    this.socket = net.connect(port, '127.0.0.1');
    await once(this.socket, 'connect');
    this.socket.setEncoding('utf8');
    this.socket.on('data', chunk => this.#receive(chunk));
    this.socket.on('error', error => this.#fail(error));
    this.socket.on('close', () => this.#fail(new Error('worker_connection_closed')));
    return this;
  }

  #receive(chunk) {
    this.buffer += chunk;
    if (this.buffer.length > 16 * 1024 * 1024) return this.#fail(new Error('worker_response_too_large'));
    for (let end = this.buffer.indexOf('\n'); end >= 0; end = this.buffer.indexOf('\n')) {
      const line = this.buffer.slice(0, end);
      this.buffer = this.buffer.slice(end + 1);
      const pending = this.pending.shift();
      if (!pending) continue;
      try { pending.resolve(JSON.parse(line)); }
      catch { pending.reject(new Error('worker_response_invalid')); }
    }
  }

  #fail(error) {
    this.closed = true;
    for (const pending of this.pending.splice(0)) pending.reject(error);
  }

  request(message) {
    if (this.closed || !this.socket) return Promise.reject(new Error('worker_unavailable'));
    const line = JSON.stringify(message) + '\n';
    const maxBytes = message.type === 'replay_init' ? 16 * 1024 * 1024 : 65536;
    if (Buffer.byteLength(line) > maxBytes) return Promise.reject(new Error('worker_request_too_large'));
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.#fail(new Error('worker_response_timeout'));
        this.close();
      }, message.type === 'replay_init' ? 120000 : 5000);
      this.pending.push({ resolve: value => { clearTimeout(timeout); resolve(value); },
        reject: error => { clearTimeout(timeout); reject(error); } });
      this.socket.write(line);
    });
  }

  close() {
    this.socket?.destroy();
    this.child?.kill();
    this.closed = true;
  }
}
