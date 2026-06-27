# Kanata Vim Plugin

This project is a reusable Vim-mode "plugin" for [kanata](https://github.com/jtroo/kanata/tree/main).
It provides mode switching and common Vim-like editing motions/actions on top of a custom kanata keymap.
Essentially, this brings Vim-like text manipulation to any application and operating system.

This works by introducing extra kanata layers where the keys are mapped to OS native keyboard shortcuts to navigate text.
So switching to the vim normal layer, the h j k l keys are now remapped to the arrow keys, w is mapped to Alt-Right, and so on.
This approach is inspired by the [Karabiner-Elements Vim Mode Plus mod](https://ke-complex-modifications.pqrs.org/#vim_mode_plus).

## Table of contents

- [What the plugin contains](#what-the-plugin-contains)
- [Inner workings (mode model)](#inner-workings-mode-model)
- [How to integrate in your kanata keymap](#how-to-integrate-in-your-kanata-keymap)
  - [1) Optional `defcfg` requirements](#1-optional-defcfg-requirements)
  - [2) Layers you must define](#2-layers-you-must-define)
  - [3) Map a Vim entrypoint from insert mode](#3-map-a-vim-entrypoint-from-insert-mode)
  - [4) Leverage the override layers to tailor to a custom keymap](#4-leverage-the-override-layers-to-tailor-to-a-custom-keymap)
- [Minimal setups](#minimal-setups)
  - [A) Standard keyboard (e.g. laptop builtin)](#a-standard-keyboard-eg-laptop-builtin)
  - [B) Minimal passthrough keyboard (e.g. external keyboard)](#b-minimal-passthrough-keyboard-eg-external-keyboard)
- [Visualize active vim mode](#visualize-active-vim-mode)
- [Supported Vim movements and actions](#supported-vim-movements-and-actions)

## What the plugin contains

The "plugin" consists of a collection of kanata `.kbd` config files that you can include in your kanata configuration.

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

### 1) Optional `defcfg` requirements

Minimal plugin-relevant settings (optional):

```kbd
(defcfg
  process-unmapped-keys yes
  alias-to-trigger-on-load switch-insert
)
```

- `process-unmapped-keys yes`: lets unmapped keys pass through while Vim layers are active.
- `alias-to-trigger-on-load switch-insert`: starts Kanata in insert mode.

### 2) Layers you must define

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

### 3) Map a Vim entrypoint from insert mode

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
For an example script that works with Hyprland on Linux, refer to [`examples/hypr-window-listener.sh`](./examples/hypr-window-listener.sh).

### 4) Leverage the override layers to tailor to a custom keymap

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

## Minimal setups

### A) Standard keyboard (e.g. laptop builtin)

```kbd
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

### B) Minimal passthrough keyboard (e.g. external keyboard)

Good for external keyboards with custom firmware (such as QMK or ZMK).
In this case, kanata is only used to enable the vim mode for this keyboard.

```kbd
(defcfg
  process-unmapped-keys yes
  alias-to-trigger-on-load switch-insert
)

(defsrc
  esc
)

(deflayermap (insert)
  esc (t! vim-entrypoint rsft)
  ___ use-defsrc    ;; needed for the @replace action to work properly
)

(deflayermap (insert-override))

(deflayermap (vim-normal-override)
  esc (multi esc @switch-insert)
  4   (fork _ @end-of-line (lsft rsft))   ;; ZMK will send a shifted 4 when I press the `$` key
)

(deflayermap (vim-visual-override)
  4   (fork _ @select-end-of-line (lsft rsft))
)
(deflayermap (vim-visual-line-override))
```

## Visualize active vim mode

It can be very confusing to use this plugin without a way to see which vim mode is currently active.
Luckily the kanata TCP port allows to build simple integrations with external tools.
For example, refer to [`examples/waybar-kanata-vim-status.sh`](./examples/waybar-kanata-vim-status.sh) for a simple integration with Linux Waybar.

(A more simple approach is to activate `CAPS` mode while vim layers are active - this shows a small caps-indicator on some OSes.)

## Supported Vim movements and actions

| Key / Combo | Action | Normal | Visual | Visual-line |
| --- | --- | --- | --- | --- |
| `h`, `j`, `k`, `l` | Move/select left down up right | ✅ | ✅ | ✅ |
| `b` | Move/select to start of word | ✅ | ✅ |  |
| `w` | Move/select to end of word | ✅ | ✅ |  |
| `0` | Move/select to start of line | ✅ | ✅ |  |
| `gg` | Go/select to start of document | ✅ | ✅ | ✅ |
| `G` | Go/select to end of document | ✅ | ✅ | ✅ |
| `i`, `a` | Enter insert mode | ✅ |  |  |
| `I` | Insert at start of line | ✅ |  |  |
| `A` | Append at end of line | ✅ |  |  |
| `o` | Open line above  | ✅ |  |  |
| `O` | Open line below  | ✅ |  |  |
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
