ROOT := source_directory() + "/.."

# Install locked Node.js, Bun, CPython, and Rust runtimes.
install:
    bash "{{ROOT}}/scripts/bootstrap/language.sh"
