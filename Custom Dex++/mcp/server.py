"""Local stdio MCP server and authenticated Roblox polling bridge (stdlib only)."""
import json
import os
import queue
import secrets
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TOKEN_FILE = ROOT / 'bridge-token.txt'
if not TOKEN_FILE.exists():
    fd = os.open(TOKEN_FILE, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as f:
        f.write(secrets.token_urlsafe(32))
TOKEN = TOKEN_FILE.read_text().strip()
if not TOKEN:
    raise RuntimeError('Empty bridge token')
pending = queue.Queue()
waiting = {}
lock = threading.Lock()
last_seen = 0
network_requests = queue.Queue()
network_state = {"enabled": False, "error": None}
network_lock = threading.Lock()

class Bridge(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        global last_seen
        if self.headers.get('Authorization') != 'Bearer ' + TOKEN:
            return self.reply(401, {'error': 'Unauthorized'})
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length <= 1048576:
                return self.reply(413, {'error': 'Invalid body size'})
            body = json.loads(self.rfile.read(length))
            if self.path == '/network':
                if self.client_address[0] != '127.0.0.1':
                    return self.reply(403, {'error': 'Local control only'})
                if 'enabled' in body:
                    if type(body['enabled']) is not bool:
                        return self.reply(400, {'error': 'Boolean required'})
                    network_requests.put(body['enabled'])
                with network_lock:
                    state = dict(network_state)
                return self.reply(200, state)
            if self.path == '/poll':
                last_seen = time.monotonic()
                commands = []
                while len(commands) < 8:
                    try:
                        command = pending.get_nowait()
                    except queue.Empty:
                        break
                    with lock:
                        if command['id'] in waiting:
                            commands.append(command)
                return self.reply(200, {'commands': commands})
            if self.path == '/result':
                with lock:
                    slot = waiting.get(body.get('id'))
                if slot:
                    slot.put_nowait(body)
                return self.reply(200, {'ok': True})
            self.reply(404, {'error': 'Unknown endpoint'})
        except (ValueError, TypeError, queue.Full):
            self.reply(400, {'error': 'Invalid request'})

TOOLS = [
    {'name': 'dex_status', 'description': 'Check whether the local Roblox client bridge is connected.', 'inputSchema': {'type': 'object', 'properties': {}, 'additionalProperties': False}},
    {'name': 'dex_children', 'description': 'List up to 200 direct children. Paths are arrays of exact names, beginning with a service such as Workspace; an empty path means game.', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'array', 'items': {'type': 'string'}}}, 'required': ['path'], 'additionalProperties': False}},
    {'name': 'dex_inspect', 'description': 'Read attributes and common numeric properties of an instance.', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'array', 'items': {'type': 'string'}}}, 'required': ['path'], 'additionalProperties': False}},
    {'name': 'dex_set', 'description': 'Modify one existing numeric attribute or an allowed property in the connected client. Does not grant server authority.', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'array', 'items': {'type': 'string'}}, 'property': {'type': 'string', 'enum': ['Value', 'Health', 'MaxHealth', 'WalkSpeed', 'JumpPower']}, 'attribute': {'type': 'string'}, 'value': {'type': 'number'}}, 'required': ['path', 'value'], 'additionalProperties': False}}
]

def call(name, args):
    if name == 'dex_status':
        return {'connected': bool(last_seen and time.monotonic() - last_seen < 5)}
    if name not in {t['name'] for t in TOOLS}:
        raise ValueError('Unknown tool')
    if not last_seen or time.monotonic() - last_seen > 5:
        raise ValueError('Roblox bridge disconnected; load Dex with the bridge configured')
    ident = secrets.token_hex(12)
    slot = queue.Queue(maxsize=1)
    with lock:
        waiting[ident] = slot
    pending.put({'id': ident, 'operation': name, 'arguments': args})
    try:
        result = slot.get(timeout=15)
        if not result.get('ok'):
            raise ValueError(result.get('error', 'Roblox operation failed'))
        return result.get('result')
    except queue.Empty:
        raise ValueError('Roblox bridge timed out; a sent write may already have applied')
    finally:
        with lock:
            waiting.pop(ident, None)

def network_manager(server):
    while True:
        enabled = network_requests.get()
        if enabled is None:
            server.shutdown()
            server.server_close()
            return
        with network_lock:
            current = network_state['enabled']
        if enabled == current:
            continue
        server.shutdown()
        server.server_close()
        try:
            replacement = ThreadingHTTPServer(('0.0.0.0' if enabled else '127.0.0.1', 8765), Bridge)
            error = None
        except OSError as exc:
            error = str(exc)
            enabled = current
            replacement = ThreadingHTTPServer(('0.0.0.0' if current else '127.0.0.1', 8765), Bridge)
        server = replacement
        with network_lock:
            network_state.update(enabled=enabled, error=error)
        threading.Thread(target=server.serve_forever, daemon=True).start()


def main():
    server = ThreadingHTTPServer(('127.0.0.1', 8765), Bridge)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    threading.Thread(target=network_manager, args=(server,), daemon=True).start()
    print('Dex bridge listening on 127.0.0.1:8765', file=sys.stderr)
    for line in sys.stdin:
        request = {}
        try:
            request = json.loads(line)
            method = request.get('method')
            if 'id' not in request:
                continue
            if method == 'initialize':
                result = {'protocolVersion': '2024-11-05', 'capabilities': {'tools': {}}, 'serverInfo': {'name': 'custom-dex-bridge', 'version': '1.0.0'}}
            elif method == 'ping':
                result = {}
            elif method == 'tools/list':
                result = {'tools': TOOLS}
            elif method == 'tools/call':
                params = request.get('params', {})
                try:
                    value = call(params['name'], params.get('arguments', {}))
                    result = {'content': [{'type': 'text', 'text': json.dumps(value)}]}
                except Exception as exc:
                    result = {'isError': True, 'content': [{'type': 'text', 'text': str(exc)}]}
            else:
                raise ValueError('Unsupported method')
            response = {'jsonrpc': '2.0', 'id': request['id'], 'result': result}
        except Exception as exc:
            response = {'jsonrpc': '2.0', 'id': request.get('id'), 'error': {'code': -32603, 'message': str(exc)}}
        print(json.dumps(response), flush=True)
    network_requests.put(None)

if __name__ == '__main__':
    main()
