#!/usr/bin/env bash

create_project() {
    local lang=$1
    local project_name=$2

    # Create project directory with the given name and copy template files
    mkdir -p "${project_name}"
    cp -r "src/${lang}/." "${project_name}/"

    # Special handling for Rust to initialize with Cargo and rename the project appropriately
    if [ "${lang}" == "rust" ]; then
        (cd "${project_name}" && cargo init --name "${project_name}")
    fi

    # Create a basic .envrc file for direnv
    echo 'use nix' > "${project_name}/.envrc"

    # Automatically allow the .envrc file with direnv, if direnv is installed
    if command -v direnv >/dev/null 2>&1; then
        (cd "${project_name}" && direnv allow)
    fi
}

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <lang> <project_name>"
    echo "Example: $0 rust my_rust_project"
    exit 1
fi

case "$1" in
    rust|python|bash)
        create_project "$1" "$2"
        ;;
    *)
        echo "Unsupported language. Supported languages: rust, python, bash"
        exit 1
        ;;
esac
