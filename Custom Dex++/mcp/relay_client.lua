-- Hosted PHP relay bridge. No local HTTP server is needed by the Roblox client.
local send=request or http_request or (syn and syn.request)
local Players=game:GetService("Players")
local player=Players.LocalPlayer
if player and send then
    local http=game:GetService("HttpService")
    local relayUrl="https://script.noky.space/mcpdex++/index.php"
        local function resolve(path)
            assert(type(path)=="table" and #path<=64,"Invalid path")
            local obj=game
            for _,name in ipairs(path) do
                assert(type(name)=="string","Invalid path segment")
                local found=nil
                for _,child in ipairs(obj:GetChildren()) do
                    if child.Name==name then
                        assert(not found,"Ambiguous path: "..name)
                        found=child
                    end
                end
                obj=assert(found,"Object not found: "..name)
            end
            return obj
        end
        local function scalar(value)
            local kind=typeof(value)
            if kind=="string" or kind=="boolean" or kind=="number" then return value end
            return tostring(value)
        end
        local function execute(command)
            local args=command.arguments
            local obj=resolve(args.path)
            if command.operation=="dex_children" then
                local children=obj:GetChildren()
                local result={children={},truncated=#children>200}
                for i=1,math.min(#children,200) do
                    table.insert(result.children,{name=children[i].Name,class=children[i].ClassName})
                end
                return result
            elseif command.operation=="dex_inspect" then
                local result={name=obj.Name,class=obj.ClassName,attributes={},properties={}}
                for name,value in pairs(obj:GetAttributes()) do result.attributes[name]=scalar(value) end
                for _,name in ipairs({"Value","Health","MaxHealth","WalkSpeed","JumpPower","Position","AssemblyLinearVelocity"}) do
                    local ok,value=pcall(function() return obj[name] end)
                    if ok then result.properties[name]=scalar(value) end
                end
                return result
            elseif command.operation=="dex_set" then
                assert(type(args.value)=="number" and args.value==args.value and math.abs(args.value)<1e9,"Invalid numeric value")
                assert((args.attribute~=nil)~=(args.property~=nil),"Choose attribute OR property")
                if args.attribute then
                    assert(type(obj:GetAttribute(args.attribute))=="number","Existing numeric attribute required")
                    obj:SetAttribute(args.attribute,args.value)
                else
                    local allowed={Value=true,Health=true,MaxHealth=true,WalkSpeed=true,JumpPower=true}
                    assert(allowed[args.property],"Property not allowed")
                    assert(type(obj[args.property])=="number","Numeric property required")
                    obj[args.property]=args.value
                end
                return {applied=true,scope="client"}
            end
            error("Unknown operation")
        end

    local function post(action,session,extra)
        local body=extra or {}
        body.action=action
        if session then body.code=session.code; body.clientToken=session.clientToken end
        local response=send({Url=relayUrl,Method="POST",Headers={["Content-Type"]="application/json"},Body=http:JSONEncode(body)})
        assert(response,"Relais inaccessible")
        local decoded=http:JSONDecode(response.Body)
        assert(response.StatusCode==200,decoded.error or "Erreur HTTP relais")
        return decoded
    end
    local gui=Instance.new("ScreenGui")
    gui.Name="DexMCPRelay"; gui.ResetOnSpawn=false
    local playerGui=player:WaitForChild("PlayerGui")
    local previous=playerGui:FindFirstChild(gui.Name)
    if previous then previous:Destroy() end
    gui.Parent=playerGui
    local frame=Instance.new("Frame",gui)
    frame.Size=UDim2.fromOffset(340,140); frame.Position=UDim2.new(1,-355,1,-155)
    frame.BackgroundColor3=Color3.fromRGB(28,28,34)
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local button=Instance.new("TextButton",frame)
    button.Size=UDim2.new(1,-20,0,34); button.Position=UDim2.fromOffset(10,10)
    button.Text="Activer le MCP"; button.Font=Enum.Font.GothamBold; button.TextSize=14
    button.TextColor3=Color3.new(1,1,1); button.BackgroundColor3=Color3.fromRGB(110,70,210)
    local codeBox=Instance.new("TextBox",frame)
    codeBox.Size=UDim2.new(1,-20,0,32); codeBox.Position=UDim2.fromOffset(10,52)
    codeBox.Text="Code de connexion"; codeBox.ClearTextOnFocus=false
    codeBox.TextEditable=false; codeBox.TextSize=13; codeBox.Font=Enum.Font.Code
    local status=Instance.new("TextLabel",frame)
    status.Size=UDim2.new(1,-20,0,42); status.Position=UDim2.fromOffset(10,90)
    status.BackgroundTransparency=1; status.TextWrapped=true; status.TextSize=12
    status.TextColor3=Color3.new(1,1,1); status.Text="MCP désactivé"
    local active=nil
    local busy=false
    local alive=true
    local function stop()
        local session=active
        active=nil
        button.Text="Activer le MCP"; codeBox.Text="Code de connexion"
        status.Text="MCP désactivé"
        if session then task.spawn(function() pcall(post,"close",session) end) end
    end
    gui.Destroying:Connect(function() alive=false; stop() end)
    button.Activated:Connect(function()
        if busy then return end
        if active then stop(); return end
        busy=true; button.Text="Connexion…"
        local ok,session=pcall(post,"pair")
        busy=false
        if not alive then
            if ok then pcall(post,"close",session) end
            return
        end
        if not ok then button.Text="Réessayer"; status.Text=tostring(session); return end
        active=session
        codeBox.Text=session.code
        button.Text="Désactiver le MCP"
        status.Text="Code valable 1 heure. Partage-le uniquement pour cette connexion."
        task.spawn(function()
            local expiry=os.clock()+(session.expiresIn or 3600)
            local failures=0
            while alive and active==session and os.clock()<expiry do
                local success,err=pcall(function()
                    local batch=post("poll",session)
                    for _,command in ipairs(batch.commands or {}) do
                        if active~=session or not alive then break end
                        local worked,result=pcall(execute,command)
                        post("result",session,{id=command.id,ok=worked,result=worked and result or nil,error=not worked and tostring(result) or nil})
                    end
                end)
                if active~=session or not alive then break end
                if success then
                    if failures>0 then status.Text="Relais connecté — code valable 1 heure." end
                    failures=0
                else
                    failures+=1
                    status.Text="Relais indisponible, nouvelle tentative…"
                    if failures>=10 then
                        stop(); status.Text="Connexion perdue. Réactive le MCP pour un nouveau code."
                        break
                    end
                end
                task.wait(success and 1 or 3)
            end
            if alive and active==session then stop(); status.Text="Code expiré. Réactive le MCP." end
        end)
    end)
elseif player then
    warn("[Dex MCP] API HTTP request indisponible : relais non activé")
end
