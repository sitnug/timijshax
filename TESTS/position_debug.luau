local setup = require("../DEPENDENCIES/PositionDebug")
local callbacks, labels, exported, hud, tick, cleanup = {}, {}, nil, nil, nil, nil
local root = {Position={X=12.345,Y=-42.5,Z=900}, IsA=function() return true end}
local character = {FindFirstChild=function() return root end}
local player = {Character=character}
local disconnected = false
local services = {
 Players={LocalPlayer=player},
 HttpService={JSONEncode=function(_, data) exported=data;return "export" end},
 RunService={Heartbeat={Connect=function(_, callback) tick=callback;return {Disconnect=function() disconnected=true end} end}},
}
-- The CLI sandbox does not expose Roblox globals; give the real module a mock environment.
local env = getfenv(setup)
env.game={PlaceId=123,GetService=function(_, name) return services[name] end}
env.Vector2={new=function() return {} end}
env.UDim2={new=function() return {} end}
env.Color3={fromRGB=function() return {} end}
env.Enum={Font={Code="Code"}}
env.Instance={new=function() hud={Destroy=function(self) self.destroyed=true end};return hud end}
env.setclipboard=function(text) assert(text=="export") end
local group={}
function group:AddLabel(text)
 local result={Text=text,SetText=function(self,t) self.Text=t end}
 table.insert(labels,result);return result
end
function group:AddToggle(_, data) callbacks.toggle=data.Callback end
function group:AddInput(_, data) callbacks.name=data.Callback end
function group:AddButton(data) callbacks[data.Text]=data.Func end
local library={ScreenGui={},Notify=function() end,OnUnload=function(_,fn) cleanup=fn end}
setup(library,group)
assert(not hud.Visible)
callbacks.toggle(true);assert(hud.Visible and hud.Text:find("12.35",1,true))
callbacks.name("Cave");callbacks["Capture waypoint"]();callbacks["Copy waypoint list"]()
assert(exported.placeId==123 and #exported.points==1 and exported.points[1].label=="Cave")
assert(exported.points[1].y==-42.5 and exported.points[1].x==12.345)
for k in pairs(exported) do assert(k=="version" or k=="placeId" or k=="points") end
for k in pairs(exported.points[1]) do assert(k=="x" or k=="y" or k=="z" or k=="label") end
player.Character=nil;tick(0.2);assert(hud.Text:find("Waiting",1,true))
callbacks["Capture waypoint"]();assert(#exported.points==1)
player.Character=character;root.Position.X=20;tick(0.2);assert(hud.Text:find("20.00",1,true))
callbacks["Copy current position"]();assert(exported.points[1].x==20)
callbacks["Undo last waypoint"]();callbacks["Undo last waypoint"]()
callbacks.toggle(false);assert(not hud.Visible)
cleanup();assert(disconnected and hud.destroyed)
print("PASS: live coordinates, exact named exports, no account fields, respawn, undo, toggle, unload")
