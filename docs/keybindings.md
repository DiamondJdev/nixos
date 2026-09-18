# Keybindings

Generated from `modules/home/desktop/hyprland/bindings.nix`. That file is the
source of truth; this document exists because plan §51.17 asks for
user-visible keybindings to be documented.

`SUPER` is the Windows key.

## Applications

| Binding | Action |
|---|---|
| `SUPER + Q` | Terminal (Alacritty) |
| `SUPER + E` | File manager (Dolphin) |
| `SUPER + I` | Settings (mirrors Windows' Win+I) |
| `SUPER + R` | Application launcher (Rofi) |
| `SUPER + Space` | Application launcher (Rofi) |
| `SUPER + V` | Clipboard history |
| `SUPER + N` | Notification centre (SwayNC) |
| `SUPER + X` | Power menu (wlogout) |
| `SUPER + L` | Lock screen (Hyprlock) |

## Windows

| Binding | Action |
|---|---|
| `SUPER + C` | Close window |
| `ALT + F4` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + SHIFT + M` | Maximise |
| `SUPER + SHIFT + F` | Toggle floating |
| `SUPER + G` | Centre window |
| `SUPER + P` | Pseudo-tile |
| `SUPER + J` | Toggle split direction (dwindle only) |
| `SUPER + M` | Exit Hyprland |

## Mouse

| Binding | Action |
|---|---|
| `SUPER + Left drag` | Move window |
| `SUPER + Right drag` | Resize window |
| `SUPER + Middle click` | Toggle maximise |
| `SUPER + Scroll` | Previous / next workspace |

Windows can also be resized by dragging their border directly — the grab area
is widened to 12px, so the modifier is optional.

## Focus and movement

| Binding | Action |
|---|---|
| `SUPER + ←/→/↑/↓` | Move focus |
| `SUPER + SHIFT + ←/→/↑/↓` | Move window |
| `SUPER + 1`…`9`, `0` | Switch to workspace 1–10 |
| `SUPER + SHIFT + 1`…`9`, `0` | Move window to workspace 1–10 |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + SHIFT + S` | Move window to scratchpad |
| `ALT + Tab` | Window switcher (hyprshell) |

## Screenshots

| Binding | Action |
|---|---|
| `Print` | Select region, open in Satty to annotate |
| `SUPER + Print` | Select region, copy to clipboard |
| `SHIFT + Print` | Whole screen to clipboard |
| `SUPER + SHIFT + Print` | Whole screen, open in Satty |

Saved to `~/Pictures/Screenshots/`. Pressing Escape during selection cancels
silently.

## Media and hardware keys

Volume, mute, mic-mute, brightness and playback keys work as labelled, and
continue to work while the session is locked.

## Changed from the previous configuration

Two bindings moved, both because the plan reassigns them:

- `SUPER + V` was *toggle floating*; it is now *clipboard history* (§22).
  Toggle floating moved to `SUPER + SHIFT + F`. With every window floating by
  default, that toggle is now rarely needed.
- `SUPER + Space` is **added** as a launcher binding (§21). `SUPER + R` still
  works.

Everything else — `SUPER + Q/C/E/R/I/M`, the workspace keys, the mouse
bindings and the media keys — is unchanged.
