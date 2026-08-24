# ✨ Anshu's Dotfiles

> Personal configuration files celebrating 1 year on Linux (Fedora + Niri + Noctalia + Spicetify).

<div align="center">
  <img width="1920" height="1080" alt="Desktop Preview" src="https://github.com/user-attachments/assets/2e922772-b267-43de-bcfa-43ba076cd8ed" />
</div>

<br/>

## 🖥️ System Overview

| Component | Choice |
| :--- | :--- |
| **OS** | [Fedora Linux](https://fedoraproject.org/) (Workstation) |
| **Compositor** | [Niri](https://github.com/YaLTeR/niri) (Scrollable-tiling Wayland compositor) |
| **Desktop Shell** | [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell) (powered by Quickshell) |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| **Music Player** | [Spotify](https://www.spotify.com/) + [Spicetify](https://spicetify.app/) |
| **System Fetch** | [Fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **Scratchpad Manager** | [Piri](https://github.com/Asthestarsfalll/piri) |
| **App Launcher** | Quickshell Launcher / Fuzzel |

---

## 📂 Included Configurations

* **`niri/`** — Tiling layouts, custom animations, gesture support, scratchpad integration, and backdrop rules.
* **`noctalia/`** — Noctalia shell configuration, colorscheme tokens, custom plugins (`clipboard`, `music-search`, `wallcards`, `shell-profiles`, `screen-toolkit`, etc.).
* **`spicetify/`** — Spicetify theme styling (`lucid`, `Comfy`, marketplace configs).
* **`fastfetch/`** — Custom structured ASCII banner and themed specs box.

---

## 📦 Dependencies & Prerequisites

Ensure the following packages and tools are installed before applying the configurations:

### Core Packages (Fedora)
```bash
# Niri compositor & dependencies
sudo dnf install niri fuzzel brightnessctl playerctl cliphist

# Fastfetch & Kitty
sudo dnf install fastfetch kitty
```

### Shell & Scratchpads
* **[Quickshell](https://github.com/outfoxxed/quickshell)** & **[Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell)**
* **[Piri](https://github.com/Asthestarsfalll/piri)** — Niri scratchpad daemon
* **[Spicetify CLI](https://spicetify.app/)** — Spotify client customization

---

## 🚀 Installation & Replication

1. **Clone the repository:**
   ```bash
   git clone https://github.com/14yofemsinmydms/dotfiles.git ~/dotfiles
   ```

2. **Deploy configurations to `~/.config`:**
   ```bash
   # Backup any existing configs first
   mkdir -p ~/.config_backup
   cp -r ~/.config/niri ~/.config/noctalia ~/.config/spicetify ~/.config/fastfetch ~/.config_backup/ 2>/dev/null || true

   # Copy dotfiles
   cp -r ~/dotfiles/niri ~/.config/
   cp -r ~/dotfiles/noctalia ~/.config/
   cp -r ~/dotfiles/fastfetch ~/.config/
   cp -r ~/dotfiles/spicetify ~/.config/
   ```

3. **Apply Spicetify Theme:**
   ```bash
   spicetify backup apply
   ```

4. **Restart / Reload Niri & Noctalia:**
   ```bash
   # Reload Niri config
   niri msg action reload-config
   ```

---

## ⌨️ Useful Keybindings Cheat Sheet

| Keybinding | Action |
| :--- | :--- |
| `Mod + Return` | Open Terminal (`kitty`) |
| `Ctrl + Space` | Toggle Noctalia App Launcher |
| `Mod + S` | Toggle Noctalia Control Center |
| `Mod + Ctrl + S` | Open Noctalia Settings |
| `Mod + Shift + T` | Toggle Scratchpad Terminal (`piri`) |
| `Mod + Shift + S` | Toggle Scratchpad Editor (`piri`) |
| `Mod + P` | Toggle PiP Scratchpad (`piri`) |
| `Alt + F9` | Open Clipboard History |
| `Mod + F4` | Session Menu (Power / Lock) |
| `Mod + Alt + W` | Wallpaper Cards Picker |

---

## 💡 Notes

* Wallpapers are intentionally omitted from this repo. You can set your own wallpaper directory inside Noctalia Settings (`Mod + Ctrl + S` -> Wallpaper).
* Make sure your user paths in `niri/config.kdl` point to your local environment.

---

<div align="center">
  <sub>Crafted with ❤️ on Fedora Linux</sub>
</div>
