--[[
    技能模型
    包含技能信息
    包含一个状态机 用来管理技能的产生和消亡
    有一个定时器 按时间向控制器发送伤害值

    近程/远程
    单体/群体
    是否显示攻击特效
    一次性攻击/持续性攻击
    物理伤害（减血）/魔法伤害（减血，减防，减魔，加防，加血，加魔，眩晕，解除眩晕）
    需要释放者类型（拳，刀，剑，箭）

]]
local SkillModel = class("SkillModel", cc.mvc.ModelBase)

local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

-- 常量
SkillModel.SENT_TO_CONTROLLER_DAMAGE = "SENT_TO_CONTROLLER_DAMAGE"            -- 向控制器发送伤害信息
SkillModel.BEGIN_ATK_EVENT = "BEGIN_ATK_EVENT"                                -- 向自身视图发送开始攻击的方法
SkillModel.ENTER_DIE_EVENT = "ENTER_DIE_EVENT"                                -- 向自身视图发送死亡信息
SkillModel.MP_CHANGE_EVENT = "MP_CHANGE_EVENT"
SkillModel.MP_FULL_EVENT = "MP_FULL_EVENT"

SkillModel.ONE_SORT_ATK = 0         -- 一次性攻击
SkillModel.CONTINUE_ATK = 1         -- 持续性攻击
-- 技能的模型类   

-- 定义属性
SkillModel.schema = clone(cc.mvc.ModelBase.schema)
SkillModel.schema["name"] = {"string"}          -- 名字
SkillModel.schema["stype"] = {"number",0}          -- 类型： 0 一次性攻击   1 持续性攻击
SkillModel.schema["rangtype"] = {"number",0}         -- 攻击范围：0 近程     1 远程
SkillModel.schema["isshow"] = {"number",0}        -- 是否进行技能显示 0 不显示  1显示
SkillModel.schema["haveeffect"] = {"number",0}    -- 是否显示攻击效果 0 不显示  1显示
SkillModel.schema["atktype"] = {"number",0}     -- 攻击类型 0 单体攻击 1 群体攻击
SkillModel.schema["damagetype"] = {"number",0}    -- 伤害类型 0 物理伤害 1   减血， 2    减防，3    减魔，4    加防，5    加血，6    加魔，7    眩晕，8    解除眩晕
SkillModel.schema["damage"] = {"number"}        -- 每次攻击的伤害值
-- SkillModel.schema["atker"] = {"table"}          -- 攻击者（数组）
-- SkillModel.schema["target"] = {"table"}         -- 被攻击者（数组）
SkillModel.schema["skill"] = {"table"}          -- 保存技能的原始数据
--[[
    target的范例
    {
        {
            target = target,
            damage = damage
        },
        {
            target = target,
            damage = damage
        }
    }
]]
SkillModel.schema["mp"] = {"number",0}
SkillModel.schema["totalmp"] = {"number",100}
-- SkillModel.schema["battleview"] = {"userdata"}     -- 保存战场视图对象 


