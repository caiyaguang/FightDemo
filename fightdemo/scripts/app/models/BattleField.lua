--[[保存战场的数据和状态信息，并在状态发生改变的时候，向视图发送通知
战场视图的基类
包含一些可以更新数据的接口  和分发事件的接口
包含一个状态机
数据包括： 战场的状态 英雄的模型数据

内部有一个定时器，用于检测当cd时间结束了，更改状态   
当状态发生改变了，向控制器发送通知，控制器根据状态，调用view的更新接口
]]

local BattleField = class("BattleField", cc.mvc.ModelBase)

-- 常量
BattleField.ENTER_BATTLE_EVENT        = "ENTER_BATTLE_EVENT"
BattleField.LEAVE_BATTLE_EVENT     = "LEAVE_BATTLE_EVENT"
BattleField.ENTER_ATK_EVENT     = "ENTER_ATK_EVENT"
BattleField.LEAVE_ATK_EVENT     = "LEAVE_ATK_EVENT"
BattleField.FIGHT_END_EVENT     = "FIGHT_END_EVENT"
BattleField.PLAY_SKILL_ANI_EVENT = "PLAY_SKILL_ANI_EVENT"
BattleField.ENTER_SKILL_ATK_EVENT = "ENTER_SKILL_ATK_EVENT"

-- 英雄的模型类   

-- 定义属性
BattleField.schema = clone(cc.mvc.ModelBase.schema)
BattleField.schema["players"] = {"table"}       -- 英雄的模型数组


function BattleField:ctor(properties, events, callbacks)
    BattleField.super.ctor(self, properties)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    -- 因为角色存在不同状态，所以这里为 BattleField 绑定了状态机组件
    self:addComponent("components.behavior.StateMachine")
    -- 由于状态机仅供内部使用，所以不应该调用组件的 exportMethods() 方法，改为用内部属性保存状态机组件对象
    self.fsm__ = self:getComponent("components.behavior.StateMachine")

    -- 监听来着于战场中所有人物模型的事件
    for i=1,#self.players_ do
        local player = self.players_[i]
        local cls = player.class
        cc.EventProxy.new(player,self)
            :addEventListener(cls.TODO_SKILL_EFFECT_EVENT, self.playSkillAni_, self)
            :addEventListener(cls.BEGIN_SKILL_ATK_EVENT, self.enterSkillAtk_, self)
    end
    

    -- 设定状态机的默认事件
    local defaultEvents = {
        -- 初始化后，角色处于 idle 状态 (闲置)
        {name = "start",  from = "none",    to = "idle" },
        -- 进入战场
        {name = "init",   from = "idle",    to = "enfield"},
        -- 开始播放技能动画
        {name = "playskill",    from = "*", to = "playskillani"},
        -- 离开战场
        {name = "lvfielding",   from = "idle",    to = "lvfield"},
        -- 技能攻击状态
        {name = "enskillatk",   from = "idle",  to = "skillatk"},
        -- 开始攻击
        {name = "atking",   from = "idle",    to = "atk"},
        -- 战斗结束
        {name = "endatk",   from = "idle",    to = "result"},
        -- 进入闲置状态
        {name = "enidle",    from = "*",      to = "idle"}
    }
    -- 如果继承类提供了其他事件，则合并
    table.insertTo(defaultEvents, totable(events))

    -- 设定状态机的默认回调
    local defaultCallbacks = {
        onchangestate = handler(self, self.onChangeState_),
        onafterstart = handler(self, self.onAfterStart_),
        onafterinit = handler(self, self.onAfterInit_),
        onafterplayskill = handler(self, self.onAfterPlaySkill_),
        onafterlvfielding = handler(self, self.onAfterLvfielding_),
        onafterenskillatk = handler(self, self.onAfterEnSkillAtk_), -- 进入技能攻击
        onafteratking = handler(self, self.onAfterAtking_),
        onafterendatk = handler(self, self.onAfterEndatk_),
        onafterenidle = handler(self, self.onAfterEnidle_),
        onenteridle = handler(self, self.onEnteridle_),
        onenterplayskillani = handler(self, self.onEnterPlaySkillAni_),
        onenterskillatk = handler(self, self.onEnterSkillAtk_),     -- 进入技能攻击状态
        onenterenfield = handler(self, self.onEnterEnfield_),
        onenterlvfield = handler(self, self.onEnterLvfield_),
        onenteratk = handler(self, self.onEnteratk_),
        onenterresult = handler(self, self.onEnterresult_),
    }
    -- 如果继承类提供了其他回调，则合并
    table.merge(defaultCallbacks, totable(callbacks))

    self.fsm__:setupState({
        events = defaultEvents,
        callbacks = defaultCallbacks
    })
    -- 存储技能显示数据
    self.displaySkill_ = nil    -- 显示的技能
    self.displayPlayer_ = nil    -- 显示的英雄
    -- 初始化血量
    self.totalhp_ = self.hp_
    self.fsm__:doEvent("start") -- 启动状态机
    self.allHero_ = {}
