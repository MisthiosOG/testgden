-- Run WindUI build from executor workspace that contains `tegalan/`.
-- Executor workspace harus = folder opoki. Bundle wajib fresh: node tools/bundle.js
if not isfile or not readfile then
    error("local_test_windui.lua needs isfile/readfile")
end

local root = "tegalan"
assert(isfile(root .. "/init.lua"), "tegalan/init.lua not found")
assert(isfile(root .. "/windui/bundle.lua"), "tegalan/windui/bundle.lua not found; run node tools/bundle.js first")

if getgenv then
    getgenv().GAG_LOCAL_ROOT = root
    getgenv().GAG_APP = "windui"
else
    _G.GAG_LOCAL_ROOT = root
    _G.GAG_APP = "windui"
end

return loadstring(readfile(root .. "/init.lua"), "@tegalan/init.lua")()
