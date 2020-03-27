-- TODO:
--	alignment

Layout = Core.class(Sprite)
Layout.FIT = 1 -- максимально "забивает" колонку/строку элементами (без переноса в новую колонку/строку)
Layout.WRAP = 2 -- если элемент не входит по высоте, то он переносится в новый столбец/строку
Layout.DEBUG = false -- отрисовка всякой дебажной фигни :)

local default = {
	-- relative size (in %)
	_relWidth = 0, -- 0: disabled
	_relHeight = 0,
	
	_paddingLeft = 0,
	_paddingRight = 0,
	_paddingUp = 0,
	_paddingDown = 0,
	
	_marginLeft = 0,
	_marginRight = 0,
	_marginUp = 0,
	_marginDown = 0,
	
	_minW = 1, -- 0: disable
	_minH = 1,
	
	_maxW = 0, -- 0: disable
	_maxH = 0,
}
------------------------------------------
---- THROW ERROR IF  v is nil and < 0 ----
------------------------------------------
local function assertPositiveNum(v, text)
	assert(type(v) == "number" and v > 0, "[Layout]: "..text.." must be positive number! Was: " .. tostring(v))
end
------------------------------------------
-------------- ROUNDS VALUE --------------
------------------------------------------
local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return (num * mult + 0.5) // mult
end

------------------------------------------
------------------ INIT ------------------
------------------------------------------
-- w,h (number): size of the layout
-- clip (boolean): use clip or not (def: false) [optional]

function Layout:init(w,h,clip)
	self.enabled = true
	self.type = "Layout"
	
	for k,v in pairs(default) do
		self[k] = v
	end
	
	self._width = w or 0
	self._height = h or 0
	
	self._prevW = 0
	self._prevH = 0
	
	self._wrap = Layout.FIT
	
	self._orientation = "row" -- or "col"
	
	self._originalW = self._width
	self._originalH = self._height
	
	-- plain list
	self._data = {}
	self._ids = {}
	self._cache = {}
	
	self.clip = clip
	
	if clip then 
		self:setClip(0,0,self._width, self._height)
	end
	
	self.__gfx = Pixel.new(0xffffff, 0.15, self._width, self._height)
	self.__bgContainer = Sprite.new()
	self:addChild(self.__bgContainer)
	
	if Layout.DEBUG then 
		self.__gfxMargin = Pixel.new(0, 0.15, 0, 0)
		self.__bgContainer:addChild(self.__gfxMargin)
		
		self.__tf = TextField.new(nil, self._width .. " X " .. self._height)
		self.__tf:setTextColor(0xffffff)
		self.__tf:setAlpha(.5)
		local w,h = self.__tf:getSize()
		self.__tf:setY(h)
		--self.__tf.w = w
		--self.__tf.h = h
		--self.__tf:setPosition(self._width / 2 - w / 2, self._height / 2 + h / 2)
		self.__bgContainer:addChild(self.__tf)
		
		self._mode = ""
		self._mpx = 0
		self._mpy = 0
	end
end
------------------------------------------
----- UPDATE CLIPING & DEBUG  SHAPES -----
------------------------------------------
function Layout:updateClip()
	
	if self.clip then 
		self:setClip(0,0,self._width, self._height)
	end
	self.__gfx:setDimensions(self._width, self._height)
	
	if Layout.DEBUG then 
		local format = "%i-%i\n%i %i\n%i %i"
		
		self.__tf:setLayout{
			w = self._width,
			h = self._height,
			flags = FontBase.TLF_CENTER|FontBase.TLF_VCENTER
		}
		
		self.__tf:setText(string.format(format, self._width,self._height, self._marginLeft, self._marginRight, self._marginUp, self._marginDown))
		if self.clip then 
			self.__gfxMargin:removeFromParent()
		else
			self.__gfxMargin:setAnchorPosition(self._marginLeft-1,self._marginUp-1)
			self.__gfxMargin:setDimensions(self._width + self._marginLeft + self._marginRight-2, self._height + self._marginUp + self._marginDown-2)
		end
		--self.__tf:setScale((self._width / self.__tf.w)><(self._height / self.__tf.h)<>1)
		--local w,h = self.__tf:getSize()
		--self.__tf:setPosition(self._width / 2 - w / 2, self._height / 2 - h / 2)
	end
