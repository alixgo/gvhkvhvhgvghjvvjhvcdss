"""Desktop network toggle for the running MCP bridge. Requires Tkinter."""
import json
from pathlib import Path
import socket
import tkinter as tk
from urllib.request import Request, urlopen

root = tk.Tk()
root.title('Dex MCP — Réseau local')
root.geometry('510x240')
status = tk.StringVar(value='Connexion au serveur MCP…')
address = tk.StringVar()

def query(enabled=None):
    token = (Path(__file__).resolve().parent / 'bridge-token.txt').read_text().strip()
    payload = {} if enabled is None else {'enabled': enabled}
    request = Request('http://127.0.0.1:8765/network', data=json.dumps(payload).encode(),
                      headers={'Content-Type': 'application/json', 'Authorization': 'Bearer '+token})
    with urlopen(request, timeout=1) as response:
        return json.load(response)

def toggle(enabled):
    try:
        query(enabled)
        status.set('Changement en cours…')
    except Exception:
        status.set('Serveur indisponible : démarre le serveur via ton client MCP.')

def refresh():
    try:
        state = query()
        status.set(state.get('error') or ('Exposé sur le réseau local — port 8765' if state['enabled'] else 'Accès limité à cet ordinateur'))
    except Exception:
        status.set('Serveur indisponible : démarre le serveur via ton client MCP.')
    root.after(2000, refresh)

try:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.connect(('192.0.2.1', 9))
        ip = sock.getsockname()[0]
    address.set('http://'+ip+':8765')
except OSError:
    address.set('http://ADRESSE_IP_DE_CET_ORDINATEUR:8765')

tk.Label(root, textvariable=status, wraplength=480).pack(pady=14)
tk.Button(root, text='Exposer sur le réseau local', command=lambda: toggle(True)).pack(pady=4)
tk.Button(root, text='Désactiver l’accès réseau', command=lambda: toggle(False)).pack(pady=4)
tk.Label(root, text='Adresse à utiliser dans Dex (ServerUrl) :').pack(pady=6)
tk.Entry(root, textvariable=address, width=58, state='readonly').pack()
refresh()
root.mainloop()
