--[[
	Copyright (c) 2020 Modpack Team
	Brent Batch#9261
]]--
dofile "../../libs/load_libs.lua"

print("loading SmartControl.lua")


SmartControl = class( nil )
SmartControl.maxChildCount = -1
SmartControl.maxParentCount = -1
SmartControl.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
SmartControl.connectionOutput = sm.interactable.connectionType.piston + sm.interactable.connectionType.bearing
SmartControl.colorNormal = sm.color.new(0xe54500ff)
SmartControl.colorHighlight = sm.color.new(0xff7033ff)
SmartControl.poseWeightCount = 1

function SmartControl.server_onCreate(self)
	self.last_length = {}

end
--smart engine/controller (setangle mode(angle, speed, strength), setspeed mode(speed, strength))
--smart piston/suspension (length, speed , strength
function SmartControl.server_onFixedUpdate(self, dt)	
	local parents = self.interactable:getParents()

	local anglelength = nil
	local speed = nil
	local strength = nil
	local logic = false
	local seats = 0
	local seat = 0
	local haslogic = false
	local stiffness = nil
	for k, v in pairs(parents) do
		local _pType = v:getType()
		local _pUuid = tostring(v:getShape():getShapeUuid())
		local _pSteer = v:hasSteering()
		if not _pSteer and _pType == "scripted" and _pUuid ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			local _pColor = tostring(v:getShape():getColor())
			if _pColor == "eeeeeeff" then
				-- speed
				speed = (speed and speed or 0) + v.power
			elseif _pColor == "222222ff" then
				-- strength
				strength = (strength and strength or 0) + v.power
			elseif _pColor == "7f7f7fff" then
				stiffness = (stiffness and stiffness or 0) + v.power
			elseif _pColor == "4a4a4aff" then
				stiffness = (stiffness and stiffness or 0) + v.power
			else
				-- angle/length
				anglelength = (anglelength and anglelength or 0) + v.power
			end
		elseif _pSteer or _pType == "steering" or _pUuid == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" or _pUuid == "e627986c-b7dd-4365-8fd8-a0f8707af63d" then
			-- seat
			seats = seats + 1
			seat = seat + v.power
		else
			--logic
			if not haslogic then logic = 1 end
			logic = logic * v.power
			haslogic = true
		end
	end
	if seats>0 then seat = seat/seats else seat = 1 end -- take average of all seat WS, no seat -> just enable this thing
	if not haslogic then logic = 1 end -- default on if no logic input
	if not stiffness then stiffness = 100 end -- default suspension-ish behaviour
	
	-- game limits: (functions will throw errors when not limited between -3.402e+38 and 3.402e+38)
	if speed then speed = sm.util.clamp(speed, -3.402e+38, 3.402e+38) end
	if strength then strength = sm.util.clamp(strength, -3.402e+38, 3.402e+38) end
	if anglelength then anglelength = sm.util.clamp(anglelength, -3.402e+38, 3.402e+38) end
	if stiffness then stiffness = sm.util.clamp(stiffness, -3.402e+38, 3.402e+38) end
	

	if logic ~= 0 then
		local angle = (anglelength ~= nil and math.rad(anglelength) or nil)
		local rotationspeed = (speed ~= nil and math.rad(speed) or math.rad(0))-- speed 0 by default as to not let it rotate bearing when no inputs
		local rotationstrength = (strength ~= nil and strength or 10000)
		for k, v in pairs(sm.interactable.getBearings(self.interactable )) do
			if anglelength == nil then
				-- engine
				sm.joint.setMotorVelocity(v, rotationspeed*seat, rotationstrength ) 
			else
				-- controller
				local angle1 = math.deg(angle)%360 - (math.deg(angle)%360 > 180 and 360 or 0)
				local angle2 = (math.deg(v.angle)%360 - (math.deg(v.angle)%360 > 180 and 360 or 0))*(v.reversed  and 1 or -1)
				local extraforce = math.abs(((angle1 - angle2)+180)%360-180)/1000*stiffness
				sm.joint.setTargetAngle( v, angle*seat, rotationspeed, rotationstrength*(1+ extraforce) - v.angularVelocity*10) -- change 10 to 1-200 depending on how well dampening oscillations works
				
			end		
		end
		
		local length = (anglelength ~= nil and anglelength or 0)
		local pistonspeed = (speed ~= nil and speed or 15)--default to 15
		local pistonstrength = (strength ~= nil and strength or 6666)
		for k, v in pairs(sm.interactable.getPistons(self.interactable )) do
			-- delta length for suspension-ish
			if not self.last_length[v.id] then self.last_length[v.id] = v.length end
			local extraforce = math.abs(length - (v.length-1))*stiffness/100

			local maxImpulse = pistonstrength*(1+ extraforce )  - (v.length-self.last_length[v.id])*10 -- change 10 to 1-200 depending on how well dampening oscillations works
			maxImpulse = sm.util.clamp(maxImpulse, -3.402e+38, 3.402e+38)

			sm.joint.setTargetLength( v, length*seat, pistonspeed, maxImpulse )
		end
	else
		local rotationspeed = (speed ~= nil and math.rad(speed) or math.rad(90)) -- if no input speed setting set , give it a 90°/s speed as to be able to reset bearing to 0°
		local rotationstrength = (strength ~= nil and strength or 10000)
		for k, v in pairs(sm.interactable.getBearings(self.interactable )) do
			if anglelength == nil then
				sm.joint.setMotorVelocity(v, 0, rotationstrength )
			else -- check if v.reversed works suspension-ish when powering off the smart engine  ('v.reversed and 1 or -1)--> test with reversed bearings
				local extraforce = math.abs(v.angle)*(v.reversed  and 1 or -1)/1000*stiffness -- acts more like suspension when strength collapses for current force

				local maxImpulse = rotationstrength*(1+ extraforce) - v.angularVelocity*10 -- change 10 to 1-200 depending on how well dampening oscillations works
				maxImpulse = sm.util.clamp(maxImpulse, -3.402e+38, 3.402e+38)

				sm.joint.setTargetAngle( v, 0, rotationspeed, maxImpulse)
			end
		end
		
		local length = (anglelength ~= nil and anglelength or 0)
		local pistonspeed = (speed ~= nil and speed or 15)--default to 15
		local pistonstrength = (strength ~= nil and strength or 6666)
		for k, v in pairs(sm.interactable.getPistons(self.interactable )) do
			-- delta length for suspension-ish
			if not self.last_length[v.id] then self.last_length[v.id] = v.length end
			local extraforce = math.abs(length - (v.length-1))*stiffness/100

			local maxImpulse = pistonstrength*(1+ extraforce) - (v.length-self.last_length[v.id])*10 -- change 10 to 1-200 depending on how well dampening oscillations works
			maxImpulse = sm.util.clamp(maxImpulse, -3.402e+38, 3.402e+38)

			sm.joint.setTargetLength( v, 0, pistonspeed, maxImpulse )
		end
	end
end
