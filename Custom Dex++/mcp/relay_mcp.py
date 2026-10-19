"""MCP stdio adapter for the PHP relay. Set DEX_PAIR_CODE before launching."""
import json
import os
import sys
import time
from urllib.request import Request, urlopen
from urllib.error import HTTPError

URL = os.environ.get('DEX_RELAY_URL', 'https://script.noky.space/mcpdex++/index.php')
CODE = os.environ.get('DEX_PAIR_CODE', '').strip()

def post(action, **values):
    payload = {'action': action, 'code': CODE, **values}
    req = Request(URL, data=json.dumps(payload).encode(), headers={'Content-Type': 'application/json'})
    try:
        with urlopen(req, timeout=10) as res:
            return json.load(res)
    except HTTPError as exc:
        try:
            message = json.load(exc).get('error', 'Relay request failed')
        except Exception:
            message = 'Relay HTTP error '+str(exc.code)
        raise RuntimeError(message) from None

path_schema = {'type': 'array', 'items': {'type': 'string'}}
TOOLS = [
    {'name': 'dex_status', 'description': 'Check the paired Roblox client connection.', 'inputSchema': {'type': 'object', 'properties': {}, 'additionalProperties': False}},
    {'name': 'dex_children', 'description': 'List direct children by exact name path; [] means game. Maximum 200 children.', 'inputSchema': {'type': 'object', 'properties': {'path': path_schema}, 'required': ['path'], 'additionalProperties': False}},
    {'name': 'dex_inspect', 'description': 'Read attributes and common properties in the paired client.', 'inputSchema': {'type': 'object', 'properties': {'path': path_schema}, 'required': ['path'], 'additionalProperties': False}},
    {'name': 'dex_set', 'description': 'Set one numeric client property or existing numeric attribute. Choose property OR attribute.', 'inputSchema': {'type': 'object', 'properties': {'path': path_schema, 'property': {'type': 'string', 'enum': ['Value','Health','MaxHealth','WalkSpeed','JumpPower']}, 'attribute': {'type': 'string'}, 'value': {'type': 'number'}}, 'required': ['path','value'], 'additionalProperties': False}},
]

def call(name, args):
    if not CODE:
        raise ValueError('Set DEX_PAIR_CODE to the code displayed in Dex')
    if name == 'dex_status':
        return post('status')
    if name not in {t['name'] for t in TOOLS}:
        raise ValueError('Unknown tool')
    ident = post('call', operation=name, arguments=args)['id']
    deadline = time.monotonic()+20
    while time.monotonic()<deadline:
        response = post('fetch', id=ident)
        if response['done']:
            result = response['response']
            if not result['ok']:
                raise RuntimeError(result.get('error') or 'Client operation failed')
            return result.get('result')
        time.sleep(0.5)
    raise TimeoutError('Dex timed out; a submitted write may already have applied')

def main():
    for line in sys.stdin:
        req = {}
        try:
            req = json.loads(line)
            if 'id' not in req:
                continue
            method = req.get('method')
            if method == 'initialize':
                result = {'protocolVersion':'2024-11-05','capabilities':{'tools':{}},'serverInfo':{'name':'dex-php-relay','version':'1.0.0'}}
            elif method == 'ping':
                result = {}
            elif method == 'tools/list':
                result = {'tools': TOOLS}
            elif method == 'tools/call':
                try:
                    params = req['params']
                    value = call(params['name'], params.get('arguments',{}))
                    result = {'content':[{'type':'text','text':json.dumps(value)}]}
                except Exception as exc:
                    result = {'isError':True,'content':[{'type':'text','text':str(exc)}]}
            else:
                raise ValueError('Unsupported method')
            response = {'jsonrpc':'2.0','id':req['id'],'result':result}
        except Exception as exc:
            response = {'jsonrpc':'2.0','id':req.get('id'),'error':{'code':-32603,'message':str(exc)}}
        print(json.dumps(response), flush=True)

if __name__ == '__main__':
    main()
