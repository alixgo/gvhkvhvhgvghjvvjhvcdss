# Installation du relais PHP

1. Copier uniquement `index.php` dans le dossier public `mcpdex++` de l'hébergement PHP. L'adresse attendue est `https://script.noky.space/mcpdex++/index.php`.
2. PHP 7.4+ avec JSON et un dossier temporaire accessible en écriture est requis. Les sessions sont stockées hors de la racine publique dans un sous-dossier de `sys_get_temp_dir()`. Pour un stockage dédié, définir la variable d'environnement serveur `DEX_RELAY_STORAGE` vers un dossier privé accessible en écriture. Configurer un nettoyage quotidien des fichiers de ce dossier âgés de plus de deux heures. Les expirations sont vérifiées à chaque requête.
3. Charger `customdex++.lua` dans le client Roblox puis cliquer **Activer le MCP**. Le panneau affiche un code de 32 caractères, valable une heure. Le sélectionner et le copier. Ce code autorise l'inspection et la modification des propriétés numériques exposées ; le garder privé. **Désactiver le MCP** révoque la session si le relais est joignable, sinon elle expire automatiquement.
4. Brancher `relay_mcp.py` dans le client MCP, en remplaçant le code de l'exemple :

```json
{
  "mcpServers": {
    "dex-relay": {
      "command": "python3",
      "args": ["/Users/orson/development/noky/script/Custom Dex++/mcp/relay_mcp.py"],
      "env": {"DEX_PAIR_CODE": "CODE_AFFICHE_DANS_DEX"}
    }
  }
}
```

Le format de configuration dépend du client MCP. Un nouveau code nécessite de mettre à jour `DEX_PAIR_CODE` et de reconnecter ce serveur MCP. `DEX_RELAY_URL` permet de changer l'URL dans l'adaptateur ; changer aussi `relayUrl` dans `relay_client.lua` et le bloc intégré à Dex si le domaine change.

Le code peut aussi être communiqué à un agent disposant d'un accès HTTP au relais : POST JSON `{"action":"status","code":"…"}`, puis `call` avec `operation` et `arguments`, et `fetch` avec l'identifiant retourné. Les opérations disponibles sont `dex_children`, `dex_inspect`, `dex_set`. L'action `pair` crée une session et retourne le code ainsi qu'un jeton réservé au client Roblox. Seul ce jeton autorise `poll`, `result` et `close`.

Le relais ne contient pas de serveur MCP HTTP : `relay_mcp.py` traduit MCP stdio en requêtes HTTPS vers PHP. Le client Roblox doit fournir `request`, `http_request` ou `syn.request`. Le relais ne donne aucune autorité serveur Roblox. Il n'expose ni exécution Lua arbitraire ni invocation de RemoteEvent. Utiliser un seul client Roblox par code. Une commande envoyée peut déjà avoir été appliquée même si sa réponse est perdue ; ne pas relancer automatiquement une écriture échouée.

Les anciens fichiers `server.py`, `client.lua` et `network_button.py` concernent uniquement le mode réseau local précédent ; ils ne sont pas nécessaires pour le relais PHP.
