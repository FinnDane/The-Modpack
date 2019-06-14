function debugmode() if sm.game.getCurrentTick() > 1 and not sm.isServerMode() then local modders = {["Brent Batch"] = true, ["TechnologicNick"] = true, ["MJM"] = true, ["Mini"] = true} local name = sm.localPlayer.getPlayer().name if modders[name] then function debugmode() return true end return true else function debugmode() return false end return false end end end

function debug(...) if debugmode() then print(...) end end

if sm.interactable.SEversion and (sm.interactable.SEversion <= 1.0) and not debugmode() then return end
sm.interactable.SEversion = 1.0


if not printO then
    printO = print
end
function print(...)
	if debugmode() then
		printO("[" .. sm.game.getCurrentTick() .. "]", sm.isServerMode() and "[Server]" or "[Client]", ...)
	else
		printO(...)
	end
end


-- interactable: setValue getValue
if not sm.interactable.values then sm.interactable.values = {} end -- stores values --[[{{tick, value}, lastvalue}]]

function sm.interactable.setValue(interactable, value)  
    local currenttick = sm.game.getCurrentTick()
    sm.interactable.values[interactable.id] = {
        {tick = currenttick, value = {value}}, 
        sm.interactable.values[interactable.id] and (    
            sm.interactable.values[interactable.id][1] ~= nil and 
            (sm.interactable.values[interactable.id][1].tick < currenttick) and 
            sm.interactable.values[interactable.id][1].value or 
			sm.interactable.values[interactable.id][2]
        ) 
        or nil
    }
end
function sm.interactable.getValue(interactable, NOW)    
	if sm.exists(interactable) and sm.interactable.values[interactable.id] then
		if sm.interactable.values[interactable.id][1] and (sm.interactable.values[interactable.id][1].tick < sm.game.getCurrentTick() or NOW) then
			return sm.interactable.values[interactable.id][1].value[1]
		elseif sm.interactable.values[interactable.id][2] then
			return sm.interactable.values[interactable.id][2][1]
		end
	end
	return nil
end
function instantiateValueHack(interactable)
	interactable.setValue = sm.interactable.setValue
	interactable.getValue = sm.interactable.getValue
end
-- sm.interactable.getValue(parents[1]) or parents[1].power


if not sm.virtualButtons then sm.virtualButtons = {} end
function sm.virtualButtons.client_configure(parentInstance, virtualButtons)
	parentInstance.__virtualButtons = virtualButtons
end
function sm.virtualButtons.client_onInteract(parentInstance, x, y) -- x, y in blocks
	for _, virtualButton in pairs(parentInstance.__virtualButtons or {}) do
		if math.abs(x-virtualButton.x) < virtualButton.width and
			math.abs(y-virtualButton.y) < virtualButton.height then
			virtualButton:callback(parentInstance)
		end
	end
end

