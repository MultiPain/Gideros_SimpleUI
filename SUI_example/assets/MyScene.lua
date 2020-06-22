MyScene = Core.class(Sprite)

function MyScene:init()
	-- SUI.new(inputType)
	-- 	inputType (string): can be "touch" or "mouse". 
	--	If not set then you have to call touch/mouse events 
	--	by yourself (see example below), otherwise it will be
	--	handled by SUI class [optional]
	self.ui = SUI.new()
	self:addChild(self.ui)
	
	-- create horizontal group
	local g = self.ui:hGroup(0, 10)
	
	local subGroup = self.ui:vGroup(0, 10)
	
	-- create button
	subGroup:add(self.ui:button(Pixel.new(0x323232,1, 32, 32), function(obj) print("DARK button pressed") end))
	-- create text button
	local tb = self.ui:button(Pixel.new(0x505050,1, 32, 32), function(obj) print("DARK button pressed with text") end)
	tb:addText("Click me!") --< can be used for any component, not perfect, but something )))
	tb:setTextColor(0xffffff)
	subGroup:add(tb)
	
	
	g:add(subGroup)
	
	-- create image button
	g:add(self.ui:button(Bitmap.new(PACK:getTextureRegion("button1.png")), function(obj) print("Image button pressed") end))
	-- create image button with pressed effect
	local b = self.ui:button(Bitmap.new(PACK:getTextureRegion("button1.png")), function(obj) print("Another image button pressed") end)
	b:setHightlight(function(obj, state)
		-- get image
		local img = obj:getChildAt(1)
		if not state then img:setY(0) else img:setY(2) end
	end)
	g:add(b)
	-- create horizontal slider
	g:add(self.ui:hSlider(0,100,0,false,{Bitmap.new(PACK:getTextureRegion("bg_line3.png")),Bitmap.new(PACK:getTextureRegion("knob3.png"))}, function(obj,value,state) print("H Slider: "..value.." ["..state.."]") end))
	-- create vertical slider 
	g:add(self.ui:vSlider(0,100,0,false,{Bitmap.new(PACK:getTextureRegion("bg_line1.png")),Bitmap.new(PACK:getTextureRegion("knob1.png"))}, function(obj,value,state) print("V Slider: "..value.." ["..state.."]") end))
	-- create horizontal integer slider
	g:add(self.ui:hSlider(1,5,1,true,{Bitmap.new(PACK:getTextureRegion("bg_line4.png")),Bitmap.new(PACK:getTextureRegion("knob4.png"))}, function(obj,value,state) print("H Slider: "..value.." ["..state.."]") end))
	
	subGroup = self.ui:vGroup(0, 10)
	-- add some checkboxes
	for i = 1, 4 do 
		local cb = self.ui:checkBox("test", nil, {Bitmap.new(PACK:getTextureRegion("check5.png")),Bitmap.new(PACK:getTextureRegion("check6.png"))},function(obj,state) print("CheckBox #"..obj.id, "State: "..state) end)
		cb.id = i
		subGroup:add(cb)
	end
	g:add(subGroup)
	
	subGroup = self.ui:vGroup(0, 10)
	-- add some radio buttons (actualy, its a checkbox, but without a group name)
	for i = 1, 4 do 
		local cb = self.ui:checkBox("", nil, {Bitmap.new(PACK:getTextureRegion("check7.png")),Bitmap.new(PACK:getTextureRegion("check8.png"))},function(obj,state) print("ComboBox #"..obj.id, "State: "..state) end)
		cb.id = i
		subGroup:add(cb)
	end
	g:add(subGroup)
	
	self.progress = self.ui:hProgress(100, false, {
		Pixel.new(0,1,200,20),
		{img=Pixel.new(0x00ff00,1,190,16),set={anchorX=-5,anchorY=-2}}
	})
	g:add(self.progress)
	
	self.timer = 0
	
	-- You dont need to add listeners for SUI library if 
	-- you have added inputType parameter to it.
	self:addEventListener("touchesBegin", self.touchBegin, self)
	self:addEventListener("touchesMove", self.touchMove, self)
	self:addEventListener("touchesEnd", self.touchEnd, self)
	
	self:addEventListener("enterFrame", self.update, self)
end
--
function MyScene:update(e)
	self.timer += e.deltaTime
	local p = math.sin(self.timer)
	
	self.progress:setProgress(SUI.map(p,-1,1,0,100))
end
--
function MyScene:touchBegin(e)
	-- if not touching UI 
	if not self.ui:touch(e) then 
		
	end
end
--
function MyScene:touchMove(e)
	-- if not touching UI 
	if not self.ui:touch(e) then 
		
	end
end
--
function MyScene:touchEnd(e)
	-- if not touching UI 
	if not self.ui:touch(e) then 
		
	end
end
