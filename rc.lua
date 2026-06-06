-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibar = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

local screenful = require("screenful")
-- local awmodoro = require("awmodoro")

local deficient = require("deficient")
-- local wsm = require("workspace")
-- instanciate calendar widget
local calendar_widget = deficient.calendar({})

-- instanciate widget
local battery_widget = deficient.battery_widget {
    -- pass options here
    ac = "AC",
    adapter = "BAT1",
    ac_prefix = "AC: ",
    bttery_prefix = "Bat: ",
    percent_colors = {
        { 25, "red"   },
        { 50, "orange"},
        {999, "green" },
    },
    listen = true,
    timeout = 10,
    widget_text = "${AC_BAT}${color_on}${percent}%${color_off}",
    widget_font = "Deja Vu Sans Mono 16",
    tooltip_text = "Battery ${state}${time_est}\nCapacity: ${capacity_percent}%",
    alert_threshold = 15,
    alert_timeout = 0,
    alert_title = "Low battery !",
    alert_text = "${AC_BAT}${time_est}",
    alert_icon = "~/Downloads/low_battery_icon.png",
    warn_full_battery = true,
    full_battery_icon = "~/Downloads/full_battery_icon.png",
}

-- Instanciate cpu info widget:
local cpuinfo = deficient.cpuinfo()

--Net speed info widget 
local net_speed_widget = require("awesome-wm-widgets.net-speed-widget.net-speed")

--pomodoro wibar
pomowibar = awful.wibar({ position = "top", screen = 1, height=4})
pomowibar.visible = false
-- local pomodoro = awmodoro.new({
-- 	minutes 			= 45,
-- 	do_notify 			= true,
-- 	active_bg_color 	= '#313131',
-- 	paused_bg_color 	= '#7746D7',
-- 	fg_color			= {type = "linear", from = {0,0}, to = {pomowibar.width, 0},
--                     stops = {{0, "#AECF96"},{0.5, "#88A175"},{1, "#FF5656"}}},
-- 	width 				= pomowibar.width,
-- 	height 				= pomowibar.height,
--
-- 	begin_callback = function()
-- 		for s in screen do
-- 			s.mywibar.visible = false
-- 		end
-- 		pomowibar.visible = true
-- 	end,
--
-- 	finish_callback = function()
--     awful.util.spawn("aplay	/home/foo/sounds/bell.wav")
-- 		for s in screen do
-- 			s.mywibar.visible = true
-- 		end
-- 		pomowibar.visible = false
-- 	end})
-- pomowibar:set_widget(pomodoro)

-- Load Debian menu entries
-- local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
--beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex"           -- 10
}

local chosen_theme = themes[8]
local vi_focus     = false -- vi-like client focus https://github.com/lcpz/awesome-copycats/issues/275

-- scan directory, and optionally filter outputs
function scandir(directory, filter)
    local i, t, popen = 0, {}, io.popen
    if not filter then
        filter = function(s) return true end
    end
    for filename in popen('ls -a "'..directory..'"'):lines() do
        if filter(filename) then
            i = i + 1
            t[i] = filename
        end
    end
    return t
end

-- }}}
local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), "zenburn")
beautiful.init(theme_path)
beautiful.wibar_height=30
-- configurations for beautiful
beautiful.font = "monospace 18"
-- configuration - edit to your liking
wp_index = 1
wp_timeout  = 300
wp_path = string.format("%s/memes", os.getenv("HOME"))
wp_files = scandir(wp_path)

--nomi_wp = wp_path .. '/' .. '87176258_10158216083568586_2744505873333223424_o.jpg'
--climate_wp = wp_path .. '/' .. 'climateChangeDenialismStrategies.png'
-- climate_risks = wp_path .. '/' .. '1682973858638.jpeg'
buddha = wp_path .. '/quotes/' .. 'hm8uqv2t8j4e1.jpeg'
-- cc1_layout = wp_path .. '/' .. 'cc1_alpha_layout.png'

-- set wallpaper to current index for all screens
for s = 1, screen.count() do
    gears.wallpaper.maximized(buddha, s, true)
end


-- Setup Volume control
local deficient = require("deficient")


-- instanciate volume control, using default settings:
volumecfg = deficient.volume_control({})


--- Variables
local names = {  "WorldWideWeb", "CodeMode", "Commune", "BgDaemons","Misc", "Monitor"}

-- This is used later as the default terminal and editor to run.
terminal = "lxterminal"
screenshot_cmd = "scrot -s '%Y-%m-%d_$wx$h_scrot.png' -e 'mv $f ~/Pictures/shots/'"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    --awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibar.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "switch user", terminal .. " -e /usr/bin/dm-tool switch-to-greeter " },
   { "suspend", terminal .. " -e systemctl suspend" },
   { "hibernate", terminal .. " -e systemctl hibernate" },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after =  { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = {
                  menu_awesome,
                  -- { "Debian", debian.menu.Debian_menu.Debian },
                  menu_terminal,
                }
    })
