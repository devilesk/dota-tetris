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
        TSPIN_TRIPLE = 8,
        TSPIN_MINI = 9,
        TSPIN_MINI_SINGLE = 10,
        TSPIN_MINI_DOUBLE = 11,
    },
    GAMEMODE = {
        MARATHON = "MARATHON",
        SPRINT = "SPRINT",
        ULTRA = "ULTRA",
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
    self:Setup()
end

function TETRIS:Setup(gameMode)
    for r = 1, self.rows do
        for c = 1, self.cols do
            self.grid[r][c]:Clear()
        end
    end
    self.gameMode = gameMode or TETRIS.GAMEMODE.MARATHON
    self.activeTetramino = nil
    self.timer = nil
    self.level = 1
    self.linesClearedTotal = 0
    self.linesCleared = 0
    self.linesPerLevel = 10
    self.linesToNextLevel = 0
    self.lineClearCombo = 0
    self.maxLevel = 15
    self.maxLockCount = 15
    self.lockDelay = 0.5
    self.started = false
    self.startCountdown = nil
    self.startTimer = nil
    self.time = nil
    self.startTime = nil
    self.endTime = nil
    self.lastFall = GameRules:GetGameTime()
    self.score = 0
    self.dropped = false
    self.ghost = nil
    self.inputQueue = List()
    self.heldTetramino = nil
    self.holdUsed = false
    self.sourceTetraminos = List({"I", "J", "L", "O", "S", "T", "Z"})
    self.sourceTetraminos:Shuffle()
    -- self.sourceTetraminos = List({"T", "O", "O", "I", "I", "J", "Z", "Z", "Z", "I", "I", "L", "I", "I"})
    self.pendingTetraminos = List()
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    self.pendingTetraminos:Push(self.sourceTetraminos:Pop())
    
    self.tSpin = false
    self.tSpinMini = false
    self.lastAction = nil
    self.softDropCount = 0
    self.hardDropCount = 0
    self:ClearTimers()
    self:Spawn()
    if self.gameMode == TETRIS.GAMEMODE.ULTRA then
        self.time = 120
    end
    self:NetworkState()
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
    Notifications:TopToAll({text="#game_over", duration=5, class="notification"})
    self:ClearTimers()
end



function TETRIS:ClearTimers()
    self.started = false
    if self.startTimer ~= nil then
        Timers:RemoveTimer(self.startTimer)
        self.startTimer = nil
    end
    if self.timer ~= nil then
        Timers:RemoveTimer(self.timer)
        self.timer = nil
    end
end

function TETRIS:PreStart(gameMode)
    self:Setup(gameMode)
    self.startCountdown = 3
    self.startTimer = Timers:CreateTimer(1, function ()
        if self.startCountdown > 0 then
            Notifications:TopToAll({text=tostring(self.startCountdown), duration=1, class="notification"})
            self.startCountdown = self.startCountdown - 1
            return 1
        else
            self:Start()
        end
    end, self)
end

function TETRIS:Start()
    self.started = true
    self.startTime = GameRules:GetGameTime()
    if self.gameMode == TETRIS.GAMEMODE.ULTRA then
        self.endTime = self.startTime + 120
    end
    self.timer = Timers:CreateTimer(function ()
        if self.started then
            self:Run()
            return 0.01
        end
    end, self)
end

function TETRIS:GetDelay()
    if self.gameMode == TETRIS.GAMEMODE.MARATHON then
        return math.pow(0.8 - (self.level - 1) * 0.007, self.level - 1)
    else
        return 1
    end
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
    
    if self.dropped or (tetramino.lockTime ~= nil and now - tetramino.lockTime >= self.lockDelay) or (tetramino.lockCount >= self.maxLockCount and not tetramino:CanDown()) then
        self.dropped = false
        self.tSpin = tetramino:IsTSpin()
        self.tSpinMini = tetramino:IsTSpinMini()
        tetramino:Lock()
        EmitGlobalSound("General.SelectAction")
        self:ClearLines()
        self:Spawn()
        self.holdUsed = false
        
        if self.linesCleared > 0 then
            self.lineClearCombo = self.lineClearCombo + 1
        else
            self.lineClearCombo = 0
        end
    end
    
    if self.ghost then
        self.ghost:Clear()
    end
    self.ghost = tetramino:Ghost()
    while self.ghost:Down() do end
    
    self:CalculateScore()
    
    self.time = now - self.startTime
    if self.gameMode == TETRIS.GAMEMODE.SPRINT then
        if self.linesClearedTotal >= 40 then
            self:EndGame()
        end
    elseif self.gameMode == TETRIS.GAMEMODE.ULTRA then
        self.time = self.endTime - now
        if self.time <= 0 then
            self.time = 0
            self:EndGame()
        end
    end
    
    self:NetworkState()
end

function TETRIS:ClearLines()
    local r = self.rows
    while r >= 1 do
        if self:IsLineFull(r) then
            self:ClearLine(r)
            self:ShiftLinesDown(r)
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

function TETRIS:ShiftLinesDown(start_row)
    for r = start_row, 2, -1 do
        self:ShiftLineDown(r)
    end
end

function TETRIS:ShiftLinesUp(end_row)
    for r = 2, end_row, 1 do
        self:ShiftLineUp(r, 1)
    end
end

function TETRIS:ShiftLineDown(r)
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

function TETRIS:ShiftLineUp(r)
    local rowA = self.grid[r - 1]
    local rowB = self.grid[r]
    for c, cellA in ipairs(rowA) do
        local cellB = rowB[c]
        cellA:Merge(cellB.type)
    end
    self:ClearLine(r)
end

function TETRIS:AddLine()
    self:ShiftLinesUp(self.rows)
    local row = self.grid[self.rows]
    for c, cell in ipairs(row) do
        cell:Lock()
    end
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
            EmitGlobalSound("Shop.PanelDown")
            self.softDropCount = self.softDropCount + 1
        end
    elseif key == "left" then
        tetramino:Left()
    elseif key == "right" then
        tetramino:Right()
    elseif key == "space" then
        while tetramino:Down() do
            EmitGlobalSound("ui_chat_msg_rec")
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
    CustomNetTables:SetTableValue("game_" .. tostring(self.index), "linesClearedTotal", {value=self.linesClearedTotal})
    
    CustomNetTables:SetTableValue("game_" .. tostring(self.index), "time", {value=self.time})
    
    CustomNetTables:SetTableValue("game_" .. tostring(self.index), "gameMode", {value=self.gameMode})
end

print ("tetris.lua is loaded")