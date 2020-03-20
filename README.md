# Gideros_SimpleUI
Simple UI library for Gideros Studio

![preview](http://forum.giderosmobile.com/uploads/editor/9z/onq2m6ol36qa.gif)

# Layout example
![preview](../../../Gideros_examples/img/LayoutExample.png)
```lua
app @ application
app:setBackgroundColor(0x323232)

local tex = Texture.new("NinePatch.png")

local layout = Layout.new(1,1)
	:relSize(100,100)
	:cols()
	:paddingAll(4)
	:wrap(Layout.WRAP)
	
	:childs({
		Layout.new(1,50):relWidth(100):marginAll(2):paddingAll(10):setTextureBackground(tex),
		Layout.new(1,1):relSize(100,100):marginAll(2)	
			:wrap(Layout.WRAP)
			:childs({
				Layout.new(120,1):relHeight(100):marginAll(2):setTextureBackground(tex),
				Layout.new(1,1):relSize(100,100):marginAll(2):setTextureBackground(tex):ID("workFlow"):paddingAll(5),
			}),
		Layout.new(1,120,true):paddingAll(10):relWidth(100):marginAll(2):setTextureBackground(tex),
	})
layout:size(app:getLogicalHeight(), app:getLogicalWidth())
layout:update()

stage:addChild(layout)

local tf = TextField.new(nil, "Hello world", "|")
tf:setTextColor(0xffffff)
tf:setScale(2)
layout:getByID("workFlow"):addChild(tf)
```
