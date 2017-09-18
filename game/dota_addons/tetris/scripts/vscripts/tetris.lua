require("libraries/util")
require("libraries/timers")
require("libraries/notifications")
require("libraries/list")
require("cell")
require("tetramino")
require("debugf")

TETRIS = class({}, {
    ACTION = {
        SINGLE = 1,
        DOUBLE = 2,
        TRIPLE = 3,
        TETRIS = 4,
        TSPIN = 5,
        TSPIN_SINGLE = 6,
        TSPIN_DOUBLE = 7,
        TSPIN_TRIPLE = 8
    }
})

function TETRIS:constructor(index)
    print ("TETRIS constructor")
    self.index = index
    self.rows = 22
    self.cols = 10
    self.spawnOrigin = CELL(self, 1, 4)
    self.grid = {}
    for r = 1, self.rows do
        local row = {}
        for c = 1, self.cols do
            table.insert(row, CELL(self, r, c))
        end
        table.insert(self.grid, row)
    end
    
    self.activeTetramino = nil
    self.timer = nil
    self.gravity = 0.05
    self.level = 1
    self.linesCleared = 0
    self.linesPerLevel = 10
    self.linesToNextLevel = 0
    self.maxLevel = 10
    self.lockDelay = 0.5
    self.time = GameRules:GetGameTime()
    self.score = 0
    self.lockTime = nil
    self.dropped = false
    self.ghost = nil
    self.inputQueue = List()
    self.heldTetramino = nil
    self.holdUsed = false
    self.sourceTetraminos = List({"I", "J", "L", "O", "S", "T", "Z"})
    self.pendingTetraminos = List()
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    
    self.tSpin = false
    self.lastAction = nil
    self.softDropCount = 0
    self.hardDropCount = 0
    
    self:Spawn()
end

function TETRIS:GetCell(r, c)
    if r >= 1 and r <= self.rows and c >= 1 and c <= self.cols then
        return self.grid[r][c]
    else
        return CELL(self, r, c, CELL.STATE.INVALID)
    end
end

function TETRIS:Spawn()
    -- print ("Spawn")
    self.activeTetramino = TETRAMINOS[self.pendingTetraminos:Shift()](self, self.spawnOrigin)
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    if self.sourceTetraminos:Size() == 0 then
        self.sourceTetraminos = List({"I", "J", "L", "O", "S", "T", "Z"})
        self.sourceTetraminos:Shuffle()
    end
    self.lockTime = nil
    
    if not self.activeTetramino:IsValid() then
        self:EndGame()
    end
end

function TETRIS:EndGame()
    print("EndGame")
    Notifications:TopToAll({text="#game_over", duration=1})
    if self.timer ~= nil then
        Timers:RemoveTimer(self.timer)
        self.timer = nil
    end
end

function TETRIS:Lock()
    -- print ("Lock")
    self.activeTetramino:Lock()
end

function TETRIS:Rotate()
    self.activeTetramino:Rotate()
end

function TETRIS:Start()
    self.timer = Timers:CreateTimer(function ()
        self:Run()
        return 0.01
    end, self)
end

function TETRIS:GetDelay()
    return (self.maxLevel + 1 - self.level) * self.gravity
end

function TETRIS:Run()
    -- print("TETRIS:Run")
    while self.inputQueue:Size() > 0 do
        self:HandleInput()
    end
    local tetramino = self.activeTetramino
    local now = GameRules:GetGameTime()
    if now - self.time >= self:GetDelay() then
        self.time = now
        tetramino:Clear()
        tetramino:Down()
        if not tetramino:IsValid() then
            tetramino:Up()
            if self.lockTime == nil then
                self.lockTime = GameRules:GetGameTime()
                tetramino:Set()
            end
        else
            self.lockTime = nil
            tetramino:Set()
        end
    end
    
    if self.dropped or (self.lockTime ~= nil and now - self.lockTime >= self.lockDelay) then
        if tetramino:IsTSpin() then
            self.tSpin = true
        end
        tetramino:Lock()
        self:ClearLines()
        self:Spawn()
        self.dropped = false
        self.holdUsed = false
    else
        tetramino:Set()
    end
    
    if self.ghost then
        self.ghost:ClearGhost()
    end
    self.ghost = tetramino:Copy()
    while self.ghost:IsValid() do
        self.ghost:Down()
    end
    self.ghost:Up()
    self.ghost:SetGhost()
    
    self:CalculateScore()
    
    self:NetworkState()
end

