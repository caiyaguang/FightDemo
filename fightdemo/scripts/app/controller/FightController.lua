-- 控制器层
-- 处理用户的输入
-- 与modle层交换更新数据
-- 控制视图的显示，比如卡牌的进入
-- 接受用户状态改变的通知，并调用页面的更新方法，更新页面

local Actor = import("..models.Actor")
local HeroView = import("..views.HeroView")
local FightController = class("FightController", function (  )
    local node = display.newLayer()
    require("framework.api.EventProtocol").extend(node)
	return node
end)

FightController.ACTION_FINISHED_EVENT = "ACTION_FINISHED_EVENT"            -- 动作完成后

function FightController:ctor()
    -- 完成初始化
    cc.EventProxy.new(self, self)
        :addEventListener(FightController.ACTION_FINISHED_EVENT, function ( event )
            self:heroActionFinished( event )
        end , self)
    
    
    self.views_ = {}        -- 存放所有英雄卡片视图
    self.heros = {}
    -- -- 创建英雄对象，并存储在app数组中
    local player = Actor.new({
        id = "player",
        nickname = "dualface1",
        level = 1,
        side = 0,
        hp = 400,
        pos = 1,
        skill = {
            skill = {
                atk = 150,
            }

        }
    })
    self.heros[player:getNickName()] = player

    local player = Actor.new({
        id = "player",
        nickname = "dualface2",
        level = 1,
        side = 0,
        hp = 500,
        pos = 2,
        skill = {
            skill = {
                atk = 130,
            }

        }
    })
    self.heros[player:getNickName()] = player

    local player = Actor.new({
        id = "player",
        nickname = "fuck1",
        level = 1,
        side = 1,
        hp = 300,
        pos = 1,
        skill = {
            skill = {
                atk = 180,
            }

        }
    })
    self.heros[player:getNickName()] = player

    local player = Actor.new({
        id = "player",
        nickname = "fuck2",
        level = 1,
        side = 1,
        hp = 600,
        pos = 2,
        skill = {
            skill = {
                atk = 165,
            }

        }
    })

    self.heros[player:getNickName()] = player

    -- 根据英雄数据，创建英雄view，并存储起来
    for k,v in pairs(self.heros) do
        
        local playerView = HeroView.new(v,self):pos(0,0):addTo(self)
        self.views_[k] = playerView
        if v:getSide() == 1 then
            playerView:setPosition(ccp( display.width / 3 * v:getPos(),-display.cy ))
        else
            playerView:setPosition(ccp( display.width / 3 * v:getPos(),display.cy * 4 / 2 ))
        end
    end

    for k,v in pairs(self.views_) do
        local cls = v.class
        cc.EventProxy.new(v, self)
            :addEventListener(cls.ANIMATION_FINISHED_EVENT, function ( event )
                self:heroActionFinished( event )
            end , self)
    end

    self:entFightScene()
    -- 攻击的索引
    self.atkIndexS0_ = 1      -- 0 方攻击位置
    self.atkIndexS1_ = 1      -- 1 方攻击位置
    self.crtAtkSide_ = 1    -- 现在攻击的一方

    self.deadCount = 0     -- 已经死亡的数目
end
function FightController:getViewBySideAndPos( side,pos )
    for k,v in pairs(self.heros) do
        if v:getSide() == side and v:getPos() == pos then
            return v
        end
    end
end
-- 进入战场
function FightController:entFightScene(  )
    local i = 1
    for k,v in pairs(self.heros) do
        
        local nickname = v:getNickName()
        local player = self.views_[nickname]
        local array = CCArray:create()
        local move
        if v:getSide() ~= 1 then
            move = CCMoveTo:create(1,ccp(player:getPositionX(),display.cy + 150))
        else
            move = CCMoveTo:create(1,ccp(player:getPositionX(),display.cy - 150))
        end
        
        local delay = CCDelayTime:create(1)
        local callBack = CCCallFunc:create(function(  )
            if v:getSide() == 1 and v:getPos() == 1 then
                self:enterNextAtk()
            end
        end)
        array:addObject(move)
        array:addObject(delay)
        
        array:addObject(callBack)
        local seq = CCSequence:create(array)
        player:runAction(seq)
        i = i + 1
    end
end

-- 进入下一轮的攻击
function FightController:enterNextAtk(  )
    if self.deadCount == 2 then
        self.stateLabel_ = ui.newTTFLabel({
            text = "进入下一个回合",
            size = 22,
            color = display.COLOR_RED,
        })
        :pos(self:getContentSize().width / 2, self:getContentSize().height / 2)
        :addTo(self)
        return
    end 
    local tSide = self.crtAtkSide_ == 1 and 0 or 1

    if self.crtAtkSide_ == 0 then
        local atkPos = self.atkIndexS0_
        local defPos = self.atkIndexS0_
        local atkerView = self:getViewBySideAndPos(self.crtAtkSide_ ,atkPos)
        local deferView = self:getViewBySideAndPos(tSide,atkPos)
        if self.atkIndexS0_ == 2 then
            self.atkIndexS0_ = 1
        else
            self.atkIndexS0_ = self.atkIndexS0_ + 1
        end
        self.crtAtkSide_ = self.crtAtkSide_ == 0 and 1 or 0
        if atkerView:isCanAtk() and not deferView:isDead() then
            atkerView:skillAtk(deferView)
        else
            self:enterNextAtk()
        end
    else
        local atkPos = self.atkIndexS1_
        local defPos = self.atkIndexS1_
        local atkerView = self:getViewBySideAndPos(self.crtAtkSide_ ,atkPos)
        local deferView = self:getViewBySideAndPos(tSide,atkPos)
        if self.atkIndexS1_ == 2 then
            self.atkIndexS1_ = 1
        else
            self.atkIndexS1_ = self.atkIndexS1_ + 1
        end
        self.crtAtkSide_ = self.crtAtkSide_ == 0 and 1 or 0
        if atkerView:isCanAtk() and not deferView:isDead() then
            atkerView:skillAtk(deferView)
        else
            self:enterNextAtk()
        end
    end
end

-- 接受用户输入的处理函数
function FightController:skillBtnTaped( tag,sender )
	
end

-- 接受用户动作结束的通知，并调用model的处理方法  如状态改变
function FightController:heroActionFinished( event )
    -- event是一个table，基础包含name和target字段
    -- name是事件名称
    -- target是分发事件的对象
    -- event.target:removeSelf()
    local target = event.target
    local actor = target:getHeroInfo()
    actor:enterNextState()
    if event.actType == "atking" then
        -- 攻击动作完成
        -- target:setColor(ccc3(255,0,0))
    elseif event.actType == "kill" then
        -- 死亡动作完成
        self.deadCount = self.deadCount + 1
    elseif event.actType == "underatk" then
        local delayTime = CCDelayTime:create(1)
        local callBack = CCCallFunc:create(function (  )
            self:enterNextAtk()
        end)
        self:runAction(CCSequence:createWithTwoActions(delayTime,callBack))
        -- self:enterNextAtk()
    end
end
return FightController
