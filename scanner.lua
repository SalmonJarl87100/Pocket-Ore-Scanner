local Pine3D = require("Pine3D")
local models = Pine3D.models

local geoscanner
local function equipScanner()
  -- equip new peripheral
  pocket.equipBack()

  -- attempt to wrap scanner
  geoscanner = peripheral.wrap("back")

  -- loop through peripherals until geo scanner is found
  while peripheral.getMethods("back")[3] ~= "cost" do
      -- equip new peripheral
      pocket.equipBack()
      -- attempt to wrap geoscanner
      geoscanner = peripheral.wrap("back")
  end
end

-- ensure geoscanner is equiped first
equipScanner()

-- define player detector object variable
local playerDetector

-- create a new frame
local ThreeDFrame = Pine3D.newFrame()

-- initialize our own camera and update the frame camera
local camera = {
  x = 0,
  y = 1,
  z = 0,
  rotX = 0,
  rotY = 0,
  rotZ = 0,
}
ThreeDFrame:setCamera(camera)

-- define the objects to be rendered
local objects = {}

local filter = {
  [arg[1]] = true,
  ["end"] = true
}

-- function names
local getBlocks, filterBlocks, equipPlayerDetector, getHeadFacing, convertYaw, makeVBlocks

-- player name to use with player detector
local playerName = arg[3]

-- scan radius to use with geoScanner
local scanRadius = tonumber(arg[2])

-- scanned blocks table
local blocks

-- handle game logic
local function handleGameLogic(dt)
  -- get the position of the players head
  local headPitch, headYaw = getHeadFacing()

  -- set camera rotation to player head rotation
  camera.rotZ = headPitch
  camera.rotY = headYaw

  -- update virtual camera
  ThreeDFrame:setCamera(camera)

  -- scan for blocks
  blocks = getBlocks()

  -- if scan worked store results
  if blocks then
    objects = makeVBlocks(blocks)
  end

  sleep(0.5)
end

-- handle the game logic and camera movement in steps
local function gameLoop()
  local lastTime = os.clock()

  while true do
    -- compute the time passed since last step
    local currentTime = os.clock()
    local dt = currentTime - lastTime
    lastTime = currentTime

    -- run all functions that need to be run
    handleGameLogic(dt)
    -- handleCameraMovement(dt)

    -- use a fake event to yield the coroutine
    os.queueEvent("gameLoop")
    os.pullEventRaw("gameLoop")
  end
end

-- render the objects
local function rendering()
  while true do
    -- load all objects onto the buffer and draw the buffer
    ThreeDFrame:drawObjects(objects)
    ThreeDFrame:drawBuffer()

    -- use a fake event to yield the coroutine
    os.queueEvent("rendering")
    os.pullEventRaw("rendering")
  end
end

function getBlocks()
  -- make sure scanner is equiped
  equipScanner()

  -- scan blocks
  local tempBlocks = geoscanner.scan(scanRadius)

  -- if block scan succeded return filtered results else return nil
  if tempBlocks then
    tempBlocks = filterBlocks(tempBlocks, filter)

    return tempBlocks

  else
    return nil
  end
end

function filterBlocks(blocksTable, filterTable)
  -- table for blocks that match given filter
  local filteredBlocks = {}

  -- find all blocks matching filter
  for _, block in ipairs(blocksTable) do
    if filterTable[block.name] then
      table.insert(filteredBlocks, block)
    end
  end

  -- return filtered blocks
  return filteredBlocks
end

function equipPlayerDetector()
  -- attempt to wrap player detector
  playerDetector = peripheral.wrap("back")

  -- equip a peripheral if none exists
  if not playerDetector then
    pocket.equipBack()
    playerDetector = peripheral.wrap("back")
  end

  while peripheral.getMethods("back")[3] ~= "getOnlinePlayers" do
    -- equip new peripheral
    pocket.equipBack()
    -- attempt to wrap geoscanner
    playerDetector = peripheral.wrap("back")
  end
end

function getHeadFacing()
  -- make sure player detector is equiped
  equipPlayerDetector()

  -- get player position data from player detector
  local playerPos = playerDetector.getPlayerPos(playerName)

  -- return converted head data
  return -playerPos.pitch, convertYaw(playerPos.yaw)
end

function convertYaw(yaw)
  if yaw >= -90 and yaw <= 180 then
      return yaw + 90

  else
      return 450 + yaw
  end
end

function makeVBlocks(realBlocks)
  local tempObjects = {}

  -- make virtual blocks at coordinates of real blocks
  for _, block in ipairs(realBlocks) do
    table.insert(tempObjects, ThreeDFrame:newObject(models:cube({color = colors.orange, top = colors.blue, bottom = colors.brown}), block.x, block.y, block.z))
  end

  return tempObjects
end

-- start the functions to run in parallel
parallel.waitForAny(gameLoop, rendering)
