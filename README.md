# Kanata Vim Plugin

This project provides a Vim-mode standalone or plugin config for [kanata](https://github.com/jtroo/kanata/tree/main).  
It brings Vim motions, actions, and modes to any text field on any operating system.

This works by introducing extra keyboard layers where keys are mapped to OS native keyboard shortcuts to navigate text.  
As an example, switching to the Vim normal layer, the `h` `j` `k` `l` keys are now mapped to the arrow keys, `w` is mapped to Alt-Right, and so on.  
This approach is inspired by the [Karabiner-Elements Vim Mode Plus mod](https://ke-complex-modifications.pqrs.org/#vim_mode_plus).

Demo Video:

https://github.com/user-attachments/assets/1bc56560-3af2-44c2-aabe-bf0b3d1e5285

## Quicklinks

- [About this config](#what-the-plugin-contains)
- [How to integrate in your kanata keymap](#how-to-integrate-in-your-kanata-keymap)
  - [Standalone mode (Recommended)](standalone-mode-recommended)
  - [Plugin setup](#plugin-setup)
- [Visualize vim mode](#visualize-active-vim-mode)
- [Supported Vim movements and actions](#supported-vim-movements-and-actions)

## What the config contains

The "plugin" consists of a collection of kanata `.kbd` config files that you can include in your kanata configuration.

- [`vim-standalone.kbd`](./examples/vim-standalone.kbd): A ready to use config for running in standalone mode.
- [`1-interface.kbd`](./1-interface.kbd): OS-specific primitive actions (`@left`, `@end-of-word`, `@copy`, `@undo`, ...). This is the only place that should use raw OS key combos.
- [`2-shared.kbd`](./2-shared.kbd): higher-level combos/macros (`@delete-word`, `@copy-line`, `@paste`, `@replace`, ...).
- [`3-bootstrapping.kbd`](./3-bootstrapping.kbd): mode state machine and entrypoint templates.
- [`4-normal-layer.kbd`](./4-normal-layer.kbd): Vim normal mode keymap.
- [`5-visual-layer.kbd`](./5-visual-layer.kbd): Vim visual mode keymap.
- [`6-visual-line-layer.kbd`](./6-visual-line-layer.kbd): Vim visual-line mode keymap.

## Inner workings (mode model)

- The plugin orchestrates 4 logical modes/layers: `insert`, `vim-normal`, `vim-visual`, `vim-visual-line`.
- For each mode, it also activates a respective override layer: `insert-override`, `vim-normal-override`, `vim-visual-override`, `vim-visual-line-override`.
- Override layers let you add custom remaps while reusing the shared Vim logic.

## How to integrate in your kanata keymap

There are two options on how to integrate this config into your setup:

  1. Standalone mode -> run a dedicated kanata instance (Recommended)
  2. Plugin mode     -> add the config to your existing kanata config

### Standalone mode (Recommended)

If you are running on Linux, I'd always recommend this approach.  
On other OSes, this will only work if you have no custom kanata setup.

The idea is to have a dedicated kanata instance running that is solely responsible for handling the Vim modes.  
This kanata instance can be applied to external keyboards (e.g. running on ZMK), but also on top of other kanata instances (Linux only?!).

Simply run a dedicated kanata process with a config similar to the one in [`vim-standalone.kbd`](./examples/vim-standalone.kbd).

To run a kanata on top of another kanata instance, I've found these two ways, which only seem to be supported on Linux:

  1. Via the keyboard name  
    - use `(defcfg linux-output-device-name "my-kanata-instance")` on the first instance to set a unique name  
    - use `(defcfg linux-dev-names-include ("my-kanata-instance"))` on the kanata Vim instance to apply on top of the first kanata instance  
  2. Via the keyboard path  
    - use `kanata --symlink-path /some/path/my-kanata-instance` to start first instance  
    - use `(defcfg linux-dev /some/path/my-kanata-instance)` on the kanata Vim instance to apply on top of the first kanata instance

Running a dedicated kanata instance allows to fully decouple the setup of the Vim config from any custom keymaps.  
So all custom keymap quirks such as homerow mods will simply work out of the box when in Vim mode.

### Plugin setup

This approach injects the Vim config into an existing kanata setup.  
It usually requires a bit more effort to make sure all keybindings work correctly.

Include the vim plugin files in this **strict order at the top** of your keymap.

```kbd
(include kanata-vim/1-interface.kbd)
(include kanata-vim/2-shared.kbd)
(include kanata-vim/3-bootstrapping.kbd)
(include kanata-vim/4-normal-layer.kbd)
(include kanata-vim/5-visual-layer.kbd)
(include kanata-vim/6-visual-line-layer.kbd)
```

Then wire your own config.

#### Optional `defcfg` requirements

Minimal plugin-relevant settings (optional):

```kbd
(defcfg
  process-unmapped-keys yes
  alias-to-trigger-on-load switch-insert
)
```

- `process-unmapped-keys yes`: lets unmapped keys pass through while Vim layers are active.
- `alias-to-trigger-on-load switch-insert`: starts Kanata in insert mode.

#### Layers you must define

You need:

- an `insert` layer (i.e. rename your normal typing layer to "insert")
- these override layermaps (can be empty initially):
  - `insert-override`
  - `vim-normal-override`
  - `vim-visual-override`
  - `vim-visual-line-override`

Example empty scaffolding:

```kbd
(deflayer insert <your custom keymap here>)
(deflayermap (insert-override))
(deflayermap (vim-normal-override))
(deflayermap (vim-visual-override))
(deflayermap (vim-visual-line-override))
```

### Map a Vim entrypoint

In the examples below, the vim entrypoint is mapped to `esc`.  
But of course you can map it to any key instead of `esc`, such as `caps` etc.

#### Simple setup

Map any key to the switch-vim-normal alias:

```kbd
(deflayermap (insert)
  esc @switch-vim-normal
)
```

Or get creative in how to enter vim mode. E.g. by double tap on escape:

```kbd
(deflayermap (insert)
  esc (tap-dance 200 (esc @switch-vim-normal))
)
```

#### Application-aware setup

It can be very nice to have a different vim mode trigger depending on the currently used app.  
E.g. in the terminal I need my `escape` key to behave normally (for actual vim use).  
But in my browser, I want the `escape` key to toggle the vim mode immediately.  
You can use the `vim-entrypoint` template for such a setup:

```kbd
(deflayermap (insert)
  esc (t! vim-entrypoint rsft)
)
```

Behavior:

- tap `esc`: normal key behavior
- hold `right shift` + tap `esc`: enter `vim-normal`
- if virtual key `vim-direct-enter` is active, always enters `vim-normal` on tap `esc`

This only makes sense in conjunction with an external script that toggles the `vim-direct-enter` virtual key based on the active app.  
For an example script that works with Hyprland on Linux, refer to [`hypr-window-listener.lua`](`./examples/hypr-window-listener.lua`) or [`hypr-window-listener.sh`](./examples/hypr-window-listener.sh).

### Leverage the override layers to tailor to a custom keymap

The plugin implementations of the vim layers assume the default vim mappings.  
E.g. in normal mode layer, the "j" key is mapped to the down arrow key.  
If you're using homerow mods, you most likely want to map a long tap of "j" to the shift key.  
Or maybe you're using `caps` as `escape` key and want to use it to exit normal mode.  

This can easily be achieved by using the override layers without touching the Vim layer implementation.  
Here are some simple examples (same principle applies to all override layers):

```kbd
(deflayermap (vim-normal-override)
  caps  @switch-insert               ;; exit normal mode by tapping the `caps` key.

  esc   (multi esc @switch-insert)   ;; Exit normal, but also tap the "Escape" key for the outside to use

  j     (tap-hold 200 200 _ rsft)  ;; add a homerow mod to normal mode (`_` will pass the keypress to the default vim normal layer action)
)
```

## Example plugin config setup

```kbd
(include kanata-vim/1-interface.kbd)
(include kanata-vim/2-shared.kbd)
(include kanata-vim/3-bootstrapping.kbd)
(include kanata-vim/4-normal-layer.kbd)
(include kanata-vim/5-visual-layer.kbd)
(include kanata-vim/6-visual-line-layer.kbd)

(defcfg
  process-unmapped-keys yes
  alias-to-trigger-on-load switch-insert
)

(defsrc
  esc
  caps
  j
  k
  ;; ... all other physical keys
)

(deflayer insert
  esc
  caps (t! vim-entrypoint rsft)
  f    (tap-hold 200 200 f lsft)
  j    (tap-hold 200 200 j rsft)
  ;; ... all other mappings
)

(deflayermap (insert-override)
)

(deflayermap (vim-normal-override)
  esc  (multi esc @switch-insert)
  caps (multi esc @switch-insert)
  f    (tap-hold 200 200 _ rsft)
  j    (tap-hold 200 200 _ rsft)
)

(deflayermap (vim-visual-override)
  esc  (multi @deselect @switch-vim-normal)
  caps (multi @deselect @switch-vim-normal)
)

(deflayermap (vim-visual-line-override)
  esc  (multi @deselect @switch-vim-normal)
  caps (multi @deselect @switch-vim-normal)
)
```

## Visualize active vim mode

It can be very confusing to use this plugin without a way to see which vim mode is currently active.  
Luckily the kanata TCP port allows to build simple integrations with external tools.  
For example, refer to [`quickshell-kanata-vim-status`](`./examples/quickshell-kanata-vim-status.qml`) [`waybar-kanata-vim-status.sh`](./examples/waybar-kanata-vim-status.sh) for a simple integration with Linux Quickshell or Waybar.  

(A more simple approach is to activate `CAPS` mode while vim layers are active - this shows a small caps-indicator on some OSes.)

## Supported Vim movements and actions

| Key / Combo | Action | Normal | Visual | Visual-line |
| --- | --- | --- | --- | --- |
| `h`, `j`, `k`, `l` | Move/select left down up right | ✅ | ✅ | ✅ |
| `b` | Move/select to start of word | ✅ | ✅ |  |
| `w`, `e` | Move/select to end of word | ✅ | ✅ |  |
| `0`, `_` | Move/select to start of line | ✅ | ✅ |  |
| `$` | Move/select to end of line | ✅ | ✅ |  |
| `gg` | Go/select to start of document | ✅ | ✅ | ✅ |
| `G` | Go/select to end of document | ✅ | ✅ | ✅ |
| `i`, `a` | Enter insert mode | ✅ |  |  |
| `I` | Insert at start of line | ✅ |  |  |
| `A` | Append at end of line | ✅ |  |  |
| `o` | Open line below  | ✅ |  |  |
| `O` | Open line above  | ✅ |  |  |
| `x` | Delete selection/character | ✅ | ✅ | ✅ |
| `X` | Delete previous character | ✅ |  |  |
| `d` | Delete selection |  | ✅ | ✅ |
| `dd` | Delete line | ✅ |  |  |
| `D` | Delete to end of line | ✅ |  |  |
| `diw`, `daw` | Delete word | ✅ |  |  |
| `cc` | Change line  | ✅ |  |  |
| `C` | Change to end of line  | ✅ |  |  |
| `ciw`, `caw` | Change inner word  | ✅ |  |  |
| `y` | Yank/copy selection |  | ✅ | ✅ |
| `yy` | Yank/copy line | ✅ |  |  |
| `Y` | Yank/copy to end of line | ✅ |  |  |
| `yiw`, `yaw` | Yank/copy word | ✅ |  |  |
| `v` | Enter visual mode | ✅ |  |  |
| `V` | Enter visual-line mode | ✅ |  |  |
| `viw`, `vaw` | Select word | ✅ |  |  |
| `p` | Paste | ✅ | ✅ | ✅ |
| `P` | Paste above  | ✅ | ✅ | ✅ |
| `r` | Replace one character | ✅ |  |  |
| `u` | Undo | ✅ |  |  |
| `C-r` | Redo | ✅ |  |  |
| `C-d` | Half-page down | ✅ | ✅ |  ✅|
| `C-u` | Half-page up | ✅ | ✅ | ✅ |
| `.` | Repeat last action (limited support) | ✅ |  |  |
| `Esc` | Exit to normal / insert mode | ✅ | ✅ | ✅ |
