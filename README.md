# Ambxst

<img src="./assets/ambxst/ambxst-banner.png" alt="Ambxst Logo" style="max-width: 500px; width: 100%;" align="center" />

<p align="center">
An ***Ax**tremely* customizable shell.
</p>

---

## Screenshots

<img src="./assets/screenshots/1.png" />
<img src="./assets/screenshots/2.png" />
<img src="./assets/screenshots/3.png" />
<img src="./assets/screenshots/4.png" />
<img src="./assets/screenshots/5.png" />
<img src="./assets/screenshots/6.png" />
<img src="./assets/screenshots/7.png" />

---

## Installation

```bash
curl -L get.axeni.de/ambxst | sh
````

> **⚠️ WARNING**
> Ambxst is currently in early development.

👉 **Check the code:**
[https://github.com/Axenide/Ambxst](https://github.com/Axenide/Ambxst)
*(Mmm... Spaghetti. 🍝)*

---

### What does the installation do?

On **non-NixOS** distros, the installation script does the following:

* Installs [Nix](https://en.wikipedia.org/wiki/Nix_%28package_manager%29) if it's not already installed.
* Installs some necessary system dependencies (only a few that Nix cannot handle by itself).
* Installs Ambxst as a Nix flake. (*Dependency hell*? No, thanks. 😎)
* Creates an alias to launch `ambxst` from anywhere
  (for example: `exec-once = ambxst` in your `hyprland.conf`).
* Gives you a kiss on the cheek. 😘 (Optional, of course.)

On **NixOS**:

* Installs Ambxst via:

  ```bash
  nix profile add github:Axenide/Ambxst
  ```

> **ℹ️ NOTE**
> The installation script doesn't do anything else on NixOS, so you can declare it however you like in your system.

---

## Features

* [x] Customizable components
* [x] Themes
* [x] System integration
* [x] App launcher
* [x] Clipboard manager
* [x] Quick notes (and not so quick ones)
* [x] Wallpaper manager
* [x] Emoji picker
* [x] [tmux](https://github.com/tmux/tmux) session manager
* [x] System monitor
* [x] Media control
* [x] Notification system
* [x] Wi-Fi manager
* [x] Bluetooth manager
* [x] Audio mixer
* [x] [EasyEffects](https://github.com/wwmm/easyeffects) integration
* [x] Screen capture
* [x] Screen recording
* [x] Color picker
* [x] OCR
* [x] QR and barcode scanner
* [x] Webcam mirror
* [x] Game mode
* [x] Night mode
* [x] Power profile manager
* [x] AI Assistant
* [x] Weather
* [x] Calendar
* [x] Power menu
* [x] Workspace management
* [x] Support for different layouts (dwindle, master, scrolling, etc.)
* [x] Multi-monitor support
* [x] Customizable keybindings
* [ ] Plugin and extension system
* [ ] Compatibility with other Wayland compositors

---

## What about the *docs*?

I want to release this before the end of the year, so you'll have to wait a bit for the full documentation. u_u

For now, the most important things to know are:

* The main configuration is located at `~/.config/Ambxst`
* Removing Ambxst is as simple as:

  ```bash
  nix profile remove Ambxst
  ```
* You can ask anything on the:

  * [Axenide Discord server](https://discord.com/invite/gHG9WHyNvH)
  * [GitHub discussions](https://github.com/Axenide/Ambxst/discussions)

> **⚠️ CAUTION**
> Packages installed via Nix will take priority over system ones.
> Keep this in mind if you run into version conflicts.
