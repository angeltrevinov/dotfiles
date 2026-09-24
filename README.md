# dotfiles

CachyOS (Arch) + Hyprland configuration with an automated install script.

## What's Included

| Config | Directory | Description |
|--------|-----------|-------------|
| Hyprland | `hypr/` | Window manager, idle, lock |
| Waybar | `waybar/` | Status bar |
| Neovim | `nvim/` | LazyVim setup with LSP + formatting |
| Rofi | `rofi/` | App launcher |
| Fish | `fish/` | Shell config |

## Fresh Install (Arch/CachyOS)

```bash
git clone https://github.com/angeltrevinov/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

This will:
1. Install all packages from `pacman-packages.txt`
2. Install AUR packages from `yay-packages.txt` (if yay/paru is available)
3. Symlink all configs into `~/.config/`

Existing configs are backed up before symlinking (e.g. `hyprland.lua.backup.20260908-213352`).

### Options

```bash
./install.sh                 # Install packages + link configs
./install.sh --packages-only # Only install packages
./install.sh --configs-only  # Only link config files
./install.sh --list-packages # Preview package lists without installing
./install.sh -y              # Skip confirmation prompt
```

### Prerequisites

- Arch-based distro (CachyOS, Arch, EndeavourOS, etc.)
- `git` installed
- For AUR packages: install [yay](https://github.com/Jguer/yay) or [paru](https://github.com/Morganamilo/paru) first

## Updating

After changing configs:

```bash
cd ~/dotfiles
# edit files in hypr/, waybar/, nvim/, etc.
git add -A
git commit -m "describe what changed"
git push
```

To sync package lists after installing/removing software:

```bash
pacman -Qe | awk '{print $1}' > pacman-packages.txt
git add pacman-packages.txt && git commit -m "update package list" && git push
```

## Only Using Neovim Config

You don't need the full setup. Just clone the repo and symlink the nvim directory:

```bash
git clone https://github.com/angeltrevinov/dotfiles.git ~/dotfiles
ln -s ~/dotfiles/nvim/.config/nvim ~/.config/nvim
```

On first launch, [lazy.nvim](https://github.com/folke/lazy.nvim) will bootstrap itself and install all plugins.

### Included Plugins

- **LazyVim** base config
- **Neo-tree** file explorer
- **Mason** auto-installs: `lua_ls`, `basedpyright`, `bashls`, `ts_ls`, `stylua`, `ruff`, `prettierd`, `shfmt`
- **Conform.nvim** formatting for Python, JS/TS, JSON, YAML, Markdown, Shell

## Directory Structure

```
dotfiles/
├── install.sh                  # Main install script
├── pacman-packages.txt         # pacman -Qe output
├── yay-packages.txt            # yay -Qm output (AUR)
├── hypr/.config/hypr/
│   ├── hyprland.lua
│   ├── hypridle.conf
│   ├── hyprlock.conf
│   └── scripts/
│       └── hypr-clamshell.sh
├── waybar/.config/waybar/
│   ├── config.jsonc
│   └── style.css
├── nvim/.config/nvim/
│   ├── init.lua
│   ├── lazyvim.json
│   ├── stylua.toml
│   └── lua/
│       ├── config/
│       │   ├── autocmds.lua
│       │   ├── keymaps.lua
│       │   ├── lazy.lua
│       │   └── options.lua
│       └── plugins/
│           ├── disable-news-alert.lua
│           ├── formatting.lua
│           ├── mason.lua
│           └── snacks-animated-scrolling-off.lua
├── rofi/.config/rofi/
│   └── config.rasi
└── fish/.config/fish/
    └── config.fish
```

## License

Do whatever you want with these files.
