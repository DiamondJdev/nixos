# Titanfall 2 Rice — Plan

Status: **planning** · Started 2026-08-23 · Target host: `nixos` (flake `~/nixos#nixos`)

Goal: turn this desktop into a coherent Titanfall 2 / Frontier-war themed
environment — boot splash through login through shell through editor — driven
entirely from this flake, so it's reproducible and rollback-safe.

---

## 1. Design brief

"Titanfall 2 themed" is not just "dark blue with orange accents". The look has
specific rules worth naming up front, because every later decision defers to
them:

- **Angular, never rounded.** TF2's HUD is built from clipped corners, chevrons,
  and hard 45° cuts. Border radius should be `0` almost everywhere; where a
  shape needs interest, cut a corner instead of rounding it.
- **Dark, near-black navy ground.** Not gray, not pure black — a cold blue-black
  that makes the accents glow.
- **One dominant accent, one warning accent.** IMC = cyan/blue authority.
  Militia = orange/amber scrappiness. Picking one as dominant and using the
  other *only* for alerts/warnings is what keeps it from looking like a generic
  "cyberpunk" rice.
- **Thin rules and hairlines.** 1px lines, bracket corners, tick marks, and
  scanline overlays rather than heavy borders or drop shadows.
- **Condensed technical type.** Wide-tracked, uppercase, condensed sans for
  labels. Monospace only in the terminal.
- **Diegetic language.** Labels read like the game's UI: `PILOT`, `STANDBY FOR
  TITANFALL`, `NEURAL LINK ESTABLISHED`, `IMC PROPERTY`. This is the single
  highest-payoff / lowest-effort part of the whole rice.
- **Motion is snappy, not floaty.** Animations 120–180ms, ease-out, with a hint
  of overshoot. Nothing should fade lazily.

Anti-goals: neon pink, glassmorphism/blur-heavy panels, rounded "macOS" docks,
rainbow gradients, Catppuccin-style pastels.

---

## 2. Decisions needed before building

These fork the work substantially. My recommendation is marked.

### 2.1 Desktop: stay on Plasma 6, or move to Hyprland?

Currently: `services.desktopManager.plasma6.enable = true` + SDDM.

| | Plasma 6 | Hyprland |
|---|---|---|
| Effort to deep-rice | High — fighting Kvantum + Aurorae + QML | High — but you're building from nothing, so nothing fights you |
| Ceiling | Good, but Plasma's own design language leaks through | Very high — every pixel is yours |
| Declarative in Nix | Awkward (`plasma-manager` helps but is fiddly) | Excellent — Hyprland/Waybar configs are plain text files |
| Risk | Low, keeps a working desktop | Medium — you'll hand-roll bar, launcher, lock, notifications, screenshots, clipboard |
| Gaming (Steam/TF2 itself) | Works | Works, but check your GPU vendor first |

**Recommendation: Hyprland**, and keep Plasma installed as a fallback session in
SDDM until the Hyprland setup is genuinely daily-drivable. A HUD-style rice is
fundamentally a *bar and widget* rice, and Waybar + hand-written CSS gets you
the angular clipped-corner HUD look in an afternoon; getting the same out of
Plasma's panel means writing QML plasmoids.

> **Decide:** _[ ] Plasma_ · _[ ] Hyprland_ · _[ ] Hyprland w/ Plasma fallback_

If Plasma wins, phases 4–6 below change shape but the palette, typography,
asset, and audio phases are unaffected.

### 2.2 Faction: IMC or Militia?

- **IMC** — cyan/blue on black, clean, corporate, high contrast, lots of
  hairline grids. Easier to make look *expensive*. Easier on the eyes for long
  sessions.
- **Militia** — orange/amber, stencil type, scuffed metal textures, asymmetric.
  More characterful, harder to keep legible, more likely to fatigue.

**Recommendation: IMC-dominant with Militia orange reserved for warnings,
errors, and "active/urgent" states.** This gives you both palettes without the
mud, and it maps naturally onto real UI semantics (error text, low battery,
failed builds, git dirty state).

> **Decide:** _[ ] IMC_ · _[ ] Militia_ · _[ ] IMC + Militia-as-alert_

### 2.3 Theming engine: hand-rolled, or Stylix?

[Stylix](https://github.com/danth/stylix) applies one base16 scheme + wallpaper
across GTK/Qt/terminal/editors/etc. automatically.

- **Note:** Stylix is *not* in nixpkgs — it's a flake input
  (`github:danth/stylix`). Verified against this system's 26.05 nixpkgs.
- Pro: enormous coverage for one config block; fixes the "app I forgot to theme"
  problem permanently.
- Con: it's opinionated, and a Titanfall rice wants deliberate, non-uniform
  color use (accent-as-semantics, not accent-everywhere). You'd fight it in
  places and override a lot.

**Recommendation: adopt Stylix for the long tail (GTK apps, Qt apps, cursors,
generic fonts), but hand-write the pieces that carry the theme's identity** —
Waybar, hyprlock, starship, SDDM, Plymouth. Best of both.

> **Decide:** _[ ] Stylix + hand-written hero pieces_ · _[ ] fully hand-rolled_

### 2.4 Home Manager

Everything in this repo is currently system-level. A rice is overwhelmingly
*per-user dotfiles* (Waybar CSS, Hyprland conf, alacritty, editor themes,
btop, cava, Obsidian snippets…). Writing all of that with
`environment.etc` / `xdg.configFile`-by-hand is painful.

**Recommendation: adopt Home Manager as a flake input and a NixOS module.** This
is a prerequisite for most of phases 4–8 and should be done first, in isolation,
before any theming so a breakage is unambiguous.

> **Decide:** _[ ] adopt Home Manager_ · _[ ] stay system-only_

---

## 3. Target repo layout

Current: `configuration.nix` + `modules/{ssh,swap,shell}.nix`, all imported
explicitly in `flake.nix`. That pattern scales fine; extend it rather than
replace it.

```
nixos/
├── flake.nix
├── configuration.nix
├── hardware-configuration.nix
├── docs/
│   └── rice.md                 ← this file
├── theme/
│   ├── palette.nix             ← SINGLE SOURCE OF TRUTH for colors
│   ├── fonts.nix               ← font packages + family name attrs
│   └── assets/                 ← wallpapers, logos, ascii art, sounds
├── modules/                    ← system-level
│   ├── ssh.nix
│   ├── swap.nix
│   ├── shell.nix
│   ├── desktop.nix             ← compositor / display manager / portals
│   ├── boot-splash.nix         ← plymouth
│   ├── login.nix               ← sddm theme
│   └── fonts.nix
└── home/                       ← home-manager, per-user
    ├── default.nix
    ├── hyprland.nix
    ├── waybar/{default.nix,style.css,config.jsonc}
    ├── terminal.nix            ← alacritty
    ├── starship.nix            ← moved from modules/shell.nix
    ├── notifications.nix
    ├── lockscreen.nix
    └── apps/{zed.nix,obsidian.nix,zen.nix,btop.nix}
```

**The key architectural idea: `theme/palette.nix` exports the palette as a plain
Nix attrset, and every other module imports it.** Waybar CSS, starship, alacritty,
hyprlock, Plymouth, and the SDDM theme all interpolate from that one file. Change
`accent` in one place, the whole desktop moves. Do not hardcode a hex value
anywhere else — the current `modules/shell.nix` starship block has ~20 hardcoded
hexes and is the first thing to migrate.

---

## 4. The palette

Draft IMC-dominant scheme, base16-compatible so Stylix can consume it directly.

| Role | base16 | Hex | Use |
|---|---|---|---|
| Ground | base00 | `#070B10` | Desktop, terminal bg, panel voids |
| Panel | base01 | `#0E141C` | Bar background, popups |
| Selection | base02 | `#1A2430` | Selected rows, inactive tab |
| Muted | base03 | `#45566B` | Comments, disabled, hairlines |
| Dim text | base04 | `#7B8FA3` | Secondary labels |
| Text | base05 | `#C9D8E4` | Primary foreground |
| Bright text | base06 | `#E4EEF6` | Headings, active label |
| White | base07 | `#FFFFFF` | Rare max-emphasis only |
| Red / critical | base08 | `#E23B2E` | Errors, "TITAN CRITICAL" |
| **Militia orange** | base09 | `#FF7A18` | Warnings, urgent, git dirty |
| Amber | base0A | `#F5C542` | Caution, modified state |
| Green | base0B | `#46C08A` | Success, friendly ping |
| Bright cyan | base0C | `#2FD8E0` | Hover, focus ring |
| **IMC blue** | base0D | `#21B7E8` | **Primary accent** — active window, prompt, links |
| Purple | base0E | `#8B6BD9` | Rare; special modes |
| Brown | base0F | `#A85B2B` | Rare; deprecated/archived |

Tasks:

- [ ] Write `theme/palette.nix` exporting the above as `{ base00 = "#070B10"; ... }`
      plus friendly aliases (`accent`, `warn`, `crit`, `bg`, `fg`).
- [ ] Sanity-check contrast: `base05` on `base00` and `base0D` on `base00` should
      both clear 4.5:1. Bump `base05` lighter if not.
