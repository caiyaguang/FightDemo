-- 保存用户的数据和状态信息，并在状态发生改变的时候，向控制器发送通知
-- 英雄的基类
-- 包含英雄的共同特征
-- 包含一些可以更新数据的接口  和分发事件的接口
-- 包含一个状态机
-- 数据包括： 等级 攻击力 血量 魔法值 

-- 内部有一个定时器，用于检测当cd时间结束了，更改状态   
-- 当状态发生改变了，向控制器发送通知，控制器根据状态，调用view的更新接口

local SkillModel = import("..models.SkillModel")

local Actor = class("Actor", cc.mvc.ModelBase)

-- 常量
Actor.CHANGE_STATE_EVENT = "CHANGE_STATE_EVENT"
Actor.START_EVENT         = "START_EVENT"
Actor.READY_EVENT         = "READY_EVENT"
Actor.FIRE_EVENT          = "FIRE_EVENT"
Actor.FREEZE_EVENT        = "FREEZE_EVENT"
Actor.THAW_EVENT          = "THAW_EVENT"
Actor.KILL_EVENT          = "KILL_EVENT"
Actor.RELIVE_EVENT        = "RELIVE_EVENT"
Actor.HP_CHANGED_EVENT    = "HP_CHANGED_EVENT"
Actor.ATTACK_EVENT        = "ATTACK_EVENT"
Actor.UNDER_ATTACK_EVENT  = "UNDER_ATTACK_EVENT"
Actor.UNDER_VERTIGO_EVENT  = "UNDER_VERTIGO_EVENT"
Actor.RELEASE_VERTIGO_EVENT  = "RELEASE_VERTIGO_EVENT"
Actor.ATACKING_EVENT        = "ATACKING_EVENT"

Actor.UNDERATK_EVENT        = "UNDERATK_EVENT"          -- 受到攻击事件
Actor.DECREASE_HP_EVENT     = "DECREASE_HP_EVENT"       -- 减少血量事件
Actor.TODO_SKILL_EFFECT_EVENT = "TODO_SKILL_EFFECT_EVENT"   -- 做播放技能特效的事件
Actor.BEGIN_SKILL_ATK_EVENT = "BEGIN_SKILL_ATK_EVENT" -- 进入技能攻击的事件

-- 定义属性
Actor.schema = clone(cc.mvc.ModelBase.schema)
Actor.schema["nickname"] = {"string"} -- 字符串类型，没有默认值
Actor.schema["sid"]      = {"string"}
Actor.schema["level"]    = {"number", 1} -- 数值类型，默认值 1
Actor.schema["totalhp"]       = {"number", 100}
Actor.schema["hp"]       = {"number", 1}
Actor.schema["side"]       = {"number", 1}
Actor.schema["mp"]       = {"number", 0}        -- 魔法值
Actor.schema["exp"]       = {"number", 0}       -- 经验值
Actor.schema["cardIcon"] = {"string"}           -- 技能图片
local mytable = {
    skill = {
        atk = 10000,
    }
}
Actor.schema["skill"]       = {"table", mytable}        -- 技能信息
Actor.schema["def"]        = {"number",0}       -- 防御
Actor.schema["pos"]        = {"number",1}       -- 位置
Actor.schema["atk"]         = {"number", 0}     -- 攻击力
Actor.schema["side"]         = {"number", 0}    -- 所处阵容
Actor.schema["image"]       = {"string", ""}    -- 人物头像
Actor.schema["skills"]      = {"table"}      -- 技能对象


