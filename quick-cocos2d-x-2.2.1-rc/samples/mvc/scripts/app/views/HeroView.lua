
--[[--

“英雄”的视图

视图注册模型事件，从而在模型发生变化时自动更新视图

]]

local HeroView = class("HeroView", function()
    return display.newNode()
end)

function HeroView:ctor(hero)
    local cls = hero.class

    -- 通过代理注册事件的好处：可以方便的在视图删除时，清理所以通过该代理注册的事件，
    -- 同时不影响目标对象上注册的其他事件
    --
    -- EventProxy.new() 第一个参数是要注册事件的对象，第二个参数是绑定的视图
    -- 如果指定了第二个参数，那么在视图删除时，会自动清理注册的事件
    cc.EventProxy.new(hero, self)
        :addEventListener(cls.CHANGE_STATE_EVENT, self.onStateChange_, self)
        :addEventListener(cls.KILL_EVENT, self.onKill_, self)
        :addEventListener(cls.HP_CHANGED_EVENT, self.updateLabel_, self)
        :addEventListener(cls.EXP_CHANGED_EVENT, self.updateLabel_, self)
        :addEventListener(cls.UNDER_VERTIGO_EVENT, self.enterVertigo, self)
        :addEventListener(cls.RELEASE_VERTIGO_EVENT, self.leaveVertigo, self)
        :addEventListener(cls.CDTIME_CD_EVENT,self.updateCdLabel_, self)

    self.hero_ = hero
    self.sprite_ = display.newSprite():addTo(self)

    self.idLabel_ = ui.newTTFLabel({
            text = string.format("%s:%s", hero:getId(), hero:getNickname()),
            size = 22,
            color = display.COLOR_BLACK,
        })
        :pos(0, 100)
        :addTo(self)

    self.stateLabel_ = ui.newTTFLabel({
            text = "",
            size = 22,
            color = display.COLOR_RED,
        })
        :pos(0, 70)
        :addTo(self)

    self.vcdLabel_ = ui.newTTFLabel({
            text = "",
            size = 22,
            color = display.COLOR_RED,
        })
        :pos(0, 190)
        :addTo(self)

    self.fcdLabel_ = ui.newTTFLabel({
            text = "",
            size = 22,
            color = display.COLOR_RED,
        })
        :pos(0, 220)
        :addTo(self)

    self:updateSprite_(self.hero_:getState())
    self:updateLabel_()
end

function HeroView:flipX(flip)
    self.sprite_:flipX(flip)
    return self
end

function HeroView:isFlipX()
    return self.sprite_:isFlipX()
end

function HeroView:onStateChange_(event)
    self:updateSprite_(self.hero_:getState())
end

function HeroView:onKill_(event)
    local frames = display.newFrames("HeroDead%04d.png", 1, 4)
    local animation = display.newAnimation(frames, 0.6 / 4)
    self.sprite_:playAnimationOnce(animation)
end

function HeroView:updateLabel_()
    local h = self.hero_
    self.stateLabel_:setString(string.format("hp:%d, level.exp:%d.%d, attack:%d, armor:%d",
        h:getHp(), h:getLevel(), h:getExp(), h:getAttack(), h:getArmor()))
end
-- 眩晕的处理
function HeroView:enterVertigo(  )
    if not self.vertigoLabel_ then
        self.vertigoLabel_ = ui.newTTFLabel({
                text = string.format("眩晕中"),
                size = 22,
                color = display.COLOR_BLACK,
            })
            :pos(0, 150)
            :addTo(self)
    end
end

function HeroView:leaveVertigo(  )
    if self.vertigoLabel_ then
        self.vertigoLabel_:removeSelf()
        self.vertigoLabel_ = nil
    end
end

function HeroView:updateCdLabel_(  )
    local h = self.hero_
    self.vcdLabel_:setString("vcd   "..h:getVcd())
    self.fcdLabel_:setString("fcd   "..h:getFcd())
end

function HeroView:updateSprite_(state)
    local frameName
    if state == "idle" then
        frameName = "HeroIdle.png"
    elseif state == "firing" then
        frameName = "HeroFiring.png"
    end

    if not frameName then return end
    self.sprite_:setDisplayFrame(display.newSpriteFrame(frameName))
end

return HeroView
