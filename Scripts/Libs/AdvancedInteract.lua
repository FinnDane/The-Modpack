-- Libs/AdvancedInteract.lua --
-- This library was made by Nick

--print("Libs/AdvancedInteract.lua reloaded")

if not sm.advancedInteract then
    sm.advancedInteract = {}
end

function sm.advancedInteract.create( parentClass )
    local object = {}
    
    object.parentClass = parentClass
    object.buttons = {}
    
    function object.addButton( self, name, x, y, width, height, effectName, onClick, onHover, active )
        local btn = {}
        
        btn.name = name
        btn.x = x
        btn.y = y
        btn.width = width
        btn.height = height
        btn.effectName = effectName
        btn.onClick = onClick
        btn.onHover = onHover
        btn.active = active and true
        
        function btn.destroy( self )
            if self.effect then
                self.effect:stop()
            end
        end
        
        if btn.effectName then
            btn.effect = sm.effect.createEffect(btn.effectName, self.parentClass.interactable)
        end
        
        self.buttons[btn.name] = btn
    end
    
    function object.destroy( self )
        for name, btn in pairs(self.buttons) do
            btn:destroy()
        end
    end
    
    function object.getRaycastPoint( self )
        local succes, raycastResult = sm.localPlayer.getRaycast(10)
    
        if succes then
            local hitPos = raycastResult.pointWorld -- world point the vector hit
            local worldPos = self.parentClass.shape:getWorldPosition() -- world point of block center
            local localHitVec = hitPos - worldPos -- vector of hit relative to block
            local localX = self.parentClass.shape:getRight()
            local localY = self.parentClass.shape:getAt()
            local localZ = self.parentClass.shape:getUp()
            dotX = sm.vec3.dot(localHitVec, localX) * 4
            dotY = sm.vec3.dot(localHitVec, localY) * 4
            dotZ = sm.vec3.dot(localHitVec, localZ) * 4
            
            return dotX, dotY, dotZ
        end
        
    end
    
    function object.onInteract( self )
        local dotX, dotY, dotZ = self:getRaycastPoint()
        
        --print("Dot X: "..string.format("%.3f",dotX))
        --print("Dot Y: "..string.format("%.3f",dotY))
        --print("Dot Z: "..string.format("%.3f",dotZ))
        
        local btn = self:getButtonAtPosition(dotX, dotY)
        if btn and btn.onClick then
            btn.onClick(self.parentClass, btn)
        end
    end
    
    function object.getButtonAtPosition( self, x, y )
        for name, btn in pairs(self.buttons) do
            if btn.x <= x and x <= btn.x + btn.width  and
               btn.y <= y and y <= btn.y + btn.height then
               
                return btn
            end
        end
    end
    
    return object
end

--TODO: Make it not interactable if not looking at button
--TODO: Highlight when buttons are in range, different color when looking at a button (onHover)