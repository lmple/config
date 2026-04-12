-- ~/.config/wezterm/wezterm.lua
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("FiraCode Nerd Font", {
  weight = "Regular",
  -- Uncomment for slightly heavier weight:
  -- weight = "Medium",
})
config.font_size = 13.0

-- Ligatures: FiraCode's full feature set
config.harfbuzz_features = {
  "calt=1", -- Contextual alternates (core ligatures: -> => != <=)
  "clig=1", -- Contextual ligatures
  "liga=1", -- Standard ligatures
  -- FiraCode-specific extras (optional, uncomment to taste):
  "zero=1",   -- Slashed zero
  -- "onum=1",   -- Oldstyle numerals
  -- "ss01=1",   -- r curved tail
  "ss02=1",   -- <= >= with bars
  -- "ss03=1",   -- &
  -- "ss05=1",   -- @ variants
  -- "ss06=1",   -- \\ (lambda shorthand)
  -- "ss07=1",   -- =~ !~
  -- "cv14=1",   -- 3 with flat top
  -- "cv25=1",   -- .= variants
  "cv26=1",   -- :=
}

-- Appearance
config.color_scheme = "Tomorrow Night"  -- or "Catppuccin Mocha", "Gruvbox Dark", etc.
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0

-- Window chrome
config.window_decorations = "RESIZE"  -- no title bar, keep resize
config.window_padding = {
  left = 12,
  right = 12,
  top = 8,
  bottom = 8,
}

-- Tab bar
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

-- Scrollback
config.scrollback_lines = 10000

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- Performance
config.max_fps = 120
config.animation_fps = 60

-- Bell: silence it
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_duration_ms = 0,
  fade_out_duration_ms = 0,
}

-- Keybinds (minimal, ergonomic additions)
local act = wezterm.action
config.keys = {
  -- Split panes
  { key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "D", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- Navigate panes
  { key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
  -- Tabs
  { key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
  -- Font size
  { key = "=", mods = "CTRL",       action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL",       action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL",       action = act.ResetFontSize },
}

return config
