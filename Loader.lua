--[[
    Loader untuk GrowAGarden Auto Buy Seeds
    File ini di-host di GitHub dan di-load oleh script pendek
    Struktur: Loader.lua → load Main.lua
]]

local HttpGet = game.HttpGet
local BASE_URL = "https://raw.githubusercontent.com/jaya40388-art/GrowAGarden-AutoBuy/refs/heads/main/"

-- Load script utama
local mainScript = HttpGet(game, BASE_URL .. "SpeedHub_Test.lua")

if mainScript then
    loadstring(mainScript)()
else
    warn("[AutoBuySeeds] Gagal load script utama!")
end
