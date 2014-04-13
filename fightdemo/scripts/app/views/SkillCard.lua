
--[[--

“英雄”的技能卡片视图

视图注册模型事件，从而在模型发生变化时自动更新视图

]]
-- 一个设置节点层叠显示颜色的方法，用来解决一个引擎bug
local function setEnableRecursiveCascading(node, enable)
    if node ~= nil then
        node:setCascadeColorEnabled(enable)
        node:setCascadeOpacityEnabled(enable)
    end

    local obj = nil
    local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
        local  child = tolua.cast(children:objectAtIndex(i), "CCNode")
        setEnableRecursiveCascading(child, enable)
    end
end

local SkillCard = class("SkillCard", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)
    return layer
end)

SkillCard.IMG_URL = "ccb/ccbResources/public/"
SkillCard.AVATAR_IMG_URL = "ccb/ccbResources/avatar/"

-- 动作完成后的事件
SkillCard.ANIMATION_FINISHED_EVENT = "ANIMATION_FINISHED_EVENT"



function SkillCard:ctor(skill)
    local cls = skill.class

    -- 通过代理注册事件的好处：可以方便的在视图删除时，清理所以通过该代理注册的事件，
    -- 同时不影响目标对象上注册的其他事件
    --
    -- EventProxy.new() --第一个参数是要注册事件的对象，第二个参数是绑定的视图
    -- 如果指定了第二个参数，那么在视图删除时，会自动清理注册的事件
    cc.EventProxy.new(skill, self)
        :addEventListener(cls.MP_CHANGE_EVENT, self.onMPChange_, self)
        :addEventListener(cls.MP_FULL_EVENT, self.onMPFull_, self)

    self.skill_ = skill

    self.sprite_ = display.newSprite():addTo(self)  -- 所有sprite的容器

    -- rankFrame_ 就是最外层的框  rotateBg_ 是为了做一个攻击动画，可以忽略不看
    self.rankFrame_ = display.newSprite(SkillCard.AVATAR_IMG_URL.."CM.jpg"):pos(0,0):addTo(self.sprite_)
    self.skillBtn_ = ui.newImageMenuItem({
        image = SkillCard.IMG_URL.."frame_4.png",
        imageSelected = SkillCard.IMG_URL.."frame_4.png",
        x = 0,
        y = 0,
        tag = 1,
        listener = function ( tag )
            self:onSkillTaped_(tag)
        end ,
    })

    local menu = ui.newMenu({self.skillBtn_})
    self:addChild(menu)
 
    self.progressBg = display.newColorLayer(ccc4(123,32,34,255)):addTo(self.rankFrame_)
    self.progressBg:setContentSize(CCSizeMake(251,29))
    display.align(self.progressBg, display.LEFT_BOTTOM, 0,0)
    self.progressBg:setScaleX(0.4)
    self.progressBg:setScaleY(0.6)

    self.progressBg:setCascadeColorEnabled(true)
    self.progressBg:setCascadeOpacityEnabled(true)

    local progressSize = self.progressBg:getContentSize()

    self.progress_ = CCProgressTimer:create(CCSprite:create("ccb/ccbResources/public/awardPro.png"))
    self.progress_:setType(kCCProgressTimerTypeBar)
    self.progress_:setMidpoint(CCPointMake(0, 0))
    self.progress_:setBarChangeRate(CCPointMake(1, 0))
    self.progress_:setPosition(ccp(progressSize.width / 2,progressSize.height / 2))
    self.progressBg:addChild(self.progress_,0, 101)
    self.progress_:setPercentage(skill:getMp(  ) / skill:getTotalMp(  ) * 100)
    -- -- 这个方法用来设置颜色层叠
    -- setEnableRecursiveCascading(self,true)
    self.canReleaseSkill_ = 0   -- 是否可以点击释放技能
end

function SkillCard:getReleaseSkillFlag( )
    return self.canReleaseSkill_
end

function SkillCard:onSkillTaped_( tag )
    if self:getReleaseSkillFlag() == 1 then
        print("释放技能   "..tag)
        self.canReleaseSkill_ = 0
    end
end

function SkillCard:onMPChange_( event )
    self.progress_:setPercentage(self.skill_:getMp(  ) / self.skill_:getTotalMp(  ) * 100)
end

function SkillCard:onMPFull_( event )
    self.progress_:setPercentage(self.skill_:getMp(  ) / self.skill_:getTotalMp(  ) * 100)
    self.canReleaseSkill_ = 1
end

function SkillCard:setCostomColor()
    setEnableRecursiveCascading(self,true)
end

return SkillCard
