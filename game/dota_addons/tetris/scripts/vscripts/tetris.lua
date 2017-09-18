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

require("tetris_score")

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
    self.lastFall = GameRules:GetGameTime()
    self.score = 0
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
    self.activeTetramino = TETRAMINOS[self.pendingTetraminos:Shift()](self, self.spawnOrigin)
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    if self.sourceTetraminos:Size() == 0 then
        self.sourceTetraminos = List({"I", "J", "L", "O", "S", "T", "Z"})
        self.sourceTetraminos:Shuffle()
    end
    
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
    while self.inputQueue:Size() > 0 do
        self:HandleInput()
    end
    
    local tetramino = self.activeTetramino
    local now = GameRules:GetGameTime()
    
    if now - self.lastFall >= self:GetDelay() then
        self.lastFall = now
        tetramino:Down()
    end
    
    if self.dropped or (tetramino.lockTime ~= nil and now - tetramino.lockTime >= self.lockDelay) then
        self.dropped = false
        self.tSpin = tetramino:IsTSpin()
        tetramino:Lock()
        self:ClearLines()
        self:Spawn()
        self.holdUsed = false
    end
    
    if self.ghost then
        self.ghost:Clear()
    end
    self.ghost = tetramino:Ghost()
    while self.ghost:Down() do end
    
    self:CalculateScore()
    
    self:NetworkState()
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
    if key == "up" then
        tetramino:RotateCW()
    elseif key == "z" then
        tetramino:RotateCCW()
    elseif key == "down" then
        if tetramino:Down() then
            self.softDropCount = self.softDropCount + 1
        end
    elseif key == "left" then
        tetramino:Left()
    elseif key == "right" then
        tetramino:Right()
    elseif key == "space" then
        while tetramino:Down() do
            self.hardDropCount = self.hardDropCount + 1
        end
        self.dropped = true
        self.inputQueue:Clear()
    elseif key == "lshift" then
        if not self.holdUsed then
            self.holdUsed = true
            if self.heldTetramino ~= nil then
                self.pendingTetraminos:Unshift(self.heldTetramino)
            end
            self.heldTetramino = tetramino:GetType()
            tetramino:Clear()
            self:Spawn()
            return
        end
    end
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