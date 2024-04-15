#!/usr/bin/env bash

create_project() {
    local lang=$1
    local project_name=$2

    # Create project directory with the given name
    mkdir -p "${project_name}"

    if [ "${lang}" == "flutter" ]; then
        # Clone the flutter template repository
        # git clone https://github.com/babariviere/flutter-nix-hello-world.git "${project_name}"
        git clone -b fix https://github.com/MikiVanousek/flutter-nix-hello-world.git "${project_name}"

        # Remove the README.md file
        rm -f "${project_name}/README.md"

        # TODO: rename project within files
    elif [ "${lang}" == "flake" ]; then
        cd "${project_name}" || exit
        nix flake init --template github:cachix/devenv#flake-parts
        echo 'use flake . --impure --accept-flake-config' > "${project_name}/.envrc"
    else
        # Create a basic .envrc file for direnv
        echo 'use nix' > "${project_name}/.envrc"

        # Copy template files for other languages
        cp -r src/"${lang}"/* "${project_name}/"
    fi

    # Special handling for rust to initialize with cargo and rename the project appropriately
    if [ "${lang}" == "rust" ]; then
        (cd "${project_name}" && cargo init --name "${project_name}")
    fi

    # Automatically allow the .envrc file with direnv, if direnv is installed
    if command -v direnv >/dev/null 2>&1; then
        (cd "${project_name}" && direnv allow)
    fi
}

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <lang> <project_name>"
    echo "example: $0 flutter my_flutter_project"
    exit 1
fi

case "$1" in
    rust|python|bash|flake|flutter)
        create_project "$1" "$2"
        ;;
    *)
        echo "unsupported language. supported languages: rust, python, bash, flake, flutter"
        exit 1
        ;;
esac
