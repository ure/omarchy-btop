# btop screen

An Omarchy plugin that runs [btop](https://github.com/aristocratos/btop) sized to a whole
monitor, choosing the layout from that monitor's shape.

- **Wide, short screens** (a Corsair Xeneon Edge is 2560x720) get a column layout: cpu,
  memory/disks, network and processes side by side, each the full height of the screen.
- **Regular monitors** get btop's normal stacked layout.
- The window covers the monitor with no border, the background is see-through so the
  wallpaper shows, and btop's light text is dimmed to stay easy on the eyes.
- The font is shrunk only as far as needed to keep btop's menus usable, which need at
  least an 80x24 grid.

## Requirements

- Omarchy with Hyprland, plus `foot`, `jq` and `awk`
- For the column layout, a btop build with the `wide_layout` option
  ([ure/btop, branch wide-layout](https://github.com/ure/btop/tree/wide-layout)). Without
  it the plugin falls back to the stacked layout.

## Install

```bash
omarchy plugin add https://github.com/ure/omarchy-btop.git --enable --yes
```

Then add the window rule to `~/.config/hypr/hyprland.lua`:

```lua
dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/ure.btop/hypr/windows.lua")
```

For the per-screen bar switches, let it patch a clone of the bar (skip this if you are
happy with the bar on every screen):

```bash
~/.config/omarchy/plugins/ure.btop/scripts/bar-support install
omarchy restart shell
```

And add the menu row:

```bash
~/.config/omarchy/plugins/ure.btop/scripts/menu-entry add
```

## Use

- **Bar icon:** click the 󰍛 icon for a panel holding:
  - **a switch per monitor**, so btop goes on the wallpaper of whichever screens you want
    (the wide short ones are marked, and start out on)
  - **a bar switch beside it**, one per screen, hiding or showing Omarchy's bar on that
    monitor alone. With the bar gone that screen reserves nothing, so btop grows into
    the freed space. `scripts/bar-screen [toggle|show|hide] <monitor>` does the same
    from a keybinding.

  Omarchy's own bar draws on every screen, so the first time the panel offers
  **Enable per-screen bars**: it clones the stock bar into your own plugins, the way
  `omarchy plugin clone` does, and teaches the clone to skip the screens listed in
  `bar.hiddenScreens`. The packaged bar is never touched, and a bar already able to do
  this is left alone. `scripts/bar-support [status|install]` is the same thing from a
  terminal.
  - **a transparency slider** for how much wallpaper shows through btop
  - **Open as a window**, the same as right clicking the icon

  The transparency is remembered in `~/.local/state/ure-btop/state.json`. Right click opens btop as an ordinary window instead.
  Place the icon with `omarchy plugin enable ure.btop --section right`.
- **On the wallpaper:** the plugin's service draws btop on a background layer surface,
  above the wallpaper and below every window, on each wide short screen it finds. It
  takes no input at all, the way a wallpaper does not. Control it with
  `scripts/btop-background [toggle|show|hide] [monitor]`, which any keybinding can call.
- **Menu:** open the Omarchy menu, then *Apps → btop*. It fills whichever display has
  focus. Run it again to focus the window that is already open.
- **Command line:**

  ```bash
  scripts/btop-screen                          # focused monitor, layout picked automatically
  scripts/btop-screen --monitor HDMI-A-1       # a specific monitor, focus returns afterwards
  scripts/btop-screen --layout wide            # force columns
  scripts/btop-screen --if-running exit        # do nothing when one is already open
  ```

- **At login**, in `~/.config/hypr/autostart.lua`:

  ```lua
  o.exec_on_start(os.getenv("HOME") .. "/.config/omarchy/plugins/ure.btop/scripts/btop-screen --monitor HDMI-A-1 --if-running exit")
  ```

## Settings

Defaults can be overridden in `~/.config/btop/ure-btop.env`:

```bash
DIM=0.7            # how much to darken btop's light text, 1 = leave it alone
ALPHA=1            # window background opacity, 1 = opaque (the wallpaper mode is the see-through one)
FONT="JetBrainsMono Nerd Font"
MAX_FONT_SIZE=9    # never bigger than this
BTOP_BIN=          # path to a specific btop build
```

btop's own settings live in `~/.config/btop/ure-btop-wide.conf` and
`~/.config/btop/ure-btop-standard.conf`, separate from your normal `btop.conf`, so
changes made in btop's options menu only affect the full-screen instance.

## Uninstall

```bash
~/.config/omarchy/plugins/ure.btop/scripts/menu-entry remove
omarchy plugin remove ure.btop
```

Then drop the `dofile` line from `~/.config/hypr/hyprland.lua`.

## License

MIT
