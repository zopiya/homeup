ROOT := source_directory() + "/.."

# Install locked user CLI tools and apply chezmoi dotfiles. Never requires sudo.
apply:
    bash "{{ROOT}}/scripts/bootstrap/user.sh"
