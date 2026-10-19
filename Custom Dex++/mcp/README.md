# Dex MCP local

Le serveur Python expose MCP sur son entrée/sortie standard et un pont HTTP authentifié sur `127.0.0.1:8765`. Python 3 suffit, sans dépendance externe. Une seule session Roblox doit se connecter à la fois.

## Connexion

1. Ajouter un serveur MCP stdio dans le client MCP utilisé :

```json
{
  "mcpServers": {
    "custom-dex": {
      "command": "python3",
      "args": ["/Users/orson/development/noky/script/Custom Dex++/mcp/server.py"]
    }
  }
}
```

Le format du fichier de configuration dépend du client MCP. Le client doit lancer le processus et garder son entrée standard ouverte. Ne pas lancer un deuxième processus sur le même port.

2. Au premier démarrage, le serveur crée `bridge-token.txt` dans ce dossier. Copier son contenu dans la configuration Lua suivante, puis lancer le fichier complet `customdex++.lua` dans le même environnement :

```lua
getgenv().DexMCPConfig = {Token = "COLLER_LE_JETON_ICI"}
-- Charger ensuite customdex++.lua.
```

Le script doit pouvoir appeler une API HTTP client `request`, `http_request` ou `syn.request`. Un LocalScript Roblox standard ne fournit pas ces API : pour Studio, une intégration plugin séparée est nécessaire. Si le jeu tourne sur un autre ordinateur, `127.0.0.1` ne pointe pas vers ce serveur.

3. Vérifier `dex_status`, puis appeler `dex_children` avec `{"path":[]}`. Les chemins sont des tableaux de noms exacts, par exemple `{"path":["Workspace"]}`. Un chemin ambigu est refusé.

## Outils

- `dex_status` : présence d'un client ayant contacté le pont dans les cinq dernières secondes.
- `dex_children` : liste au maximum 200 enfants directs.
- `dex_inspect` : attributs et propriétés usuelles, notamment santé, vitesse et valeurs numériques.
- `dex_set` : modification d'une propriété numérique autorisée ou d'un attribut numérique existant. Fournir `property` OU `attribute`, plus `path` et `value`.

Les modifications se font dans le client connecté. Elles peuvent être corrigées par le serveur et ne donnent pas accès au code serveur absent du client. Aucune commande d'exécution de Lua arbitraire, de décompilation ou d'appel de RemoteEvent n'est exposée.

Le jeton est privé et ignoré par Git. Pour arrêter le pont côté jeu :

```lua
getgenv().DexMCPState = nil
```

`client.lua` est la copie de référence du bloc intégré au début de Dex ; modifier les deux exemplaires ensemble.

## Bouton réseau local

Le serveur MCP doit être lancé par le client MCP. Ouvrir ensuite la fenêtre de contrôle :

```sh
python3 "Custom Dex++/mcp/network_button.py"
```

Python doit inclure Tkinter. Cliquer sur **Exposer sur le réseau local** : le pont passe de `127.0.0.1` à `0.0.0.0:8765`. **Désactiver l'accès réseau** rétablit l'accès local. Au redémarrage du serveur, l'accès revient toujours en mode local. Le bouton ne démarre pas un deuxième serveur et reste utilisable pendant l'exposition réseau.

Sur l'autre ordinateur, renseigner l'adresse affichée et le même jeton :

```lua
getgenv().DexMCPConfig = {
    Token = "COLLER_LE_JETON_ICI",
    ServerUrl = "http://192.168.1.10:8765"
}
```

L'adresse affichée est indicative si plusieurs interfaces réseau sont actives. Le pare-feu doit autoriser Python sur le réseau privé. Le jeton reste obligatoire ; la commande d'activation réseau est acceptée uniquement depuis cet ordinateur. Le transport HTTP n'est pas chiffré : utiliser ce mode sur un réseau de confiance. Aucun tunnel Internet ni règle de routeur n'est créé. Seul le pont Roblox HTTP est exposé ; le protocole MCP reste sur stdio.
