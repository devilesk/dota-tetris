function TETRIS:CalculateScore()
    self.score = self.score + self.softDropCount
    self.score = self.score + self.hardDropCount * 2
    
    local value = 0
    if not self.tSpin and not self.tSpinMini then
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
    elseif self.tSpinMini then
        -- tspin mini
        if self.linesCleared == 0 then
            self.lastAction = TETRIS.ACTION.TSPIN_MINI
            Notifications:TopToAll({text="#tspin_mini", duration=0.5})
        -- tspin mini single
        elseif self.linesCleared == 1 then
            value = 100 * self.level
            self.lastAction = TETRIS.ACTION.TSPIN_MINI_SINGLE
            Notifications:TopToAll({text="#tspin_mini_single", duration=0.5})
        -- tspin mini double
        elseif self.linesCleared == 2 then
            value = 300 * self.level
            self.lastAction = TETRIS.ACTION.TSPIN_MINI_DOUBLE
            Notifications:TopToAll({text="#tspin_mini_double", duration=0.5})
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
    elseif self.tSpin then
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

    if self.linesCleared > 0 then 
        EmitGlobalSound("ui.crafting_gem_applied")
        print("SOUND")
    end
    
    self.linesToNextLevel = self.linesToNextLevel + self.linesCleared
    if self.linesToNextLevel >= self.linesPerLevel then
        self.linesToNextLevel = self.linesToNextLevel - self.linesPerLevel
        self.level = math.min(self.maxLevel, self.level + 1)
        Notifications:TopToAll({text="#level_up", duration=1})
        EmitGlobalSound("General.FemaleLevelUp")
    end
    
    self.softDropCount = 0
    self.hardDropCount = 0
    self.tSpin = false
    self.tSpinMini = false
    self.linesCleared = 0
end