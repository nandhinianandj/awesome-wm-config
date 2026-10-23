local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local i18n = require("modules/i18n")

local function factory(args)
    local args = args or {}
    local widget = wibox.widget.textbox()
    
    local user = os.getenv("USER") or "User"
    local label_format = i18n.translate("switch_user.label", " 👤 %s ")
    widget:set_text(string.format(label_format, user))
    widget:set_align("right")
    
    -- Tooltip
    local tooltip_text = i18n.translate("switch_user.tooltip", "Click to switch user")
    local tooltip = awful.tooltip({
        objects = { widget },
        timer_function = function()
            return tooltip_text
        end
    })
    
    -- Action on click
    local function switch_user()
        naughty.notify({
            preset = naughty.config.presets.normal,
            title = i18n.translate("switch_user.notification_title", "Switch User"),
            text = i18n.translate("switch_user.notification_text", "Switching to login screen...")
        })
        awful.spawn.with_shell("/usr/bin/dm-tool switch-to-greeter")
    end
    
    widget:connect_signal("button::press", function(c, _, _, button)
        if button == 1 then -- Left click
            switch_user()
        end
    end)
    
    -- Mouse hover feedback: highlight color on hover
    local beautiful = require("beautiful")
    local focus_fg = beautiful.fg_focus or "#F0CC67"
    
    widget:connect_signal("mouse::enter", function()
        widget:set_markup(string.format("<span foreground='%s'>%s</span>", focus_fg, string.format(label_format, user)))
    end)
    
    widget:connect_signal("mouse::leave", function()
        widget:set_text(string.format(label_format, user))
    end)
    
    return widget
end

return factory