function Actor:ctor(properties, events, callbacks)
    Actor.super.ctor(self, properties)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    -- 因为角色存在不同状态，所以这里为 Actor 绑定了状态机组件
    self:addComponent("components.behavior.StateMachine")
    -- 由于状态机仅供内部使用，所以不应该调用组件的 exportMethods() 方法，改为用内部属性保存状态机组件对象
    self.fsm__ = self:getComponent("components.behavior.StateMachine")

    -- 设定状态机的默认事件
    local defaultEvents = {
        -- 初始化后，角色处于 idle 状态
        {name = "start",  from = "none",    to = "idle" },
        -- 走
        {name = "walking",   from = "idle",    to = "walk"},
        -- 站立
        {name = "endwalk",   from = "walk",    to = "idle"},
        -- 开始攻击
        {name = "atking",   from = "idle",    to = "atk"},
        -- 攻击结束
        {name = "endatk",   from = "atk",    to = "idle"},
        -- 受到攻击
        {name = "beatk",    from = {"idle","underatk"},      to = "underatk"},

        -- 从攻击回复
        {name = "backidle", from = "underatk",      to = "idle"},
        -- 死亡
        {name = "kill",  from = "underatk",  to = "dead"},
    }
    -- 如果继承类提供了其他事件，则合并
    table.insertTo(defaultEvents, totable(events))

    -- 设定状态机的默认回调
    local defaultCallbacks = {
        onchangestate = handler(self, self.onChangeState_),
        onafterstart = handler(self, self.onAfterStart_),
        onafterwalking = handler(self, self.onAfterWalking_),
        onafterendwalk = handler(self, self.onAfterEndwalk_),
        onafteratking = handler(self, self.onAfterAtking_),
        onafterendatk = handler(self, self.onAfterEndatk_),
        onafterbeatk = handler(self, self.onAfterBeatk_),
        onafterBackidle = handler(self, self.onAfterBackidle_),
        onafterkill = handler(self, self.onAfterKill_),
        onenteridle = handler(self, self.onEnteridle_),
        onenterwalk = handler(self, self.onEnterwalk_),
        onenteratk = handler(self, self.onEnteratk_),
        onenterunderatk = handler(self, self.onEnterunderatk_),
        onenterdead = handler(self, self.onEnterdead_),
    }
    -- 如果继承类提供了其他回调，则合并
    table.merge(defaultCallbacks, totable(callbacks))

    self.fsm__:setupState({
        events = defaultEvents,
        callbacks = defaultCallbacks
    })

    -- 每次攻击的目标
    self.targets_ = {}

    -- 自己的天赋技能对象
    self.giftSkill_ = SkillModel.new()
    
    -- 初始化血量
    self.totalhp_ = self.hp_
    self.fsm__:doEvent("start") -- 启动状态机
end

function Actor:getSkills(  )
    return self.skills_
end

-- 进行cd时间更新
-- cd结束，修改英雄的状态
-- 参数： dt 时间间隔
function Actor:updateCdTimeAndHeroState( dt )
    
end

-- 判断一个英雄是否可以进行攻击
function Actor:isCanAtk(  )
    return self.fsm__:canDoEvent("atking")
end

function Actor:isDead(  )
    return self:getState() == "dead"
end
-- 接受controller的通知，进入下一个状态
function Actor:enterNextState(  )
    local currentState = self:getState()
    if currentState == "underatk" then
        if self.hp_ <= 0 then
            self.fsm__:doEvent("kill")
        else
            self.fsm__:doEvent("backidle")
        end
    elseif currentState == "atk" then
        self.fsm__:doEvent("endatk")
    elseif currentState == "walk" then
        self.fsm__:doEvent("endwalk")
    end
end

function Actor:enterAtk(  )
    self.fsm__:doEvent("atking")
end
-- 普通攻击
function Actor:noramlAtk( target )
    local skill = self.skill_.normalSkill
    local atk = skill.atk
    local damage = 0
    local armor = target:getArmor()
    damage = armor - atk
    if damage >= 0 then
        -- 当没有伤害的时候，设置伤害为1
        damage = 1
    end
    -- target:underAtk(damage)
    -- 普通攻击直接进入攻击状态
    self:enterAtk()