- [ ] Decide whether a Militia variant ships as a second attrset that can be
      swapped with one line (nice-to-have, genuinely fun, low cost if the
      single-source-of-truth rule is honored).

---

## 5. Typography

The actual Titanfall font is proprietary and not redistributable — don't try to
vendor it into the repo. Free approximations that read correctly:

- **UI / display:** Rajdhani, Saira Condensed, or Titillium Web. All three ship
  inside the `google-fonts` package (verified present in 26.05); they are *not*
  standalone nixpkgs attrs. `orbitron` *is* a standalone attr (verified) but is
  too wide/retro-futurist for body UI — good for a single big display element
  like the lock screen clock, bad everywhere else.
- **Monospace:** you already have `nerd-fonts.fira-code`. Fine. Consider
  `nerd-fonts.jetbrains-mono` for a slightly more technical feel. Keep a Nerd
  Font — the starship config depends on the glyphs.

Tasks:

- [ ] `theme/fonts.nix`: install `google-fonts` (or a slimmed subset) + nerd font,
      and export family-name strings so no module hardcodes `"Rajdhani"`.
- [ ] Set `fonts.fontconfig.defaultFonts` for sans/serif/mono.
- [ ] Establish type rules: UI labels uppercase + `letter-spacing: 0.08em`,
      weights 500/600 only, no italics.

---

## 6. Phased build

Each phase should be one commit (or a small series) and should end at a bootable,
rebuildable system. `nixos-rebuild switch` keeps old generations — if a phase
breaks the desktop, pick the previous generation in systemd-boot. That's the
safety net; nothing here is irreversible.

### Phase 0 — Groundwork (no visible change)

- [ ] Create `docs/` (this file) and commit.
- [ ] Add Home Manager to `flake.nix` inputs, wire `home-manager.nixosModules.home-manager`,
      create `home/default.nix` with an empty-but-valid config. Rebuild. Verify
      nothing changed visually.
- [ ] Add `theme/palette.nix` and `theme/fonts.nix`. Nothing consumes them yet.
- [ ] Migrate `modules/shell.nix`'s starship block into `home/starship.nix`, and
      replace its hardcoded hexes with palette references. Visual output should
      be *close to* unchanged — this proves the palette plumbing works before
      anything depends on it.
- [ ] Add `.editorconfig` / confirm `nixfmt` formatting stays consistent with the
      existing files.

### Phase 1 — Assets

- [ ] Collect wallpapers. Sources: official EA/Respawn key art, r/titanfall,
      Wallhaven (`titanfall` tag), ArtStation. Want at least: one dark
      Titan-silhouette piece for the desktop, one high-contrast piece for the
      lock screen, one very dark/low-detail piece for the boot splash.
- [ ] Normalize to your monitor's native resolution; keep the focal subject out
      of where the bar and lock-screen clock will sit.
- [ ] Vector the IMC and Militia insignia as SVG (redraw or trace) so they scale
      into the bar, lock screen, and splash cleanly.
- [ ] Build a fastfetch ASCII logo — an IMC insignia or Titan chassis in ASCII.
      This is high-visibility since `fastfetch` already runs on every shell init.
- [ ] **Audio:** the boot/login/notification sounds should come from your own
      owned copy of the game (VPK extraction) or be original recordings. Don't
      pull ripped audio packs into the repo — keep `theme/assets/audio/`
      gitignored and document the extraction step instead. Nix builds are
      reproducible only if the asset is present, so note this as a manual
      bootstrap step in the README.
- [ ] Decide repo policy on binary assets: commit directly (simple, bloats git)
      vs. fetch via `pkgs.fetchurl` with hashes (clean, but needs a host). For a
      handful of wallpapers, committing is fine.

### Phase 2 — Boot: Plymouth

- [ ] `boot.plymouth.enable = true`.
- [ ] Note: `boot.loader.systemd-boot` is essentially unthemeable — the menu is
      plain text. Options: (a) accept it and set `boot.loader.timeout` low so
      it flashes past; (b) switch to rEFInd for a themed boot menu. **Recommend
      (a)** — not worth the bootloader risk.
- [ ] Custom Plymouth theme: an IMC boot-sequence progress bar with
      `NEURAL LINK … STANDBY`. Start from `adi1090x-plymouth-themes` (verified in
      nixpkgs) as a structural reference, then write your own
      `.plymouth`/`.script` pair into `theme/assets/plymouth/`.
- [ ] Add `boot.kernelParams = [ "quiet" "splash" ... ]` and reduce console noise
      so the splash isn't interrupted by kernel text.
