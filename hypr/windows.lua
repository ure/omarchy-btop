-- Window rules for the btop screen plugin.
--
-- Load it from ~/.config/hypr/hyprland.lua with:
--   dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/ure.btop/hypr/windows.lua")
--
-- Floating at monitor size rather than fullscreen on purpose: Hyprland skips
-- drawing the wallpaper behind a fullscreen window, which would leave the
-- see-through terminal with nothing to show through to.
o.window("org.omarchy.btop-screen", {
  float = true,
  size = { "(monitor_w)", "(monitor_h)" },
  move = { 0, 0 },
  border_size = 0,
  no_shadow = true,
})