end
------------------------------------------
--------------- ADD CHILDS ---------------
------------------------------------------
function Layout:addChild(child)
	Sprite.addChild(self, child)
	child:setPosition(self._paddingLeft, self._paddingUp)
end
--
function Layout:child(child)
	if child.type ~= "Layout" then 
		for k,v in pairs(default) do
			if not child[k] then 
				child[k] = v
			end
		end
		local w,h = child:getSize()
		child._originalW = w
		child._originalH = h
		child:setPosition(0,0)
	end
	self:addChild(child)
	local ind = #self._data+1
	child.__ind = ind
	child.__owner = self
	self._data[ind] = child
	--if ind - 1 > 0 then ind -= 1 end
	return self
end
-- t (table): set of Layouts
function Layout:childs(t)
	for i,v in ipairs(t) do 
		self:child(v,flag)
	end
	self:update()
	return self
end
--
------------------------------------------
------------- REMOVE CHILDS --------------
------------------------------------------
-- 
function Layout:free()
	self:removeFromParent()
	self._data = nil
	self._ids = nil
	self._cache = nil
	self = nil
end
--
function Layout:remove(child)
	local i = Layout.DEBUG and 1 or 0
	
	local parent = child.__owner
	if parent then 
		parent:removeAt(parent:getChildIndex(child)-i)
	end
end
-- 
function Layout:removeAt(ind)
	local child = self._data[ind]
	if child then
		table.remove(self._data, ind)
		child:free()
		self:update()
	end
end
------------------------------------------
------------------- ID -------------------
------------------------------------------
local function setID(self)
	local id = self.__id or self.__ind
	local parent = self.__owner
	if parent and id and not rawget(parent._ids,id) then 
		--parent._ids[id] = self
		rawset(parent._ids, id, self)
	end
end
--
function Layout:ID(id)
	self.__id = id
	return self
end
--
function Layout:getByID(id)
	for i,v in ipairs(self._data) do 
		local parent = v:getParent()
		
		if parent and parent._ids[id] then 
			return parent._ids[id]
		else
			local id = v:getByID(id)
			if id then 
				return id
			end
		end
	end
end
------------------------------------------
------------ UPDATE (REBUILD) ------------
------------------------------------------
--
function Layout:scaleAllWidth(scale)
	local newX = self._paddingLeft
	for i,row in ipairs(self._data) do 
		row.__ind = i
		newX += row._marginLeft
		local summMargin = row._marginLeft + row._marginRight
		local fullW = 0
		if row._relWidth > 0 then 
			fullW = row:getWidth() + summMargin
		else
			fullW = (row._originalW + summMargin) * scale
		end
		if row.width then row:width(fullW - summMargin) end
		row:setPosition(
			newX,
			self._paddingUp + row._marginUp
		)
		newX += row._marginRight + row:getWidth()
	end
end
--
function Layout:scaleAllHeight(scale)
	local newY = self._paddingUp
	for i,row in ipairs(self._data) do 
		row.__ind = i
		newY += row._marginUp
		local summMargin = row._marginUp + row._marginDown
		local fullH = 0
		if row._relHeight > 0 then
			fullH = row:getHeight() + summMargin
		else
			fullH = (row._originalH + summMargin) * scale
		end
		
		if row.height then row:height(fullH - summMargin) end
		row:setPosition(
			self._paddingLeft + row._marginLeft,
			newY
		)
		newY += row._marginDown + row:getHeight()
	end
end
--
function Layout:updateRelSize(parent, sw, sh)
	local relW = self._relWidth
	sw = sw or 0
	sh = sh or 0
	
	if relW > 0 then 
		local newW = ((parent:getWidth() - parent._paddingLeft - parent._paddingRight - sw) * relW) / 100
		self:width(newW - self._marginLeft - self._marginRight)
	end
	local relH = self._relHeight
	if relH > 0 then 
		local newH = ((parent:getHeight() - parent._paddingUp - parent._paddingDown - sh) * relH) / 100
		self:height(newH - self._marginUp - self._marginDown)
	end
