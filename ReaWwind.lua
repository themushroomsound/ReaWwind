local reaWwind = {}

--[[ WAAPI OPERATIONS ]]--

reaWwind.transport_id = 18446744073709551614

-- Check Wwise connectivity
function reaWwind.wwise_connection_ok()

    -- Check ReaWwise installed
    if(not reaper.AK_Waapi_Connect) then
        reaper.ShowConsoleMsg("ReaWwise not installed, aborting\n")
        return false
    end

    -- Check Waapi connection
    if(not reaper.AK_Waapi_Connect("127.0.0.1", 8080)) then
        reaper.ShowConsoleMsg("Could not connect to Wwise, aborting\n")
        return false
    end

    return true
end

-- Builds an options object to pass to a WAAPI query
function reaWwind.build_query_options(return_attributes)

    local fieldsToReturn = reaper.AK_AkJson_Array()
    for i,attribute in ipairs(return_attributes) do
        reaper.AK_AkJson_Array_Add(fieldsToReturn, reaper.AK_AkVariant_String(attribute))
    end

    local options = reaper.AK_AkJson_Map()
    reaper.AK_AkJson_Map_Set(options, "return", fieldsToReturn)

    return options
end

-- Performs an ak.wwise.core.object.get query
function reaWwind.get_objects(waql_query, return_attributes)

    -- Store query return fields, field name for objects in expected result JSON
    reaWwind.return_attributes = return_attributes
    reaWwind.query_result_objects_field_name = "return"

    -- Building arguments object 
    local arguments = reaper.AK_AkJson_Map()
    reaper.AK_AkJson_Map_Set(arguments, "waql", reaper.AK_AkVariant_String(waql_query))

    -- Querying for objects
    reaWwind.query_result = reaper.AK_Waapi_Call("ak.wwise.core.object.get", arguments, reaWwind.build_query_options(return_attributes))
end

-- Performs an ak.wwise.ui.getSelectedObjects query
function reaWwind.get_selected_objects(return_attributes)

    -- Store query return fields, field name for objects in expected result JSON
    reaWwind.return_attributes = return_attributes
    reaWwind.query_result_objects_field_name = "objects"

    -- Querying for selected objects
    reaWwind.query_result = reaper.AK_Waapi_Call("ak.wwise.ui.getSelectedObjects", reaper.AK_AkJson_Map(), reaWwind.build_query_options(return_attributes))
end

-- Gets the current switch value for a switch group on the Transport game object
function reaWwind.get_transport_switch_group_value(switch_group, return_attributes)

    -- Store query return fields, field name for objects in expected result JSON
    reaWwind.return_attributes = return_attributes
    reaWwind.query_result_objects_field_name = "return"

    -- Building arguments object 
    local arguments = reaper.AK_AkJson_Map()
    reaper.AK_AkJson_Map_Set(arguments, "switchGroup", reaper.AK_AkVariant_String(switch_group))
    reaper.AK_AkJson_Map_Set(arguments, "gameObject", reaper.AK_AkVariant_Int(reaWwind.transport_id))

    -- Querying for switch value objects
    reaWwind.query_result = reaper.AK_Waapi_Call("ak.soundengine.getSwitch", arguments, reaWwind.build_query_options(return_attributes))
end

-- Check last query success
function reaWwind.query_successful()
    if(not reaper.AK_AkJson_GetStatus(reaWwind.query_result)) then
        return false
    end
    return true
end

-- Get the objects list returned by a ak.wwise.core.object.get request
function reaWwind.get_query_returned_objects()
    local objects = reaper.AK_AkJson_Map_Get(reaWwind.query_result, reaWwind.query_result_objects_field_name)
    local num_objects = reaper.AK_AkJson_Array_Size(objects)
    return objects, num_objects
end

-- Get the string value for an AkJson_Map field
function reaWwind.get_AkJson_Map_String(object, field_name)
    local field_value = reaper.AK_AkJson_Map_Get(object, field_name)
    return reaper.AK_AkVariant_GetString(field_value)
end

-- Get the int value for an AkJson_Map field
function reaWwind.get_AkJson_Map_Int(object, field_name)
    local field_value = reaper.AK_AkJson_Map_Get(object, field_name)
    return reaper.AK_AkVariant_GetInt(field_value)
end

-- Debug print query results
function reaWwind.print_returned_objects()

    -- Get wwise search results
    local objects, num_objects = reaWwind.get_query_returned_objects()

    -- Print objects
    for i=0, num_objects - 1 do
        local object = reaper.AK_AkJson_Array_Get(objects, i)
--[[ 
        local values_str = {}
        for i,attr_name in ipairs(reaWwind.return_attributes) do
            local attr_value = reaper.AK_AkJson_Map_Get(object, attr_name)
            local attr_value_str = "test" --reaper.AK_AkVariant_GetString(attr_value) -- crashing if not a string
            values_str[i] = attr_value_str
        end
        reaper.ShowConsoleMsg(table.concat(values_str, " - ") .. "\n")
 ]]--
        reaper.ShowConsoleMsg(reaWwind.get_AkJson_Map_String(object, "id") .. " - ")
        reaper.ShowConsoleMsg(reaWwind.get_AkJson_Map_String(object, "name") .. "\n")
    end
end

-- Returns the first audio source in the query results, if any
function reaWwind.get_first_audio_source_path()

    -- Get wwise search results
    local objects, num_objects = reaWwind.get_query_returned_objects()

    -- Iterate until finding an audio source with a file path, or return False
    for i=0, num_objects - 1 do
        local item = reaper.AK_AkJson_Array_Get(objects, i)
        local path = reaper.AK_AkJson_Map_Get(item, "originalFilePath")
        local path_str = reaper.AK_AkVariant_GetString(path)
        if(path_str ~= "") then
            return path_str
        end
    end
    return false
end

-- Returns the first play action target ID in the query results, if any
function reaWwind.get_first_play_action_target_ID()

    -- Get wwise search results
    local objects, num_objects = reaWwind.get_query_returned_objects()

    -- Iterate until finding a play action and return its ID, or return False
    for i=0, num_objects - 1 do
        local item = reaper.AK_AkJson_Array_Get(objects, i)
        local type_str = reaWwind.get_AkJson_Map_String(item, "type")
        local action_type_int = reaWwind.get_AkJson_Map_Int(item, "ActionType")
        if(type_str == "Action" and action_type_int == 1) then
            local target = reaper.AK_AkJson_Map_Get(item, "Target")
            return reaWwind.get_AkJson_Map_String(target, "id")
        end
    end
    return false
end

--[[ MEDIA ITEMS OPERATIONS ]]--

-- replace the source of a media item's active take
function reaWwind.import_to_media_item(item, source_file)

    local take = reaper.GetActiveTake(item)
    local source = reaper.PCM_Source_CreateFromFile(source_file)
    reaper.SetMediaItemTake_Source(take, source)

    -- set position, name, length
    local source_length = reaper.GetMediaSourceLength(source)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", source_length)  

    reaper.UpdateArrange()

    return source_length
end

-- create a new media item
function reaWwind.create_media_item(track, item_position, item_name, source_file)

    -- create item and take
    local item = reaper.AddMediaItemToTrack(track)
    local take = reaper.AddTakeToMediaItem(item)

    -- import media to take
    local source_length = reaWwind.import_to_media_item(item, source_file)

    -- set position, name
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", item_position)
    reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", item_name, true)

    reaper.UpdateArrange()

    return source_length
end

return reaWwind