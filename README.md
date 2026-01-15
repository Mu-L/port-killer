# PortKiller

<p align="center">
  <img src="https://raw.githubusercontent.com/productdevbook/port-killer/refs/heads/main/platforms/macos/Resources/AppIcon.svg" alt="PortKiller Icon" width="128" height="128">
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-15.0%2B-brightgreen" alt="macOS"></a>
  <a href="https://www.microsoft.com/windows"><img src="https://img.shields.io/badge/Windows-10%2B-0078D6" alt="Windows"></a>
  <a href="https://github.com/productdevbook/port-killer/releases"><img src="https://img.shields.io/github/v/release/productdevbook/port-killer" alt="GitHub Release"></a>
</p>

<p align="center">
A powerful cross-platform port management tool for developers.<br>
Monitor ports, manage Kubernetes port forwards, integrate Cloudflare Tunnels, and kill processes with one click.
</p>

### macOS

<p align="center">
  <img src=".github/assets/macos.png" alt="PortKiller macOS" width="800">
</p>

### Windows

<p align="center">
  <img src=".github/assets/windows.jpeg" alt="PortKiller Windows" width="800">
</p>

## Installation

### macOS

**Homebrew:**
```bash
brew install --cask productdevbook/tap/portkiller
```

**Manual:** Download `.dmg` from [GitHub Releases](https://github.com/productdevbook/port-killer/releases).

### Windows

Download `.zip` from [GitHub Releases](https://github.com/productdevbook/port-killer/releases) and extract.

## Features

### Port Management
- 🔍 Auto-discovers all listening TCP ports
- ⚡ One-click process termination (graceful + force kill)
- 🔄 Auto-refresh with configurable interval
- 🔎 Search and filter by port number or process name
- ⭐ Favorites for quick access to important ports
- 👁️ Watched ports with notifications
- 📂 Smart categorization (Web Server, Database, Development, System)

### Kubernetes Port Forwarding
- 🔗 Create and manage kubectl port-forward sessions
- 🔌 Auto-reconnect on connection loss
- 📝 Connection logs and status monitoring
- 🔔 Notifications on connect/disconnect

### Cloudflare Tunnels
- ☁️ View and manage active Cloudflare Tunnel connections
- 🌐 Quick access to tunnel status

### Cross-Platform
- 📍 Menu bar integration (macOS)
- 🖥️ System tray app (Windows)
- 🎨 Native UI for each platform

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup.

## Sponsors

<p align="center">
  <a href="https://cdn.jsdelivr.net/gh/productdevbook/static/sponsors.svg">
    <img src='https://cdn.jsdelivr.net/gh/productdevbook/static/sponsors.svg'/>
  </a>
</p>

## License

MIT License - see [LICENSE](LICENSE).