end
--
function Layout:getSumms()
	local summWA,summHA = 0,0
	local summWR,summHR = 0,0
	for i,v in ipairs(self._data) do 
		summWA += v._relWidth
		summHA += v._relHeight
		
		if v._relWidth == 0 then 
			summWR += v:getWidth() + v._marginLeft + v._marginRight
		end
		if v._relHeight == 0 then 
			summHR += v:getHeight() + v._marginUp + v._marginDown
		end
	end
	return summWA, summHA, summWR, summHR
end
--
function Layout:colUpdate(ind, first)
	local summW,summH, absSW,absSH = self:getSumms()	
	local n = #self._data
	-- максимальная ширина элемена (без отступа слева)
	local maxW = first:getWidth() + first._marginRight
	-- максимальное занчение правого края элемента в колонке
	local maxX = first:getWidth() + first._marginRight + first._marginLeft
	
	-- доступная высота родителя (без учета паддингов)(в px)
	local aH = self._height - self._paddingUp - self._paddingDown	
	
	-- сумма абсолютных высот элементов (в px)
	local summAbsHeight = 0
	-- считаем абсолютную высоту только для тех у кого не задано значение 
	-- абсолютной высоты
	if first._relHeight == 0 then 
		summAbsHeight = first._originalH + first._marginUp + first._marginDown
	end
	
	local isNewLine = false
	local updateScale = nil
	local last = first
	
	for i = ind, n do 
		local row = self._data[i]
		row.__ind = i
		setID(row)
		
		-- меняем размер элемента 
		if row.updateRelSize then 
			row:updateRelSize(self, absSW, absSH)
		end
		
		local x,y = last:getPosition()
		if row._relHeight == 0 then 
			summAbsHeight += row._originalH + row._marginUp + row._marginDown
		end
		-- режим "Забивать"
		-- Layout.FIT
		if self._wrap == 1 then 
			-- считаем сколько всего пикселей осталось 
			local av = aH - (summH * aH)/100
			-- если сумма высот превышает допустимую, то нужно уменьшить высоту
			-- всех элементов 
			if summAbsHeight > av and not self._isFixed then 
				-- считаем во сколько раз нужно уменьшить (или увеличить) элементы
				-- обновление произойдет после данного цикла в целях оптимизации
				updateScale = av / summAbsHeight
			-- если сумма допусимая, то просто ставим элемент ниже предыдущего
			else
				row:setPosition(
					self._paddingLeft + row._marginLeft,
					y + last:getHeight() + last._marginDown + row._marginUp
				)
			end
		-- режим "перенос"
		-- Layout.WRAP
		elseif self._wrap == 2 then 
			local newY = y + last:getHeight() + last._marginDown + row._marginUp
			local nextY = newY + row:getHeight() + row._marginDown
			
			if nextY > self:getHeight() - self._paddingDown then 
				newY = self._paddingUp + row._marginUp
				row:setPosition(maxX + row._marginLeft + self._paddingLeft, newY)
				maxW = row:getWidth() + row._marginRight
				maxX += row._marginLeft + row:getWidth() + row._marginRight
				isNewLine = true
			else
				local xx = self._paddingLeft + row._marginLeft
				if isNewLine then 
					xx = x - last._marginLeft + row._marginLeft
				end
				row:setPosition(xx, newY)
			end
			maxW = maxW <> (row:getWidth() + row._marginRight)
			maxX = maxX <> (row:getWidth() + row._marginRight + row._marginLeft)
		end
		
		if row.update then 
			row:update()
		end
		last = row
	end	
	
	if updateScale then 
		self:scaleAllHeight(updateScale)
	end