- [ ] Verify it survives a real cold boot, not just a rebuild.

### Phase 3 — Login: SDDM

- [ ] Custom QML theme. `sddm-astronaut` (verified in nixpkgs) is a good,
      modern, Qt6 base to fork — copy it into `theme/assets/sddm/` and rewrite
      the layout and palette rather than depending on it directly.
- [ ] Target look: full-bleed dark wallpaper, hairline-bracketed username field,
      `PILOT AUTHENTICATION` header, `> INITIATE` for the login button, faction
      insignia watermark, session/power controls as small ticked icons.
- [ ] SDDM must be Qt6 to match Plasma 6 / modern themes — confirm the theme's
      Qt version matches or it silently falls back to the default.
- [ ] Keep a known-good fallback theme configured so a broken QML doesn't lock
      you out of the machine. Test by switching to a TTY before rebooting.

### Phase 4 — Compositor (assumes Hyprland; skip if staying on Plasma)

- [ ] Enable Hyprland, XDG portals, and a polkit agent. Keep the Plasma session
      listed in SDDM as fallback.
- [ ] `home/hyprland.nix`: keybinds, workspace rules, window rules.
- [ ] Visual config from the palette: `border_size = 1`, zero rounding,
      `col.active_border` = IMC blue, `col.inactive_border` = muted, no shadows
      or a single very tight one, minimal blur (blur is off-brief).
- [ ] Animations: 120–180ms, `easeOutQuint`-ish, slide-in from the direction of
      travel. No `popin` bounce.
- [ ] Wallpaper daemon: **`swww` is no longer in nixpkgs 26.05** (verified
      absent). Use `hyprpaper` (verified present) for static, or `mpvpaper` if
      you want an animated/looping wallpaper — a slow-panning Frontier shot is
      very on-theme but costs GPU while gaming, so make it toggleable.
- [ ] Screenshot, clipboard, idle daemon, and screen-share all need explicit
      setup on Hyprland — budget a session for the boring plumbing.

### Phase 5 — The HUD: Waybar

This is the centerpiece. `waybar` verified present in nixpkgs.

- [ ] Decide placement: top bar reads more like a game HUD; consider two bars
      (thin top status + bottom "loadout" launcher strip) if you want to commit.
- [ ] Modules: workspaces (as numbered chevrons), active window title (uppercase,
      tracked), clock, CPU/mem/temp as thin meters, network, audio, battery,
      tray, and a custom module or two.
- [ ] CSS is where the theme lives. Techniques that sell it:
  - `clip-path: polygon(...)` for cut corners on each module
  - 1px `border-bottom` hairlines in `base03`
  - accent-colored left edge on the focused workspace
  - a repeating-linear-gradient scanline overlay at ~3% opacity
  - color state transitions: normal `base04` → warn `base09` → crit `base08`
- [ ] Custom modules worth building:
  - **Titanfall countdown** — a `custom/` module showing uptime styled as
    `TITANFALL IN 00:00`, or a rebuild-since counter.
  - **Faction indicator** — clicking toggles IMC/Militia accent live.
  - **`nixos-rebuild` status** — dirty flake / generation number.
- [ ] Generate `style.css` from `theme/palette.nix` via `pkgs.substituteAll` or a
      Nix string, so it stays on the single source of truth.

### Phase 6 — Launcher, notifications, lock

- [ ] **Launcher:** `rofi` (verified) or `walker` (verified). Style it as a
      loadout-select screen — grid of large tiles, hard-cut corners, accent
      selection bracket. `wofi` is present too but is much harder to style well.
- [ ] **Notifications:** `dunst`, `mako`, or `swaynotificationcenter` (all
      verified). Style as HUD alerts sliding in from the top-right with a
      colored left bar keyed to urgency (`base0D` → `base09` → `base08`). Add
      the TF2 notification blip as the sound.
- [ ] **Lock:** `hyprlock` (verified). Big Orbitron clock, `PILOT: CAMERON`,
      password field as a bracketed input, failed attempt →
      `AUTHENTICATION FAILED` in Militia orange. Wire `hypridle` for timeout.
- [ ] Consider a logout/power menu (`wlogout`-style) with `EJECT` / `STANDBY` /
      `SHUTDOWN` labels.

### Phase 7 — Terminal and shell

- [ ] `alacritty` (already installed): palette colors, zero padding *or*
      deliberate large padding, opacity ~0.92, no rounding, cursor as a solid
      block in IMC blue.
- [ ] Consider `kitty` or `foot` (both verified) if you want ligature/graphics
      features Alacritty lacks — but Alacritty is fine and already configured;
      don't churn without a reason.