end

-- get和set方法

-- 获得所有英雄数据信息
function BattleField:getAllHeros(  )
    return self.players_
end
-- 进入闲置的方法
function BattleField:enterIdle(  )
    self.fsm__:doEvent("enidle")
end
-- 进入战场的方法
function BattleField:initAction(  )
    self.fsm__:doEvent("init")
end
-- 进入战斗状态
function BattleField:enterAtk(  )
    self.fsm__:doEvent("atking")
end
-- 离开战场状态
function BattleField:leaveAtk(  )
    self.fsm__:doEvent("lvfielding")
end
-- 战斗结束
function BattleField:endFight(  )
    self.fsm__:doEvent("endatk")
end

function BattleField:getNickName(  )
    return "BattleField"
end

function BattleField:setPlayerForKey( key,value )
    self.allHero_[key] = value
end

function BattleField:getPlayerForKey( key )
    return self.allHero_[key]
end

-- 显示技能后 继续进行战斗 参数（攻击者，被攻击者）
function BattleField:continueAtk( )
    self.displayPlayer_:enterAtk()
    self.displaySkill_ = nil
    self.displayPlayer_ = nil 
end

-- 被攻击者进入被攻击的状态
function BattleField:beginEnterDamage( atker,targets,skill )
    -- 计算攻击伤害
    for i=1,#targets do
        local targetObj = targets[i]
        -- 进行战斗计算和数据更改
        local skill = atker:getSkill().skill
        local atk = skill.atk
        local damage = 0
        if targetObj.target:isDead() then
            return
        end
        local armor = targetObj.target:getArmor()
        damage = armor - atk
        if damage >= 0 then
            -- 当没有伤害的时候，设置伤害为1
            damage = -1
        end
        damage = - damage
        targetObj.target:underAtk( damage )
    end
end

-- 收到消息后的回调
function BattleField:playSkillAni_( event )
    self.displaySkill_ = event.params.skill
    self.displayPlayer_ = event.params.player
    self.fsm__:doEvent("playskill")
end

-- 进入技能攻击的回调
function BattleField:enterSkillAtk_( event )
    self.skillAtkAtker_ = event.atker
    self.skillAtkTarget_ = event.targetModel
    self.skillAtkSkill_ = event.skill
    self.fsm__:doEvent("enskillatk")
end
-- 状态发生改变后的回调

-- 当初始化完成之后
function BattleField:onChangeState_( event )
    
end
function BattleField:onAfterStart_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

-- 播放战场动画
function BattleField:onAfterPlaySkill_( event )
    
end

function BattleField:onAfterEnSkillAtk_( event )
    
end

function BattleField:onAfterInit_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function BattleField:onAfterLvfielding_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function BattleField:onAfterAtking_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
end

function BattleField:onAfterEndatk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function BattleField:onAfterEnidle_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function BattleField:onEnteridle_( event )
    -- printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function BattleField:onEnterPlaySkillAni_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    self:dispatchEvent({name = BattleField.PLAY_SKILL_ANI_EVENT, playerParam = { player = self.displayPlayer_, skill = self.displaySkill_}})

end

function BattleField:onEnterSkillAtk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    self:dispatchEvent({name = BattleField.ENTER_SKILL_ATK_EVENT, atker = self.skillAtkAtker_, targetModel = self.skillAtkTarget_, skill = self.skillAtkSkill_})
    self.skillAtkAtker_ = nil
    self.skillAtkTarget_ = nil
    self.skillAtkSkill_ = nil
end

function BattleField:onEnterEnfield_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    self:dispatchEvent({name = BattleField.ENTER_BATTLE_EVENT})
end

function BattleField:onEnterLvfield_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    -- 进入被攻击的状态
    self:dispatchEvent({name = BattleField.LEAVE_BATTLE_EVENT})
end

function BattleField:onEnteratk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    self:dispatchEvent({name = BattleField.ENTER_ATK_EVENT})
end

function BattleField:onEnterresult_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    self:dispatchEvent({name = BattleField.FIGHT_END_EVENT})
end


return BattleField
