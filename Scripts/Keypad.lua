--[[ Keypad block ]]--
-- This version was made by Nick

dofile("functions.lua")
dofile("Libs/AdvancedInteract.lua")

Keypad = class()
Keypad.maxParentCount = 1
Keypad.maxChildCount = -1
Keypad.connectionInput = sm.interactable.connectionType.logic
Keypad.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Keypad.colorNormal = sm.color.new( 0x00971dff )
Keypad.colorHighlight = sm.color.new( 0x00b822ff )

function Keypad.client_onRefresh( self )
    self:client_onCreate()
end

function Keypad.client_onCreate( self )
    self.advInteract = sm.advancedInteract.create(self)
    self.advInteract:addButton("0",   -1,   -1, 0.5, 0.5, "Keypad - OutlineSmall", self.client_onKeypadNumber, nil)
    self.advInteract:addButton("1",   -1, -0.5, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    self.advInteract:addButton("2", -0.5, -0.5, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    self.advInteract:addButton("3",    0, -0.5, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    self.advInteract:addButton("4",   -1,    0, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    self.advInteract:addButton("5", -0.5,    0, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    self.advInteract:addButton("6",    0,    0, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    self.advInteract:addButton("7",   -1,  0.5, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    self.advInteract:addButton("8", -0.5,  0.5, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    self.advInteract:addButton("9",    0,  0.5, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
    
    self.advInteract:addButton(".", -0.5,   -1, 0.5, 0.5, nil, self.client_onKeypadDot   , nil)
    self.advInteract:addButton("-",    0,   -1, 0.5, 0.5, nil, self.client_onKeypadMinus , nil)
    self.advInteract:addButton("e",  0.5,   -1, 0.5,   1, nil, self.client_onKeypadEnter , nil)
    self.advInteract:addButton("c",  0.5,    0, 0.5,   1, nil, self.client_onKeypadClear , nil)
end

function Keypad.client_onDestroy( self )
    self.advInteract:destroy()
end

function Keypad.client_onInteract( self )
    self.advInteract:onInteract()
end

function Keypad.client_onUpdate( self, dt )
    
end

function createParticle(position, color)
    sm.particle.createParticle( "paint_smoke", position, nil, color )
end




-- Client keystrokes
function Keypad.client_onKeypadNumber( self, btn )
    self.network:sendToServer("server_onKeypadNumber", btn)
end

function Keypad.client_onKeypadDot( self, btn )
    self.network:sendToServer("server_onKeypadDot", btn)
end

function Keypad.client_onKeypadMinus( self, btn )
    self.network:sendToServer("server_onKeypadMinus", btn)
end

function Keypad.client_onKeypadEnter( self, btn )
    self.network:sendToServer("server_onKeypadEnter", btn)
end

function Keypad.client_onKeypadClear( self, btn )
    self.network:sendToServer("server_onKeypadClear", btn)
end




-- Test setup (remove when done testing)
--function Keypad.client_onUpdate( self, dt )
--    sm.gui.displayAlertText(self.numberString, 1)
--end






function Keypad.server_onRefresh( self )
    self:server_onCreate()
end

function Keypad.server_onCreate( self )
    self.numberString = "0"
    self.ticksActive = 5
    self.lastTrigger = nil
end

function Keypad.server_onFixedUpdate( self, timeStep )
    self:server_updateActive()
end

function Keypad.client_canInteract(self)
    if (self.shape.worldPosition - sm.localPlayer.getPosition()):length2() > 4 then return false end
    
    local parent = self.interactable:getSingleParent()
    if parent and parent.active == false then
        return false
    end
    
    return true
end



-- Server keystrokes
function Keypad.server_onKeypadNumber( self, btn )
    if self.lastTrigger then
        self.lastTrigger = nil
        self.numberString = "0"
    end
    
    self.numberString = (self.numberString == "0" and "" or self.numberString == "-0" and "-" or self.numberString) .. btn.name
    self:server_updatePower()
end

function Keypad.server_onKeypadDot( self, btn )
    if self.lastTrigger then
        self.lastTrigger = nil
        self.numberString = "0"
    end
    
    self.numberString = self.numberString:find("%.") and self.numberString or self.numberString .. "."
    self:server_updatePower()
end

function Keypad.server_onKeypadMinus( self, btn )
    if self.lastTrigger then
        self.lastTrigger = nil
        self.numberString = "0"
    end
    
    self.numberString = self.numberString:sub(1, 1) == "-" and self.numberString:sub(2) or ("-" .. self.numberString)
    self:server_updatePower()
end

function Keypad.server_onKeypadEnter( self, btn )
    self.lastTrigger = sm.game.getCurrentTick()
    self:server_updateActive()
    self:server_updatePower()
end

function Keypad.server_onKeypadClear( self, btn )
    self.numberString = "0"
    self:server_updatePower()
end

function Keypad.server_updatePower( self )
    local number = tonumber(self.numberString)
    
    local power = number
    if math.abs(power) >= 3.3*10^38 then 
        if power < 0 then power = -3.3*10^38 else power = 3.3*10^38 end --Infinity detected
    end
    self.interactable.power = power
    sm.interactable.setValue(self.interactable, number)
end

function Keypad.server_updateActive( self )
    self.interactable.active = self.lastTrigger and (sm.game.getCurrentTick() < self.lastTrigger + self.ticksActive) or false
end





