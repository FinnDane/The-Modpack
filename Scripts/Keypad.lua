--[[ Keypad block ]]--
Keypad = class()
Keypad.maxParentCount = 0
Keypad.maxChildCount = -1
Keypad.connectionInput = sm.interactable.connectionType.none
Keypad.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Keypad.colorNormal = sm.color.new( 0x00971dff )
Keypad.colorHighlight = sm.color.new( 0x00b822ff )

dofile "functions.lua" 

-- Called on creation
function Keypad.server_onCreate( self )
	self.activeTime = 0
end
function Keypad.server_onRefresh( self )
    self:server_onCreate()
	self.interactable.power = 0
	self.interactable.active = false
end


function Keypad.server_onFixedUpdate( self, dt )
	if self.interactable.active then
		if self.activeTime <= 1 then -- when active and activeTime is only 1 tick it'll insta go inactive, thus it stayed active for 1 tick
			self.interactable.active = false
		else
			self.activeTime = self.activeTime - 1
		end
	end
	if self.buttonPress then
		self.buttonPress = false
		self.network:sendToClients("client_playSound","Button off")
	end
end

function Keypad.server_changePower( self, num )
	self.interactable.power = num
	self.network:sendToClients("client_playSound","Button on")
	self.buttonPress = true
end

function Keypad.server_changeActive( self )
	self.activeTime = 1 --ticks
	self.interactable.active = true
	self.network:sendToClients("client_playSound","Button on")
	self.buttonPress = true
end


--- client ---

function Keypad.client_playSound(self, soundName)
	sm.audio.play(soundName, self.shape.worldPosition)
end

function Keypad.client_onCreate(self)
	self.number = "0"
	local virtualButtons = {
		--[[1]] { x = -0.75, y = -0.25, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."1" end},
		--[[2]] { x = -0.25, y = -0.25, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."2" end},
		--[[3]] { x =  0.25, y = -0.25, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."3" end},
		--[[4]] { x = -0.75, y =  0.25, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."4" end},
		--[[5]] { x = -0.25, y =  0.25, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."5" end},
		--[[6]] { x =  0.25, y =  0.25, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."6" end},
		--[[7]] { x = -0.75, y =  0.75, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."7" end},
		--[[8]] { x = -0.25, y =  0.75, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."8" end},
		--[[9]] { x =  0.25, y =  0.75, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."9" end},
		--[[0]] { x = -0.75, y = -0.75, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."0" end},
		--[[.]] { x = -0.25, y = -0.75, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = obj.number.."." end},
		--[[-]] { x =  0.25, y = -0.75, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = (obj.number:sub(1,1) == '-' and obj.number:sub(2) or '-'..obj.number) end},
		--[[c]] { x =  0.75, y =  0.50, width = 0.25, height = 0.50, callback = function(self, obj) obj.number = "0" end}, 
		--[[e]] { x =  0.75, y = -0.50, width = 0.25, height = 0.50, callback = function(self, obj) obj.enter = true end},
	}
	sm.virtualButtons.client_configure(self, virtualButtons)
end

-- Called on pressing [E]
function Keypad.client_onInteract( self ) 
	local hit, hitResult = sm.localPlayer.getRaycast(10) -- world point the vector hit
	if not hit then return end
	local worldPos = self.shape.worldPosition -- world point of block center
	local hitPos = hitResult.pointWorld
	local localHitVec = hitPos - worldPos -- vector of hit relative to block
	local localX = self.shape.right
	local localY = self.shape.at
	local localZ = self.shape.up
	dotX = localHitVec:dot(localX) * 4
	dotY = localHitVec:dot(localY) * 4
	
	self.number = (self.enter and "0" or self.number)
	self.enter = false
	
	sm.virtualButtons.client_onInteract(self, dotX, dotY)
	
	if self.enter then
		self.network:sendToServer("server_changeActive")
	else
		--print('notify server, number = ',tonumber(self.number))
		self.network:sendToServer("server_changePower", tonumber(self.number))
	end
end

