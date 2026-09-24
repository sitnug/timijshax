"""Run actual library search code against visibility regressions."""
from pathlib import Path
import subprocess, sys, tempfile
root = Path(__file__).resolve().parents[1]
cases = r"""
local Library = {Tabs={}}
SOURCE
local function element(text, visible, kind, values)
 return {Text=text,Visible=visible,Type=kind or "Toggle",Values=values,Holder={Visible=true}}
end
local function group(elements)
 return {Elements=elements,DependencyBoxes={},Holder={Visible=true},BoxHolder={Visible=true},Resize=function() end}
end
local hidden = element("Secret",false)
local ingredient = element("Types",true,"Dropdown",{"Moss Plant","Scroom","A+B"})
local ingredients = group({ingredient,hidden})
local combat = group({element("Auto parry",true)})
local intel = {Groupboxes={Ingredients=ingredients}}
local fight = {Groupboxes={Combat=combat}}
for _,tab in ipairs({intel,fight}) do
 function tab:Show() Library.ActiveTab=self; Library:UpdateSearch(Library.SearchText) end
end
Library.Tabs={Intel=intel,Combat=fight}; Library.ActiveTab=fight
local last
Library.OnSearchUpdated=function(q,total,modules,active) last={q,total,modules,active} end
Library:UpdateSearch("  intel moss  ")
assert(ingredient.Holder.Visible and not hidden.Holder.Visible)
assert(not combat.Holder.Visible and not combat.BoxHolder.Visible)
assert(Library.ActiveTab==intel and last[2]==1 and last[3]==1 and last[4]==1)
Library:UpdateSearch("a+b")
assert(ingredient.Holder.Visible, "punctuation must be literal")
Library:UpdateSearch("no-match")
assert(last[2]==0 and not ingredients.BoxHolder.Visible)
Library:UpdateSearch("")
assert(ingredient.Holder.Visible and combat.BoxHolder.Visible and ingredients.BoxHolder.Visible)
assert(not hidden.Holder.Visible, "clearing search must preserve explicit visibility")
local dependency=group({element("Hidden child",true)}); dependency.Visible=false
ingredients.DependencyBoxes={dependency}
Library:UpdateSearch("hidden")
assert(last[2]==0 and not dependency.Holder.Visible)
Library:UpdateSearch("")
assert(not dependency.Holder.Visible)
assert(SearchMatches("<b>Moss Plant</b>","plant moss"))
assert(not SearchMatches("Moss","moss plant"))
local box={Tabs={},Holder={},BoxHolder={}}
local function child(text)
 local c={Elements={element(text,true)},Container={},ButtonHolder={}}
 function c:Show() if box.ActiveTab then box.ActiveTab.Container.Visible=false end; box.ActiveTab=self;self.Container.Visible=true end
 function c:Resize() end
 return c
end
local a,b=child("Apple"),child("Banana")
box.Tabs={A=a,B=b};box.ActiveTab=a;intel.Tabboxes={box}
Library:UpdateSearch("banana")
assert(box.ActiveTab==b and b.Container.Visible and not a.Container.Visible)
assert(not a.ButtonHolder.Visible and box.BoxHolder.Visible)
Library:UpdateSearch("")
assert(a.ButtonHolder.Visible and b.ButtonHolder.Visible and not a.Container.Visible)
print("PASS: words, literal punctuation, contexts, counts, auto navigation, hidden controls, dependencies, nested tabs, clear")
"""
for name in ["Library.lua", "LibraryClassic.lua"]:
 source=(root/"DEPENDENCIES"/name).read_text()
 actual=source[source.index("local function SearchMatches("):source.index("function Library:AddToRegistry(")]
 with tempfile.TemporaryDirectory() as tmp:
  script=Path(tmp)/"search.luau";script.write_text(cases.replace("SOURCE",actual))
  subprocess.run([sys.argv[1],str(script)],check=True)
