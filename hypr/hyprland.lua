-- Hyprland 0.57+ reads only Lua (~/.config/hypr/hyprland.lua): the old
-- hyprlang hyprland.conf is ignored. hyprlock and hypridle still use .conf.
-- API reference: /usr/share/hypr/stubs/hl.meta.lua, wiki.hypr.land.

-- ─── NVIDIA env vars (must be set early) ────────────────────────────────────
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("NVD_BACKEND", "direct")
hl.env("__GL_GSYNC_ALLOWED", "0")
hl.env("__GL_VRR_ALLOWED", "0")

-- ─── Toolkit / Wayland env vars ─────────────────────────────────────────────
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- KDE apps (Dolphin) outside Plasma. Without the menu prefix, Dolphin's
-- "Open with" is empty: KDE builds it from <prefix>applications.menu, and
-- only /etc/xdg/menus/plasma-applications.menu is installed. The platform
-- theme gives Breeze and the colours set in Plasma (plasma-integration).
hl.env("XDG_MENU_PREFIX", "plasma-")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- ─── Cursor ──────────────────────────────────────────────────────────────────
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- ─── Monitors ────────────────────────────────────────────────────────────────
-- The laptop's own screen (eDP-1) always on the right, any other screen to
-- its left, whatever order they are found in
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto-right", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto-left", scale = 1 })

-- ─── Startup ─────────────────────────────────────────────────────────────────
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle > /dev/null 2>&1")
    hl.exec_cmd("waybar > /dev/null 2>&1")
    -- Started here, not D-Bus activated: Plasma's daemon also claims
    -- org.freedesktop.Notifications, and whichever starts first wins
    hl.exec_cmd("mako")
    hl.exec_cmd("~/.config/hypr/battery-notify.sh")
    -- No nm-applet: Waybar's network pill connects, through nmtui
    hl.exec_cmd("emacs --daemon")
end)

-- ─── Look and feel ───────────────────────────────────────────────────────────
hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 5,
        border_size = 2,
        col = {
            -- Ashen red-ember and g-8, as zellij's selected tab and panes
            active_border = "rgba(b14242ff)",
            inactive_border = "rgba(323232cc)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 0.95,
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

-- ─── Input ───────────────────────────────────────────────────────────────────
hl.config({
    input = {
        -- Swiss French, as `localectl` reports; "ch" alone is Swiss German
        kb_layout = "ch",
        kb_variant = "fr",
        -- Caps Lock is another Ctrl, easier to reach for Emacs's chords
        kb_options = "ctrl:nocaps",
        follow_mouse = 1,
        -- The mouse wheel and TrackPoint scroll like the touchpad below.
        -- SUPER + wheel's workspace scroll follows, so it flips direction too.
        natural_scroll = true,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            -- Right click by pressing with two fingers, not in the corner of the pad
            clickfinger_behavior = true,
        },
        sensitivity = 0,
    },
})

-- ─── Layout ──────────────────────────────────────────────────────────────────
hl.config({
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
})

-- ─── Misc ────────────────────────────────────────────────────────────────────
hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
    cursor = {
        no_hardware_cursors = true, -- NVIDIA draws a black hardware cursor
    },
    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_invert = true,
        workspace_swipe_cancel_ratio = 0.5,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- ─── Key bindings ────────────────────────────────────────────────────────────
local mod = "SUPER"

-- Prefix the main modifier: key("SHIFT + H") is "SUPER + SHIFT + H"
local function key(rest)
    return mod .. " + " .. rest
end

hl.bind(key("Return"), hl.dsp.exec_cmd("alacritty"))
hl.bind(key("Q"), hl.dsp.window.close())
hl.bind(key("M"), hl.dsp.exit())
hl.bind(key("E"), hl.dsp.exec_cmd("dolphin"))
hl.bind(key("V"), hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("P"), hl.dsp.exec_cmd("wofi --show drun"))
-- Same launcher on Space too: the Plasma/macOS habit
hl.bind(key("space"), hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(key("R"), hl.dsp.window.pseudo())
hl.bind(key("F"), hl.dsp.window.fullscreen({ action = "toggle" }))
-- Through logind, so hypridle's lock_cmd runs it: the same path as the idle
-- and before-sleep locks, and never two hyprlocks (hypridle.conf)
hl.bind(key("L"), hl.dsp.exec_cmd("loginctl lock-session"))
-- Lock, suspend, logout, reboot, shutdown (also Waybar's power button)
hl.bind(key("Escape"), hl.dsp.exec_cmd("~/.config/hypr/power-menu.sh"))

-- Alt+Tab / Alt+Shift+Tab (or Super): focus the next / previous window on
-- this workspace and raise it, so a floating one isn't left behind the others.
-- Cycles in order, not most-recently-used like Plasma's switcher.
local function cycle_windows(forward)
    return function()
        hl.dispatch(hl.dsp.window.cycle_next({ next = forward }))
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
    end
end
hl.bind("ALT + Tab", cycle_windows(true))
hl.bind("ALT + SHIFT + Tab", cycle_windows(false))
hl.bind(key("Tab"), cycle_windows(true))
hl.bind(key("SHIFT + Tab"), cycle_windows(false))

-- Region screenshot, then copy, save or both (screenshot.sh). Super+Shift+S
-- too, for keyboards without a Print key.
local screenshot = "~/.config/hypr/screenshot.sh"
hl.bind("Print", hl.dsp.exec_cmd(screenshot))
hl.bind(key("SHIFT + S"), hl.dsp.exec_cmd(screenshot))

-- Screen brightness keys: 5% steps while held, also on the lock screen. The
-- kernel doesn't act on them itself here (no acpi_video backlight).
hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("~/.config/hypr/brightness.sh up"),
    { repeating = true, locked = true }
)
hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("~/.config/hypr/brightness.sh down"),
    { repeating = true, locked = true }
)

local directions = {
    { arrow = "left", vim = "H", dx = -30, dy = 0 },
    { arrow = "right", vim = "L", dx = 30, dy = 0 },
    { arrow = "up", vim = "K", dx = 0, dy = -30 },
    { arrow = "down", vim = "J", dx = 0, dy = 30 },
}

for _, d in ipairs(directions) do
    -- Move focus. Arrows only: SUPER + L is the lock, so SUPER + H/J/K/L
    -- would be a set with one key missing.
    hl.bind(key(d.arrow), hl.dsp.focus({ direction = d.arrow }))
    -- Move window
    hl.bind(key("SHIFT + " .. d.vim), hl.dsp.window.move({ direction = d.arrow }))
    -- Resize, repeating while held
    hl.bind(
        key("ALT + " .. d.vim),
        hl.dsp.window.resize({ x = d.dx, y = d.dy, relative = true }),
        { repeating = true }
    )
end

-- Workspaces: SUPER + 1..9, 0 for 10; SUPER + SHIFT + 1..5 moves a window
for i = 1, 10 do
    hl.bind(key(tostring(i % 10)), hl.dsp.focus({ workspace = i }))
end
for i = 1, 5 do
    hl.bind(key("SHIFT + " .. i), hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces
hl.bind(key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("mouse_up"), hl.dsp.focus({ workspace = "e-1" }))

-- Mouse window control
hl.bind(key("mouse:272"), hl.dsp.window.drag(), { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })
