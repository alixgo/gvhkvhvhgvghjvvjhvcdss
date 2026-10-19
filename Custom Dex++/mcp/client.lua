-- Optional local MCP bridge. Configure before loading Dex:
-- getgenv().DexMCPConfig={Token="contents of mcp/bridge-token.txt"}
local config = getgenv and getgenv().DexMCPConfig
if type(config) == "table" and type(config.Token) == "string" and #config.Token > 0 then
    local send = request or http_request or (syn and syn.request)
    if send then
        local http = game:GetService("HttpService")
        local baseUrl=(config.ServerUrl or "http://127.0.0.1:8765"):gsub("/+$", "")
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
        local function post(path,body)
            local response=send({Url=baseUrl..path,Method="POST",Headers={
                ["Content-Type"]="application/json",Authorization="Bearer "..config.Token
            },Body=http:JSONEncode(body)})
            assert(response and response.StatusCode==200,"Bridge HTTP request failed")
            return http:JSONDecode(response.Body)
        end
        -- Replacing this state stops the old polling task on a Dex reload.
        local state={}
        getgenv().DexMCPState=state
        task.spawn(function()
            local reported=false
            while getgenv().DexMCPState==state do
                local ok,err=pcall(function()
                    local batch=post("/poll",{})
                    for _,command in ipairs(batch.commands or {}) do
                        local success,result=pcall(execute,command)
                        post("/result",{id=command.id,ok=success,result=success and result or nil,error=not success and tostring(result) or nil})
                    end
                end)
                if not ok and not reported then warn("[Dex MCP] "..tostring(err)); reported=true end
                if ok then reported=false end
                task.wait(ok and 0.25 or 2)
            end
        end)
    else
        warn("[Dex MCP] HTTP request API unavailable in this client")
    end
end
