ROOT := source_directory() + "/.."

# Install the Debian/Ubuntu base package layer. Requires root or non-interactive sudo.
install:
    bash "{{ROOT}}/scripts/bootstrap/system.sh"
