-- Import ReaWwind Module
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"
local ReaWwind = require("ReaWwind")

reaper.ClearConsole()

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
local objects, num_objects = ReaWwind.get_query_returned_objects()

-- Check if any selected objects
if(num_objects < 1) then
    reaper.ShowConsoleMsg("No selected object in Wwise\n")
    return
end

-- Get the current cursor position
local cursor_pos = reaper.GetCursorPosition()

-- Get the selected track number
local sel_track = reaper.GetSelectedTrack(0, 0)

-- Check selected track
if(not sel_track) then
    reaper.ShowConsoleMsg("No selected track in Reaper\n")
    -- TODO: create a new track
    return
end

-- Iterate on selected objects
for i=0, num_objects - 1 do

    local selected_object = reaper.AK_AkJson_Array_Get(objects, i)
    local name_str = ReaWwind.get_AkJson_Map_String(selected_object, "name")

    -- Get and check if selected object has a source WAV
    local original_file_path_str = ReaWwind.get_AkJson_Map_String(selected_object, "originalFilePath")
    if(original_file_path_str == "") then
        reaper.ShowConsoleMsg("No source file found for wwise object: " .. name_str .. "\n")
        ReaWwind.print_returned_objects()
        goto continue
    end

    -- Create item
    local item_length = ReaWwind.create_media_item(sel_track, cursor_pos, name_str, original_file_path_str)

    -- Shift position for next item
    cursor_pos = cursor_pos + item_length

    ::continue::
end

-- Cleanup
reaper.AK_AkJson_ClearAll()
reaper.AK_Waapi_Disconnect()

-- Build all missing peaks
reaper.Main_OnCommand(40047, 0)
