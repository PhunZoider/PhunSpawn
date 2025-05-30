local overlayMap = {}
overlayMap.VERSION = 1

-- south facing
overlayMap["phunspawn_01_4"] = {{
    name = "other",
    chance = 10,
    usage = "",
    tiles = {"walls_interior_house_02_49"}
}}

-- East facing
overlayMap["phunspawn_01_6"] = {{
    name = "other",
    chance = 10,
    usage = "",
    tiles = {"walls_interior_house_02_49"}
}}

if not TILEZED then
    getTileOverlays():addOverlays(overlayMap)
end

return overlayMap