end


mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
menubar.menubar_border_width=50
menubar.height = 50
-- }}}

-- Volume control widget

tb_volume = wibar.widget({ type = "textbox", name = "tb_volume", align = "right" })
 tb_volume:buttons({
 	button({ }, 4, function () volume("up", tb_volume) end),
 	button({ }, 5, function () volume("down", tb_volume) end),
 	button({ }, 1, function () volume("mute", tb_volume) end)
 })
-- volume("update", tb_volume)

-- Create a textclock widget
mytextclock = wibar.widget.textclock()
-- attach calendar it as popup to your text clock widget
calendar_widget:attach(mytextclock)

-- Create a wibar for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(nomi_wp, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- Lightweight text-based widgets
local cpu_widget = wibar.widget.textbox()
local cpu_prev_total, cpu_prev_active = 0, 0
awful.widget.watch("grep 'cpu ' /proc/stat", 1, function(widget, stdout)
    local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice = stdout:match("cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
    local total = user + nice + system + idle + iowait + irq + softirq + steal
    local active = total - idle
    local diff_total = total - cpu_prev_total
    local diff_active = active - cpu_prev_active
    if diff_total > 0 then
        local usage = math.floor((diff_active / diff_total) * 100)
        widget:set_text(" CPU: " .. usage .. "% ")
    end
    cpu_prev_total = total
    cpu_prev_active = active
end, cpu_widget)

local net_widget = wibar.widget.textbox()
local net_prev_rx, net_prev_tx = 0, 0
awful.widget.watch("cat /proc/net/dev", 1, function(widget, stdout)
    local rx, tx = 0, 0
    for line in stdout:gmatch("[^\r\n]+") do
        local r, t = line:match("%s+(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)")
        if r and t then
            rx = rx + tonumber(r)
            tx = tx + tonumber(t)
        end
    end
    local down = math.floor((rx - net_prev_rx) / 1024)
    local up = math.floor((tx - net_prev_tx) / 1024)
    widget:set_text(" NET: ↓" .. down .. " ↑" .. up .. " KB/s ")
    net_prev_rx = rx
    net_prev_tx = tx
end, net_widget)

local disk_widget = wibar.widget.textbox()
local disk_prev_read, disk_prev_write = 0, 0
awful.widget.watch("cat /proc/diskstats", 1, function(widget, stdout)
    local read, write = 0, 0
    for line in stdout:gmatch("[^\r\n]+") do
        local r, w = line:match("%s+%d+%s+%d+%s+sd[a-z]%s+%d+%s+%d+%s+(%d+)%s+%d+%s+%d+%s+%d+%s+(%d+)")
        if r and w then
            read = read + tonumber(r) * 512
            write = write + tonumber(w) * 512
        end
    end
    local read_rate = math.floor((read - disk_prev_read) / 1024 / 1024)
    local write_rate = math.floor((write - disk_prev_write) / 1024 / 1024)
    widget:set_text(" DISK: R" .. read_rate .. " W" .. write_rate .. " MB/s ")
    disk_prev_read = read
    disk_prev_write = write
end, disk_widget)

local gpu_widget = wibar.widget.textbox()
awful.widget.watch("nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits", 5, function(widget, stdout)
    local usage = stdout:match("%d+")
    if usage then
        widget:set_text(" GPU: " .. usage .. "% ")
    else
        widget:set_text("")
    end
end, gpu_widget)

--- For each screen do these actions
awful.screen.connect_for_each_screen(function(s)
    -- Set Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    local tags = awful.tag(names, s, awful.layout.layouts[1])

    if s.index == 1 then
        -- Find the Monitor tag on the laptop screen
        local monitor_tag = nil
        for _, t in ipairs(tags) do
            if t.name == "Monitor" then
                monitor_tag = t
                break
            end
        end

        if monitor_tag then
            monitor_tag.layout = awful.layout.suit.tile
            monitor_tag:view_only()

            -- Ensure "Monitor" tag stays selected on screen 1
            monitor_tag:connect_signal("property::selected", function(tag)
                if not tag.selected then
                    tag:view_only()
                end
            end)
        end
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibar
    s.mywibar = awful.wibar({ position = "top", screen = s })
        -- Add widgets to the wibar
    s.mywibar:setup {
        layout = wibar.layout.align.horizontal,
        { -- Left widgets
            layout = wibar.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibar.layout.fixed.horizontal,
            tb_volume,
            wibar.widget.systray(),
            mytextclock,
            cpu_widget,
            net_widget,
            disk_widget,
            gpu_widget,
            battery_widget,
            -- volumecfg.widget,
            s.mylayoutbox,
        },
    }

end)

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),
    -- Trigger the manual detect
    awful.key({ modkey, "Control" }, "m", function () awful.spawn.with_shell("~/.config/awesome/monitor.sh")
            end, {description = "detect external monitor", group = "screen"}),

    -- Toggle microphone state
    awful.key({ modkey, "Shift" }, "m",
          function ()
              beautiful.mic:toggle()
          end,
          {description = "Toggle microphone (amixer)", group = "Hotkeys"}
    ),
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),
    -- Screenshot command
    awful.key({ modkey  , "Shift" }, "p", function () awful.spawn(screenshot_cmd) end,
          {description = "take screenshot", group = "launcher"}),
    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Shift"   }, "h", function () awful.util.spawn("systemctl hibernate") end,
              {description = "trigger Yad tools", group="awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    -- Lock Screen
    awful.key({ modkey },  	"b",  function () awful.spawn("slock") end,
    		{description="lock screen", group="layout"}),
    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    -- Volume controls
    awful.key({}, "XF86AudioRaiseVolume", function() volumecfg:up() end),
    awful.key({}, "XF86AudioLowerVolume", function() volumecfg:down() end),
    awful.key({}, "XF86AudioMute",        function() volumecfg:toggle() end)
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
    )
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 5 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"})
    )
