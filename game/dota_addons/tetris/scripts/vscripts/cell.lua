require("libraries/util")
require("libraries/timers")

CELL = class({}, {
    STATE = {
        INVALID = -1,
        EMPTY = 0,
        OCCUPIED = 1,
        LOCKED = 2,
        GHOST = 3
    }
})

DeepPrintTable(CELL)

function CELL:constructor(tetris, row, col, state)
    self.tetris = tetris
    self.row = row
    self.col = col
    self.state = state or CELL.STATE.EMPTY
    self.type = nil
end

function CELL:Merge(cell)
    self.tetris = cell.tetris
    self.row = cell.row
    self.col = cell.col
    self.state = cell.state
    self.type = cell.type
end

function CELL:Translate(x, y)
    return CELL(self.tetris, self.row - y, self.col + x, self.state)
end

function CELL:Copy()
    return CELL(self.tetris, self.row, self.col, self.state)
end

function CELL:IsLocked()
    -- print("CELL:IsLocked")
    return self.state == CELL.STATE.LOCKED
end

function CELL:IsGhost()
    -- print("CELL:IsGhost")
    return self.state == CELL.STATE.GHOST
end

function CELL:IsEmpty()
    -- print("CELL:IsEmpty")
    return self.state == CELL.STATE.EMPTY
end

function CELL:IsValid()
    -- print("CELL:IsValid")
    return self.state ~= CELL.STATE.INVALID
end

function CELL:Clear()
    -- print("CELL:Clear")
    self.state = CELL.STATE.EMPTY
    self.type = nil
end

function CELL:ClearGhost()
    -- print("CELL:Clear")
    if self:IsGhost() then
        self.state = CELL.STATE.EMPTY
    end
end

function CELL:SetGhost()
    -- print("CELL:Clear")
    if self:IsEmpty() then
        self.state = CELL.STATE.GHOST
    end
end

function CELL:Set(t)
    -- print("CELL:Set")
    self.state = CELL.STATE.OCCUPIED
    self.type = t
end

function CELL:Lock(t)
    -- print("CELL:Set")
    self.state = CELL.STATE.LOCKED
    self.type = t
end

function CELL:ToString()
    return "(" .. tostring(self.row) .. "," .. tostring(self.col) .. "," .. tostring(self.type) .. ")"
end

function CELL:Serialize(bFull)
    return {self.state, self.type}
end

function CELL:GetCoordinate()
    return {self.row, self.col}
end

function CELL:Dump()
    print(self:ToString())
end