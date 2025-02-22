---
local idCounter = 0

local function GenerateUniqueID()
    idCounter = idCounter + 1
    return idCounter
end

local function dump(o, visited)
    visited = visited or {} -- Tabelle, um bereits verarbeitete Objekte zu speichern

    if type(o) == "table" then
        if visited[o] then
            return "{ <RECURSION> }" -- Verhindert Endlosschleife
        end
        visited[o] = true -- Markiere Tabelle als besucht

        local s = "{ "
        for k, v in pairs(o) do
            local key = type(k) == "number" and k or '"' .. tostring(k) .. '"'
            s = s .. "[" .. key .. "] = " .. dump(v, visited) .. ", "
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

---

local QuestieMap = QuestieLoader:ImportModule("QuestieMap")
local l10n = QuestieLoader:ImportModule("l10n")

local frame = CreateFrame("Frame")
local activeIcons = {}

local function GetZoneNameById(searchId)
    for parentIndex, subTable in pairs(l10n.zoneLookup) do
        if subTable[searchId] then
            return subTable[searchId]
        end
    end
    return nil
end

local function GetLocalizedZoneName(zoneName)
    if l10n.translations[zoneName] and l10n.translations[zoneName]["deDE"] then
        deZoneName = l10n.translations[zoneName]["deDE"]

        if deZoneName == "Das Brachland" then
            deZoneName = "Brachland"
        end

        return deZoneName
    end
    return zoneName
end

local function GetQuestObjectives(questId)
    local objectives = {}

    if not QuestieMap.questIdFrames[questId] then
        return objectives
    end

    for _, frame in pairs(QuestieMap:GetFramesForQuest(questId)) do
        if frame then
            table.insert(objectives, frame)
        end
    end

    return objectives
end
-- qcframe = nil;
local function GenerateTooltip(frame)
    local tooltip = ""
    -- qcframe = frame
    tooltip = tooltip .. frame.data.QuestData.name .. "\n"
    tooltip = tooltip .. "Stufe: " .. frame.data.QuestData.level .. "\n"
    -- tooltip = tooltip .. "Abzugeben bei: " .. frame.data.QuestData.Finisher.Name .. "\n"

    return tooltip
end

local function AddCarboniteIcon(uid, zone, x, y, iconPath, iconScale, tooltip)
    Nx.MapInitIconType(uid, "WP", iconPath, 16 * iconScale, 16 * iconScale)
    local icon = Nx.MapAddIconPoint(uid, zone, x, y, iconPath)
    Nx.MapSetIconTip(icon, tooltip)
end

local function RemoveCarboniteIcon(uid)
    Nx.MapInitIconType(uid, "")
end
qcframe = {};
local function UpdateCarboniteIcons()
    for uid, _ in pairs(activeIcons) do
        RemoveCarboniteIcon(uid)
    end
    activeIcons = {}
    for questId, _ in pairs(QuestieMap.questIdFrames) do
        local objectives = GetQuestObjectives(questId)
        for _, frame in ipairs(objectives) do
            local zoneName = GetZoneNameById(frame.AreaID)
            local l10nZoneName = GetLocalizedZoneName(zoneName)
            local iconTexturePath = Questie.usedIcons[frame.data.Icon]
            local iconScale = frame.data.IconScale
            local uid = "!" .. GenerateUniqueID()
            local type = frame.data.Type

            if (type == "available" or type == "complete") then
                AddCarboniteIcon(uid, l10nZoneName, frame.x, frame.y, iconTexturePath, iconScale, GenerateTooltip(frame))

                activeIcons[uid] = true
            end
        end
    end
end

function QCMergeCallback()
    UpdateCarboniteIcons()
end
