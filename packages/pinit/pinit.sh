#!/usr/bin/env bash

set -o pipefail
trap 'exit 0' SIGINT

# Initial argument values
output_path="$(pwd)"
project_name="$(basename "$(pwd)")"
mode="package"  # Set default mode to "package"
lang=""

# Source directory, will be substituted in place during the build
src_dir="src"

# Display usage information
display_usage() {
  cat <<USAGE
Usage: pinit [OPTIONS...] LANG

Description:
  Initialize a project environment for a given language.

Arguments:
  LANG
    Supported languages: rust, python, bash, javascript
    Shorthands: rs (for rust), py (for python), sh (for bash), js (for javascript)

Options:
  -o, --output VALUE
    Output path for the project (default: current directory)

  -n, --name VALUE
    Name of the project (default: parent directory name)

  -m, --mode VALUE
    Mode of project initialization (default: package)
    Supported modes: package, flake

  -h, --help
    Show this help message

Examples:
  pinit --output /path/to/dir --name my_rust_project rust --mode flake

USAGE
}

# Parse and validate command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -o|--output)
      output_path="$2"
      project_name="$(basename "$output_path")"  # Set project name to output dir name by default
      shift 2
      ;;
    -n|--name)
      project_name="$2"
      shift 2
      ;;
    -m|--mode)
      mode="$2"
      shift 2
      ;;
    -h|--help)
      display_usage
      exit 0
      ;;
    *)
      if [ -z "$lang" ]; then
        lang="$1"
        # Normalize shorthand language names to full names
        case "$lang" in
          sh) lang="bash" ;;
          py) lang="python" ;;
          rs) lang="rust" ;;
          js) lang="javascript" ;;
        esac
      else
        echo "error: unknown option '$1'"
        echo "try '--help' for more information"
        display_usage
        exit 1
      fi
      shift
      ;;
    esac
  done
}

# Create the project based on the provided language and mode
create_project() {
    # Create the output directory
    mkdir -p "${output_path}"
    chmod 755 "${output_path}"

    case "$mode" in
        package)
            echo "status: setting up package project in ${output_path}..."
            if [ -d "${src_dir}/${lang}" ]; then

                cp -vr "${src_dir}/${lang}/." "${output_path}/"

                find "${output_path}" -type d -exec chmod 755 {} \;
                find "${output_path}" -type f -exec chmod 644 {} \;

                echo 'use nix' > "${output_path}/.envrc"
                chmod 644 "${output_path}/.envrc"

                # Rename to default.nix and substitute project name in it
                if [ -f "${output_path}/package.nix" ]; then
                    mv "${output_path}/package.nix" "${output_path}/default.nix"
                    sed -i "s|./package.nix|./default.nix|g" "${output_path}/shell.nix"
                    sed -i "s/foobar/${project_name}/g" "${output_path}/default.nix"
                fi
            else
                echo "error: no source files available for ${lang}"
                exit 1
            fi
            ;;
        flake)
            echo "status: setting up flake project in ${output_path}.."
            if [ -d "${src_dir}/${lang}" ]; then

                cp -vr "${src_dir}/${lang}/." "${output_path}/"
                cp -v "${src_dir}/module.nix" "${output_path}/module.nix"
                cp -v "${src_dir}/flake.nix" "${output_path}/flake.nix"

                find "${output_path}" -type d -exec chmod 755 {} \;
                find "${output_path}" -type f -exec chmod 644 {} \;

                echo '.direnv/' >> "${output_path}/.gitignore"
                echo 'use flake . --impure --accept-flake-config' > "${output_path}/.envrc"
                chmod 644 "${output_path}/.gitignore" "${output_path}/.envrc"

                # Substitute project name in flake.nix
                if [ -f "${output_path}/flake.nix" ]; then
                    sed -i "s/foobar/${project_name}/g" "${output_path}/flake.nix"
                fi
            else
                echo "error: no source files available for ${lang}"
                exit 1
            fi
            ;;
        *)
            echo "error: invalid mode; supported modes are package, flake"
            exit 1
            ;;
    esac

    # Set permissions for directories (755) and files (644)
    find "${output_path}" -type d -exec chmod 755 {} \;
    find "${output_path}" -type f -exec chmod 644 {} \;

    # Initialize the project based on the language
    if [ "${lang}" == "rust" ]; then
        cargo init --name "${project_name}" "${output_path}" --vcs "none"
        ( cd "${output_path}" && cargo build )
    elif [ "${lang}" == "javascript" ]; then
        ( cd "${output_path}" && npm init -y && yarn install )
    fi

    # Automatically allow the .envrc file if direnv is installed
    if command -v direnv >/dev/null 2>&1; then
        direnv allow "${output_path}"
    fi

    # Initialize a git repository at the end if flake mode is used
    if [ "$mode" == "flake" ]; then
        nix flake lock path:"${output_path}"
        git init "${output_path}" --initial-branch=main
        git -C "${output_path}" add -A
        git -C "${output_path}" commit -m "init"
    fi
}

# Main function
main() {
  # Parse arguments
  parse_arguments "$@"

  # Validate language
  if [ -z "$lang" ]; then
      echo "error: no language specified"
      display_usage
      exit 1
  fi

  # Supported languages
  case "$lang" in
      rust|python|bash|javascript)
          create_project
          ;;
      *)
          echo "error: unsupported language '${lang}'"
          echo "supported languages: rust, python, bash, javascript"
          exit 1
          ;;
  esac
}

main "$@"