end
--
function Layout:rowUpdate(ind, first)
	local summW,summH, absSW,absSH = self:getSumms()
	
	local n = #self._data
	-- максимальная высота элемена (без отступа слева)
	local maxH = first:getHeight() + first._marginDown
	-- максимальное занчение нижнего края элемента в строке
	local maxY = first:getHeight() + first._marginDown + first._marginUp
	
	-- доступная ширина родителя (без учета паддингов)(в px)
	local aW = self:getWidth() - self._paddingLeft - self._paddingRight
	
	-- сумма абсолютных ширин элементов (в px)
	local summAbsWidth = 0
	-- считаем абсолютную высоту только для тех у кого не задано значение 
	-- абсолютной ширины
	if first._relWidth == 0 then 
		summAbsWidth = first._originalW + first._marginLeft + first._marginRight
	end
	
	local isNewLine = false
	local updateScale = nil
	local last = first
	
	for i = ind, n do 
		local row = self._data[i]
		row.__ind = i
		setID(row)
		
		-- меняем размер элемента 
		if row.updateRelSize then row:updateRelSize(self, absSW,absSH) end
		
		local x,y = last:getPosition()
		if row._relWidth == 0 then 
			summAbsWidth += row._originalW + row._marginLeft + row._marginRight
		end
		-- режим "Забивать"
		-- Layout.FIT
		if self._wrap == 1 then 
			-- считаем сколько всего пикселей осталось 
			local av = aW - (summW * aW)/100
			
			-- если сумма ширин превышает допустимую, то нужно уменьшить ширину 
			-- всех элементов 
			if summAbsWidth > av and not self._isFixed then 
				-- считаем во сколько раз нужно уменьшить (или увеличить) элементы
				-- обновление произойдет после данного цикла в целях оптимизации
				updateScale = av / summAbsWidth
			-- если сумма допусимая, то просто ставим элемент правее предыдущего
			else
				row:setPosition(
					x + last:getWidth() + last._marginLeft + row._marginRight,
					self._paddingUp + row._marginUp
				)
			end
		-- режим "перенос"
		-- Layout.WRAP
		elseif self._wrap == 2 then 
			local newX = x + last:getWidth() + last._marginLeft + row._marginRight
			local nextX = newX + row:getWidth() + row._marginRight
			
			if nextX > self:getWidth() - self._paddingRight then 
				newX = self._paddingLeft + row._marginLeft
				row:setPosition(newX, maxY + row._marginUp + self._paddingUp)
				maxH = row:getHeight() + row._marginUp + row._marginDown
				maxY += row._marginUp + row:getHeight() + row._marginDown
				isNewLine = true
			else
				local yy = self._paddingUp + row._marginUp
				if isNewLine then 
					yy = y - last._marginUp + row._marginUp
				end
				row:setPosition(newX, yy)
			end
			maxH = maxH <> (row:getHeight() + row._marginDown)
			maxY = maxY <> (row:getHeight() + row._marginDown + row._marginUp)
		end
		
		if row.update then row:update() end
		last = row
	end	
	
	if updateScale then 
		self:scaleAllWidth(updateScale)
	end
end
--
function Layout:update(ind)
	ind = ind or 2
	local n = #self._data
	if n > 0 and (self:getWidth() ~= self._prevW or self:getHeight() ~= self._prevW) then 
		local first = self._data[1]
		first:setPosition(self._paddingLeft + (first._marginLeft or 0), self._paddingUp + (first._marginUp or 0)	)
		if first.updateRelSize then 
			first:updateRelSize(self)
		end
		first.__ind = 1
		setID(first)
		
		-- call "colUpdate" / "rowUpdate" to rebuild layout for column/rows 
		-- depending on "_orientation" variable
		self[self._orientation.."Update"](self, ind, first)
		
		if first.update then first:update() end
		
	end
	return self
end

--
function Layout:recursiveUpdate()
	local owner = self._owner
	self:update()
	if owner then 
		owner:recursiveUpdate()
	end
	return self
end
------------------------------------------
------------------ CLIP ------------------
------------------------------------------
function Layout:clip(flag)
	self.clip = flag
	return self
end
------------------------------------------
----------------- QUERY ------------------
------------------------------------------
function Layout:query(x, y)
	if self:hitTestPoint(x, y) then 
		for k,v in ipairs(self._data) do 
			if v.type == "Layout" then
				if v:hitTestPoint(x, y) then 
					if #v._data > 0 then 
						return v:query(x,y)
					else
						return v
					end
				end
			end
		end
		return self
	end
end
------------------------------------------
---------------- USE ROWS ----------------
------------------------------------------
function Layout:rows(isFixed)
	self._isFixed = isFixed
	self._orientation = "row"
	return self
end
------------------------------------------
---------------- USE COLS ----------------
------------------------------------------
function Layout:cols(isFixed)
	self._isFixed = isFixed
	self._orientation = "col"
	return self
