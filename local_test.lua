-- Run this file from the executor workspace that contains `tegalan/`.
-- No absolute filesystem path: executor readfile sandboxes reject it.
if not isfile or not readfile then
    error("local_test.lua needs isfile/readfile")
end

local root = "tegalan"
assert(isfile(root .. "/init.lua"),
    "tegalan/init.lua not found; set the executor workspace to the opoki root")
assert(isfile(root .. "/garden/bundle.lua"),
    "tegalan/garden/bundle.lua not found; run node tools/bundle.js first")

if getgenv then
    getgenv().GAG_LOCAL_ROOT = root
    getgenv().GAG_APP = "garden"
else
    _G.GAG_LOCAL_ROOT = root
    _G.GAG_APP = "garden"
end

return loadstring(readfile(root .. "/init.lua"), "@tegalan/init.lua")()
