--[[
    Main            Trystan Cannon
                    19 June 2015

        The main program for the layers system.
    Once this program is executed, a main startup thread
    is spawned under which the layers system lies. The
    startup thread executes the desired startup program,
    or Craft OS if no startup is specified, and waits
    for the user to call upon a layer.

        Because this program will be the startup program
    for the computer, the desired startup file should be
    saved as _startup for now. This may be subject to change.

        By default, the hotkey ALT + H opens a layer which
    lists all active layers and their respective hotkeys. To
    return to the base program while a layer is active, simply
    press home. This does however limit the kind of functionality
    possible within a layer, but the key value for returning
    is editable via the Layers namespace with the key 'nReturnKey.'

    TODO:
        + Make a whole god-damn GUI system -> buttons, etc.
        + Make a simple install script -> We need to make sure all directories/files are in place.
        ~ Maybe make a how-to-use animation like Windows 8 has, you know?

    AS ALWAYS:
        Use find and go to: "Main Entry Point" if you
        want to see where the magic happens :)
--Globals-----------------------------------------]]
-- Give an access point to the layers system through this program's environment.
_G.Layers      = getfenv()
sLayersHomeDir = "/Layers/" -- Root directory for the layers system.

nVesrion                 = 0.1
sStartupPath             = "/_startup"                 -- The path for the desired startup program.
sDefaultStartupPath      = "/rom/programs/shell"       -- The path for the default startup program; this is executed if no desired startup is found.
sLayersDirPath           = sLayersHomeDir .. "Layers/" -- Path for all "layers;" the programs that are loaded as layers.
sLayersLogPath           = sLayersHomeDir .. "Log"     -- Path for the layers system log. This is recreated each time the system starts up.
tBaseTerminal            = term.current()              -- The base terminal object to which everything is ultimately drawn.
nHotkeyTimeoutTime       = 0.25                        -- The amount of time between an ALT press and when the program stops listening for a hotkey.
nReturnKey               = keys.home                   -- The key that is pressed to minimize a layer and return to the base program.
sFrontLayerRequestEvent  = "Front Layer Request"       -- The event name that signifies a layer requesting to be the front layer.
--APIs--------------------------------------------
os.loadAPI(sLayersHomeDir .. "Buffer")
--generateEnvironment-----------------------------
--[[
    Creates and returns an environment table with access to the _G table
    and the original shell api.

    This is used primarily for providing a traditional environment table
    for functions for which a coroutine is spawned; typically, a function
    loaded using 'loadfile' will not have access to these critical components
    if it is not given them explicitly, making normal operation difficult and
    requiring unnecessary environment manipulation from within the program.
]]
local function generateEnvironment()
    return setmetatable({ shell = shell }, { __index = _G })
end
--createThread------------------------------------
--[[
    Creates and returns a coroutine with the appropriate environment
    variables to ensure normal operation (shell api and _G table access) for
    the program at the given path.

    If there is no program at the path provided, then 'nil' is returned.

    sFilePath
        The path to the program for which the thread is spawned.
]]
local function createThread(sFilePath)
    if not fs.exists(sFilePath) or fs.isDir(sFilePath) then
        return nil
    end

    return coroutine.create(
        setfenv(loadfile(sFilePath), generateEnvironment())
    )
end
--loadLayers--------------------------------------
--[[
    Loads all of the layers at the given location, placing
    them into the given container. Each loaded layer is placed
    into the table with a numerical key.

    Layers possess their own name and use their function address
    from memory as a unique id.

    If a layer fails to load, then it is simply not placed into
    the container table.

    tContainer
        The table into which the loaded layers are placed.
    sLayersPath
        The path at which the layer programs should be located.
]]
local function loadLayers(tContainer, sLayersPath)
    if not fs.isDir(sLayersPath) or type(tContainer) ~= "table" then
        return
    end

    for _, sFileName in pairs(fs.list(sLayersPath)) do
        local fLayer = loadfile(sLayersPath .. '/' .. sFileName)

        if fLayer then
            setfenv(fLayer, generateEnvironment())
            local bSuccess, tLayer = pcall(fLayer)

            if bSuccess and tLayer then
                table.insert(tContainer, tLayer)
                print(tLayer:getName() .. " loaded.")
            end
        end
    end

    print("Pausing for readability...")
    sleep(1)
end
--isHotkey----------------------------------------
--[[
    Checks if the given key value is a hotkey for
    any of the layers contained with the given table.

    tLayers
        Layers whose hotkeys will be checked.
    nKey
        The key to check.
]]
local function isHotkey(tLayers, nKey)
    for _, tLayer in ipairs(tLayers) do
        if tLayer.nHotkey == nKey then
            return tLayer
        end
    end
end
--distributeEvents--------------------------------
--[[
    Distributes the given event data to all of the
    layers within the given table.

    Layers which receive events must be registered for
    them or be currently summoned.

    tLayers
        The layers which may receive events.
    tEventData
        The event data to distribute.
]]
local function distributeEvents(tLayers, tEventData)
    for _, tLayer in ipairs(tLayers) do
        if tLayer:isSummoned() or tLayer:isEventRegistered(tEventData[1]) then
            tLayer:update(unpack(tEventData))
        end
    end