end
------------------------------------------
---------------- WRAP MODE ---------------
------------------------------------------
function Layout:wrap(value)
	self._wrap = value
	self:updateClip()
	return self
end
------------------------------------------
---------------- PADDING ----------------
------------------------------------------
function Layout:padding(left, right, up, down) 
	self._paddingLeft = left or 0
	self._paddingRight = right or 0
	self._paddingUp = up or 0
	self._paddingDown = down or 0
	
	self:updateClip()
	return self 
end
--
function Layout:paddingAll(value) 
	self._paddingLeft = value
	self._paddingRight = value
	self._paddingUp = value
	self._paddingDown = value
	
	self:updateClip()
	return self 
end
------------------------------------------
----------------- MARGIN -----------------
------------------------------------------
function Layout:margin(left, right, up, down) 
	self._marginLeft = left or 0
	self._marginRight = right or 0
	self._marginUp = up or 0
	self._marginDown = down or 0
	
	self:updateClip()
	return self 
end
--
function Layout:marginAll(value)
	self._marginLeft = value
	self._marginRight = value
	self._marginUp = value
	self._marginDown = value
	
	self:updateClip()
	return self 
end
------------------------------------------
-------------- MINIMUM SIZE --------------
------------------------------------------
function Layout:minSize(w, h)
	self._minW = w
	self._minH = h
	return self
end
--
function Layout:minWidth(w)
	self._minW = w
	return self
end
--
function Layout:minHeight(h)
	self._minH = h
	return self
end
------------------------------------------
-------------- MAXIMUM SIZE --------------
------------------------------------------
function Layout:maxSize(w, h)
	self._maxW = w
	self._maxH = h
	return self
end
--
function Layout:maxWidth(w)
	self._maxW = w
	return self
end
--
function Layout:maxHeight(h)
	self._maxH = h
	return self
end
------------------------------------------
-------------- CHANGE WIDTH --------------
------------------------------------------
--
function Layout:relWidth(percent)
	assertPositiveNum(percent, "relative width")
	assert(percent <= 100, "[Layout]: relative width must be <= 100, but was: "..percent)
	self._relWidth = percent
	return self
end
--
function Layout:width(w)
	if self._minW > 0 and w < self._minW then 
		w = self._minW
	end
	if self._maxW > 0 and w > self._maxW then 
		w = self._maxW
	end
	assertPositiveNum(w, "width")
	self._prevW = self._width
	self._width = w
	self:updateClip()
	return self
end
--
function Layout:addWidth(value)
	self:width(self._width + value)
end
--
function Layout:scaleWidth(value)
	self:width(self._width * value)
end
------------------------------------------
-------------- CHANGE HEIGHT -------------
------------------------------------------
--
function Layout:relHeight(percent)
	assertPositiveNum(percent, "relative height")
	assert(percent <= 100, "[Layout]: relative height must be <= 100, but was: "..percent)
	self._relHeight = percent
	return self
end
--
function Layout:height(h)
	if self._minH > 0 and h < self._minH then 
		h = self._minH
	end
	if self._maxH > 0 and h > self._maxH then 
		h = self._maxH
	end
	assertPositiveNum(h, "height")
	self._prevH = self._height
	self._height = h
	self:updateClip()
	return self
end
--
function Layout:addHeight(value)
	self:height(self._height + value)
end
--
function Layout:scaleHeight(value)
	self:height(self._height * value)
end
------------------------------------------
--------- CHANGE WIDTH & HEIGHT ----------
------------------------------------------
-- 
function Layout:relSize(w, h)
	self:relWidth(w)
	self:relHeight(h)
	return self
end
--
function Layout:size(w, h)
	self:width(w)
	self:height(h)
	return self
end
--
function Layout:addSize(dw,dh)
	self:size(self._width + dw, self._height + dh)
end
--
function Layout:scaleSize(dw,dh)
	self:size(self._width * dw, self._height * dh)
end
------------------------------------------
---------------- ADD GFX -----------------
------------------------------------------
function Layout:setSolidBackground(color, alpha)
	self.__gfx:setColor(color, alpha or 1)
	self.__bgContainer:addChild(self.__gfx)
	return self
