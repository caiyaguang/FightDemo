local FightViewBg = import("..views.FightViewBg")
local FightController = import("..controller.FightController")

FightSceneOwner = FightSceneOwner or {}
ccb["FightSceneOwner"] = FightSceneOwner

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    local  proxy = CCBProxy:create()
    local  node  = CCBuilderReaderLoad("FightScene.ccbi",proxy,FightSceneOwner)
    local  layer = tolua.cast(node,"CCLayer")
    self:addChild(layer)

    self.contentLayer = tolua.cast(FightSceneOwner["contentLayer"],"CCLayer")       -- 盛放所有界面元素的容器

    -- local FightBg = FightViewBg.new()           -- 战斗背景图片
    -- self.contentLayer:addChild(FightBg)
    -- local size = self.contentLayer:getContentSize()
    -- FightBg:setPosition(ccp( size.width / 2,size.height / 2 ))

    -- 加入动画层
        
    -- 加入控制层
    local controllerView = FightController.new()
    -- self.contentLayer:addChild(controllerView)
    -- local size = self.contentLayer:getContentSize()
    -- controllerView:setPosition(ccp( size.width / 2,size.height / 2 ))
    self:addChild(controllerView)
    -- controllerView:setAnchorPoint(ccp(0.5,0.5))
    -- controllerView:setPosition(ccp(0,0))
end

function MainScene:onEnter()
    if device.platform == "android" then
        -- avoid unmeant back
        self:performWithDelay(function()
            -- keypad layer, for android
            local layer = display.newLayer()
            layer:addKeypadEventListener(function(event)
                if event == "back" then app.exit() end
            end)
            self:addChild(layer)

            layer:setKeypadEnabled(true)
        end, 0.5)
    end
end

function MainScene:onExit()
end

return MainScene