function TETRIS:CalculateScore()
    self.score = self.score + self.softDropCount
    self.score = self.score + self.hardDropCount * 2
    
    local value = 0
    if not self.tSpin then
        -- single
        if self.linesCleared == 1 then
            value = 100 * self.level
            self.lastAction = TETRIS.ACTION.SINGLE
            Notifications:TopToAll({text="#single", duration=0.5})
        -- double
        elseif self.linesCleared == 2 then
            value = 300 * self.level
            self.lastAction = TETRIS.ACTION.DOUBLE
            Notifications:TopToAll({text="#double", duration=0.5})
        -- triple
        elseif self.linesCleared == 3 then
            value = 500 * self.level
            self.lastAction = TETRIS.ACTION.TRIPLE
            Notifications:TopToAll({text="#triple", duration=0.5})
        -- tetris
        elseif self.linesCleared == 4 then
            -- back to back
            if self.lastAction == TETRIS.ACTION.TETRIS then
                value = 1200 * self.level
                Notifications:TopToAll({text="#b2b_tetris", duration=0.5})
            else
                value = 500 * self.level
                Notifications:TopToAll({text="#tetris", duration=0.5})
            end
            self.lastAction = TETRIS.ACTION.TETRIS
        end
    else
        -- tspin single
        if self.linesCleared == 0 then
            value = 400 * self.level
            self.lastAction = TETRIS.ACTION.TSPIN
            Notifications:TopToAll({text="#tspin", duration=0.5})
        elseif self.linesCleared == 1 then
            value = 800 * self.level
            self.lastAction = TETRIS.ACTION.TSPIN_SINGLE
            Notifications:TopToAll({text="#tspin_single", duration=0.5})
        -- tspin double
        elseif self.linesCleared == 2 then
            -- back to back
            if self.lastAction == TETRIS.ACTION.TSPIN_DOUBLE then
                value = 1800 * self.level
                Notifications:TopToAll({text="#b2b_tspin_double", duration=0.5})
            else
                value = 1200 * self.level
                Notifications:TopToAll({text="#tspin_double", duration=0.5})
            end
            self.lastAction = TETRIS.ACTION.TSPIN_DOUBLE
        -- tspin triple
        elseif self.linesCleared == 3 then
            -- back to back
            if self.lastAction == TETRIS.ACTION.TSPIN_TRIPLE then
                value = 2400 * self.level
                Notifications:TopToAll({text="#b2b_tspin_triple", duration=0.5})
            else
                value = 1600 * self.level
                Notifications:TopToAll({text="#tspin_triple", duration=0.5})
            end
            self.lastAction = TETRIS.ACTION.TSPIN_TRIPLE
        end
    end
    
    if value > 0 then
        self.score = self.score + value
        Notifications:TopToAll({text="+" .. tostring(value), duration=0.5})
    end

    self.linesToNextLevel = self.linesToNextLevel + self.linesCleared
    if self.linesToNextLevel >= self.linesPerLevel then
        self.linesToNextLevel = self.linesToNextLevel - self.linesPerLevel
        self.level = math.min(self.maxLevel, self.level + 1)
        Notifications:TopToAll({text="#level_up", duration=1})
    end
    
    self.softDropCount = 0
    self.hardDropCount = 0
    self.tSpin = false
    self.linesCleared = 0
end

function TETRIS:ClearLines()
    local r = self.rows
    while r >= 1 do
        if self:IsLineFull(r) then
            self:ClearLine(r)
            self:ShiftLines(r)
            self.linesCleared = self.linesCleared + 1
        else
            r = r - 1
        end
    end
end

function TETRIS:IsLineFull(r)
    local row = self.grid[r]
    for c, cell in ipairs(row) do
        if not cell:IsLocked() then return false end
    end
    return true
end

function TETRIS:ClearLine(r)
    local row = self.grid[r]
    for c, cell in ipairs(row) do
        cell:Clear()
    end
end

function TETRIS:ShiftLines(start_row)
    for r = start_row, 2, -1 do
        self:ShiftLine(r)
    end
end

function TETRIS:ShiftLine(r)
    local rowA = self.grid[r]
    local rowB = self.grid[r - 1]
    for c, cellA in ipairs(rowA) do
        local cellB = rowB[c]
        if cellB:IsLocked() then
            cellA:Lock(cellB.type)
        end
    end
    self:ClearLine(r - 1)
end

function TETRIS:OnInput(key)
    self.inputQueue:Push(key)
end