end
--
function Layout:setTextureBackground(texture, v, color, alpha)
	self.__gfx:setTexture(texture)
	self.__gfx:setColor(color or 0xffffff, alpha or 1)
	self.__gfx:setNinePatch(v or 4)
	self.__bgContainer:addChild(self.__gfx)
	return self
end
------------------------------------------
------------ SUI INTEGRATION -------------
------------------------------------------
function Layout:input(e)
	local x = e.x or e.touch.x
	local y = e.y or e.touch.y
	
	local child = self:query(x, y)
	if child then 
		if child.type == "Layout" then 
			local n = child:getNumChildren()
			for i = n, 1, -1 do 
				local spr = child:getChildAt(i)
				if spr.enabled and spr.input and spr:input(e) then 
					return true
				end
			end
		else
			if child.enabled and child.input and child:input(e) then  return true end
		end
	end
end
------------------------------------------
---------------- OVERRIDE ----------------
------------------------------------------
function Layout:getWidth() 
	return self._width
end
--
function Layout:getHeight() 
	return self._height
end
--
function Layout:getSize() 
	return self._width, self._height
end
-- TODO:
function Layout:setVisible(visible)
	
end
------------------------------------------
-------------- Mouse resize --------------
------------------------------------------
local function overlapRect(x,y, rx,ry,rw,rh)
	return not(x < rx or y < ry or x > rx+rw or y > ry+rh)
end
--
function Layout:allowResize(left, right, top, bottom)
	self._resizeLeft = left
	self._resizeRight = right
	self._resizeTop = top
	self._resizeBottom = bottom
	
	if not self:hasEventListener("mouseMove") then 
		self:addEventListener("mouseHover", self.mouseHover, self)
		self:addEventListener("mouseMove", self.mouseMove, self)
		self:addEventListener("mouseDown", self.mouseDown, self)
	end
	return self
end
--
function Layout:allowResizeAll(flag)
	self._resizeLeft = flag
	self._resizeRight = flag
	self._resizeTop = flag
	self._resizeBottom = flag
	
	if not self:hasEventListener("mouseMove") then 
		self:addEventListener("mouseHover", self.mouseHover, self)
		self:addEventListener("mouseMove", self.mouseMove, self)
		self:addEventListener("mouseDown", self.mouseDown, self)
	end
	return self
end
--
function Layout:resizeOffset(off)
	self._resizeOffset = off
	return self
end
--
function Layout:mouseHover(e)
	local cursor = "arrow"
	local x,y = self:globalToLocal(e.x,e.y)
	local off = self._resizeOffset or 10
	local sx,sy = self:getPosition()
	
	if self._resizeTop and overlapRect(x,y, sx+off,sy-off,self._width-off*2,off*2) then 
		cursor = "sizeVer"
		self._mode = "T"
	elseif self._resizeRight and overlapRect(x,y, sx+self._width-off,sy+off,off*2,self._height-off*2) then 
		cursor = "sizeHor"
		self._mode = "R"
	elseif self._resizeBottom and overlapRect(x,y, sx+off,sy+self._height-off*2,self._width-off*2,off*2) then 
		cursor = "sizeVer"
		self._mode = "B"
	elseif self._resizeLeft and overlapRect(x,y, sx-off,sy+off,off*2,self._height-off*2) then 
		cursor = "sizeHor"
		self._mode = "L"
	else
		self._mode = ""
		cursor = "arrow"
	end
	application:set("cursor", cursor)
end
--
function Layout:mouseMove(e)
	local dx,dy = e.x - self._mpx, e.y - self._mpy
	if self._mode == "T" then 
		self:setY(e.y)
		self:addHeight(-dy)
	elseif self._mode == "R" then 
		self:addWidth(dx)
	elseif self._mode == "B" then 
		self:addHeight(dy)
	elseif self._mode == "L" then 
		self:setX(e.x)
		self:addWidth(-dx)
	end
	--if (dx ~= 0 or dy ~= 0) then 
		self:update()
		if self.__owner then 
			self.__owner:update()
		end
	--end
	self._mpx = e.x
	self._mpy = e.y
end
--
function Layout:mouseDown(e)
	self._mpx = e.x
	self._mpy = e.y
end
--
