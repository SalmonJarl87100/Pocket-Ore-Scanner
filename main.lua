local basalt = require("basalt")
local geoScanner, playerDetector

local CWD = arg[1]


local function getBlockNames()
    if not fs.exists(CWD .. "/block names.txt") then
        -- create new block names file with default data
        local writer = fs.open(CWD .. "/block names.txt", "w")
        writer.write("{}")
        writer.close()

        return {}

    else
        -- get saved block names
        local reader = fs.open(CWD .. "/block names.txt", "r")
        local blockNames = textutils.unserialise(reader.readAll())
        reader.close()

        return blockNames
    end
end

local function equipScanner()
    -- attempt to wrap scanner
    geoScanner = peripheral.wrap("back")

    -- equip a peripheral if none exists
    if not geoScanner then
        pocket.equipBack()
        geoScanner = peripheral.wrap("back")
    end

    -- loop through peripherals until geo scanner is found
    while peripheral.getMethods("back")[3] ~= "cost" do
        -- equip new peripheral
        pocket.equipBack()
        -- attempt to wrap geoscanner
        geoScanner = peripheral.wrap("back")
    end
end

local function equipPlayerDetector()
    -- attempt to wrap player detector
    playerDetector = peripheral.wrap("back")
  
    while peripheral.getMethods("back")[3] ~= "getOnlinePlayers" do
      print("G")
      -- equip new peripheral
      pocket.equipBack()
      -- attempt to wrap geoscanner
      playerDetector = peripheral.wrap("back")
    end
  end

local function getUniqueBlocks(blocksTable)
    local encounteredBlocks = {}
    local uniqueBlocks = {}

    for _, block in ipairs(blocksTable) do
        if not encounteredBlocks[block.name] then
            table.insert(uniqueBlocks, block.name)
        end

        encounteredBlocks[block.name] = true
    end

    return uniqueBlocks
end

