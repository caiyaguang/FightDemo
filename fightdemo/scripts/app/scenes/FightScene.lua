local FightViewBg = import("..views.FightViewBg")
local FightController = import("..controller.FightController")
local BattleView = import("..views.BattleView")
local BattleField = import("..models.BattleField")
local Actor = import("..models.Actor")
local SkillModel = import("..models.SkillModel")

FightSceneOwner = FightSceneOwner or {}
ccb["FightSceneOwner"] = FightSceneOwner

local MainScene = class("MainScene", function()
    local node = display.newScene("MainScene")
    require("framework.api.EventProtocol").extend(node)
    return node
end)

function MainScene:ctor()
    local  proxy = CCBProxy:create()
    local  node  = CCBuilderReaderLoad("FightScene.ccbi",proxy,FightSceneOwner)
    local  layer = tolua.cast(node,"CCLayer")
    self:addChild(layer)

    self.contentLayer_ = tolua.cast(FightSceneOwner["contentLayer"],"CCLayer")       -- 盛放所有界面元素的容器

    self.FightBg_ = FightViewBg.new()           -- 战斗背景图片
    self.contentLayer_:addChild(self.FightBg_)
    local size = self.contentLayer_:getContentSize()
    self.FightBg_:setPosition(ccp( size.width / 2,size.height / 2 ))

    -- 获得每一个英雄的属性信息

    self.views_ = {}        -- 存放所有英雄卡片视图
    self.heros = {}
    -- -- 创建英雄对象，并存储在self.heros数组中
    local player = Actor.new({
        id = "player",
        sid = "player1",
        nickname = "dualface1",
        level = 1,
        side = 0,
        hp = 400,
        pos = 1,
        image = "hero_000403_bust_1.png",
        skills = SkillModel.new({
            name = "如来神掌",
            stype = 0,
            rangtype = 0,
            isshow = 0,
            haveeffect = 0,
            atktype = 0,
            damagetype = 0,
            damage = 100
            }),
        skill = {
            skill = {
                sid = 1,
                name = "万马千军",
                stype = 1,
                atk = 180
            }

        }
    })
    table.insert(self.heros,player)

    local player = Actor.new({
        id = "player",
        sid = "player2",
        nickname = "dualface2",
        level = 1,
        side = 0,
        hp = 500,
        pos = 2,
        image = "hero_000404_bust_1.png",
        skills = SkillModel.new({
            name = "如来神掌",
            stype = 0,
            rangtype = 0,
            isshow = 0,
            haveeffect = 0,
            atktype = 0,
            damagetype = 0,
            damage = 100
            }),
        skill = {
            skill = {
                name = "万马千军",
                stype = 0,
                atk = 110
            }

        }
    })
    table.insert(self.heros,player)

    local player = Actor.new({
        id = "player",
        sid = "player3",
        nickname = "fuck1",
        level = 1,
        side = 1,
        hp = 300,
        pos = 1,
        image = "hero_000405_bust_1.png",
        skills = SkillModel.new({
            name = "如来神掌",
            stype = 0,
            rangtype = 0,
            isshow = 0,
            haveeffect = 0,
            atktype = 0,
            damagetype = 0,
            damage = 100
            }),
        skill = {
            skill = {
                name = "万马千军",
                stype = 0,
                atk = 150
            }

        }
    })
    table.insert(self.heros,player)

    local player = Actor.new({
        id = "player",
        sid = "player4",
        nickname = "fuck2",
        level = 1,
        side = 1,
        hp = 600,
        pos = 2,
        image = "hero_000406_bust_1.png",
        skills = SkillModel.new({
            name = "如来神掌",
            stype = 0,
            rangtype = 0,
            isshow = 0,
            haveeffect = 0,
            atktype = 0,
            damagetype = 0,
            damage = 100
            }),
        skill = {
            skill = {
                name = "万马千军",
                stype = 0,
                atk = 130
            }

        }
    })

    table.insert(self.heros,player)

    -- 加入战斗动画层
    self.battleFieldObj_ = BattleField.new({ players = self.heros})
    -- 根据战场模型对象创建战场视图对象
    self.battleView_ = BattleView.new(self.battleFieldObj_)

    -- 绑定战场模型对战场数据的监听，当战场动作执行完毕后，修改战场模型的状态为闲置
    local cls = self.battleView_.class
    cc.EventProxy.new(self.battleView_, self.battleFieldObj_)
            :addEventListener(cls.BATTLE_ANIMATION_FINISHED, function ( event )
                self.battleFieldObj_:enterIdle()
            end,self.battleFieldObj_)

    self:addChild(self.battleView_)

    -- 根据战场视图对象创建控制器层
    self.controllerView_ = FightController.new(self.battleView_)
    self:addChild(self.controllerView_)
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
