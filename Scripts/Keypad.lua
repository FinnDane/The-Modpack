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
	if not sm.exists(self.interactable) then return end
    self:server_onCreate()
	self.interactable.power = 0
	self.interactable.active = false
end

function Keypad.server_onFixedUpdate( self, dt )
	if not sm.exists(self.interactable) then return end
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
	sm.interactable.setValue(self.interactable, num)
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
		--[[.]] { x = -0.25, y = -0.75, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = (obj.hasDec and obj.number or obj.number..".") obj.hasDec = true end},
		--[[-]] { x =  0.25, y = -0.75, width = 0.25, height = 0.25, callback = function(self, obj) obj.number = (obj.number:sub(1,1) == '-' and obj.number:sub(2) or '-'..obj.number) end},
		--[[c]] { x =  0.75, y =  0.50, width = 0.25, height = 0.50, callback = function(self, obj) obj.number = "0" obj.hasDec = false end},
		--[[e]] { x =  0.75, y = -0.50, width = 0.25, height = 0.50, callback = function(self, obj) obj.enter = true obj.hasDec = false end},
	}
	sm.virtualButtons.client_configure(self, virtualButtons)
	self.effect = sm.effect.createEffect( "RadarDot", self.interactable)
	self.effect2 = sm.effect.createEffect( "RadarDot", self.interactable)
end

function Keypad.client_onFixedUpdate(self)
	if not sm.exists(self.interactable) then return end
	local hit, hitResult = sm.localPlayer.getRaycast(10)
	if not hit then
		self:client_stopEffect()
		return
	end
	
	local dotX, dotY = self:getLocalXY(hitResult.pointWorld)
	local buttonX, buttonY = sm.virtualButtons.client_getButtonPosition(self, dotX, dotY)
	
	if not buttonX then 
		self:client_stopEffect()
		return 
	end
	
	self.effect:setOffsetPosition(sm.vec3.new(buttonX/4, buttonY/4, 0))
	self.effect2:setOffsetPosition(sm.vec3.new(buttonX/4, buttonY/4, 0))
	if not self.effect:isPlaying() then
		self.effect:start()
		self.effect2:start()
	end
end

function Keypad.client_stopEffect(self)
	self.effect:setOffsetPosition(sm.vec3.new(100000,0,0))
	self.effect2:setOffsetPosition(sm.vec3.new(100000,0,0))
	if self.effect:isPlaying() then
		self.effect:stop()
		self.effect2:stop()
	end
end

function Keypad.getLocalXY(self, vec)
	local hitVec = vec - self.shape.worldPosition
	local localX = self.shape.right
	local localY = self.shape.at
	dotX = hitVec:dot(localX) * 4
	dotY = hitVec:dot(localY) * 4
	return dotX, dotY
end

-- Called on pressing [E]
function Keypad.client_onInteract( self ) 
	local hit, hitResult = sm.localPlayer.getRaycast(10) -- world point the vector hit
	if not hit then return end
	local dotX, dotY = self:getLocalXY(hitResult.pointWorld)
	
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

function Keypad.client_onDestroy(self)
	self:client_stopEffect()
end