function TETRIS:HandleInput()
    local key = self.inputQueue:Shift()
    local tetramino = self.activeTetramino
    if tetramino:IsLocked() then return end
    tetramino:Clear()
    if key == "up" or key == "z" then
        -- try rotate
        if key == "up" then
            tetramino:RotateCW()
        else
            tetramino:RotateCCW()
        end
        if not tetramino:IsValid() then
            tetramino.lastRotated = false
            
            -- try right shift
            tetramino:Right()
            if not tetramino:IsValid() then
                -- try second right shift if type I
                if tetramino:GetType() == "I" then
                    tetramino:Right()
                    if not tetramino:IsValid() then
                        -- undo second right shift
                        tetramino:Left()
                    else
                        if self.lockTime ~= nil then
                            self.lockTime = GameRules:GetGameTime()
                        end
                        tetramino:Set()
                        return
                    end
                end
            
                -- shift back to original position
                tetramino:Left()
                
                -- try left shift
                tetramino:Left()
                if not tetramino:IsValid() then
                    -- try second left shift if type I
                    if tetramino:GetType() == "I" then
                        tetramino:Left()
                        if not tetramino:IsValid() then
                            -- undo second left shift
                            tetramino:Right()
                        else
                            if self.lockTime ~= nil then
                                self.lockTime = GameRules:GetGameTime()
                            end
                            tetramino:Set()
                            return
                        end
                    end
                
                    -- back to original position
                    tetramino:Right()
                    if key == "up" then
                        tetramino:RotateCCW()
                    else
                        tetramino:RotateCW()
                    end
                elseif self.lockTime ~= nil then
                    self.lockTime = GameRules:GetGameTime()
                end
            elseif self.lockTime ~= nil then
                self.lockTime = GameRules:GetGameTime()
            end
        else
            if self.lockTime ~= nil then
                self.lockTime = GameRules:GetGameTime()
            end
            tetramino.lastRotated = true
        end
    elseif key == "down" then
        tetramino:Down()
        if not tetramino:IsValid() then
            tetramino:Up()
        else
            self.softDropCount = self.softDropCount + 1
            tetramino.lastRotated = false
        end
    elseif key == "left" then
        tetramino:Left()
        if not tetramino:IsValid() then
            tetramino:Right()
        else
            if self.lockTime ~= nil then
                self.lockTime = GameRules:GetGameTime()
            end
            tetramino.lastRotated = false
        end
    elseif key == "right" then
        tetramino:Right()
        if not tetramino:IsValid() then
            tetramino:Left()
        else
            if self.lockTime ~= nil then
                self.lockTime = GameRules:GetGameTime()
            end
            tetramino.lastRotated = false
        end
    elseif key == "space" then
        while true do
            tetramino:Down()
            if not tetramino:IsValid() then
                tetramino:Up()
                break
            else
                self.hardDropCount = self.hardDropCount + 1
            end
        end
        tetramino.lastRotated = false
        self.dropped = true
        self.lockTime = GameRules:GetGameTime()
        self.inputQueue:Clear()
    elseif key == "lshift" then
        if not self.holdUsed then
            self.holdUsed = true
            if self.heldTetramino ~= nil then
                self.pendingTetraminos:Unshift(self.heldTetramino)
            end
            self.heldTetramino = tetramino:GetType()
            self:Spawn()
            return
        end
    end
    tetramino:Set()
end

function TETRIS:NetworkState()
    CustomNetTables:SetTableValue("game_" .. tostring(self.index), "pending", self.pendingTetraminos:Map(function (t, i)
        local origin = CELL(self, i * 3 - 2, 1)
        local tetramino = TETRAMINOS[t](self, origin)
        local data = {
            t=t,
            cells=tetramino:GetCells():Map(CELL.GetCoordinate):Items()
        }
        return data
    end):Items())
    for k, v in ipairs(self.grid) do
        CustomNetTables:SetTableValue("grid_" .. tostring(self.index), tostring(k), imap(CELL.Serialize, v))
    end
    
    if self.heldTetramino ~= nil then
        local origin = CELL(self, 1, 1)
        local tetramino = TETRAMINOS[self.heldTetramino](self, origin)
        local data = {
            t=self.heldTetramino,
            cells=tetramino:GetCells():Map(CELL.GetCoordinate):Items()
        }
        CustomNetTables:SetTableValue("game_" .. tostring(self.index), "hold", data)
    else
        CustomNetTables:SetTableValue("game_" .. tostring(self.index), "hold", nil)
    end
    
    CustomNetTables:SetTableValue("game_" .. tostring(self.index), "score", {value=self.score})
    CustomNetTables:SetTableValue("game_" .. tostring(self.index), "level", {value=self.level})
end

print ("tetris.lua is loaded")