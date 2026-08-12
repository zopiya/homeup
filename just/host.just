ROOT := source_directory() + "/.."

# Persistent-host-only provisioning. SSH hardening is intentionally excluded.
provision:
    sudo -E bash "{{ROOT}}/scripts/host/provision.sh"
    @echo "Host provisioning complete. Verify the new login before separately running 'just host::ssh-harden'."

# Manual, human-confirmed SSH hardening. Never invoked by bootstrap or provisioning.
ssh-harden:
    sudo -E bash "{{ROOT}}/scripts/host/ssh-harden.sh"
