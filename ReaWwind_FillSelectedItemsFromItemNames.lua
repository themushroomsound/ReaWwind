-- Import ReaWwind Module
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"
local ReaWwind = require("ReaWwind")

reaper.ClearConsole()

-- Finds an object in wwise
local function import_media_from_wwise(item)

    -- Get the active take of the item
    local take = reaper.GetActiveTake(item)
    
    -- Get the name of the active take
    local _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    
    -- Print the name of the active take
    reaper.ShowConsoleMsg("Item name: " .. take_name .. "\n")

    -- Query for wwise objects named as the media item
    ReaWwind.get_objects("from search \"" .. take_name .. "\" select this, descendants", { "id", "category", "type", "name", "originalFilePath", "ActionType", "Target" })

    -- Check query success
    if(not ReaWwind.query_successful()) then
        reaper.ShowConsoleMsg("Failed to seach for object: " .. take_name .. "\n")
        return
    end

    -- Print query results to console
    ReaWwind.print_returned_objects()

    -- Look for an original file path in the results
    local first_path = ReaWwind.get_first_audio_source_path()

    -- If an original file path is directly available in the results, import it and abort
    if(first_path) then
        ReaWwind.import_to_media_item(item, first_path)
        return
    end
    
    -- If not, look for an event play action in the search results
    local play_action_target_ID = ReaWwind.get_first_play_action_target_ID()

    -- If no play action is found in the results either, abort
    if(not play_action_target_ID) then
        reaper.ShowConsoleMsg("No play action found for object: " .. take_name .. " (or its children)\n")
        return
    end

    reaper.ShowConsoleMsg("Found play action target: " .. play_action_target_ID .. "\n")

    -- Query for play action target object
    ReaWwind.get_objects("\"" .. play_action_target_ID .. "\" select this, descendants", { "id", "type", "name", "originalFilePath" })

    -- Check query success
    if(not ReaWwind.query_successful()) then
        reaper.ShowConsoleMsg("Failed to seach for play action target ID: " .. play_action_target_ID .. "\n")
        return
    end

    -- Look for an original file path in the results
    first_path = ReaWwind.get_first_audio_source_path()

    -- If no original file path directly available in the results, abort
    if(not first_path) then
        reaper.ShowConsoleMsg("No audio source found for object: " .. play_action_target_ID .. " (or its children)\n")
        return
    end

    reaper.ShowConsoleMsg("Found source: " .. first_path .. "\n")

    -- Inport source to media item
    ReaWwind.import_to_media_item(item, first_path)
end

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

-- Iterate over each selected item
for i = 0, num_items - 1 do
    -- Get the selected media item at the current index
    local item = reaper.GetSelectedMediaItem(0, i)
    -- Import  media to item from Wwise
    import_media_from_wwise(item)
end

-- Build peaks on selected items
reaper.Main_OnCommand(40245, 0)

-- Cleanup
reaper.AK_AkJson_ClearAll()
reaper.AK_Waapi_Disconnect()