- [ ] **Starship rework.** The current powerline theme is the generic blue/gray
      one and is the single most-visible thing that doesn't match. Redesign
      around: `` (right chevron) separators, IMC blue for path, orange for
      dirty git state, a `▶` or `❯` prompt char that turns orange on non-zero
      exit. Pull every color from `theme/palette.nix`.
- [ ] fastfetch: custom ASCII logo (phase 1) + trimmed module list with renamed
      labels (`HOST` → `CHASSIS`, `KERNEL` → `FIRMWARE`, `UPTIME` → `TIME SINCE
      DEPLOYMENT`). Cheap, very effective.
- [ ] zsh: theme completion menu colors, `ls`/`eza` colors, and consider an
      `LS_COLORS` derived from the palette.
- [ ] `btop` / `cava` (verified) themes from the palette — `cava` on the desktop
      as a HUD audio meter is very on-theme.

### Phase 8 — Applications (the long tail)

- [ ] **Zed** — custom theme JSON generated from the palette, dropped into
      `~/.config/zed/themes/`. Also set the buffer font.
- [ ] **Obsidian** — CSS snippet theme. Its default UI is rounded and soft;
      overriding radius and accent gets most of the way there.
- [ ] **Zen browser** — `userChrome.css` for the tab strip and URL bar. Requires
      `toolkit.legacyUserProfileCustomizations.stylesheets = true`. Consider a
      matching new-tab page.
- [ ] **Steam** — you have Steam enabled and TF2 presumably installed. A dark
      skin (Millennium-based) is optional and lives outside Nix; note it as
      manual.
- [ ] **GTK / Qt fallback theming** — this is where Stylix earns its place. If
      not using Stylix: a GTK theme + `qt6Packages.qtstyleplugin-kvantum` with a
      custom Kvantum theme, plus `qt.platformTheme`.
- [ ] **Icons** — `papirus-icon-theme` (verified) recolored to the accent via
      `papirus-folders`, or Tela. Icons are the easiest place for the theme to
      fall apart.
- [ ] **Cursor** — `bibata-cursors` (verified) in a modern/angular variant. Set
      it consistently across Hyprland, GTK, Qt, and XWayland or you'll get
      cursor-size flicker between apps.

### Phase 9 — Audio and polish

- [ ] Boot/login sound via a systemd user service or the compositor's exec-once.
- [ ] Notification blip, error tone, lock/unlock sounds.
- [ ] Optional and very on-theme: a shell greeting that occasionally emits a
      BT-7274 line. Keep it toggleable — it will get old.
- [ ] Screenshot the finished desktop, add to `docs/` for the repo README.

---

## 7. Risks and how to not brick the desktop

| Risk | Mitigation |
|---|---|
| Broken SDDM theme locks you out | Test from a TTY first; keep a fallback theme set; you can always boot the previous generation |
| Hyprland session unusable | Keep Plasma listed as a session in SDDM through phase 6 at minimum |
| Plymouth hides a real boot error | Keep a non-quiet boot entry, or be ready to remove `quiet splash` from the kernel params at the boot menu |
| GPU/driver trouble on Wayland | Check vendor before phase 4 — this is the one thing that can genuinely block the Hyprland path |
| Rice churn eats weeks | One phase per session; each phase ends bootable and committed |
| Asset licensing | Game assets stay local and gitignored; only original/redrawn art is committed |

Rollback is always: reboot → pick the previous generation in systemd-boot
(`configurationLimit = 15`, so there's plenty of history). Worth confirming that
still holds after the Plymouth change.

---

## 8. Suggested order of attack

If you want visible payoff fast rather than strict phase order:

1. Phase 0 groundwork (unavoidable, do it properly)
2. Starship + fastfetch + alacritty (phase 7) — every terminal instantly on-theme
3. Wallpaper + Waybar (phases 1, 5) — the desktop reads as Titanfall
4. Lock screen (phase 6) — high wow-per-hour
5. SDDM + Plymouth (phases 2–3) — completes the boot-to-desktop story
6. App long tail (phase 8) — slow grind, do it opportunistically

---

## 9. Open questions

- [ ] GPU vendor/model? Gates the Hyprland decision.
- [ ] Monitor count, resolutions, refresh rates? Gates wallpaper prep and Waybar
      layout.
- [ ] Do you actually want an animated wallpaper, given you game on this machine?
- [ ] Is a second, hot-swappable Militia palette worth the extra abstraction, or
      is that scope creep?
- [ ] Should `docs/` also carry a `decisions.md` log, so the "why" behind the
      forks in §2 survives past this file?
