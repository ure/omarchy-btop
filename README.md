# btop screen

An Omarchy plugin that runs [btop](https://github.com/aristocratos/btop) sized to a whole
monitor, choosing the layout from that monitor's shape.

- **Wide, short screens** (a Corsair Xeneon Edge is 2560x720) get a column layout: cpu,
  memory/disks, network and processes side by side, each the full height of the screen.
  That layout is the one thing needing a patched btop — see
  [The patched btop](#the-patched-btop-and-when-you-need-it).
- **Regular monitors** get btop's normal stacked layout, with the btop you already have.
- The window covers the monitor with no border, the background is see-through so the
  wallpaper shows, and btop's light text is dimmed to stay easy on the eyes.
- The font is shrunk only as far as needed to keep btop's menus usable, which need at
  least an 80x24 grid.

## Dependencies

All of these come from your distribution; the plugin installs none of them for you.

| Needed for | Packages |
|---|---|
| Everything | Omarchy (Quattro) with Hyprland and `omarchy-shell`, `jq`, `awk`, `hyprctl` |
| The window mode | `foot` |
| The wallpaper mode | `tmux`, `python3` |
| `scripts/btop-build`, only for the column layout | `git`, `make`, a C++ compiler, and btop's own build dependencies |

## The patched btop, and when you need it

**Most people do not need this.** On an ordinary monitor the plugin uses whatever btop
your distribution ships and draws its normal stacked layout. Everything else — the
wallpaper surface, the window, the bar panel, the menu row — works with the stock btop.

The **column layout is the exception**. It exists for a short, wide screen such as the
Corsair Xeneon Edge (2560x720), where the stacked layout leaves most of the strip empty,
and it comes from a `wide_layout` option that upstream btop does not have and no
distribution ships. So a screen like that needs a btop built from the patch.

Whichever way you get it, the plugin looks for a btop in this order: `BTOP_BIN` from
`~/.config/btop/ure-btop.env`, then `~/.local/share/ure.btop/bin/btop`, then `btop` on
your `PATH`. If none of them has `wide_layout`, it says so once and uses the stacked
layout instead.

### The easy way

```bash
~/.config/omarchy/plugins/ure.btop/scripts/btop-build
```

It fetches [ure/btop](https://github.com/ure/btop/tree/wide-layout) at one pinned commit,
builds it, and installs it under `~/.local/share/ure.btop`. Your system btop is never
touched or replaced. `--status` says what is installed, `--force` rebuilds, and the
build takes a couple of minutes.

### Building it yourself

The same thing by hand, if you would rather see every step:

```bash
git clone https://github.com/ure/btop.git
cd btop
git checkout wide-layout
make -j"$(nproc)"
make install PREFIX="$HOME/.local/share/ure.btop"
```

### Patching your own btop

`patches/wide-layout.patch` is the change on its own — five files, no dependencies — if
you would rather apply it to your own btop checkout or send it somewhere:

```bash
cd your-btop-checkout
git apply /path/to/omarchy-btop/patches/wide-layout.patch
make -j"$(nproc)"
```

Then point the plugin at the result by putting `BTOP_BIN=/path/to/your/btop` in
`~/.config/btop/ure-btop.env`.

## Install

```bash
omarchy plugin add https://github.com/ure/omarchy-btop.git --enable --yes
```

Only for a short wide screen, build the btop that has the column layout (see
[The patched btop](#the-patched-btop-and-when-you-need-it); skip it on an ordinary
monitor and btop's stacked layout is used):

```bash
~/.config/omarchy/plugins/ure.btop/scripts/btop-build
```

Then add the window rule to `~/.config/hypr/hyprland.lua`:

```lua
dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/ure.btop/hypr/windows.lua")
```

And add the menu row:

```bash
~/.config/omarchy/plugins/ure.btop/scripts/menu-entry add
```

## Use

- **Bar icon:** click the 󰍛 icon for a panel holding:
  - **a switch per monitor**, so btop goes on the wallpaper of whichever screens you want
    (the wide short ones are marked, and start out on)
  - **a transparency slider** for how much wallpaper shows through btop
  - **Open as a window**, the same as right clicking the icon

  Right click the icon opens the window straight away. The transparency is remembered
  in `~/.local/state/ure-btop/state.json`. Place the icon with
  `omarchy plugin enable ure.btop --section right`.
- **On the wallpaper:** the plugin's service draws btop on a layer-shell surface, above
  the wallpaper and below every window, on each wide short screen it finds. It
  takes no input at all, the way a wallpaper does not. Control it with
  `scripts/btop-background [toggle|show|hide] [monitor]`, which any keybinding can call.
- **Menu:** open the Omarchy menu and pick *btop*. It opens a window on the wide short
  screen when there is one, else on the focused display. Run it again to focus the
  window that is already open.
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
BTOP_BIN=          # a specific btop binary, ahead of the plugin's own build
DIM=0.7            # how much to darken btop's light text, 1 = leave it alone
ALPHA=1            # window background opacity, 1 = opaque (the wallpaper mode is the see-through one)
FONT="JetBrainsMono Nerd Font"
MAX_FONT_SIZE=9    # never bigger than this
```

btop's own settings live in `~/.config/btop/ure-btop-wide.conf` and
`~/.config/btop/ure-btop-standard.conf`, separate from your normal `btop.conf`, so
changes made in btop's options menu only affect the full-screen instance.

## Uninstall

```bash
~/.config/omarchy/plugins/ure.btop/scripts/menu-entry remove   # the menu row
omarchy plugin remove ure.btop                                 # the plugin and its bar icon
rm -rf ~/.local/share/ure.btop ~/.cache/ure.btop               # the btop it built
rm -rf ~/.local/state/ure-btop                                 # the remembered transparency
rm -f ~/.config/btop/ure-btop-*.conf ~/.config/btop/themes/ure-btop-dim.theme
```

Then drop the `dofile` line from `~/.config/hypr/hyprland.lua`.

Your own `btop.conf` is never touched.

## License

MIT
