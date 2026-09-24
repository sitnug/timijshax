local planner=require("../DEPENDENCIES/AreaRoutePlanner")
local setup=require("../DEPENDENCIES/AreaRoutes")
local markers={{name="A",x=0,y=0,z=0},{name="B",x=1000,y=0,z=0}}
local groups=planner.group({{x=10,y=0,z=0},{x=990,y=0,z=0},{x=0/0,y=0,z=0}},markers)
assert(#groups.A==1 and #groups.B==1)
assert(next(planner.group({{x=1,y=2,z=3}},{}))==nil)
local ordered=planner.order({{x=9,y=0,z=0},{x=2,y=0,z=0}},{x=0,y=0,z=0})
assert(ordered[1].x==2 and ordered[2].x==9)
local vec={}
local function v(x,y,z) return setmetatable({X=x,Y=y,Z=z},vec) end
vec.__add=function(a,b) return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vec.__sub=function(a,b) return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vec.__index=function(a,k) if k=="Magnitude" then return math.sqrt(a.X^2+a.Y^2+a.Z^2) end end
local root={Position=v(0,0,0)}
local h={Health=100,MoveTo=function(_,p) root.target=p end}
local char={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return h end}
local player={Character=char}
local callbacks,labels,queue={}, {}, {}
local time,repeatStop=0,false
local stalled=false
local busy,gateOK,gateCalls,releases=false,true,0,0
local captured,unload,stored
local world={}
function world:FindFirstChild() return {GetChildren=function() return {
 {Name="A",Position=v(0,0,0),IsA=function() return true end},
 {Name="B",Position=v(1000,0,0),IsA=function() return true end},
} end} end
function world:Raycast(origin) return {Position=origin-v(0,6,0)} end
function world:GetChildren() return {} end
local services={Workspace=world,Players={LocalPlayer=player},HttpService={
 JSONEncode=function(_,data) stored=data;return "json" end,
 JSONDecode=function() return stored end,
},PathfindingService={CreatePath=function()
 local path={Status="Success"}
 function path:ComputeAsync(_,target) self.target=target;self.Status=target.X==20 and "Failed" or "Success" end
 function path:GetWaypoints() return {{Position=self.target,Action="Walk"}} end
 function path:Destroy() end
 return path
end}}
local env=getfenv(setup)
env.game={PlaceId=123,GetService=function(_,name) return services[name] end,HttpGet=function() return "planner" end}
env.loadstring=function() return function() return planner end end
env.Vector3={new=v};env.RaycastParams={new=function() return {} end}
env.Enum={RaycastFilterType={Exclude="Exclude"},PathStatus={Success="Success"},PathWaypointAction={Jump="Jump"}}
env.readfile=nil;env.writefile=function() end;env.fireclickdetector=function() end;env.warn=function() end
env.os={clock=function() return time end}
env.task={
 defer=function(fn) table.insert(queue,fn);return fn end,
 delay=function(_,fn) return fn end,
 cancel=function(fn) for i=#queue,1,-1 do if queue[i]==fn then table.remove(queue,i) end end end,
 wait=function(dt)
  time+=dt
  if root.target and not stalled then root.Position=root.target end
  if repeatStop and time>12 then repeatStop=false;callbacks["Stop area route"]() end
 end,
}
local group={}
function group:AddLabel(text) local l={Text=text,SetText=function(self,t) self.Text=t end};table.insert(labels,l);return l end
function group:AddDropdown(id,data)
 callbacks[id]=data.Callback
 return {SetValues=function() end,SetValue=function(_,value) data.Callback(value) end}
end
function group:AddToggle(id,data) callbacks[id]=data.Callback end
function group:AddInput(id,data) callbacks[id]=data.Callback end
function group:AddSlider(id,data) callbacks[id]=data.Callback end
function group:AddButton(data) callbacks[data.Text]=data.Func end
local library={TimijshaxSpawnMemory={records={{x=10,y=0,z=0},{x=20,y=0,z=0}}},Notify=function() end,OnUnload=function(_,fn) unload=fn end}
local adapter={busy=function() return busy end,setBusy=function(b) busy=b end,
 preview=function(p) captured=p end,
 gate=function(_,pos) gateCalls+=1;root.Position=pos;return gateOK end,
 releaseGate=function() releases+=1 end,
}
setup(library,group,adapter,"source/")
local function flush() while #queue>0 do table.remove(queue,1)() end end
callbacks["Generate route preview"]();flush()
assert(captured and #captured==1 and captured[1].position.X==10)
assert(labels[1].Text:find("1 skipped",1,true))
callbacks["Run area once"]();flush();assert(not busy and labels[1].Text:find("Finished once",1,true))
root.Position=v(0,0,0);callbacks.AreaRouteGateName("Gate A");callbacks["Record Gate arrival here"]()
assert(stored.placeId==123 and stored.mappings.A.gate=="Gate A")
callbacks.AreaRouteUseGate(true);callbacks["Generate route preview"]();flush()
root.Position=v(900,0,0);callbacks["Run area once"]();flush()
assert(gateCalls==1 and releases==1 and labels[1].Text:find("Finished once",1,true))
gateOK=false;callbacks["Run area once"]();flush();assert(not busy and labels[1].Text:find("could not be verified",1,true))
gateOK=true;callbacks.AreaRouteRepeatDelay(10);repeatStop=true
callbacks["Repeat area route"]();flush();assert(not busy and labels[1].Text=="Stopped")
callbacks["Generate route preview"]();callbacks["Stop area route"]();flush();assert(not busy)
callbacks.AreaRouteUseGate(false);root.Position=v(0,0,0)
callbacks["Generate route preview"]();flush();stalled=true
callbacks["Run area once"]();flush();assert(not busy and labels[1].Text:find("Movement blocked",1,true))
stalled=false
player.Character=nil;callbacks["Generate route preview"]();flush();assert(labels[1].Text:find("Character unavailable",1,true))
unload();assert(not busy)
print("PASS: grouping, invalid points, ordering, unreachable skips, preview, once, Gate mapping/verification/failure, repeat cancellation, missing character, unload")
