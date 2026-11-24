<div align="center">

# knight-rice

**Minimal, daily-driven Hyprland desktop — built for focus, speed, and calm.**

`Arch Linux` · `Hyprland` · `Wayland`

</div>

---

## Overview

A clean, distraction-free environment tuned for everyday work: browsing, YouTube, reading, and light coding.

- **Obsidian & Steel Aesthetic** — Unified dark palette across Hyprland, Waybar, Rofi, Kitty, Dunst, Wlogout, Hyprlock, and Neovim.
- **Your Stack, Your Choice** — Pick **Neovim** or **VS Code** and **Brave**, **Firefox**, **Chromium**, or **Zen Browser** during install (or in `hypr/module/programs.lua`).
- **Curated Wallpapers & Live Theming** — Clones [`bat-fun/wallpaper`](https://github.com/bat-fun/wallpaper) with a 3×2 Rofi gallery picker (`Super + W`) powered by `matugen`.
- **Daily Comfort** — Media pill & Quick Settings dropdown (`󰒓` for Wi-Fi, Bluetooth, Brightness, Volume, Night Light, DND) in Waybar, `Super + G` web/YouTube search, `Super + Alt + R` warm reading mode, and scratchpad (`Super + S`).
- **Minimal SDDM Login** — Optional obsidian SDDM theme (`knight-sddm`) that syncs with your active wallpaper.
- **Safe Installation** — Interactive installer with automatic config backups and atomic rollback if anything fails or is interrupted.

---

## Install

```bash
git clone https://github.com/bat-fun/dotfiles-hybrid.git
cd ~/dotfiles-hybrid
./install.sh
```

The installer walks you through choosing your editor and browser, previews the plan, backs up existing configs in `~/.config`, and rolls back cleanly on any error.

---

## Keybindings

| Keys | Action |
| :--- | :--- |
| `SUPER + Return` | Terminal (`kitty`) |
| `SUPER + A` | App launcher (`rofi`) |
| `SUPER + B` | Browser (configured in `programs.lua`) |
| `SUPER + C` | Editor (`Neovim` or `VS Code`) |
| `SUPER + E` | File manager (`dolphin`) |
| `SUPER + G` | Google / YouTube search (`yt <query>`) |
| `SUPER + W` | Wallpaper gallery picker |
| `SUPER + R` | Random wallpaper |
| `SUPER + K` | Keybind cheatsheet |
| `SUPER + ALT + R` | Toggle warm reading mode |
| `SUPER + ALT + N` | Toggle Do Not Disturb |
| `SUPER + S` | Toggle scratchpad terminal |
| `SUPER + V` | Clipboard history |
| `SUPER + L` / `X` | Lock screen / Power menu |
| `SUPER + Q` | Close window |
| `PRINT` | Screenshot region |

---

## Structure

```text
dunst/         Notification daemon & OSD bars
gtk-3.0/       GTK3 dark theme defaults
gtk-4.0/       GTK4 dark theme defaults
hypr/          Hyprland config, keybinds, lockscreen & scripts
kitty/         Terminal configuration
matugen/       Dynamic color templates
nvim/          Neovim configuration
qt6ct/         Qt6 dark palette (for Dolphin & Qt apps)
rofi/          App launcher, clipboard, control center & wallpaper gallery
sddm/          Minimal Qt6 SDDM login theme (wallpaper-synced)
starship.toml  Minimal single-line prompt
waybar/        Status bar layout & styling
wlogout/       Session power menu
zsh/           Minimal Zsh configuration
install.sh     Interactive, rollback-safe installer
```
