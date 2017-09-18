require("libraries/util")
require("libraries/timers")
require("libraries/list")

TETRAMINO = class({})

function TETRAMINO:constructor(tetris, origin, orientation)
    -- print ("TETRAMINO constructor", self:GetType())
    self.tetris = tetris
    self.orientation = orientation or 1
    self.origin = origin:Copy()
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

function TETRAMINO:GetCells(origin, orientation)
    -- print ("TETRAMINO GetCells")
    origin = origin or self.origin
    orientation = orientation or self.orientation
    local state = self.STATE[orientation]
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

function TETRAMINO:RotateCW()
    self.orientation = self.orientation % 4 + 1
end

function TETRAMINO:RotateCCW()
    self.orientation = (self.orientation + 2) % 4 + 1
end

function TETRAMINO:Up()
    self.origin.row = self.origin.row - 1
end

function TETRAMINO:Down()
    -- print("TETRAMINO:Down")
    self.origin.row = self.origin.row + 1
end

function TETRAMINO:Left()
    self.origin.col = self.origin.col - 1
end

function TETRAMINO:Right()
    self.origin.col = self.origin.col + 1
end

function TETRAMINO:Clear()
    self:GetCells():Each(function (cell) cell:Clear() end)
end

function TETRAMINO:ClearGhost()
    self:GetCells():Each(function (cell) cell:ClearGhost() end)
end

function TETRAMINO:SetGhost()
    self:GetCells():Each(function (cell) cell:SetGhost() end)
end

function TETRAMINO:Set()
    self:GetCells():Each(function (cell) cell:Set(self:GetType()) end)
end

function TETRAMINO:Lock()
    self.locked = true
    self:GetCells():Each(function (cell) cell:Lock(self:GetType()) end)
end

function TETRAMINO:IsLocked()
    return self.locked
end

function TETRAMINO:IsTSpin()
    if not self.lastRotated or self:GetType() ~= "T" then return false end
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