
--[[--

“英雄”的视图

视图注册模型事件，从而在模型发生变化时自动更新视图

]]
-- local FightController = import("..controller.FightController")
HeroCardOwner = HeroCardOwner or {}
ccb["HeroCardOwner"] = HeroCardOwner

local function setEnableRecursiveCascading(node, enable)
    if node == nil then
        -- cclog("node == nil, return directly")
        return
    end

    if node ~= nil then
        node:setCascadeColorEnabled(enable)
        node:setCascadeOpacityEnabled(enable)
    end

    local obj = nil
    local children = node:getChildren()
    if children == nil then
        -- cclog("children is nil")
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len-1, 1 do
        local  child = tolua.cast(children:objectAtIndex(i), "CCNode")
        setEnableRecursiveCascading(child, enable)
    end
end

local HeroView = class("HeroView", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)
    return layer
end)

-- 动作完成后的事件
HeroView.ANIMATION_FINISHED_EVENT = "ANIMATION_FINISHED_EVENT"

function HeroView:ctor(hero,controller)
    -- self:setCascadeOpacityEnabled(true)
    local cls = hero.class
    self.controller_ = controller

    -- 通过代理注册事件的好处：可以方便的在视图删除时，清理所以通过该代理注册的事件，
    -- 同时不影响目标对象上注册的其他事件
    --
    -- EventProxy.new() --第一个参数是要注册事件的对象，第二个参数是绑定的视图
    -- 如果指定了第二个参数，那么在视图删除时，会自动清理注册的事件
    cc.EventProxy.new(hero, self)
        -- :addEventListener(cls.CHANGE_STATE_EVENT, self.onStateChange_, self)
        :addEventListener(cls.KILL_EVENT, self.onKill_, self)
        :addEventListener(cls.ATACKING_EVENT, self.onAtacking_, self)
        :addEventListener(cls.UNDERATK_EVENT, self.underAtk_, self)
        :addEventListener(cls.DECREASE_HP_EVENT, self.decreaseHp_, self)
    --     :addEventListener(cls.UNDER_VERTIGO_EVENT, self.enterVertigo, self)
    --     :addEventListener(cls.RELEASE_VERTIGO_EVENT, self.leaveVertigo, self)
    --     :addEventListener(cls.CDTIME_CD_EVENT,self.updateCdLabel_, self)

    self.hero_ = hero
    self.content = display.newSprite():addTo(self)
    self.sprite_ = display.newSprite():addTo(self)

    -- self.sprite_:setColor(ccc3(123,123,123))
    -- self.sprite_:setCascadeColorEnabled(true)
    -- self.sprite_:setCascadeOpacityEnabled(true)

    -- self.contentLayer = display.newColorLayer(ccc4(123,1,111,255)):addTo(self.sprite_)
    -- -- self.contentLayer = display.newLayer():addTo(self.sprite_)
    -- self.contentLayer:setContentSize(CCSizeMake(130,170))
    -- display.align(self.contentLayer, display.LEFT_BOTTOM, -60,-80)

    -- self.contentLayer:setCascadeColorEnabled(true)
    -- self.contentLayer:setCascadeOpacityEnabled(true)
    -- self.contentLayer:setOpacity(50)

    self.rankFrame_ = display.newSprite("ccb/ccbResources/cardImage/frame_4.png"):pos(0,0):addTo(self.sprite_)
    self.rankFrame_:setScale(0.4)

    self.rankSprite = display.newSprite("ccb/ccbResources/cardImage/rank_4.png"):pos(0,0):addTo(self.rankFrame_)
    display.align(self.rankSprite, display.LEFT_BOTTOM, 0, 0)

    self.heroBust_ = display.newSprite("ccb/ccbResources/herobust/hero_000406_bust_1.png"):addTo(self.rankFrame_)
    local size = self.rankFrame_:getContentSize()
    display.align(self.heroBust_, display.CENTER, size.width / 2, size.height / 2 + 40)

    -- self.heroBust_:setColor(ccc3(200,200,0))

    -- self.heroBust_:setColor(ccc3(200,200,0))
    -- local progressBg = display.newColorLayer(ccc4(123,23,55,255)):addTo(self.rankFrame_)
    self.progressBg = display.newLayer():addTo(self.rankFrame_)
    self.progressBg:setContentSize(CCSizeMake(251,29))
    display.align(self.progressBg, display.LEFT_BOTTOM, 65,0)
    self.progressBg:setScaleX(0.86)
    self.progressBg:setScaleY(1.3)

    self.progressBg:setCascadeColorEnabled(true)
    self.progressBg:setCascadeOpacityEnabled(true)

    local progressSize = self.progressBg:getContentSize()

    self.progress_ = CCProgressTimer:create(CCSprite:create("ccb/ccbResources/public/awardPro.png"))
    self.progress_:setType(kCCProgressTimerTypeBar)
    self.progress_:setMidpoint(CCPointMake(0, 0))
    self.progress_:setBarChangeRate(CCPointMake(1, 0))
    self.progress_:setPosition(ccp(progressSize.width / 2,progressSize.height / 2))
    self.progressBg:addChild(self.progress_,0, 101)
    self.progress_:setPercentage(hero:getHp(  ) / hero:getTotalHp(  ) * 100)

    -- progress:setOpacity(50)
    -- progress:setCascadeColorEnabled(true)
    -- progress:setCascadeOpacityEnabled(true)
    -- progressBg:setOpacity(50)
    -- self.sprite_:runAction(CCFadeOut:create(5))

    -- setEnableRecursiveCascading(self,true)

    -- local array = CCArray:create()
    -- array:addObject(CCTintTo:create(0.01, 255, 0, 0))
    -- self:runAction(CCSequence:create(array))
    setEnableRecursiveCascading(self,true)