end

-- clientbuttons = gears.table.join(
--     awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
--     awful.button({ modkey }, 1, awful.mouse.client.move),
--     awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     -- buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
     { rule_any = { class = { "Chrome", "Chromium-browser",
                              "Firefox", "Opera", "Brave" } },
      properties = { tag = "WorldWideWeb" } },

     -- Monitoring apps routing
     { rule_any = { class = { "sys-btop", "sys-iotop", "sys-nmon" } },
       properties = { screen = 1, tag = "Monitor", switch_to_tags = false } },

     { rule_any = { class = { "zed", "cursor", "Spyder", "AntiGravity", "Code", "Replit"} },
      properties = { tag = "CodeMode" } },

      { rule_any = { class = { "xterm", "gnome-terminal", "lxterminal", "mate-terminal"} },
      properties = { tag = "BgDaemons" } },

      { rule_any = { class = { "Signal", "Slack", "Teams", "Zoom Meeting", "Telegram", "Discord", "meet" } },
            properties = { tag = "Commune" } },

      { rule_any = { class = { "Cisco Anyconnect", "Spotify", "Transmission" } },
      properties = { tag = "Misc" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
-- client.connect_signal("manage", function (c)
--     -- Set the windows at the slave,
--     -- i.e. put it at the end of others instead of setting it master.
--     -- if not awesome.startup then awful.client.setslave(c) end
--
--     if awesome.startup and
--       not c.size_hints.user_position
--       and not c.size_hints.program_position then
--         -- Prevent clients from being unreachable after screen count changes.
-- 	awful.client.movetoscreen(c, client.focus.screen)
-- 	awful.client.movetoscreen(c, client.focus.screen)
--         awful.placement.no_offscreen(c)
--     end
-- end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibar.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibar.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibar.layout.fixed.horizontal()
        },
        layout = wibar.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

awful.util.spawn("eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg) &")
-- autostart dropbox, rescuetime, network manager etc..
awful.util.spawn("nm-applet &")
-- Communications and time management.
awful.util.spawn("nohup rescuetime &")
-- music
-- awful.util.spawn("nohup spotify &")
-- redshift
-- awful.util.spawn("nohup redshift &")
awful.util.spawn('nohup signal-desktop --password-store="gnome-libsecret" &')
-- awful.util.spawn("nohup teams &")
-- awful.util.spawn("nohup skypeforlinux &")
-- awful.util.spawn("nohup gitter &")
-- awful.util.spawn("nohup slack &")
-- awful.util.spawn("nohup zoom &")
awful.util.spawn("nohup syncthing &")
-- awful.util.spawn("nohup discord &")
awful.util.spawn("nohup Telegram  &")
--awful.util.spawn("nohup /opt/cisco/anyconnect/bin/vpnui &")
-- awful.util.spawn("xscreensaver &")
-- awful.util.spawn("sudo " .. string.format("%s/playspace/get-shit-done/get-shit-done.py work;", os.getenv("HOME")))
-- Start Ibus keyboard layout
awful.spawn.with_shell("~/.config/awesome/ibus_starter.sh")
-- Add this to rc.lua
awful.spawn.with_shell("setxkbmap -layout us,in -variant ,tam_tamil99 -option grp:alt_shift_toggle")
awful.util.spawn("export $(dbus-launch)")
-- Start GNOME Keyring daemon
awful.spawn.with_shell("eval $(ssh-agent); eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)")
-- Automatically handle external monitor on startup-- Automatically start the display hotplug daemon
-- Only start the display daemon if an instance isn't already running
awful.spawn.with_shell("pgrep -f monitor-daemon.sh || ~/.local/bin/monitor-daemon.sh")

-- Launch monitoring apps on startup
gears.timer.delayed_call(function()
    awful.spawn("xterm -class sys-btop -e btop")
    awful.spawn("xterm -class sys-iotop -e 'sudo iotop'")
    awful.spawn("xterm -class sys-nmon -e nmon")
end)


