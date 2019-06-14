--[[ Keypad block ]]--

dofile("Libs/AdvancedInteract.lua")

Keypad = class()
Keypad.maxParentCount = 1
Keypad.maxChildCount = -1
Keypad.connectionInput = sm.interactable.connectionType.logic
Keypad.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Keypad.colorNormal = sm.color.new( 0x00971dff )
Keypad.colorHighlight = sm.color.new( 0x00b822ff )

function Keypad.client_onRefresh( self )
    --sm.advancedInteract = nil
    self:client_onCreate()
end

function Keypad.client_onCreate( self )
    self.advInteract = sm.advancedInteract.create(self)
    self.advInteract:addButton("0",   -1,   -1, 0.5, 0.5, nil, self.client_onKeypadNumber, nil)
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

function Keypad.client_onInteract( self )
	--local camPos = sm.camera.getPosition()
	--local camDir = sm.camera.getDirection()
	--local R1,R2 = sm.physics.raycast((camPos + camDir), (camPos + camDir * 10))
    
    self.advInteract:onInteract()
end

function Keypad.client_onKeypadNumber( self, btn )
    print("client_onKeypad", btn.name)
end

function Keypad.client_onKeypadDot( self, btn )
    print("client_onKeypad", btn.name)
end

function Keypad.client_onKeypadMinus( self, btn )
    print("client_onKeypad", btn.name)
end

function Keypad.client_onKeypadEnter( self, btn )
    print("client_onKeypad", btn.name)
end

function Keypad.client_onKeypadClear( self, btn )
    print("client_onKeypad", btn.name)
end

--TODO: Make it not interactable if not looking at button