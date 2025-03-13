--------------------------------
-- Save and load workspace configurations
--------------------------------


--------------------------------------------------------------------------------
-- Helper: Serialize a Lua table to a human-readable string.
--------------------------------------------------------------------------------
function M.serializeTable(val, name, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    local ret = ""
    if name then 
        ret = ret .. indent .. string.format("[%q] = ", tostring(name))
    end
    if type(val) == "table" then
        ret = ret .. "{\n"
        for k, v in pairs(val) do
            ret = ret .. M.serializeTable(v, tostring(k), depth + 1) .. ",\n"
        end
        ret = ret .. indent .. "}"
    elseif type(val) == "string" then
        ret = ret .. string.format("%q", val)
    else
        ret = ret .. tostring(val)
    end
    return ret
end

--------------------------------------------------------------------------------
-- Save Workspace Configuration:
-- Saves the current tag’s layout (by name), master width factor, and tiling order
-- (cycling through clients starting at the master) to a file.
--------------------------------------------------------------------------------
function M.saveWorkspaceConfiguration(optionalFilename)
    local s = awful.screen.focused()
    local t = s.selected_tag
    if not t then return nil end

    local order = {}
    local master = awful.client.getmaster() or t:clients()[1]
    if not master then return nil end
    local origFocus = client.focus
    client.focus = master
    order[1] = { class = master.class or "", name = master.name or "" }
    local current = master
    repeat
        awful.client.focus.byidx(1)
        current = client.focus
        if current and current ~= master then
            table.insert(order, { class = current.class or "", name = current.name or "" })
        end
    until current == master
    if origFocus then client.focus = origFocus end

    local layoutName = "unknown"
    for _, mapping in ipairs(layoutMapping) do
        if t.layout == mapping.func then
            layoutName = mapping.name
            break
        end
    end

    local config = {
        workspace = optionalFilename or "",
        layoutName = layoutName,
        master_width_factor = t.master_width_factor,
        windowOrder = order,
    }

    local folder = os.getenv("HOME") .. "/.config/awesome/workspaces/"
    os.execute("mkdir -p " .. folder)
    if optionalFilename then
        if not optionalFilename or optionalFilename == "" then return end
        config.workspace = optionalFilename
        local serialized = M.serializeTable(config, nil, 0)
        local filename = folder .. optionalFilename .. ".lua"
        local file = io.open(filename, "w")
        if file then
            file:write("return " .. serialized)
            file:close()
        end
    else
        awful.prompt.run({
            prompt = "Save workspace configuration as: ",
            textbox = s.mypromptbox.widget,
            exe_callback = function(input)
                if not input or input == "" then return end
                config.workspace = input
                local serialized = M.serializeTable(config, nil, 0)
                local filename = folder .. input .. ".lua"
                local file = io.open(filename, "w")
                if file then
                    file:write("return " .. serialized)
                    file:close()
                end
            end,
        })
    end
end

--------------------------------------------------------------------------------
-- Compare and Reorder:
-- Compares the saved window order (target) with the current tiling order on a tag,
-- swapping windows as needed so that the order matches the saved order.
--------------------------------------------------------------------------------
function M.compareAndReorder(savedOrder, t)
    -- Extract numeric keys from savedOrder, then sort them in descending order.
    local savedKeys = {}
    for k in pairs(savedOrder) do
        table.insert(savedKeys, tonumber(k))
    end

    table.sort(savedKeys)

    -- We'll iterate through whichever list is shorter (assuming same size, though).
    local len = #savedKeys
    naughty.notify({text="Number of windows: " .. tostring(len)})
    client.focus = awful.client.getmaster()
    for index = 1, len do
        local savedKey     = savedKeys[index]
        local desiredClass = savedOrder[tostring(savedKey)].class
        repeat
            awful.client.focus.byidx(1)
        until client.focus.class == desiredClass
        awful.client.setslave(client.focus)
    end
end

--------------------------------------------------------------------------------
-- Load Workspace Configuration:
-- Creates (or reuses) a tag with the saved layout and master width factor.
-- If a tag with the target workspace name already exists, its clients are moved
-- to an Overflow tag (volatile). Then, windows are moved (or spawned) onto the target tag.
-- Finally, the current order is saved to a compare file (with "_compare" appended)
-- and that compare order is compared with the saved order to swap windows as needed.
--------------------------------------------------------------------------------
function M.loadWorkspaceConfiguration(optionalFilename)
    local folder = os.getenv("HOME") .. "/.config/awesome/workspaces/"
    local wsName = optionalFilename  -- assume optionalFilename is the workspace name (without extension)
    local function loadOrder(file, wsName)
        local config = dofile(file)
        local s = awful.screen.focused()
        local workspaceName = wsName or config.workspace or "LoadedWorkspace"

        -- Determine the layout function using our mapping table.
        local layoutFunc = awful.layout.layouts[1]
        for _, mapping in ipairs(layoutMapping) do
            if mapping.name:lower() == (config.layoutName or ""):lower() then
                layoutFunc = mapping.func
                break
            end
        end

        -- Create (or get) the Overflow tag first.
        local overflowTag = awful.tag.find_by_name(s, "Overflow")
        if not overflowTag then
            overflowTag = awful.tag.add("Overflow", {
                screen = s,
                layout = awful.layout.suit.fair,
                volatile = true,
            })
        end
        local overflowTag = awful.tag.find_by_name(s, "Overflow")
        -- If a tag with the target workspace name exists, move its windows to Overflow.
        local targetTag = awful.tag.find_by_name(s, workspaceName)
        if targetTag then
            for _, c in ipairs(targetTag:clients()) do
                c:move_to_tag(overflowTag)
            end
        else
            targetTag = awful.tag.add(workspaceName, {
                screen = s,
                layout = layoutFunc,
            })
        end

        targetTag.master_width_factor = config.master_width_factor or targetTag.master_width_factor

        -- STEP 1: Spawn any missing windows on the Overflow tag, accounting for duplicates.
        overflowTag:view_only()
        local savedCounts = {}
        for _, winRec in pairs(config.windowOrder) do
            savedCounts[winRec.class] = (savedCounts[winRec.class] or 0) + 1
        end

        local currentCounts = {}
        for _, c in ipairs(overflowTag:clients()) do
            if c.class then
                currentCounts[c.class] = (currentCounts[c.class] or 0) + 1
            end
        end

        for class, savedCount in pairs(savedCounts) do
            local currentCount = currentCounts[class] or 0
            if currentCount < savedCount then
                local missing = savedCount - currentCount
                local cmd = defaultApps[class:lower()] or class:lower()
                for i = 1, missing do
                    M.openNew(cmd,overflowTag)
                end
            end
        end
        
        -- STEP 1.5: Wait until all required windows have spawned on the Overflow tag.
        local function waitForAllWindows()
            local freqFound = {}
            for _, c in ipairs(overflowTag:clients()) do
                freqFound[c.class] = (freqFound[c.class] or 0) + 1
            end
            for class, reqCount in pairs(savedCounts) do
                local curCount = freqFound[class] or 0
                if curCount < reqCount then
                    return false
                end
            end
            return true
        end

        gears.timer.start_new(0.1, function()
            if not waitForAllWindows() then
                return true  -- continue polling
            end
            -- Once all windows are present, proceed to STEP 2.
            -- Before STEP 2: Order the saved window order as a numeric sequence.
            local orderedWindowOrder = {}
            for k, v in pairs(config.windowOrder) do
                local idx = tonumber(k)
                if idx then
                    table.insert(orderedWindowOrder, { index = idx, winRec = v })
                end
            end
            table.sort(orderedWindowOrder, function(a, b)
                return a.index < b.index
            end)

            -- STEP 2: Move matching windows from the Overflow tag (overflowTag) to the target tag.
            local usedClients = {}
            for _, entry in ipairs(orderedWindowOrder) do
                local winRec = entry.winRec
                local found = nil
                -- First, try an exact match: class and name.
                for _, c in ipairs(overflowTag:clients()) do
                    if not usedClients[c] and c.class == winRec.class and c.name == winRec.name then
                        found = c
                        usedClients[c] = true
                        break
                    end
                end
                -- If no exact match, try matching by class only.
                if not found then
                    for _, c in ipairs(overflowTag:clients()) do
                        if not usedClients[c] and c.class == winRec.class then
                            found = c
                            usedClients[c] = true
                            break
                        end
                    end
                end
                if found then
                    found:move_to_tag(targetTag)
                    awful.client.setslave(found)
                end
            end
        end)
        targetTag:view_only()
        local function isMasterFocused()
            current = client.focus
            if current ~= awful.client.getmaster() then
                awful.client.focus.byidx(1)
            else
                return true
            end
        end
        gears.timer.start_new(0.1, function()
            if not isMasterFocused() then
                return true  -- continue polling
            end
        end)
        gears.timer.delayed_call(M.centerMouseOnFocusedClient)
    end

    local folder = os.getenv("HOME") .. "/.config/awesome/workspaces/"
    local fullpath = folder .. wsName .. ".lua"
    loadOrder(fullpath, wsName)
end
--------------------------------
-- Save and load workspace configurations
--------------------------------



--------------------------------------------------------------------------------
-- Helper: Serialize a Lua table to a human-readable string.
--------------------------------------------------------------------------------
function M.serializeTable(val, name, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    local ret = ""
    if name then 
        ret = ret .. indent .. string.format("[%q] = ", tostring(name))
    end
    if type(val) == "table" then
        ret = ret .. "{\n"
        for k, v in pairs(val) do
            ret = ret .. M.serializeTable(v, tostring(k), depth + 1) .. ",\n"
        end
        ret = ret .. indent .. "}"
    elseif type(val) == "string" then
        ret = ret .. string.format("%q", val)
    else
        ret = ret .. tostring(val)
    end
    return ret
end


--------------------------------------------------------------------------------
-- Save Workspace Configuration:
-- Saves the current tag’s layout (by name), master width factor, and tiling order
-- (cycling through clients starting at the master) to a file.
--------------------------------------------------------------------------------
function M.saveWorkspaceConfiguration(optionalFilename)
    local s = awful.screen.focused()
    local t = s.selected_tag
    if not t then return nil end


    local order = {}
    local master = awful.client.getmaster() or t:clients()[1]
    if not master then return nil end
    local origFocus = client.focus
    client.focus = master
    order[1] = { class = master.class or "", name = master.name or "" }
    local current = master
    repeat
        awful.client.focus.byidx(1)
        current = client.focus
        if current and current ~= master then
            table.insert(order, { class = current.class or "", name = current.name or "" })
        end
    until current == master
    if origFocus then client.focus = origFocus end


    local layoutName = "unknown"
    for _, mapping in ipairs(layoutMapping) do
        if t.layout == mapping.func then
            layoutName = mapping.name
            break
        end
    end


    local config = {
        workspace = optionalFilename or "",
        layoutName = layoutName,
        master_width_factor = t.master_width_factor,
        windowOrder = order,
    }


    local folder = os.getenv("HOME") .. "/.config/awesome/workspaces/"
    os.execute("mkdir -p " .. folder)
    if optionalFilename then
        if not optionalFilename or optionalFilename == "" then return end
        config.workspace = optionalFilename
        local serialized = M.serializeTable(config, nil, 0)
        local filename = folder .. optionalFilename .. ".lua"
        local file = io.open(filename, "w")
        if file then
            file:write("return " .. serialized)
            file:close()
        end
    else
        awful.prompt.run({
            prompt = "Save workspace configuration as: ",
            textbox = s.mypromptbox.widget,
            exe_callback = function(input)
                if not input or input == "" then return end
                config.workspace = input
                local serialized = M.serializeTable(config, nil, 0)
                local filename = folder .. input .. ".lua"
                local file = io.open(filename, "w")
                if file then
                    file:write("return " .. serialized)
                    file:close()
                end
            end,
        })
    end
end


--------------------------------------------------------------------------------
-- Compare and Reorder:
-- Compares the saved window order (target) with the current tiling order on a tag,
-- swapping windows as needed so that the order matches the saved order.
--------------------------------------------------------------------------------
function M.compareAndReorder(savedOrder, t)
    -- Extract numeric keys from savedOrder, then sort them in descending order.
    local savedKeys = {}
    for k in pairs(savedOrder) do
        table.insert(savedKeys, tonumber(k))
    end


    table.sort(savedKeys)


    -- We'll iterate through whichever list is shorter (assuming same size, though).
    local len = #savedKeys
    naughty.notify({text="Number of windows: " .. tostring(len)})
    client.focus = awful.client.getmaster()
    for index = 1, len do
        local savedKey     = savedKeys[index]
        local desiredClass = savedOrder[tostring(savedKey)].class
        repeat
            awful.client.focus.byidx(1)
        until client.focus.class == desiredClass
        awful.client.setslave(client.focus)
    end
end


--------------------------------------------------------------------------------
-- Load Workspace Configuration:
-- Creates (or reuses) a tag with the saved layout and master width factor.
-- If a tag with the target workspace name already exists, its clients are moved
-- to an Overflow tag (volatile). Then, windows are moved (or spawned) onto the target tag.
-- Finally, the current order is saved to a compare file (with "_compare" appended)
-- and that compare order is compared with the saved order to swap windows as needed.
--------------------------------------------------------------------------------
function M.loadWorkspaceConfiguration(optionalFilename)
    local folder = os.getenv("HOME") .. "/.config/awesome/workspaces/"
    local wsName = optionalFilename  -- assume optionalFilename is the workspace name (without extension)
    local function loadOrder(file, wsName)
        local config = dofile(file)
        local s = awful.screen.focused()
        local workspaceName = wsName or config.workspace or "LoadedWorkspace"


        -- Determine the layout function using our mapping table.
        local layoutFunc = awful.layout.layouts[1]
        for _, mapping in ipairs(layoutMapping) do
            if mapping.name:lower() == (config.layoutName or ""):lower() then
                layoutFunc = mapping.func
                break
            end
        end


        -- Create (or get) the Overflow tag first.
        local overflowTag = awful.tag.find_by_name(s, "Overflow")
        if not overflowTag then
            overflowTag = awful.tag.add("Overflow", {
                screen = s,
                layout = awful.layout.suit.fair,
                volatile = true,
            })
        end
        local overflowTag = awful.tag.find_by_name(s, "Overflow")
        -- If a tag with the target workspace name exists, move its windows to Overflow.
        local targetTag = awful.tag.find_by_name(s, workspaceName)
        if targetTag then
            for _, c in ipairs(targetTag:clients()) do
                c:move_to_tag(overflowTag)
            end
        else
            targetTag = awful.tag.add(workspaceName, {
                screen = s,
                layout = layoutFunc,
            })
        end


        targetTag.master_width_factor = config.master_width_factor or targetTag.master_width_factor


        -- STEP 1: Spawn any missing windows on the Overflow tag, accounting for duplicates.
        overflowTag:view_only()
        local savedCounts = {}
        for _, winRec in pairs(config.windowOrder) do
            savedCounts[winRec.class] = (savedCounts[winRec.class] or 0) + 1
        end


        local currentCounts = {}
        for _, c in ipairs(overflowTag:clients()) do
            if c.class then
                currentCounts[c.class] = (currentCounts[c.class] or 0) + 1
            end
        end


        for class, savedCount in pairs(savedCounts) do
            local currentCount = currentCounts[class] or 0
            if currentCount < savedCount then
                local missing = savedCount - currentCount
                local cmd = defaultApps[class:lower()] or class:lower()
                for i = 1, missing do
                    M.openNew(cmd,overflowTag)
                end
            end
        end
        
        -- STEP 1.5: Wait until all required windows have spawned on the Overflow tag.
        local function waitForAllWindows()
            local freqFound = {}
            for _, c in ipairs(overflowTag:clients()) do
                freqFound[c.class] = (freqFound[c.class] or 0) + 1
            end
            for class, reqCount in pairs(savedCounts) do
                local curCount = freqFound[class] or 0
                if curCount < reqCount then
                    return false
                end
            end
            return true
        end


        gears.timer.start_new(0.1, function()
            if not waitForAllWindows() then
                return true  -- continue polling
            end
            -- Once all windows are present, proceed to STEP 2.
            -- Before STEP 2: Order the saved window order as a numeric sequence.
            local orderedWindowOrder = {}
            for k, v in pairs(config.windowOrder) do
                local idx = tonumber(k)
                if idx then
                    table.insert(orderedWindowOrder, { index = idx, winRec = v })
                end
            end
            table.sort(orderedWindowOrder, function(a, b)
                return a.index < b.index
            end)


            -- STEP 2: Move matching windows from the Overflow tag (overflowTag) to the target tag.
            local usedClients = {}
            for _, entry in ipairs(orderedWindowOrder) do
                local winRec = entry.winRec
                local found = nil
                -- First, try an exact match: class and name.
                for _, c in ipairs(overflowTag:clients()) do
                    if not usedClients[c] and c.class == winRec.class and c.name == winRec.name then
                        found = c
                        usedClients[c] = true
                        break
                    end
                end
                -- If no exact match, try matching by class only.
                if not found then
                    for _, c in ipairs(overflowTag:clients()) do
                        if not usedClients[c] and c.class == winRec.class then
                            found = c
                            usedClients[c] = true
                            break
                        end
                    end
                end
                if found then
                    found:move_to_tag(targetTag)
                    awful.client.setslave(found)
                end
            end
        end)
        targetTag:view_only()
        local function isMasterFocused()
            current = client.focus
            if current ~= awful.client.getmaster() then
                awful.client.focus.byidx(1)
            else
                return true
            end
        end
        gears.timer.start_new(0.1, function()
            if not isMasterFocused() then
                return true  -- continue polling
            end
        end)
        gears.timer.delayed_call(M.centerMouseOnFocusedClient)
    end


    local folder = os.getenv("HOME") .. "/.config/awesome/workspaces/"
    local fullpath = folder .. wsName .. ".lua"
    loadOrder(fullpath, wsName)
end

function M.openNew(appCmd, targetTag)
    awful.spawn.with_shell(appCmd)
    if targetTag then
        local function manage_callback(c)
            if not c._moved then
                c:move_to_tag(targetTag)
                c._moved = true
                client.disconnect_signal("manage", manage_callback)
                gears.timer.delayed_call(M.centerMouseOnNewWindow)
            end
        end
        client.connect_signal("manage", manage_callback)
    else
        gears.timer.delayed_call(M.centerMouseOnNewWindow)
    end
end

function M.openNew(appCmd, targetTag)
    awful.spawn.with_shell(appCmd)
    if targetTag then
        local function manage_callback(c)
            if not c._moved then
                c:move_to_tag(targetTag)
                c._moved = true
                client.disconnect_signal("manage", manage_callback)
                gears.timer.delayed_call(M.centerMouseOnNewWindow)
            end
        end
        client.connect_signal("manage", manage_callback)
    else
        gears.timer.delayed_call(M.centerMouseOnNewWindow)
    end
end