local function main()
    local root = basalt.createFrame()

    local playerName

    -- get player name if save file exists
    if fs.exists(CWD .. "/player.txt") then
        local reader = fs.open(CWD .. "/player.txt", "r")
        playerName = reader.readAll()
        reader.close()
    end

    -- nil check root
    if not root then
        return
    end

    local frames = {
        root:addFrame("scannerFrame"):setPosition(1, 2):setSize("parent.w", "parent.h - 1"):setBackground(colors.lightGray), -- frame that holds the scanner window
        root:addFrame("toggleFrame"):setPosition(1, 2):setSize("parent.w", "parent.h - 1"):setBackground(colors.lightGray):hide(), -- frame to select which block to scan for
        root:addFrame("registerFrame"):setPosition(1, 2):setSize("parent.w", "parent.h - 1"):setBackground(colors.lightGray):hide() -- frame to add blocks to toggle list
    }

    -- menu bar to switch between tabs
    root:addMenubar():setSize("parent.w", 1):setPosition(1, 1):addItem("Scanner"):addItem("Toggle"):addItem("Register"):onChange(function (self)
        local index = self:getItemIndex()

        if(frames[index]~=nil)then
            for k,v in pairs(frames)do
                v:hide()
            end
            frames[index]:show()
        end
    end)

    -- Scanner Frame --

    local scanProgram = frames[1]:addProgram():setPosition(1, 2):setSize("parent.w", "parent.h - 4")

    local startButton, stopButton

    local function startScanner(targetName, radius, username)
        -- equip playerDetector
        equipPlayerDetector()

        -- get list of online players
        local players = playerDetector:getOnlinePlayers()

        -- check if given username is online
        local isValidUsername = false
        for _, player in ipairs(players) do
            if player == username then
                isValidUsername = true
            end
        end

        if isValidUsername then
            -- hide start button
            startButton:hide()

            -- show stop button
            stopButton:show()

            -- start scanning program
            scanProgram:execute(function ()
            shell.run(CWD .. "/scanner.lua", targetName, radius, username)
            end)

        else
            -- tell user to provide a valid username
            scanProgram:execute(function ()
                print('"' .. username .. '" is not a valid username.')
            end)
        end
    end

    stopButton = frames[1]:addButton():setPosition(1, "parent.h - 2"):setText("Stop"):setSize(6, 3):setBackground(colors.red):hide()

    startButton = frames[1]:addButton():setPosition(1, "parent.h - 2"):setText("Start"):setSize(7, 3):setBackground(colors.lime)

    frames[1]:addLabel():setPosition(9, "parent.h - 2"):setText("Radius:")
    local radiusLabel = frames[1]:addLabel():setPosition(9, "parent.h - 1"):setText("8")
    local radiusSlider = frames[1]:addSlider():setPosition(12, "parent.h - 1"):setMaxValue(15):setIndex(8):setSize(15, 1)

    stopButton:onClick(function (self, event, button)
        if event == "mouse_click" and button == 1 then
            -- change button color
            self:setBackground(colors.black)
            -- change button text color
            self:setForeground(colors.white)

            -- stop scanning program
            scanProgram:stop()

            -- clear program output
            scanProgram:execute(function ()
                shell.run("clear")
            end)

            -- hide stop button
            self:hide()

            -- show start button
            startButton:show()
        end
    end):onRelease(function (self)
        -- reset stop button colors
        self:setBackground(colors.red)
        self:setForeground(colors.black)
    end)

    -- Toggle Frame --
    local longestBlockName = ""

    local blockNamesFrame = frames[2]:addFrame("blockNamesFrame"):setPosition(2, 2):setTheme({FrameBG = colors.gray, FrameFG = colors.black}):setSize("parent.w - 2", "parent.h - 5")

    -- get saved block names from save file
    local blockNames = getBlockNames()

    -- scrollbar to scroll through frame
    local blockFrameScroll = frames[2]:addScrollbar():setPosition("blockNamesFrame.x + blockNamesFrame.w", "blockNamesFrame.y"):setSize(1, "blockNamesFrame.h"):hide():onChange(function (self, _, value)
        local scrollIndex = self:getIndex()
        local xOffset, _ = blockNamesFrame:getOffset()

        if scrollIndex == 1 then
            blockNamesFrame:setOffset(xOffset, 0)

        else
            blockNamesFrame:setOffset(xOffset, math.floor(self:getIndex() / self:getHeight() * (#blockNames - blockNamesFrame:getHeight() + 2)))
        end
    end)
    if #blockNames > blockNamesFrame:getHeight() - 1 then
        blockFrameScroll:show()
    end

    -- scrollbar to scroll through frame
    local horizontalNameScroll = frames[2]:addScrollbar():setPosition("blockNamesFrame.x", "blockNamesFrame.y + blockNamesFrame.h"):setBarType("horizontal"):hide():setSize("blockNamesFrame.w", 1):onChange(function (self)
        local scrollIndex = self:getIndex()
        local _, yOffset = blockNamesFrame:getOffset()

        if scrollIndex == 1 then
            blockNamesFrame:setOffset(0, yOffset)

        else
            blockNamesFrame:setOffset(math.floor(self:getIndex() / self:getWidth() * (string.len(longestBlockName) - blockNamesFrame:getWidth() + 4)), yOffset)
        end
    end)

    -- list of block names for user to choose
    local blockNamesList = blockNamesFrame:addList():setPosition(4, 2)

    -- table to store buttons to remove block names
    local deleteNameButtons = {}

    local function displayBlockNames()
        -- clear block names list
        blockNamesList:clear()

        -- remove all existing delete buttons
        for _, button in ipairs(deleteNameButtons) do
            button:remove()
        end

        -- reset frame offset
        blockNamesFrame:setOffset(0, 0)

        -- clear delete button list
        deleteNameButtons = {}

        -- reset longest block name tracker
        longestBlockName = ""

        -- reset scrollbars index
        blockFrameScroll:setIndex(1)
        horizontalNameScroll:setIndex(1)

        for index, blockName in ipairs(blockNames) do
            -- keep track of which block has the longest name
            if string.len(blockName) > string.len(longestBlockName) then
                longestBlockName = blockName
            end

            -- add list option
            blockNamesList:addItem(blockName)

            -- button to remove item name from list
            deleteNameButtons[index] = blockNamesFrame:addButton()
                :setPosition(2, index + 1)
                :setText("X")
                :setBackground(colors.red)
                :setSize(1, 1)
            :onClick(function (self, event, button)
                if event == "mouse_click" and button == 1 then
                    -- remove item 
                    table.remove(blockNames, index)

                    -- save block names
                    local writer = fs.open(CWD .. "/block names.txt", "w")
                    writer.write(textutils.serialise(blockNames))
                    writer.close()

                    -- remake name list
                    displayBlockNames()
                end
            end)
        end

        -- set name list size to the number of blocks saved and the length of longest block name
        blockNamesList:setSize(string.len(longestBlockName), #blockNames)

        -- show or hide horizontal scrollbar if needed
        if string.len(longestBlockName) + 4 > blockNamesFrame:getWidth() then
            horizontalNameScroll:show()

        else
            horizontalNameScroll:hide()
        end

        -- show or hide scrollbar if needed
        if #blockNames + 2 > blockNamesFrame:getHeight() then
            blockFrameScroll:show()

        else
            blockFrameScroll:hide()
        end
    end

    displayBlockNames()

    startButton:onClick(function (self, event, button)
        if event == "mouse_click" and button == 1 then
           -- change button color
            self:setBackground(colors.green)

            if not blockNamesList:getItemIndex() then
                return
            end

            -- start scanning program
            startScanner(blockNames[blockNamesList:getItemIndex()], radiusSlider:getIndex(), playerName)

            -- -- hide start button
            -- self:hide()

            -- -- show stop button
            -- stopButton:show()
        end
    end):onRelease(function (self)
        -- reset button color
        self:setBackground(colors.lime)
    end)

    blockNamesList:onChange(function (self)
        if not (scanProgram:getStatus() == "inactive" or scanProgram:getStatus() == "dead") then
            -- stop scanner
            scanProgram:stop()

            -- relaunch scanner with newly selected block
            scanProgram:execute(function ()
                shell.run(CWD .. "/scanner.lua", blockNames[self:getItemIndex()], radiusSlider:getIndex(), playerName)
            end)
        end
    end)

    radiusSlider:onChange(function (self)
        -- update radius label with current radius
        radiusLabel:setText(self:getIndex())

        -- restart scan program if it's running
        if not (scanProgram:getStatus() == "inactive" or scanProgram:getStatus() == "dead") and blockNamesList:getItemIndex() then
            scanProgram:stop()
            startScanner(blockNames[blockNamesList:getItemIndex()], self:getIndex(), playerName)
        end
    end)

    -- player name label
    frames[2]:addLabel():setText("Player Name:"):setPosition(2, 18)

    local playerNameEtry = frames[2]:addInput():setPosition(14, 18):setSize(12, 1):onChange(function (self, event, value)
        playerName = self:getValue()

        local writer = fs.open(CWD .. "/player.txt", "w")
        writer.write(playerName)
        writer.close()
    end)

    -- set the default value for player name entry
    if playerName then
        playerNameEtry:setValue(playerName)
    end

    -- Register Frame --

    -- block name input label
    frames[3]:addLabel("registerNameLabel"):setPosition(2, 2):setText("Name:")
    local registerNameInput = frames[3]:addInput("registerNameInput"):setPosition("registerNameLabel.w + 2", 2):setSize("parent.w - registerNameLabel.w - 5", 1)

    -- add name button
    frames[3]:addButton():setPosition("registerNameLabel.w + registerNameInput.w + 3", 2):setText("Add"):setSize(3, 1):setBackground(colors.lime)
        :onClick(function (self, event, button)
            if event == "mouse_click" and button == 1 then
                self:setBackground(colors.green)

                -- add new block name to block names table
                table.insert(blockNames, registerNameInput:getValue())

                -- clear register name input
                registerNameInput:setValue("")

                -- save block names
                local writer = fs.open(CWD .. "/block names.txt", "w")
                writer.write(textutils.serialise(blockNames))
                writer.close()

                -- display new block name
                displayBlockNames()

                if #blockNames > blockNamesFrame:getHeight() - 1 then
                    blockFrameScroll:show()
                end
            end
        end)
    :onRelease(function (self)
        self:setBackground(colors.lime)
    end)

    -- button to get a scan sample
    local sampleButton = frames[3]:addButton("sampleButton"):setPosition(2, 4):setText("Sample"):setSize(8, 3)

    -- slider label
    frames[3]:addLabel("sampleSliderLabel"):setPosition("sampleButton.x + sampleButton.w + 1", "sampleButton.y"):setText("Radius:")

    -- label to display slider value
    local sampleRadiusLabel = frames[3]:addLabel():setPosition("sampleSliderLabel.x", "sampleSliderLabel.y + 1"):setText("2")
    local sampleRadiusSlider = frames[3]:addSlider():setPosition("sampleSliderLabel.x + 2", "sampleSliderLabel.y + 1"):setSize(14, 1):setIndex(2):onChange(function (self)
        -- update slider label
        sampleRadiusLabel:setText(tostring(self:getIndex()))
    end)

    local sampleFrame = frames[3]:addFrame("sampleFrame"):setPosition(2, 8):setScrollable():setTheme({FrameBG = colors.gray, FrameFG = colors.black}):setSize("parent.w - 2", 11)

    local sampleNames = {}

    local sampleLabels = {}

    local addSampleButtons = {}

    local longestSampleName = ""

    -- scrollbar to scroll through frame
    local sampleScroll = frames[3]:addScrollbar():setPosition("sampleFrame.x + sampleFrame.w", "sampleFrame.y"):setSize(1, "sampleFrame.h"):hide():onChange(function (self)
        local scrollIndex = self:getIndex()
        local xOffset, _ = sampleFrame:getOffset()

        if scrollIndex == 1 then
            sampleFrame:setOffset(xOffset, 0)

        else
            sampleFrame:setOffset(xOffset, math.floor(self:getIndex() / self:getHeight() * (#sampleNames - sampleFrame:getHeight() + 2)))
        end
    end)

    -- scrollbar to navigate list of names given from sample scan
    local horizontalSampleScroll = frames[3]:addScrollbar():setPosition("sampleFrame.x", "sampleFrame.y + sampleFrame.h"):setSize("sampleFrame.w", 1):setBarType("horizontal"):hide():onChange(function (self)
        local scrollIndex = self:getIndex()
        local _, yOffset = sampleFrame:getOffset()

        if scrollIndex == 1 then
            sampleFrame:setOffset(0, yOffset)

        else
            sampleFrame:setOffset(math.floor(self:getIndex() / self:getWidth() * (string.len(longestSampleName) - sampleFrame:getWidth() + 6)), yOffset)
        end
    end)

    local function displaySampleNames(blocksTable)
        -- remove existing labels
        for _, label in ipairs(sampleLabels) do
            label:remove()
        end

        -- remove existing add buttons
        for _, button in ipairs(addSampleButtons) do
            button:remove()
        end

        -- reset frame offset
        sampleFrame:setOffset(0, 0)

        -- reset sample block name tracker
        longestSampleName = ""

        -- reset index of scrollbars
        sampleScroll:setIndex(1)
        horizontalSampleScroll:setIndex(1)

        for index, name in ipairs(blocksTable) do
            -- keep track of which block name is longest
            if string.len(name) > string.len(longestSampleName) then
                longestSampleName = name
            end

            -- add block name label
            sampleLabels[index] = sampleFrame:addLabel()
                :setPosition(6, index + 1)
            :setText(name)

            -- add button to add block name to saved list
            addSampleButtons[index] = sampleFrame:addButton()
                :setPosition(2, index + 1)
                :setText("Add")
                :setSize(3, 1)
                :setBackground(colors.lime)
                :onClick(function (self, event, button)
                    if event == "mouse_click" and button == 1 then
                        self:setBackground(colors.green)

                        -- add block name to block names table
                        table.insert(blockNames, name)

                        -- save block names
                        local writer = fs.open(CWD .. "/block names.txt", "w")
                        writer.write(textutils.serialise(blockNames))
                        writer.close()

                        -- remake block names list
                        displayBlockNames()
                    end
                end)
            :onRelease(function (self)
                self:setBackground(colors.lime)
            end)
        end

        -- show or hide horizontal scrollbar if needed
        if string.len(longestSampleName) + 6 > sampleFrame:getWidth() then
            horizontalSampleScroll:show()

        else
            horizontalSampleScroll:hide()
        end

        -- display or hide scroll bar if needed
        if #sampleNames > sampleFrame:getHeight() - 1 then
            sampleScroll:show()

        else
            sampleScroll:hide()
        end

    end

    -- button to scan block names to register
    sampleButton:onClick(function (self, event, button)
        if event == "mouse_click" and button == 1 then
            self:setBackground(colors.black)
            self:setForeground(colors.white)

            -- stop scanner program
            scanProgram:stop()
            scanProgram:execute(function ()
                shell.run("clear")
            end)

            -- hide stop button and show start buttons
            stopButton:hide()
            startButton:show()

            -- make sure geo scanner is equipped
            equipScanner()

            -- continue to scan until block data is returned
            local blockData
            while not blockData do
                blockData = geoScanner.scan(sampleRadiusSlider:getIndex())
            end

            -- filter out repeat block names
            sampleNames = getUniqueBlocks(blockData)

            -- display sample block names
            displaySampleNames(sampleNames)
        end
    end):onRelease(function (self)
        self:setBackground(colors.gray)
        self:setForeground(colors.black)
    end)

    basalt.autoUpdate()
end

main()