function SkillModel:ctor(properties, events, callbacks)
    SkillModel.super.ctor(self, properties)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    -- 因为角色存在不同状态，所以这里为 SkillModel 绑定了状态机组件
    self:addComponent("components.behavior.StateMachine")
    -- 由于状态机仅供内部使用，所以不应该调用组件的 exportMethods() 方法，改为用内部属性保存状态机组件对象
    self.fsm__ = self:getComponent("components.behavior.StateMachine")

    -- 监听来着于战场对象的消息    (例如技能被打断)
    -- local cls = self.battleview_.class
    -- cc.EventProxy.new(self.battleview_,self)
    --     :addEventListener(cls.INTERRUPT_SKILL_EVENT,self.interruptSkillAction_,self)

    -- 设定状态机的默认事件
    local defaultEvents = {
        -- 初始化后，角色处于 攻击 状态
        {name = "start",  from = "none",    to = "idle" },
        {name = "enatk",    from = "idle",  to = "atk"},
        {name = "todie",    from = "*",      to = "die"}
    }
    -- 如果继承类提供了其他事件，则合并
    table.insertTo(defaultEvents, totable(events))

    -- 设定状态机的默认回调
    local defaultCallbacks = {
        onchangestate = handler(self, self.onChangeState_),
        onafterstart = handler(self, self.onAfterStart_),
        onafterenatk = handler(self, self.onAfterEnatk_),
        onaftertodie = handler(self, self.onAfterTodie_),
        onenteratk = handler(self, self.onEnteratk_),
        onenterdie = handler(self, self.onEnterdie_),
    }
    -- 如果继承类提供了其他回调，则合并
    table.merge(defaultCallbacks, totable(callbacks))

    self.fsm__:setupState({
        events = defaultEvents,
        callbacks = defaultCallbacks
    })
    self.canSentAtkInfo_ = 0 -- 用以管理是否可以向目标发送伤害信息

    self.mpCdTime_ = 0 -- 魔法值的cd时间 为零可以释放
    self.fsm__:doEvent("start") -- 启动状态机 直接进入攻击状态

    -- 一个定时器，用来向控制器发送是否已伤害的信息
    local function sentDamage(  )
        if self:isCanSentDamage() then
            -- 发送伤害信息  from: SkillModel   to: FightController
            self:dispatchEvent({name = SkillModel.SENT_TO_CONTROLLER_DAMAGE, atker = self.atker_, targets = self.target_, skill = self.skill_})
            if self.stype_ == SkillModel.ONE_SORT_ATK then
                self:switchSendInfo(false)
            end
        end
    end
    self.schedulerHandle_ = scheduler.scheduleGlobal(sentDamage, 0.5)   -- 每0.1秒就发送一次
    local function coolDownCD(  )
        -- cd时间管理
        if self.mp_ < self.totalmp_ then
            self.mp_ = self.mp_ + 10
            self:dispatchEvent({name = SkillModel.MP_CHANGE_EVENT})
            if self.mp_ >= self.totalmp_ then
                self.mp_ = self.totalmp_
                self:dispatchEvent({name = SkillModel.MP_FULL_EVENT})
            end
        end
    end

    self:dispatchEvent({name = SkillModel.MP_FULL_EVENT})
    self.schedulerCDHandle_ = scheduler.scheduleGlobal(coolDownCD, 1)   -- cd循环
end

-- get和set方法
function SkillModel:getNickName()
    return self.name_
end

function SkillModel:getSkillType(  )
    return self.stype_
end

function SkillModel:getDamege(  )
    return self.damage_
end

function SkillModel:getAtker(  )
    return self.atker_
end

function SkillModel:getTargets(  )
    return self.target_
end

function SkillModel:getMp(  )
    return self.mp_
end

function SkillModel:setMp( value )
    self.mp_ = value
end

function SkillModel:getTotalMp(  )
    return self.totalmp_
end

-- 被打断的回调
function SkillModel:interruptSkillAction_( event )
    self.fsm__:doEvent("todie")
end

-- 是否可以开始发送伤害信息
function SkillModel:isCanSentDamage(  )
    return self.canSentAtkInfo_ == 1
end

-- 打开或者关系是否可以发送伤害信息的开关
function SkillModel:switchSendInfo( flag )
    self.canSentAtkInfo_ = flag and  1 or 0
end

-- 开始攻击
function SkillModel:enterAtk(  )
    self.fsm__:doEvent("enatk")
end

-- 状态发生改变后的回调

-- 当初始化完成之后
function SkillModel:onChangeState_( event )
    
end
function SkillModel:onAfterStart_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function SkillModel:onAfterTodie_( event )
    
end

function SkillModel:onAfterEnatk_( event )
    
end

function SkillModel:onEnteratk_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    -- 通知视图开始攻击了
    self:dispatchEvent({name = SkillModel.BEGIN_ATK_EVENT})
end

function SkillModel:onEnterdie_( event )
    printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    -- 通知视图可以死亡把自己移除了
    self:dispatchEvent({name = SkillModel.ENTER_DIE_EVENT})
end

function SkillModel:removeSelf(  )
    scheduler.unscheduleGlobal(self.schedulerHandle_)
end
return SkillModel