end
--Main Entry Point--------------------------------
local SCREEN_WIDTH, SCREEN_HEIGHT = term.native().getSize()
local tMainBuffer                 = Buffer.new(SCREEN_WIDTH, SCREEN_HEIGHT, 1, 1, term.current()) -- Central screen buffer for all drawing to the screen.

-- Setup the buffer to draw to the screen at the same time as it writes to itself.
--tMainBuffer:clear(true)

local cStartupThread      = createThread(sStartupPath) or createThread(sDefaultStartupPath) -- Thread for the desired startup program. 'nil' if there is none.
local tFrontLayer         = nil                                                             -- The currently focused layer. This will be 'nil' if there is none.
local tLayers             = {}                                                              -- All "layers" that are currently alive.

-- Load layers from the layers directory. Layers that failed to load will be receive
-- a log entry, but their failure will not crash the program. Simply, they will not
-- appear or be useable.
loadLayers(tLayers, sLayersDirPath)

term.redirect(tMainBuffer:redirect())
print("Terminal redirected to buffer.")
-- Initialize the startup thread.
coroutine.resume(cStartupThread)

term.redirect(tBaseTerminal)
tMainBuffer:render()

local bIsRunning = coroutine.status(cStartupThread) ~= "dead" -- Whether or not the underlying startup thread is still running.

-- Main program loop: executes as long as the startup thread is alive.
while bIsRunning do
    term.redirect(tMainBuffer:redirect())
    local tEventData = { os.pullEvent() }

    if tEventData[1] == sFrontLayerRequestEvent and tEventData[2] ~= tFrontLayer and isRequestOriginal(tFrontLayerRequests, tEventData[2]) then
        table.insert(tFrontLayerRequests, tEventData[2])
    end

    -- Alt pressed -> Hotkey inbound, maybe.
    if tEventData[1] == "key" and (tEventData[2] == keys.leftAlt or tEventData[2] == keys.rightAlt) then
        --[[
            Hotkey system:
                Alt pressed -> start a short timer to wait for the hotkey to be pressed
                Catch any events being fired while the timer runs
                Distribute non-hotkey or hotkey timer events back to the startup thread
                Hotkey pressed?
                    Do hotkey stuff
                Hotkey timer fires?
                    Maybe remove alt key press. However, it could have been intended.
                    Break the loop and return to normal functions.
        ]]

        local tHotkeyTimer = os.startTimer(nHotkeyTimeoutTime)
        local _tEventData  = { os.pullEvent() }

        while not (_tEventData[1] == "timer" and _tEventData[2] == tHotkeyTimer) do
            local tLayerSummoned = isHotkey(tLayers, _tEventData[2]) -- 'nil' if there was no corresponding hotkey.

            if _tEventData[1] == "key" and tLayerSummoned then
                -- Make sure the catch feature times out after a very short period to prevent the
                -- computer from hanging. There's probably a MUCH better way to do this.
                local tCatchTimer = os.startTimer(0.1)

                -- Attempt to catch the stray 'char' event that fires when a letter key is pressed.
                -- However, if the event caught is not a 'char' then we'll requeue it.
                local tCaughtEvent = { os.pullEvent() }
                if tCaughtEvent[1] ~= "char" and tCaughtEvent[1] ~= "timer" and tCaughtEvent[2] ~= tCatchTimer then
                    os.queueEvent(unpack(tCaughtEvent))
                end

                -- Summon the layer.
                tLayerSummoned:summon()
                tFrontLayer = tLayerSummoned

                -- Nullify the event.
                tEventData = {}
                break
            end

            coroutine.resume(cStartupThread, unpack(_tEventData))
            _tEventData = { os.pullEvent() }
        end
    end

    --[[
        Prevailing hypothesis:
            The redirection code in the Buffer API is not written properly for recording.
            Or, you know, something could be happening as the layers attempt to draw to
            the base terminal, affecting the main buffer somehow. Or, the user sees a change
            in the base terminal which the main buffer does not reflect. Something doesn't
            redirect properly...
    ]]

    -- Layer brought to the front.
    while tFrontLayer ~= nil do
        local tLayerEventData = { os.pullEvent() }

        if tLayerEventData[1] == "key" and tLayerEventData[2] == nReturnKey then
            -- Refresh the screen to clear away the layer.
            tFrontLayer:hide()
            tFrontLayer = nil

            break
        end

        distributeEvents(tLayers, tLayerEventData)
    end

    coroutine.resume(cStartupThread, unpack(tEventData))
    term.redirect(tBaseTerminal) -- This is probably unnecessary.
    tMainBuffer:render()

    distributeEvents(tLayers, tEventData)

    -- Update the health of the system. However, if something has already killed us
    -- (set bIsRunning to false), then do not change the status.
    bIsRunning = bIsRunning and coroutine.status(cStartupThread) ~= "dead"
end

term.redirect(tMainBuffer.tTerm) -- Just in case.
print("Terminal restored.")
--------------------------------------------------