end

function HeroView:getHeroInfo(  )
    return self.hero_
end

function HeroView:setCostomColor()

    setEnableRecursiveCascading(self,true)
end

-- function HeroView:flipX(flip)
--     self.sprite_:flipX(flip)
--     return self
-- end

-- function HeroView:isFlipX()
--     return self.sprite_:isFlipX()
-- end

-- function HeroView:onStateChange_(event)
--     self:updateSprite_(self.hero_:getState())
-- end

-- 正在减血
function HeroView:decreaseHp_( event )
    local damageLabel = ui.newTTFLabel({
            text = "-"..event.damage,
            size = 22,
            color = display.COLOR_RED,
        }):pos(0,90)
        :addTo(self, 1000)
        transition.moveBy(damageLabel, {y = 50, time = 1, onComplete = function()
            damageLabel:removeSelf()
        end})
    self.progress_:setPercentage(self:getHeroInfo():getHp(  ) / self:getHeroInfo():getTotalHp(  ) * 100)
end

-- 正在攻击时的动作
function HeroView:onAtacking_( event )
    -- 获得攻击的人
    -- 播放攻击的动作
    local array = CCArray:create()
    local rotateLeft = CCRotateBy:create(0.1,-30)
    local deleyTime1 = CCDelayTime:create(0.01)
    local rotateRight = CCRotateBy:create(0.1,90)
    local deleyTime2 = CCDelayTime:create(0.01)
    local rotateBack = CCRotateBy:create(0.05,-60)
    local callBack = CCCallFunc:create(function (  )
        self:dispatchEvent({name = HeroView.ANIMATION_FINISHED_EVENT,actType = "atking"})
    end)
    array:addObject(rotateLeft)
    array:addObject(deleyTime1)
    array:addObject(rotateRight)
    array:addObject(deleyTime2)
    array:addObject(rotateBack)
    array:addObject(callBack)
    self:runAction(CCSequence:create(array))
end

function HeroView:onKill_(event)
    -- self.sprite_:removeAllChildren()
    self:runAction(CCSequence:createWithTwoActions(CCFadeOut:create(0.05),CCCallFunc:create(function (  )
            self:dispatchEvent({name = HeroView.ANIMATION_FINISHED_EVENT,actType = "kill"})
    end)) )
    self.rankFrame1_ = CCGraySprite:create("ccb/ccbResources/cardImage/frame_4.png")
    self.rankFrame1_:setScale(0.4)
    self.content:addChild(self.rankFrame1_)
   
    self.rankSprite1 = CCGraySprite:create("ccb/ccbResources/cardImage/rank_4.png")
    self.rankSprite1:setAnchorPoint(ccp(0,0))
    self.rankFrame1_:addChild(self.rankSprite1)

    self.heroBust1_ = CCGraySprite:create("ccb/ccbResources/herobust/hero_000406_bust_1.png")
    self.rankFrame1_:addChild(self.heroBust1_)
    local size = self.rankFrame1_:getContentSize()
    self.heroBust1_:setPosition(ccp(size.width / 2, size.height / 2 + 40))

    local progressSize = self.progressBg:getContentSize()

    -- self.progress_:removeFromParentAndCleanup()
    -- self.progress_ = CCProgressTimer:create(CCGraySprite:create("ccb/ccbResources/public/awardPro.png"))
    -- self.progress_:setType(kCCProgressTimerTypeBar)
    -- self.progress_:setMidpoint(CCPointMake(0, 0))
    -- self.progress_:setBarChangeRate(CCPointMake(1, 0))
    -- self.progress_:setPosition(ccp(progressSize.width / 2,progressSize.height / 2))
    -- self.progressBg:addChild(self.progress_,0, 101)
    -- self.progress_:setPercentage(100)

    -- self.progress_:setCascadeColorEnabled(true)
    -- self.progress_:setCascadeOpacityEnabled(true)
    -- self.progress_:runAction(CCTintTo:create(0.001,123,123,123))
end

-- 正在遭受攻击
function HeroView:underAtk_( event )
    local array = CCArray:create()
    local moveUp = CCMoveBy:create(0.1,ccp(0,10))
    local tintToRed = CCTintTo:create(0.01,255,0,0)
    local moveDown = CCMoveBy:create(0.1,ccp(0,-20))
    local tintBack = CCTintTo:create(0.01,255,255,255)
    local moveBack = CCMoveBy:create(0.1,ccp(0,10))
    local delayTime = CCDelayTime:create(0.2)
    local callBack = CCCallFunc:create(function (  )
        self:dispatchEvent({name = HeroView.ANIMATION_FINISHED_EVENT,actType = "underatk"})
    end)
    array:addObject(moveUp)
    array:addObject(tintToRed)
    array:addObject(moveDown)
    array:addObject(tintBack)
    array:addObject(moveBack)
    array:addObject(delayTime)
    array:addObject(callBack)
    self:runAction(CCSequence:create(array))
end

return HeroView
