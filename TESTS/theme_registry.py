"""Exercise the actual UI property factory with Roblox-style color type checks.
Usage: python3 TESTS/theme_registry.py /path/to/luau
"""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
runner = sys.argv[1] if len(sys.argv) > 1 else "luau"
harness = '''
local function color(name) return {kind = "Color3", name = name} end
local function typeof(value)
    return type(value) == "table" and value.kind or type(value)
end
local Library = {
    Registry = {}, DPIRegistry = {},
    Scheme = {FontColor = color("font"), BackgroundColor = color("background"), AccentColor = color("accent")},
}
local function GetTableSize(t) local n = 0; for _ in pairs(t) do n += 1 end; return n end
local function ApplyDPIScale(v) return v end
local function ApplyTextScale(v) return v end
local stored = {}
local target = setmetatable({}, {
    __index = stored,
    __newindex = function(_, key, value)
        if key == "TextColor3" or key == "BackgroundColor3" or key == "ImageColor3" or key == "Color" then
            assert(typeof(value) == "Color3", key .. ": Color3 expected, got " .. typeof(value))
        end
        stored[key] = value
    end,
})
'''
cases = '''
-- New() applies class defaults, then caller overrides: the reported crash.
FillInstance({TextColor3 = "FontColor"}, target)
FillInstance({TextColor3 = "BackgroundColor"}, target)
assert(target.TextColor3 == Library.Scheme.BackgroundColor)
assert(Library.Registry[target].TextColor3 == "BackgroundColor")
FillInstance({TextColor3 = "AccentColor"}, target)
assert(target.TextColor3 == Library.Scheme.AccentColor)
-- Theme refresh must use the latest token, not the original binding.
Library.Scheme.AccentColor = color("new accent")
for property, binding in pairs(Library.Registry[target]) do
    target[property] = type(binding) == "function" and binding() or Library.Scheme[binding]
end
assert(target.TextColor3 == Library.Scheme.AccentColor)
-- A concrete Color3 clears the binding; it must not be recolored later.
local literal = color("literal")
FillInstance({TextColor3 = literal}, target)
assert(target.TextColor3 == literal and Library.Registry[target].TextColor3 == nil)
-- Callback overrides must also evaluate rather than assigning a function.
FillInstance({TextColor3 = "FontColor"}, target)
local callback = function() return literal end
FillInstance({TextColor3 = callback}, target)
assert(target.TextColor3 == literal and Library.Registry[target].TextColor3 == callback)
FillInstance({TextColor3 = "AccentColor"}, target)
assert(target.TextColor3 == Library.Scheme.AccentColor)
-- Display text equal to a token name remains literal text.
FillInstance({Text = "AccentColor"}, target)
assert(target.Text == "AccentColor" and Library.Registry[target].Text == nil)
for _, property in ipairs({"BackgroundColor3", "ImageColor3", "Color"}) do
    FillInstance({[property] = "FontColor"}, target)
    FillInstance({[property] = "AccentColor"}, target)
    assert(target[property] == Library.Scheme.AccentColor)
end
print("PASS: template override, theme refresh, literal colors, callbacks, literal text, background/image/stroke colors")
'''
for name in ["Library.lua", "LibraryClassic.lua"]:
    source = (root / "DEPENDENCIES" / name).read_text()
    factory = source[source.index("local function FillInstance("):source.index("\nlocal function New(")]
    with tempfile.TemporaryDirectory(prefix="timijshax-theme-test-") as directory:
        script = Path(directory) / "test.luau"
        script.write_text(harness + factory + cases)
        result = subprocess.run([runner, str(script)], capture_output=True, text=True)
        print(name + ": " + (result.stdout or result.stderr).strip())
        if result.returncode:
            raise SystemExit(result.returncode)
