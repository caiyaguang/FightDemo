
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    local item = ui.newTTFLabelMenuItem({
        text = "call Java - showAlertDialog()",
        size = 64,
        x = display.cx,
        y = display.cy,
        align = ui.TEXT_ALIGN_CENTER,
        listener = function()
            -- call Java method
            local javaClassName = "com.quick_x.sample.luajavabridge.Luajavabridge"
            local javaMethodName = "showAlertDialog"
            local javaParams = {
                "How are you ?",
                "I'm great !",
                function(event)
                    printf("Java method callback value is [%s]", event)
                end
            }
            local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;I)V"
            luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        end
    })
    self:addChild(ui.newMenu({item}))
end

function MainScene:onEnter()
    if device.platform ~= "android" then return end

    -- avoid unmeant back
    self:performWithDelay(function()
        -- keypad layer, for android
        local layer = display.newLayer()
        layer:addKeypadEventListener(function(event)
            if event == "back" then game.exit() end
        end)
        self:addChild(layer)

        layer:setKeypadEnabled(true)
    end, 0.5)
end

return MainScene
