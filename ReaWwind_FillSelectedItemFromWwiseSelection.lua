-- Import ReaW2R Module
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"
local ReaWwind = require("ReaW2R")

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

-- Query for wwise selected objects
ReaWwind.get_selected_objects({ "id", "category", "type", "name", "originalFilePath", "ActionType", "Target" })

-- Check query success
if(not ReaWwind.query_successful()) then
    reaper.ShowConsoleMsg("Could not get selected object in Wwise\n")
    return
end

-- Get selected wwise objects
local objects, num_objects = ReaWwind.get_query_returned_objects("objects")

-- Check if any selected objects
if(num_objects < 1) then
    reaper.ShowConsoleMsg("No selected object in Wwise\n")
    return
end

-- Look for an original file path in the results
local first_path = ReaWwind.get_first_audio_source_path()

-- If no original file path directly available in the results
if(not first_path) then
    reaper.ShowConsoleMsg("No audio source found in wwise selection\n")
    return
end

-- Get the selected media item at the current index
local item = reaper.GetSelectedMediaItem(0, 0)

-- Inport source to media item
ReaWwind.import_to_media_item(item, first_path)

-- Cleanup
reaper.AK_AkJson_ClearAll()
reaper.AK_Waapi_Disconnect()

-- Build all missing peaks
reaper.Main_OnCommand(40047, 0)