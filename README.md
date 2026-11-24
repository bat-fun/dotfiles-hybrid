<div align="center">

# knight-rice

**Minimal, Daily-Driven Hyprland Environment**

`ARCH LINUX` &nbsp;·&nbsp; `HYPRLAND` &nbsp;·&nbsp; `WAYLAND`

</div>

A clean, distraction-free desktop environment engineered for speed, low cognitive load, and reliable day-to-day productivity.

---

## Highlights

- **Precision Window Management**: Hyprland configured with tight 1px borders, subtle depth shading, crisp input repeat/touchpad settings, and swift animations.
- **Unified Status Bar**: Minimalist Waybar displaying only essentials (workspaces, focused window, active media pill via MPRIS, connectivity, volume, battery, and clock/calendar).
- **Streamlined Workflow**: Frictionless application launcher via Rofi, fast terminal scratchpad (`Super + S`), clipboard manager (`Super + V`), quick Google/YouTube search (`Super + G`, prefix `yt ` for YouTube), and instant OSD indicators.
- **Eye Comfort & Reading**: One-keybind warm reading filter (`Super + Alt + R`) via `hyprsunset`.
- **Cohesive Muted Palette**: Matte obsidian and steel tones synchronized across Hyprland, Waybar, Rofi, Kitty, Dunst, Wlogout, Hyprlock, and Neovim.
- **Flexible Tooling**: Choose between **Neovim** or **VS Code** as your editor, and **Brave**, **Firefox**, **Chromium**, or **Zen Browser** during installation (or in `hypr/module/programs.lua`).
- **Curated Wallpapers**: Clones `github.com/bat-fun/wallpaper` during install with a redesigned 3×2 Rofi gallery picker (`Super + W`) and dynamic Matugen theming.

---

## Installation

Review `install.sh`, then run:

```bash
cd ~/dotfiles-hybrid
./install.sh
```

Existing configurations are automatically backed up before deployment.

---

## Keybindings

`SUPER` corresponds to the Windows/Super key.

| Keys | Action |
| :--- | :--- |
| `SUPER + Return` | Open Terminal (Kitty) |
| `SUPER + A` | Application Launcher (Rofi) |
| `SUPER + E` | File Manager (Dolphin) |
| `SUPER + B` | Web Browser (configured in `programs.lua`) |
| `SUPER + C` | Code Editor (Neovim or VS Code) |
| `SUPER + S` | Toggle Scratchpad Terminal |
| `SUPER + SHIFT + S` | Send window to scratchpad |
| `SUPER + Q` | Close focused window |
| `SUPER + SPACE` | Toggle floating |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + V` | Clipboard history |
| `SUPER + SHIFT + V` | Clear clipboard history |
| `SUPER + .` | Emoji picker |
| `SUPER + G` | Web search (prefix `yt ` for YouTube) |
| `SUPER + W` | Wallpaper picker |
| `SUPER + R` | Random wallpaper |
| `SUPER + ALT + R` | Toggle warm reading mode |
| `SUPER + SHIFT + W` | Reload Waybar |
| `SUPER + L` | Lock screen |
| `SUPER + X` | Power / Logout menu |
| `SUPER + M` | Exit Hyprland |
| `PRINT` / `SHIFT + PRINT` | Screenshot region / Fullscreen |
| `SUPER + 1` … `SUPER + 0` | Switch to workspace 1–10 |
| `SUPER + SHIFT + 1` … `SUPER + SHIFT + 0` | Move window to workspace 1–10 |

Hardware volume, mute, brightness, and media control keys are configured out of the box with Dunst OSD progress bar feedback.

---

## Structure

```text
dunst/         Notification daemon configuration and styling
gtk-3.0/       GTK dark theme preferences
hypr/          Hyprland window manager setup, bindings, and scripts
kitty/         Terminal emulator settings and keybindings
matugen/       Color scheme generation and templates
nvim/          Neovim text editor configuration
rofi/          Application launcher and gallery wallpaper picker styling
starship.toml  Minimal shell prompt configuration
waybar/        Status bar configuration and stylesheet
wlogout/       Session power menu layout and style
install.sh     Interactive backup, preference, and deployment script
```
