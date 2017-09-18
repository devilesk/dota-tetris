require("libraries/util")
require("libraries/timers")
require("libraries/list")

JLSTZ_OFFSET = {
    {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
    {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
    {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
    {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
}
I_OFFSET = {
    {{0, 0}, {-2, 0}, {1, 0}, {-2, -1}, {1, 2}},
    {{0, 0}, {-1, 0}, {2, 0}, {-1, 2}, {2, -1}},
    {{0, 0}, {2, 0}, {-1, 0}, {2, 1}, {-1, -2}},
    {{0, 0}, {1, 0}, {-2, 0}, {1, -2}, {-2, 1}},
}
O_OFFSET = {
    {{0, 0}},
    {{0, 0}},
    {{0, 0}},
    {{0, 0}},
}
ROTATION_OFFSETS = {
    I = I_OFFSET,
    J = JLSTZ_OFFSET,
    L = JLSTZ_OFFSET,
    O = O_OFFSET,
    S = JLSTZ_OFFSET,
    T = JLSTZ_OFFSET,
    Z = JLSTZ_OFFSET
}

TETRAMINO = class({})

function TETRAMINO:constructor(tetris, origin, orientation)
    -- print ("TETRAMINO constructor", self:GetType())
    self.tetris = tetris
    self.orientation = orientation or 1
    self.origin = origin:Copy()
    self.lockTime = nil
    self.locked = false
    self.lastRotated = false
end

function TETRAMINO:Copy()
    return TETRAMINOS[self:GetType()](self.tetris, self.origin, self.orientation)
end

function TETRAMINO:GetType()
    return string.sub(self.__class__name, 1, 1)
end

function TETRAMINO:GetCell(r, c)
    return self.tetris:GetCell(r, c)
end

function TETRAMINO:GetState(orientation)
    -- print ("TETRAMINO GetState")
    orientation = orientation or self.orientation
    return self.STATE[orientation]
end

function TETRAMINO:GetCells(origin, orientation)
    -- print ("TETRAMINO GetCells")
    origin = origin or self.origin
    orientation = orientation or self.orientation
    local state = self:GetState(orientation)
    local cells = List()
    for r, row in ipairs(state) do
        for c, v in ipairs(row) do
            if v == 1 then
                local cell = self:GetCell(origin.row + r - 1, origin.col + c - 1)
                cells:Push(cell)
            end
        end
    end
    return cells
end

function TETRAMINO:Translate(x, y)
    self:Clear()
    local newOrigin = self.origin:Translate(x, y)
    local isDown = x == 0 and y == -1
    if self:IsValid(newOrigin) then
        self.origin = newOrigin
        self.kicked = false
        self.lastRotated = false
        if isDown then
            self:ClearLockDelay()
        else
            self:ResetLockDelay()
        end
        self:Set()
        return true
    end
    if isDown then self:StartLockDelay() end
    self:Set()
    return false
end

function TETRAMINO:Rotate(direction)
    self:Clear()
    direction = direction or 1
    local offsets = self:GetRotationOffset()
    local newOrientation = self:NextOrientation(direction)
    for k, offset in ipairs(offsets) do
        local newOrigin = self.origin:Translate(offset[1] * direction, offset[2] * direction)
        if self:IsValid(newOrigin, newOrientation) then
            local kicked = k > 1
            self.origin = newOrigin
            self.orientation = newOrientation
            self.kicked = kicked
            self.lastRotated = true
            self:ResetLockDelay()
            self:Set()
            return true
        end
    end
    self:Set()
    return false
end

function TETRAMINO:GetRotationOffset(orientation)
    orientation = orientation or self.orientation
    print("GetRotationOffset", self:GetType(), orientation)
    return ROTATION_OFFSETS[self:GetType()][orientation]
end

function TETRAMINO:NextOrientation(direction)
    direction = direction or 1
    if direction == 1 then
        return self.orientation % 4 + 1
    else
        return (self.orientation + 2) % 4 + 1
    end
end

function TETRAMINO:RotateCW()
    return self:Rotate(1)
end

function TETRAMINO:RotateCCW()
    return self:Rotate(-1)
end

function TETRAMINO:Up()
    return self:Translate(0, 1)
end

function TETRAMINO:Down()
    return self:Translate(0, -1)
end

function TETRAMINO:Left()
    return self:Translate(-1, 0)
end

function TETRAMINO:Right()
    return self:Translate(1, 0)
end

function TETRAMINO:Clear()
    self:GetCells():Each(function (cell) cell:Clear() end)
end

function TETRAMINO:Set()
    self:GetCells():Each(function (cell) cell:Set(self:GetType()) end)
end

function TETRAMINO:StartLockDelay()
    self.locked = false
    if self.lockTime == nil then
        self.lockTime = GameRules:GetGameTime()
    end
end

function TETRAMINO:ClearLockDelay()
    self.locked = false
    self.lockTime = nil
end

function TETRAMINO:ResetLockDelay()
    self.locked = false
    if self.lockTime ~= nil then
        self.lockTime = GameRules:GetGameTime()
    end
end

function TETRAMINO:Lock()
    self.locked = true
    self:GetCells():Each(function (cell) cell:Lock(self:GetType()) end)
end

function TETRAMINO:IsLocked()
    return self.locked
end

function TETRAMINO:IsTSpin()
    if self:GetType() ~= "T" or not self.lastRotated or self.kicked then return false end
    local adjCells = List()
    adjCells:Push(self:GetCell(self.origin.row, self.origin.col))
    adjCells:Push(self:GetCell(self.origin.row + 2, self.origin.col))
    adjCells:Push(self:GetCell(self.origin.row + 2, self.origin.col + 2))
    adjCells:Push(self:GetCell(self.origin.row, self.origin.col + 2))
    return adjCells:Count(function (cell) return cell:IsLocked() end) == 3
end

function TETRAMINO:IsValid(origin, orientation)
    local cells = self:GetCells(origin, orientation)
    -- print(cells:Size())
    -- cells:Dump(CELL.Dump)
    local result = cells:All(function (cell) return cell:IsValid() and not cell:IsLocked() end)
    -- print("TETRAMINO:IsValid", result)
    return result
end

function TETRAMINO:Ghost()
    return GHOST_TETRAMINO(self)
end

GHOST_TETRAMINO = class({}, {}, TETRAMINO)

function GHOST_TETRAMINO:constructor(tetramino)
    -- print("GHOST_TETRAMINO constructor")
    TETRAMINOS[tetramino:GetType()].constructor(self, tetramino.tetris, tetramino.origin, tetramino.orientation)
    self.type = tetramino:GetType()
end

function GHOST_TETRAMINO:GetType()
    return self.type
end

function GHOST_TETRAMINO:GetState(orientation)
    -- print ("GHOST_TETRAMINO GetState")
    orientation = orientation or self.orientation
    return TETRAMINOS[self.type].STATE[orientation]
end

function GHOST_TETRAMINO:Clear()
    self:GetCells():Each(function (cell) cell:ClearGhost() end)
end

function GHOST_TETRAMINO:Set()
    self:GetCells():Each(function (cell) cell:SetGhost() end)
end

I_TETRAMINO = class({},  {
    __class__name = "I_TETRAMINO",
    STATE = {
        {
            {0, 0, 0, 0},
            {1, 1, 1, 1},
            {0, 0, 0, 0},
            {0, 0, 0, 0}
        },
        {
            {0, 0, 1, 0},
            {0, 0, 1, 0},
            {0, 0, 1, 0},
            {0, 0, 1, 0}
        },
        {
            {0, 0, 0, 0},
            {0, 0, 0, 0},
            {1, 1, 1, 1},
            {0, 0, 0, 0}
        },
        {
            {0, 1, 0, 0},
            {0, 1, 0, 0},
            {0, 1, 0, 0},
            {0, 1, 0, 0}
        }
    }
}, TETRAMINO)

J_TETRAMINO = class({},  {
    __class__name = "J_TETRAMINO",
    STATE = {
        {
            {1, 0, 0},
            {1, 1, 1},
            {0, 0, 0}
        },
        {
            {0, 1, 1},
            {0, 1, 0},
            {0, 1, 0}
        },
        {
            {0, 0, 0},
            {1, 1, 1},
            {0, 0, 1}
        },
        {
            {0, 1, 0},
            {0, 1, 0},
            {1, 1, 0}
        }
    }
}, TETRAMINO)

L_TETRAMINO = class({},  {
    __class__name = "L_TETRAMINO",
    STATE = {
        {
            {0, 0, 1},
            {1, 1, 1},
            {0, 0, 0}
        },
        {
            {0, 1, 0},
            {0, 1, 0},
            {0, 1, 1}
        },
        {
            {0, 0, 0},
            {1, 1, 1},
            {1, 0, 0}
        },
        {
            {1, 1, 0},
            {0, 1, 0},
            {0, 1, 0}
        }
    }
}, TETRAMINO)

O_TETRAMINO = class({},  {
    __class__name = "O_TETRAMINO",
    STATE = {
        {
            {0, 1, 1},
            {0, 1, 1}
        },
        {
            {0, 1, 1},
            {0, 1, 1}
        },
        {
            {0, 1, 1},
            {0, 1, 1}
        },
        {
            {0, 1, 1},
            {0, 1, 1}
        }
    }
}, TETRAMINO)

S_TETRAMINO = class({},  {
    __class__name = "S_TETRAMINO",
    STATE = {
        {
            {0, 1, 1},
            {1, 1, 0},
            {0, 0, 0}
        },
        {
            {0, 1, 0},
            {0, 1, 1},
            {0, 0, 1}
        },
        {
            {0, 0, 0},
            {0, 1, 1},
            {1, 1, 0}
        },
        {
            {1, 0, 0},
            {1, 1, 0},
            {0, 1, 0}
        }
    }
}, TETRAMINO)

T_TETRAMINO = class({},  {
    __class__name = "T_TETRAMINO",
    STATE = {
        {
            {0, 1, 0},
            {1, 1, 1},
            {0, 0, 0}
        },
        {
            {0, 1, 0},
            {0, 1, 1},
            {0, 1, 0}
        },
        {
            {0, 0, 0},
            {1, 1, 1},
            {0, 1, 0}
        },
        {
            {0, 1, 0},
            {1, 1, 0},
            {0, 1, 0}
        }
    }
}, TETRAMINO)

Z_TETRAMINO = class({},  {
    __class__name = "Z_TETRAMINO",
    STATE = {
        {
            {1, 1, 0},
            {0, 1, 1},
            {0, 0, 0}
        },
        {
            {0, 0, 1},
            {0, 1, 1},
            {0, 1, 0}
        },
        {
            {0, 0, 0},
            {1, 1, 0},
            {0, 1, 1}
        },
        {
            {0, 1, 0},
            {1, 1, 0},
            {1, 0, 0}
        }
    }
}, TETRAMINO)

TETRAMINOS = {
    I = I_TETRAMINO,
    J = J_TETRAMINO,
    L = L_TETRAMINO,
    O = O_TETRAMINO,
    S = S_TETRAMINO,
    T = T_TETRAMINO,
    Z = Z_TETRAMINO
}

print ("tetramino.lua is loaded")