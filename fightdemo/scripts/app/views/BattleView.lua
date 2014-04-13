-- 战场视图是BattleField的一个视图对象，对应着BattleField模型对象
-- 保存每一个英雄对象
-- 用来管理英雄对象的宏观运动

local HeroView = import("..views.HeroView")
local SkillModel = import("..models.SkillModel")
local SkillView = import("..views.SkillView")
local SkillCard = import("..views.SkillCard")

local BattleView = class("BattleView", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)

BattleView.BATTLE_ANIMATION_FINISHED = "BATTLE_ANIMATION_FINISHED"
BattleView.INTERRUPT_SKILL_EVENT = "INTERRUPT_SKILL_EVENT"
BattleView.SKILL_ATK_FROM_SM_TO_C_EVENT = "SKILL_ATK_FROM_SM_TO_C_EVENT"

function BattleView:ctor( battleFieldObj )
	local cls = battleFieldObj.class
	self.views_ = {}
	-- self.controller_ = controller
	self.battleObj_ = battleFieldObj
	-- 通过代理注册事件的好处：可以方便的在视图删除时，清理所以通过该代理注册的事件，
    -- 同时不影响目标对象上注册的其他事件
    --
    -- EventProxy.new() --第一个参数是要注册事件的对象，第二个参数是绑定的视图
    -- 如果指定了第二个参数，那么在视图删除时，会自动清理注册的事件
    		-- 进入战场事件的监听

    -- 添加各个英雄视图
    self.heros_ = self.battleObj_:getAllHeros() 

	-- cc.EventProxy.new(self, self.battleObj_)
 --        :addEventListener(BattleView.BATTLE_ANIMATION_FINISHED, self.battleObj_.enterIdle, self.battleObj_)
 	local cls = self.battleObj_.class
	cc.EventProxy.new(self.battleObj_, self)  
	        :addEventListener(cls.ENTER_BATTLE_EVENT, function ( event )
	        	self:onEnterBattleAction_(event)
	        end,self)
            :addEventListener(cls.PLAY_SKILL_ANI_EVENT, self.playSkillDisplayAni_,self)
            :addEventListener(cls.ENTER_SKILL_ATK_EVENT, self.enterSkillAtk_,self)


    for i=1,#self.heros_ do
    	local hero = self.heros_[i]
        -- 创建每个英雄的视图
    	local playerView = HeroView.new(hero):pos(0,0):addTo(self)
    	table.insert(self.views_,playerView)

        -- 存储英雄视图到战场模型中
        if hero:getSide() == 1 then
        --     -- 被动打的
            local skillCardView = SkillCard.new(hero:getSkills()):pos(200,200):addTo(self)
            self.battleObj_:setPlayerForKey(hero:getSid(),{model = hero,view = playerView, skillView = skillCardView})
        else
            self.battleObj_:setPlayerForKey(hero:getSid(),{model = hero,view = playerView})
        end
    
        if hero:getSide() == 1 then
            playerView:setPosition(ccp( display.width / 3 * hero:getPos(),-display.cy ))
        else
            playerView:setPosition(ccp( display.width / 3 * hero:getPos(),display.cy * 4 / 2 ))
        end
    end

    -- 添加技能显示层
    self.skillDisplayLayer_ = display.newColorLayer(ccc4(0,0,0,150)):pos(0,0):addTo(self)
    
    self.skillDisplayLayer_:setVisible(false)
end

-- 返回战场视图对应的战场对象
function BattleView:getBattleField(  )
	return self.battleObj_
end

-- 返回战场视图对应的所有英雄视图
function BattleView:getAllHeroView(  )
	return self.views_
end

function BattleView:HLAddParticleScale( plist, node, pos, duration, z, tag, scaleX, scaleY )
    local ps = CCParticleSystemQuad:create(plist)
    ps:setPosition(pos)
    node:addChild(ps, z, tag)
end

-- 播放显示技能动画
function BattleView:playSkillDisplayAni_( event )
    local player = event.playerParam.player
    local skill = event.playerParam.skill
    -- 开始技能显示动画
    self.skillDisplayLayer_:setVisible(true)
    self:HLAddParticleScale( "ccb/ccbResources/particle/eff_page_504.plist", self.skillDisplayLayer_, ccp(display.cx,display.cy), 5, 102, 100,1,1 )


    local skillName = ui.newTTFLabel({
            text = "葵花宝典",
            size = 48,
            color = display.COLOR_RED,
        })
        :pos(display.cx, display.cy)
        :addTo(self.skillDisplayLayer_)
    transition.moveBy(skillName, {x = -100, y = 0, time = 1.5, onComplete = function()
        skillName:removeSelf()
    end})

    local actArray = CCArray:create()
    local delayTime = CCDelayTime:create(1)
    local callBack = CCCallFunc:create(function(  )
        self:dispatchEvent({name = BattleView.BATTLE_ANIMATION_FINISHED,actType = "playskill"})
        self.skillDisplayLayer_:setVisible(false)
    end)
    actArray:addObject(delayTime)
    actArray:addObject(callBack)
    self:runAction(CCSequence:create(actArray))
end

-- 当释放技能的时候创建技能图像
function BattleView:addSkillView( atker,target )
    -- 创建技能的对象
end
-- 进入技能攻击的状态
function BattleView:enterSkillAtk_( event )
    self.skillAtkAtker_ = event.atker
    self.skillAtkTarget_ = event.targetModel
    self.skillAtkSkill_ = event.skill
    -- 创建技能对象
    self.currentAtkSkill_ = SkillModel.new({
            name = self.skillAtkSkill_.name,
            stype = self.skillAtkSkill_.stype,
            damage = self.skillAtkSkill_.atk,
            atker = self.skillAtkAtker_,
            target = self.skillAtkTarget_,
            skill = self.skillAtkSkill_,
            battleview = self
        })
    self.currentAtkSkillView_ = SkillView.new(self.currentAtkSkill_,self.battleObj_)
    self:addChild(self.currentAtkSkillView_)
    self.currentAtkSkill_:enterAtk()
    -- 让自身监听技能动作的变化
    local cls = self.currentAtkSkill_.class
    cc.EventProxy.new(self.currentAtkSkill_, self)  
        :addEventListener(cls.SENT_TO_CONTROLLER_DAMAGE, self.reciveInfoFromSkill_,self)
    -- self.currentAtkSkill_ = nil
    -- 设置攻击者和被攻击者的z值
end

function BattleView:reciveInfoFromSkill_( event )
    self:dispatchEvent({name = BattleView.SKILL_ATK_FROM_SM_TO_C_EVENT , atker = event.atker, targets = event.targets, skill = event.skill})

end

-- 进入战场的动作
function BattleView:onEnterBattleAction_( event )
	for i=1,#self.views_ do

		local playerView = self.views_[i]
		local hero = playerView:getHeroInfo()
		local array = CCArray:create()
        local move
        if hero:getSide() ~= 1 then
            move = CCMoveTo:create(1,ccp(playerView:getPositionX(),display.cy + 150))
        else
            move = CCMoveTo:create(1,ccp(playerView:getPositionX(),display.cy - 150))
        end
        
        local delay = CCDelayTime:create(1)
        local callBack = CCCallFunc:create(function(  )
        	self:dispatchEvent({name = BattleView.BATTLE_ANIMATION_FINISHED,actType = "enterbattle"})
        end)
        array:addObject(move)
        array:addObject(delay)
        
        array:addObject(callBack)
        local seq = CCSequence:create(array)
        playerView:runAction(seq)
	end
end

return BattleView
