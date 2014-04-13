--[[
    技能的视图，根据技能属性，创建技能视图，支持单个飞出群攻 统一群攻 单攻
    -- 当技能做完，可以对敌方进行伤害的时候，调用父类的方法，把像敌方发送伤害信息的方法打开
]]

local SkillView = class("SkillView", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)

function SkillView:ctor( skillModel,battleModel )
	self.skillModel_ = skillModel
    self.battleModel_ = battleModel
	-- 通过代理注册事件的好处：可以方便的在视图删除时，清理所以通过该代理注册的事件，
    -- 同时不影响目标对象上注册的其他事件
    --
    local cls = self.skillModel_.class

	cc.EventProxy.new(self.skillModel_, self)
            :addEventListener(cls.BEGIN_ATK_EVENT, self.beginAtk_, self)
            :addEventListener(cls.ENTER_DIE_EVENT, self.enterDie_, self)
    self.bgLayer_ = display.newColorLayer(ccc4(255,255,255,0)):pos(0,0):addTo(self)
end

-- 进入攻击的状态
function SkillView:beginAtk_( event )
    -- 在攻击的动作中会调用父方法
    local delay1 = CCDelayTime:create(0.5)
    local callBack = CCCallFunc:create(function (  )
        self.skillModel_:switchSendInfo(true)
    end)
    local delay2 = CCDelayTime:create(1)
    local callBack1 = CCCallFunc:create(function (  )
        self.skillModel_:switchSendInfo(false)
        self:removeSelf()
        self.skillModel_:removeSelf()
        self.skillModel_ = nil
    end)
    local array = {delay1,callBack,delay2,callBack1}
    local actArray = CCArray:create()
    for i=1,#array do
        actArray:addObject(array[i])
    end
    self:runAction(CCSequence:create(actArray))
    local atker = self.skillModel_:getAtker()
    local targets = self.skillModel_:getTargets()

        display.addSpriteFramesWithFile("ccb/ccbResources/teture/csm.plist", "ccb/ccbResources/teture/csm.pvr.ccz")
    -- for i=1,#targets do
    --     local target = targets[i].target
    --     for i=1,3 do
    --         local atkerView = self.battleModel_:getPlayerForKey(atker:getSid()).view

    --         local targetView = self.battleModel_:getPlayerForKey(target:getSid()).view
    --         local frames = display.newFrames("chuansongmen_00%02d@2x.png",0,15)

    --         local sprite = display.newSprite(frames[1],atkerView:getPositionX() + (i - 2) * 200 ,atkerView:getPositionY() + 100)
    --         self:addChild(sprite)
    --         sprite:setScale(0.1)
    --         local animation = display.newAnimation(frames, 0.08)
    --         -- 播放动画
    --         sprite:playAnimationForever(animation)
    --         local moveto = CCMoveTo:create(0.5,ccp(targetView:getPositionX(),targetView:getPositionY()))
    --         local scale = CCScaleTo:create(0.5,0.4)
    --         sprite:runAction(CCSpawn:createWithTwoActions(moveto,scale))
    --     end
        
    -- end
end

-- 进入死亡的状态
function SkillView:enterDie_( event )
    
end

return SkillView
