# Homeup - Modular Development Environment

A modular, cross-platform, and opt-in personal development environment configuration system based on **Chezmoi** + **Homebrew** + **Mise**.

## 🚀 Features

- **Fast Initialization**: 15 minutes from bare metal to a fully working environment.
- **Cross-Platform**: Supports macOS (Intel/Apple Silicon) and Linux (Debian/Fedora).
- **Modular**: Choose what to install (Security, GUI, Runtime, Maintenance).
- **Infrastructure as Code**: All configurations are version controlled.

## 🛠 Tech Stack

- **Configuration Management**: [Chezmoi](https://www.chezmoi.io/)
- **Package Management**: [Homebrew](https://brew.sh/)
- **Runtime Management**: [Mise](https://mise.jdx.dev/)
- **Shell**: Zsh + [Sheldon](https://sheldon.cli.rs/) + [Starship](https://starship.rs/)
- **Editor**: [Neovim](https://neovim.io/) (Lazy.nvim based)

## 📦 Installation

### 1. Bootstrap (Bare Metal)

Run the following command in your terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/homeup/main/bootstrap.sh)
```

### 2. Manual Installation

If you already have Chezmoi installed:

```bash
chezmoi init --apply https://github.com/yourusername/homeup.git
```

## ⚙️ Configuration

During initialization, you will be prompted to choose which modules to enable:

- **Security Module**: GPG, YubiKey, 1Password
- **GUI Module**: VSCode, Chrome, iTerm2 (macOS only)
- **Mise**: Runtime version manager (Node.js, Python, etc.)
- **Maintenance**: Topgrade, Restic

## 📂 Structure

```
~/.local/share/chezmoi/
├── home/               # Homeup files mapped to $HOME
├── config/             # Modular config snippets
├── scripts/            # Installation scripts
├── data/               # Data templates (Brewfile)
└── .chezmoi.toml.tmpl  # Configuration template
```

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

[MIT](https://choosealicense.com/licenses/mit/)
