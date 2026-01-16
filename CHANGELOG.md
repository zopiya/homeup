# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- MIT LICENSE file for open-source compliance
- Comprehensive documentation structure with 26 guides (468KB+)
- Unified Chinese documentation titles with numeric prefixes (01-61 system)
- Quick reference guides (to be added)
- CHANGELOG tracking (this file)

### Changed
- Reorganized documentation files with consistent naming convention
- Improved project metadata and structure

### Fixed
- SSH configuration compatibility improvements
- Homebrew installation and package management refinements

---

## [2.1.0] - 2024-01-16

### Added
- Ghostty terminal emulator setup guide and remote usage guide
- Documentation style guide with unified formatting rules
- 15 comprehensive tool guides covering entire stack:
  - Infrastructure tier (01-04): Chezmoi, Direnv, Just, Git+SSH
  - Editor tier (10-13): Neovim, LSP, VS Code, Lazygit
  - Shell tier (20-23): Shell setup, Sheldon, Zellij, Tmux
  - Packages tier (30-32): Homebrew, YubiKey, Lefthook
  - Workflow tier (40-42): Multi-machine sync, Modern workflow, Mise
  - Reference tier (50-55): Architecture, Best practices, Troubleshooting, Tools, Assessment
- Complete documentation for all 102 installed tools

### Changed
- Refactored all configuration files to improve readability
- Simplified code comments following "code is the best comment" philosophy
- Consolidated Homebrew Brewfiles and optimized package management
- Updated SSH configuration for improved compatibility
- Enhanced error reporting and logging in bootstrap scripts
- Improved Chezmoi configuration with better template variables

### Fixed
- Removed deprecated Git forge entries
- Streamlined Keychain integration in SSH configuration
- Enhanced platform-specific dependency installation (Debian, Fedora, Alpine, Arch)
- Fixed GPG hardening measures in CI workflows
- Corrected profile handling and environment variable verification

---

## [2.0.0] - 2024-01-10

### Added
- Comprehensive project architecture documentation
- Best practices guide covering development workflows
- Complete tools inventory for the Homeup ecosystem
- Platform detection and auto-profile selection (macOS, Linux)
- CI/CD pipeline integration with GitHub Actions
- Security features:
  - YubiKey FIDO2 SSH authentication
  - Git SSH signing support
  - Lefthook for automated pre-commit checks
  - Secret detection in commits

### Changed
- Major refactor of Justfile architecture (4-layer design):
  - Installation layer (bootstrap, core, profiles)
  - Setup layer (environment, tools)
  - Orchestration layer (integration tasks)
  - Validation layer (health checks)
- Restructured dotfiles organization with Chezmoi templates
- Updated Brewfile strategy with bootstrap/core/platform-specific split
- Enhanced shell environment configuration

### Fixed
- Improved error handling in installation scripts
- Enhanced platform detection logic
- Better handling of edge cases in package management

---

## [1.0.0] - 2024-01-01

### Added
- Initial release of Homeup dotfiles management system
- Chezmoi-based configuration synchronization
- Just task runner for package and environment management
- Support for macOS and Linux platforms
- Neovim configuration with LSP support
- Zsh shell customization with Sheldon plugins
- Git configuration with SSH signing
- Homebrew package management
- VS Code profile synchronization
- Tmux terminal multiplexer configuration

### Features
- **102 installed tools** across development, shell, editors, and utilities
- **Chezmoi v2.68.1** for dotfiles management with profile-based deployment
- **4-tier Homebrew strategy**: bootstrap, core, macOS-specific, Linux-specific
- **20+ Just tasks** for complete lifecycle management
- **Multiple shell configurations**: Zsh with aliases, functions, and plugins
- **Editor support**: Neovim with 40+ plugins and VS Code profiles
- **Terminal tools**: Tmux configuration and future Zellij support
- **Version management**: Mise for handling tool versions
- **Git hooks**: Lefthook for automated code quality checks
- **SSH/YubiKey**: Hardware key integration and signing support

---

## Version History Summary

| Version | Date | Focus | Commits |
|---------|------|-------|---------|
| 2.1.0 | 2024-01-16 | Documentation & Polish | 15+ |
| 2.0.0 | 2024-01-10 | Architecture & Features | 30+ |
| 1.0.0 | 2024-01-01 | Initial Release | Initial |

---

## Notes for Contributors

### Breaking Changes (v2.0.0)
- Chezmoi profile auto-detection replaces manual selection
- Brewfile structure changed from flat to tiered approach
- Justfile task names and arguments updated for consistency

### Deprecations
- Mini profile removed in favor of platform-based profiles
- Deprecated Git forge entries removed from SSH config
- Old configuration templates superseded by current versions

### Future Roadmap

**Planned for v2.2.0:**
- Quick reference cards for common commands
- Integration scenario guides
- Enhanced FAQ with troubleshooting
- Version management automation

**Planned for v3.0.0:**
- Possible multi-user support
- Enhanced CI/CD templates
- Expanded platform support (Windows with WSL)
- Package version pinning strategies

---

## How to Contribute

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Reporting Issues
- Check existing issues first
- Use clear, descriptive titles
- Include your OS, shell, and relevant tool versions

### Submitting Changes
- Create feature branches from main
- Follow commit message conventions (see CONTRIBUTING.md)
- Ensure all tests pass with `just validate-all`
- Update documentation for new features

---

## Support

- 📖 [Documentation](docs/) - Comprehensive guides for all tools
- 🐛 [Issues](https://github.com/zopiya/homeup/issues) - Report bugs and request features
- 💬 [Discussions](https://github.com/zopiya/homeup/discussions) - Ask questions and share ideas

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
