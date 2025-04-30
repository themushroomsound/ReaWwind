-- Import ReaWwind Module
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"
local ReaWwind = require("ReaWwind")

reaper.ClearConsole()

-- Get the number of selected media items
local num_items = reaper.CountSelectedMediaItems(0)
if(num_items < 1) then
    reaper.ShowConsoleMsg("No selected item, aborting\n")
    return
end

-- Check waapi connection
if(not ReaWwind.wwise_connection_ok()) then
    return
end

-- Get the first selected item
local item = reaper.GetSelectedMediaItem(0, 0)

-- Get the active take of the item
local take = reaper.GetActiveTake(item)

-- Get the name of the active take
local _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)

-- Print the name of the active take
reaper.ShowConsoleMsg("Looking for this name in Wwise: " .. take_name .. "\n")

-- Query for wwise objects named as the media item
ReaWwind.search(take_name)

-- Cleanup
reaper.AK_AkJson_ClearAll()
reaper.AK_Waapi_Disconnect()