end
-- 技能攻击
function Actor:skillAtk( target )
    -- 根据技能信息计算伤害，并把攻击者置为攻击状态
    local skill = self.skill_.skill
    local atk = skill.atk
    local damage = 0
    if target:isDead() then
        return
    end
    local armor = target:getArmor()
    damage = armor - atk
    if damage >= 0 then
        -- 当没有伤害的时候，设置伤害为1
        damage = -1
    end
    damage = - damage
    -- target:underAtk(damage)
    -- 把伤害值保存到目标数组里边
    local target = {target = target,damage = damage}
    table.insert(self.targets_,target)
    -- 技能攻击等播完技能显示动画后开始进入攻击状态
    -- 向战场模型对象发送要播放技能显示特效的消息  
    -- 参数 自身信息 技能信息
    -- self:enterAtk()
    self:dispatchEvent({name = Actor.TODO_SKILL_EFFECT_EVENT, params = { player = self,skill = self.skill_.skill }})
end

-- 受到攻击的方法
function Actor:underAtk( damage )
    self.fsm__:doEvent("beatk")
    self:decreaseHp(damage)
    self:dispatchEvent({name = Actor.DECREASE_HP_EVENT,damage = damage})
end

-- 减血
function Actor:decreaseHp( damage )
    self.hp_ = self.hp_ - damage
end

-- 加血
function Actor:increaseHp(  )
    
end

-- =进入走路状态
function Actor:initWalkState(  )
    self.fsm__:doEvent("walking")
end

-- get和set方法
-- 获得防御
function Actor:getArmor(  )
    return self.def_
end
function Actor:setArmor( value )
    self.def_ = value
end
function Actor:getPos(  )
    return self.pos_
end
function Actor:setPos( value )
    self.pos_ = value
end
-- 获得经验
function Actor:getExp(  )
    return self.exp_
end
function Actor:setExp( value )
    self.exp_ = value
end
-- 英雄头像
function Actor:setImage( image )
    self.image_ = image
end
function Actor:getImage(  )
    return self.image_
end

function Actor:getHp(  )
    return self.hp_
end

function Actor:setHp( value )
    self.hp_ = value
end

function Actor:getTotalHp(  )
    return self.totalhp_
end
-- 获得等级
function Actor:getLevel(  )
    return self.level_
end
function Actor:setLevel( value )
    self.level_ = value
end
-- -- 获得名字
function Actor:getNickName(  )
    return self.nickname_
end
-- 获得英雄所处状态
function Actor:getState(  )
    return self.fsm__:getState()
end

function Actor:getSid(  )
    return self.sid_
end

-- 获得所处阵容
function Actor:getSide(  )
    return self.side_
end

function Actor:getSkill(  )
    return self.skill_
end


-- 命中的方法

-- 状态发生改变后的回调

-- 当初始化完成之后
function Actor:onChangeState_( event )
    
end
function Actor:onAfterStart_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function Actor:onAfterWalking_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function Actor:onAfterEndwalk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function Actor:onAfterAtking_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    -- self:dispatchEvent({name = Actor.BEGIN_SKILL_ATK_EVENT})
end

function Actor:onAfterEndatk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function Actor:onAfterBeatk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    self:dispatchEvent({name = Actor.UNDERATK_EVENT})
end

function Actor:onAfterBackidle_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function Actor:onAfterKill_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function Actor:onEnteridle_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function Actor:onEnterwalk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
end

function Actor:onEnterunderatk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    -- 进入被攻击的状态
    -- self:dispatchEvent({name = Actor.UNDERATK_EVENT})
end

function Actor:onEnteratk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    -- 事件包含被攻击者的信息
    -- print("数量是    "..#self.targets_)
    self:dispatchEvent({name = Actor.ATACKING_EVENT, targetModel = self.targets_})     -- 向自己的视图发消息

    self:dispatchEvent({name = Actor.BEGIN_SKILL_ATK_EVENT, atker = self, targetModel = self.targets_, skill = self.skill_.skill})     -- 向战场模型发信息，进入大招释放的状态
    -- 重置目标数组
    self.targets_ = {}
end

function Actor:onEnterdead_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    self:dispatchEvent({name = Actor.KILL_EVENT})
end


return Actor
